export interface SlotDisponibilidad {
  diaSemana: number;
  bloqueHora: number;
}

export interface SlotHeatmap extends SlotDisponibilidad {
  disponibles: number;
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
}

