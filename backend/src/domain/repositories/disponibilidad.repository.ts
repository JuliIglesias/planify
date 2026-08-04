export interface SlotDisponibilidad {
  diaSemana: number;
  bloqueHora: number;
}

export interface SlotHeatmap extends SlotDisponibilidad {
  disponibles: number;
}

/** Item 5 — cuántos de los participantes están libres en TODO un rango horario, no en un bloque suelto. */
export interface DisponibilidadEnRango {
  disponibles: number;
  total: number;
}

export interface DisponibilidadRepository {
  /** Reemplaza (no acumula) la disponibilidad del participante en ese evento. */
  replaceForParticipante(
    eventoId: string,
    participanteId: string,
    slots: SlotDisponibilidad[],
  ): Promise<void>;

  /** Cuántos participantes están disponibles en cada bloque (HU-08). */
  heatmapForEvento(eventoId: string): Promise<SlotHeatmap[]>;

  /** Obtiene la disponibilidad de un participante específico en un evento. */
  findByParticipante(
    eventoId: string,
    participanteId: string,
  ): Promise<SlotDisponibilidad[]>;

  /**
   * Item 5 — cuenta participantes libres en TODOS los bloques del rango
   * [bloqueHoraInicio, bloqueHoraFin) de un día de semana, no en uno solo.
   * Sirve para que el organizador vea, al elegir el rango horario, cuánta
   * gente puede para el evento completo (no un bloque aislado).
   */
  disponiblesEnRango(
    eventoId: string,
    diaSemana: number,
    bloqueHoraInicio: number,
    bloqueHoraFin: number,
  ): Promise<DisponibilidadEnRango>;
}

