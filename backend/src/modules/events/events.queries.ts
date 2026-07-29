import { NotFoundError } from '../../common/errors';
import {
  DeudaRepository,
  EventoConResumen,
  EventoRepository,
  GastoRepository,
  ParticipanteRepository,
  TareaConAsignado,
  TareaRepository,
} from '../../domain/repositories';
import { toCents, fromCents } from '../debts/debt-engine';

export interface EventoHistorial extends EventoConResumen {
  /** Los mismos 3 estados que Balances (Duda #2: "el historial trabaja igual"). */
  estadoSaldo: 'pagar' | 'pendiente' | 'saldado';
  monto: string;
}

export interface DetalleEvento extends Omit<EventoConResumen, 'participantes'> {
  /**
   * La pantalla de detalle necesita saber quién es el organizador para mostrar
   * u ocultar cancelar y cerrar gastos, así que lleva más campos que el resumen.
   */
  participantes: {
    id: string;
    nombreDisplay: string;
    estadoAsistencia: string;
    esOrganizador: boolean;
    esAnonimo: boolean;
  }[];
  tareas: TareaConAsignado[];
  gastos: number;
}

/**
 * Consultas de lectura para las pantallas (Home, Historial, detalle).
 * Están separadas de `EventsService` a propósito: ese maneja los comandos que
 * cambian estado, este solo arma vistas. Mezclarlos hace que la clase crezca
 * sin control (responsabilidad única).
 */
export class EventsQueryService {
  constructor(
    private readonly eventos: EventoRepository,
    private readonly participantes: ParticipanteRepository,
    private readonly deudas: DeudaRepository,
    private readonly tareas: TareaRepository,
    private readonly gastos: GastoRepository,
  ) {}

  /** Home — "Próximos eventos". */
  async proximosDe(usuarioId: string): Promise<EventoConResumen[]> {
    return this.eventos.listUpcomingForUsuario(usuarioId);
  }

  /** Historial — eventos pasados con su estado de saldo. */
  async historialDe(usuarioId: string): Promise<EventoHistorial[]> {
    const [eventos, participaciones] = await Promise.all([
      this.eventos.listPastForUsuario(usuarioId),
      this.participantes.listByUsuario(usuarioId),
    ]);

    const misIds = new Set(participaciones.map((p) => p.id));
    const deudas = await this.deudas.listByParticipantes([...misIds]);

    const porEvento = new Map<string, { deboCents: number; meDebenCents: number }>();
    for (const deuda of deudas) {
      if (deuda.estado === 'saldado') continue;

      const actual = porEvento.get(deuda.eventoId) ?? { deboCents: 0, meDebenCents: 0 };
      const montoCents = toCents(deuda.monto);

      if (misIds.has(deuda.deudorParticipanteId)) actual.deboCents += montoCents;
      else if (misIds.has(deuda.acreedorParticipanteId)) actual.meDebenCents += montoCents;

      porEvento.set(deuda.eventoId, actual);
    }

    return eventos.map((evento) => {
      const saldo = porEvento.get(evento.id);

      // Deber tiene prioridad sobre que te deban: es lo accionable para el usuario.
      if (saldo && saldo.deboCents > 0) {
        return { ...evento, estadoSaldo: 'pagar' as const, monto: fromCents(saldo.deboCents) };
      }
      if (saldo && saldo.meDebenCents > 0) {
        return {
          ...evento,
          estadoSaldo: 'pendiente' as const,
          monto: fromCents(saldo.meDebenCents),
        };
      }
      return { ...evento, estadoSaldo: 'saldado' as const, monto: '0.00' };
    });
  }

  async detalle(eventoId: string): Promise<DetalleEvento> {
    const evento = await this.eventos.findById(eventoId);
    if (!evento) throw new NotFoundError('Evento no encontrado');

    const [participantes, tareas, gastos] = await Promise.all([
      this.participantes.listByEvento(eventoId),
      this.tareas.listByEvento(eventoId),
      this.gastos.contarPorEvento([eventoId]),
    ]);

    return {
      ...evento,
      // El nombre del grupo ya viene del contexto de navegación en la app,
      // así que se evita una consulta extra para traerlo.
      grupoNombre: '',
      participantes: participantes.map((p) => ({
        id: p.id,
        nombreDisplay: p.nombreDisplay,
        estadoAsistencia: p.estadoAsistencia,
        esOrganizador: p.esOrganizador,
        esAnonimo: p.esAnonimo,
      })),
      confirmados: participantes.filter((p) => p.estadoAsistencia === 'confirmado').length,
      tareas,
      gastos: gastos[eventoId] ?? 0,
    };
  }
}
