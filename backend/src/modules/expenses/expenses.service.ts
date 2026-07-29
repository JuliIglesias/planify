import { BadRequestError, NotFoundError } from '../../common/errors';
import { GastoCompleto, MontoParticipante } from '../../domain/entities';
import {
  EventoRepository,
  GastoDetallado,
  GastoRepository,
  ParticipanteRepository,
} from '../../domain/repositories';
import { ActivityLogService } from '../activity-log/activity-log.service';
import { ActivityType } from '../activity-log/activity-log.types';
import { DebtsService } from '../debts/debts.service';
import { fromCents, splitEvenlyCents, toCents } from '../debts/debt-engine';
import { EventsService } from '../events/events.service';

export interface CrearGastoInput {
  descripcion: string;
  montoTotal: string | number;
  /** Quién puso la plata: soporta varios acreedores (FR7). */
  acreedores: MontoParticipante[];
  /** A quién le toca pagar. Si se omite, se divide en partes iguales. */
  deudores?: MontoParticipante[];
  dividirEntre?: string[];
}

/** SCRUM-11 — HU-13/HU-14/HU-19. */
export class ExpensesService {
  constructor(
    private readonly gastos: GastoRepository,
    private readonly eventos: EventoRepository,
    private readonly participantes: ParticipanteRepository,
    private readonly debts: DebtsService,
    private readonly events: EventsService,
    private readonly log: ActivityLogService,
  ) {}

  async crear(
    eventoId: string,
    participanteId: string,
    input: CrearGastoInput,
  ): Promise<GastoCompleto> {
    const descripcion = input.descripcion?.trim();
    if (!descripcion) throw new BadRequestError('descripcion es requerida');

    const evento = await this.eventos.findById(eventoId);
    if (!evento) throw new NotFoundError('Evento no encontrado');
    if (evento.estado === 'cancelado') throw new BadRequestError('El evento está cancelado');

    const totalCents = toCents(input.montoTotal);
    if (totalCents <= 0) throw new BadRequestError('montoTotal debe ser mayor a 0');

    const acreedores = input.acreedores ?? [];
    if (acreedores.length === 0) throw new BadRequestError('Se requiere al menos un acreedor');

    // Si los aportes no suman el total, el gasto está mal cargado: preferimos
    // rechazarlo antes que generar deudas silenciosamente incorrectas (NFR#4).
    const sumaAcreedores = acreedores.reduce((acc, a) => acc + toCents(a.monto), 0);
    if (sumaAcreedores !== totalCents) {
      throw new BadRequestError(
        `Los aportes suman ${fromCents(sumaAcreedores)} pero el gasto es ${fromCents(totalCents)}`,
      );
    }

    const deudores = await this.resolverDeudores(eventoId, totalCents, input);

    const sumaDeudores = deudores.reduce((acc, d) => acc + toCents(d.monto), 0);
    if (sumaDeudores !== totalCents) {
      throw new BadRequestError(
        `Las deudas suman ${fromCents(sumaDeudores)} pero el gasto es ${fromCents(totalCents)}`,
      );
    }

    const gasto = await this.gastos.create({
      eventoId,
      descripcion,
      montoTotal: fromCents(totalCents),
      creadoPor: participanteId,
      acreedores: acreedores.map((a) => ({
        participanteId: a.participanteId,
        monto: fromCents(toCents(a.monto)),
      })),
      deudores,
    });

    await this.log.registrar({
      eventoId,
      tipo: ActivityType.gastoAgregado,
      actorParticipanteId: participanteId,
      payload: { gastoId: gasto.id, descripcion, monto: gasto.montoTotal },
    });

    await this.debts.recalcular(eventoId);

    return gasto;
  }

  async listar(eventoId: string): Promise<GastoDetallado[]> {
    return this.gastos.listByEvento(eventoId);
  }

  /** HU-19 — cerrar gastos: permiso exclusivo del organizador (Duda #6). */
  async cerrar(eventoId: string, usuarioId: string): Promise<void> {
    const organizador = await this.events.exigirOrganizador(eventoId, usuarioId);

    await this.debts.recalcular(eventoId);

    await this.log.registrar({
      eventoId,
      tipo: ActivityType.gastosCerrados,
      actorParticipanteId: organizador.id,
    });
  }

  /**
   * Sin detalle de deudores, se divide en partes iguales entre los indicados
   * (o entre todos los participantes). El reparto usa centavos enteros para
   * que la suma de las partes dé exactamente el total.
   */
  private async resolverDeudores(
    eventoId: string,
    totalCents: number,
    input: CrearGastoInput,
  ): Promise<MontoParticipante[]> {
    if (input.deudores && input.deudores.length > 0) {
      return input.deudores.map((d) => ({
        participanteId: d.participanteId,
        monto: fromCents(toCents(d.monto)),
      }));
    }

    const ids = input.dividirEntre?.length
      ? input.dividirEntre
      : (await this.participantes.listByEvento(eventoId)).map((p) => p.id);

    if (ids.length === 0) {
      throw new BadRequestError('No hay participantes entre los que dividir el gasto');
    }

    const partes = splitEvenlyCents(totalCents, ids.length);
    return ids.map((participanteId, i) => ({
      participanteId,
      monto: fromCents(partes[i]),
    }));
  }
}
