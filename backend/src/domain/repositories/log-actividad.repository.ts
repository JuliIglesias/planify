import { LogActividad, PersonaRef } from '../entities';

export interface EntradaLog extends LogActividad {
  actor: PersonaRef;
}

export interface CrearLogData {
  eventoId: string;
  tipo: string;
  actorParticipanteId: string;
  payload?: Record<string, unknown>;
}

export interface EntradaLogConEvento extends EntradaLog {
  eventoNombre: string;
}

export interface LogActividadRepository {
  create(data: CrearLogData): Promise<LogActividad>;
  listByEvento(eventoId: string): Promise<EntradaLog[]>;

  /**
   * Actividad reciente de todos los eventos del usuario, para el feed de Home
   * y la pantalla de Notificaciones (Tanda 6, Item 2 — paginada de a
   * [limite] por vez). Incluye el nombre del evento porque en Home/
   * Notificaciones no hay contexto de cuál es.
   *
   * [before] es el cursor: si viene, trae solo entradas estrictamente más
   * viejas que esa fecha (la `createdAt` de la última entrada de la página
   * anterior). Sin [before], trae la primera página.
   */
  listRecientesPorEventos(
    eventoIds: string[],
    limite: number,
    before?: Date,
  ): Promise<EntradaLogConEvento[]>;

  /**
   * Actividad que el participante todavía no vio en ese evento, sin contar la
   * que generó él mismo.
   */
  contarNoLeidas(
    eventoId: string,
    participanteId: string,
    desde: Date | null,
  ): Promise<number>;
}
