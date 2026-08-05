import { PersonaRef } from '../../domain/entities';
import {
  Clock,
  EntradaLog,
  LogActividadRepository,
  NotificacionPersonalRepository,
  ParticipanteRepository,
} from '../../domain/repositories';
import { ActivityTypeValue } from './activity-log.types';

/**
 * Cuántas entradas trae cada página del feed de Home y de Notificaciones
 * (Tanda 6, Item 2 — paginación de a 20).
 */
const LIMITE_ACTIVIDAD_RECIENTE = 20;

export interface RegistrarActividad {
  eventoId: string;
  tipo: ActivityTypeValue;
  actorParticipanteId: string;
  payload?: Record<string, unknown>;
}

/**
 * F2 — igual que [RegistrarActividad], pero para algo que no cuelga de
 * ningún evento (ej. una solicitud de amistad recibida).
 */
export interface RegistrarNotificacionPersonal {
  usuarioId: string;
  tipo: ActivityTypeValue;
  actorUsuarioId: string;
  payload?: Record<string, unknown>;
}

/**
 * F2 — forma común del feed de "Actividad reciente"/Notificaciones: mezcla
 * entradas de eventos (`EntradaLogConEvento`, con `eventoId`/`eventoNombre`)
 * y notificaciones personales (sin evento — esos dos campos vienen
 * `undefined`). El cliente ya sabe tratar un `eventoId` ausente como "esto
 * no rutea a ningún evento" (lo hacía desde antes con `rango_extendido`).
 */
export interface NotificacionFeedItem {
  id: string;
  tipo: string;
  actor: PersonaRef;
  payload: Record<string, unknown> | null;
  createdAt: Date;
  eventoId?: string;
  eventoNombre?: string;
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
    // F2 — opcional a propósito: así ninguno de los ~10 sitios que ya
    // construían `ActivityLogService` (tests incluidos) tiene que cambiar
    // para seguir compilando. Sin esto, `recientesDe` simplemente no
    // mezcla notificaciones personales — se comporta exactamente como
    // antes de este item.
    private readonly notificacionesPersonales?: NotificacionPersonalRepository,
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

  /**
   * F2 — registrar algo que le pasó a un usuario sin que haya un evento de
   * por medio (hoy: recibir una solicitud de amistad). Push queda pendiente
   * a propósito (el usuario pidió arrancar solo con in-app); el punto de
   * entrada ya está pensado para sumarlo después sin tocar a los que llaman
   * a este método — mismo criterio que `registrar()` de arriba.
   */
  async registrarPersonal(entrada: RegistrarNotificacionPersonal): Promise<void> {
    if (!this.notificacionesPersonales) return;
    await this.notificacionesPersonales.crear(entrada);
  }

  async listar(eventoId: string): Promise<EntradaLog[]> {
    return this.logs.listByEvento(eventoId);
  }

  /**
   * Feed de "Actividad reciente" de Home y de la pantalla de Notificaciones:
   * lo último que pasó en todos los eventos del usuario, con el nombre del
   * evento para dar contexto — más (F2) las notificaciones personales que
   * no cuelgan de ningún evento (ej. solicitudes de amistad recibidas).
   * Paginado (Tanda 6, Item 2): pasar el `createdAt` de la última entrada
   * recibida como [before] para la siguiente página; si el resultado trae
   * menos de 20, no hay más páginas.
   *
   * Las dos fuentes se piden con el mismo cursor [before] y se mezclan por
   * fecha: como cada una ya viene ordenada `desc` y acotada a [limite], el
   * top [limite] del resultado combinado siempre sale de entre esos dos
   * top-[limite] parciales (no hace falta pedir "todo" de ninguna fuente).
   */
  async recientesDe(usuarioId: string, before?: Date): Promise<NotificacionFeedItem[]> {
    const participaciones = await this.participantes.listByUsuario(usuarioId);
    const eventoIds = [...new Set(participaciones.map((p) => p.eventoId))];

    const [deEventos, personales] = await Promise.all([
      this.logs.listRecientesPorEventos(eventoIds, LIMITE_ACTIVIDAD_RECIENTE, before),
      this.notificacionesPersonales?.listRecientes(usuarioId, LIMITE_ACTIVIDAD_RECIENTE, before) ??
        Promise.resolve([]),
    ]);

    const combinadas: NotificacionFeedItem[] = [
      ...deEventos.map((e) => ({
        id: e.id,
        tipo: e.tipo,
        actor: e.actor,
        payload: e.payload,
        createdAt: e.createdAt,
        eventoId: e.eventoId,
        eventoNombre: e.eventoNombre,
      })),
      ...personales.map((n) => ({
        id: n.id,
        tipo: n.tipo,
        actor: n.actor,
        payload: n.payload,
        createdAt: n.createdAt,
      })),
    ];

    return combinadas
      .sort((a, b) => b.createdAt.getTime() - a.createdAt.getTime())
      .slice(0, LIMITE_ACTIVIDAD_RECIENTE);
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
