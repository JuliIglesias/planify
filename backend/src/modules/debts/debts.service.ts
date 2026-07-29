import { BadRequestError, NotFoundError } from '../../common/errors';
import { DeudaSimplificada } from '../../domain/entities';
import {
  Clock,
  DeudaConPersonas,
  DeudaRepository,
  EventoRepository,
  GastoRepository,
  NuevaDeuda,
  ParticipanteRepository,
} from '../../domain/repositories';
import { ActivityLogService } from '../activity-log/activity-log.service';
import { ActivityType } from '../activity-log/activity-log.types';
import { fromCents, ParticipantAmountCents, simplifyDebts, toCents } from './debt-engine';

export interface SaldoPorPersona {
  id: string;
  nombre: string;
  monto: string;
  estado: 'pagar' | 'pendiente' | 'saldado';
}

export interface BalanceUsuario {
  balanceNeto: string;
  meDeben: string;
  debo: string;
  saldos: SaldoPorPersona[];
}

/**
 * SCRUM-11 — HU-15 a HU-18. La aritmética vive en `debt-engine.ts` (pura y
 * testeable); esta clase se ocupa de leer, persistir y aplicar las reglas de
 * negocio alrededor (qué queda saldado, cuándo se finaliza un evento).
 */
export class DebtsService {
  constructor(
    private readonly deudas: DeudaRepository,
    private readonly gastos: GastoRepository,
    private readonly participantes: ParticipanteRepository,
    private readonly eventos: EventoRepository,
    private readonly log: ActivityLogService,
    private readonly clock: Clock,
  ) {}

  /**
   * HU-15 — recalcula desde cero las deudas del evento. Se llama después de
   * cada alta de gasto y de cada pago.
   */
  async recalcular(eventoId: string): Promise<DeudaSimplificada[]> {
    const gastos = await this.gastos.listMontosByEvento(eventoId);

    const movimientos: ParticipantAmountCents[] = [];
    for (const gasto of gastos) {
      for (const acreedor of gasto.acreedores) {
        movimientos.push({
          participanteId: acreedor.participanteId,
          aportadoCents: toCents(acreedor.monto),
          adeudadoCents: 0,
        });
      }
      for (const deudor of gasto.deudores) {
        movimientos.push({
          participanteId: deudor.participanteId,
          aportadoCents: 0,
          adeudadoCents: toCents(deudor.monto),
        });
      }
    }

    const simplificadas = movimientos.length > 0 ? simplifyDebts(movimientos) : [];

    // Una deuda que ya se pagó y quedó idéntica sigue saldada: agregar otro
    // gasto al evento no debe "revivir" un pago que ya ocurrió.
    const previas = await this.deudas.listByEvento(eventoId);
    const saldadasPrevias = new Map(
      previas
        .filter((d) => d.estado === 'saldado')
        .map((d) => [this.clave(d.deudorParticipanteId, d.acreedorParticipanteId), d]),
    );

    const nuevas: NuevaDeuda[] = simplificadas.map((deuda) => {
      const monto = fromCents(deuda.montoCents);
      const previa = saldadasPrevias.get(
        this.clave(deuda.deudorParticipanteId, deuda.acreedorParticipanteId),
      );
      const sigueIgual = previa?.monto === monto;

      return {
        deudorParticipanteId: deuda.deudorParticipanteId,
        acreedorParticipanteId: deuda.acreedorParticipanteId,
        monto,
        estado: sigueIgual ? 'saldado' : 'pendiente',
        saldadoEn: sigueIgual ? (previa?.saldadoEn ?? null) : null,
      };
    });

    const resultado = await this.deudas.reemplazarEvento(eventoId, nuevas);
    await this.actualizarEstadoEvento(eventoId);
    return resultado;
  }

  async listarDelEvento(eventoId: string): Promise<DeudaConPersonas[]> {
    return this.deudas.listByEvento(eventoId);
  }

  /**
   * HU-16/HU-17 — balance del usuario y saldos por persona.
   * Los 3 estados de la UI (Duda #2): `pagar` si yo debo, `pendiente` si me
   * deben y no me pagaron, `saldado` si no queda nada.
   */
  async balanceDe(usuarioId: string): Promise<BalanceUsuario> {
    const participaciones = await this.participantes.listByUsuario(usuarioId);
    const misIds = new Set(participaciones.map((p) => p.id));

    const deudas = await this.deudas.listByParticipantes([...misIds]);

    let meDebenCents = 0;
    let deboCents = 0;
    const porPersona = new Map<string, { nombre: string; netoCents: number }>();

    for (const deuda of deudas) {
      if (deuda.estado === 'saldado') continue;

      const montoCents = toCents(deuda.monto);
      const soyDeudor = misIds.has(deuda.deudorParticipanteId);
      const otro = soyDeudor ? deuda.acreedor : deuda.deudor;

      // Se agrupa por usuario registrado; los anónimos quedan sueltos por
      // participante, porque su identidad no sobrevive al evento (Duda #5).
      const clave = otro.usuarioId ?? otro.id;

      if (soyDeudor) deboCents += montoCents;
      else meDebenCents += montoCents;

      const actual = porPersona.get(clave) ?? { nombre: otro.nombre, netoCents: 0 };
      actual.netoCents += soyDeudor ? -montoCents : montoCents;
      porPersona.set(clave, actual);
    }

    const saldos: SaldoPorPersona[] = [...porPersona.entries()].map(([id, valor]) => ({
      id,
      nombre: valor.nombre,
      monto: fromCents(Math.abs(valor.netoCents)),
      estado: valor.netoCents === 0 ? 'saldado' : valor.netoCents < 0 ? 'pagar' : 'pendiente',
    }));

    return {
      balanceNeto: fromCents(meDebenCents - deboCents),
      meDeben: fromCents(meDebenCents),
      debo: fromCents(deboCents),
      saldos,
    };
  }

  /** HU-18 — marcar una deuda como saldada. */
  async saldar(deudaId: string, participanteId: string): Promise<DeudaSimplificada> {
    const deuda = await this.deudas.findById(deudaId);
    if (!deuda) throw new NotFoundError('Deuda no encontrada');
    if (deuda.estado === 'saldado') throw new BadRequestError('La deuda ya está saldada');

    const saldada = await this.deudas.marcarSaldada(deudaId, this.clock.now());

    await this.log.registrar({
      eventoId: deuda.eventoId,
      tipo: ActivityType.deudaSaldada,
      actorParticipanteId: participanteId,
      payload: { deudaId, monto: deuda.monto },
    });

    await this.actualizarEstadoEvento(deuda.eventoId);

    return saldada;
  }

  /**
   * Un evento se finaliza cuando no le queda ninguna deuda pendiente
   * (definición de Duda #5). Es lo que enciende el badge "SALDADO" del
   * historial. Si vuelve a haber deuda, se revierte a `confirmado`.
   */
  private async actualizarEstadoEvento(eventoId: string): Promise<void> {
    const evento = await this.eventos.findById(eventoId);
    if (!evento || evento.estado === 'cancelado') return;

    const [pendientes, total] = await Promise.all([
      this.deudas.contarPendientes(eventoId),
      this.deudas.contarTotal(eventoId),
    ]);

    if (pendientes === 0 && total > 0 && evento.estado !== 'finalizado') {
      await this.eventos.updateEstado(eventoId, 'finalizado');
    } else if (pendientes > 0 && evento.estado === 'finalizado') {
      await this.eventos.updateEstado(eventoId, 'confirmado');
    }
  }

  private clave(deudorId: string, acreedorId: string): string {
    return `${deudorId}->${acreedorId}`;
  }
}
