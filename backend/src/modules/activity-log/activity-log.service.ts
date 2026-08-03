import {
  Clock,
  EntradaLog,
  EntradaLogConEvento,
  LogActividadRepository,
  ParticipanteRepository,
} from '../../domain/repositories';
import { ActivityTypeValue } from './activity-log.types';

/** Cuántas entradas muestra el feed de Home. */
const LIMITE_ACTIVIDAD_RECIENTE = 20;

export interface RegistrarActividad {
  eventoId: string;
  tipo: ActivityTypeValue;
  actorParticipanteId: string;
  payload?: Record<string, unknown>;
}

/**
 * Puerto mínimo hacia las notificaciones (SCRUM-15). Se inyecta como interfaz
 * para no acoplar el log a la implementación concreta y para que los tests que
 * no prueban push no tengan que pasar nada.
 */
export interface ActivityNotifier {
  notificarActividad(input: {
    eventoId: string;
    actorParticipanteId: string;
    tipo: ActivityTypeValue;
  }): Promise<void>;
}

/**
 * SCRUM-13 — HU-24/HU-25. El "chat" del charter reinterpretado: un feed
 * automático de lo que pasa en el evento, sin mensajería libre (Duda #9).
 *
 * Los demás servicios registran actividad a través de esta clase, no escribiendo
 * en el repositorio directamente: así el día que haya que disparar también una
 * notificación push (SCRUM-15), se agrega en un solo lugar.
 */
export class ActivityLogService {
  constructor(
    private readonly logs: LogActividadRepository,
    private readonly participantes: ParticipanteRepository,
    private readonly clock: Clock,
    private readonly notifier?: ActivityNotifier,
  ) {}

  async registrar(entrada: RegistrarActividad): Promise<void> {
    await this.logs.create(entrada);
    // SCRUM-15/HU-35: la notificación push se dispara desde acá, en un solo
    // lugar. Si falla el push, no se cae el registro de la actividad.
    if (this.notifier) {
      try {
        await this.notifier.notificarActividad({
          eventoId: entrada.eventoId,
          actorParticipanteId: entrada.actorParticipanteId,
          tipo: entrada.tipo,
        });
      } catch {
        // Notificar es best-effort; el log ya quedó persistido.
      }
    }
  }

  async listar(eventoId: string): Promise<EntradaLog[]> {
    return this.logs.listByEvento(eventoId);
  }

  /**
   * Feed de "Actividad reciente" de Home: lo último que pasó en todos los
   * eventos del usuario, con el nombre del evento para dar contexto.
   */
  async recientesDe(usuarioId: string): Promise<EntradaLogConEvento[]> {
    const participaciones = await this.participantes.listByUsuario(usuarioId);
    const eventoIds = [...new Set(participaciones.map((p) => p.eventoId))];

    return this.logs.listRecientesPorEventos(eventoIds, LIMITE_ACTIVIDAD_RECIENTE);
  }

  /** Abrir el log marca el evento como leído (HU-25). */
  async marcarLeido(participanteId: string): Promise<void> {
    await this.participantes.marcarLeido(participanteId, this.clock.now());
  }

  /**
   * Actividad sin leer por evento. La agregación por grupo la hace el servicio
   * de grupos, que es el que sabe qué evento pertenece a qué grupo (Duda #2).
   */
  async contarNoLeidasPorEvento(usuarioId: string): Promise<Record<string, number>> {
    const participaciones = await this.participantes.listByUsuario(usuarioId);

    const conteos = await Promise.all(
      participaciones.map(async (p) => ({
        eventoId: p.eventoId,
        cantidad: await this.logs.contarNoLeidas(p.eventoId, p.id, p.ultimaLecturaAt),
      })),
    );

    return Object.fromEntries(conteos.map((c) => [c.eventoId, c.cantidad]));
  }
}
