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
   * Actividad reciente de todos los eventos del usuario, para el feed de Home.
   * Incluye el nombre del evento porque en Home no hay contexto de cuál es.
   */
  listRecientesPorEventos(
    eventoIds: string[],
    limite: number,
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
