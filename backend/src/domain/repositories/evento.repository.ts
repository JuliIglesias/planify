import { Evento, EventoEstado, Participante } from '../entities';

export interface CrearEventoData {
  grupoId: string;
  nombre: string;
  lugarTexto: string;
  organizadorUsuarioId: string;
  organizadorUsername: string;
  /**
   * Los demás miembros registrados del grupo, que se materializan como
   * `Participante` del evento en la misma transacción. Sin esto, un miembro del
   * grupo no aparecería en la lista para asignarle gastos/tareas ni podría
   * confirmar asistencia (era el bug H-01 de la auditoría).
   */
  otrosMiembros?: { usuarioId: string; username: string }[];
}

/** Evento + datos derivados que las pantallas de listado necesitan. */
export interface EventoConResumen extends Evento {
  grupoNombre: string;
  participantes: Pick<Participante, 'id' | 'username' | 'estadoAsistencia'>[];
  confirmados: number;
}

export interface EventoRepository {
  findById(id: string): Promise<Evento | null>;

  /**
   * Crea el evento y su participante organizador de forma atómica: un evento
   * sin organizador sería un estado inválido (nadie podría cancelarlo).
   */
  createWithOrganizer(data: CrearEventoData): Promise<{ evento: Evento; organizador: Participante }>;

  updateEstado(id: string, estado: EventoEstado): Promise<Evento>;
  /** Item 5 — el horario confirmado es un rango: inicio y fin. */
  confirmarHorario(id: string, fechaHoraInicio: Date, fechaHoraFin: Date): Promise<Evento>;

  /**
   * Próximos: en planificación (sin fecha aún) o confirmados cuya fecha todavía
   * no pasó. `ahora` decide el corte por fecha, no solo el estado (H-09).
   */
  listUpcomingForUsuario(usuarioId: string, ahora: Date): Promise<EventoConResumen[]>;

  /**
   * Historial: finalizados, cancelados, o confirmados cuya fecha ya pasó. Así un
   * mismo evento no aparece a la vez en Próximos y en Historial (H-09).
   */
  listPastForUsuario(usuarioId: string, ahora: Date): Promise<EventoConResumen[]>;

  listByGrupo(grupoId: string): Promise<Evento[]>;
}
