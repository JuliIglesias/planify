import { PrismaClient } from '@prisma/client';
import {
  DisponibilidadEnRango,
  DisponibilidadRepository,
  SlotDisponibilidad,
  SlotHeatmap,
} from '../../domain/repositories';

export class PrismaDisponibilidadRepository implements DisponibilidadRepository {
  constructor(private readonly prisma: PrismaClient) {}

  async replaceForParticipante(
    eventoId: string,
    participanteId: string,
    slots: SlotDisponibilidad[],
  ): Promise<void> {
    // Borrar + insertar en una transacción: si falla el insert, el participante
    // no puede quedarse sin la disponibilidad que ya tenía cargada.
    await this.prisma.$transaction([
      this.prisma.disponibilidadSlot.deleteMany({ where: { eventoId, participanteId } }),
      this.prisma.disponibilidadSlot.createMany({
        data: slots.map((s) => ({
          eventoId,
          participanteId,
          diaSemana: s.diaSemana,
          bloqueHora: s.bloqueHora,
        })),
      }),
    ]);
  }

  async heatmapForEvento(eventoId: string): Promise<SlotHeatmap[]> {
    const grupos = await this.prisma.disponibilidadSlot.groupBy({
      by: ['diaSemana', 'bloqueHora'],
      // Item 4 — quien dijo "No voy" no debe contar en la disponibilidad
      // grupal, aunque haya cargado horarios antes de responder. Si después
      // vuelve a "Voy", el filtro deja de excluirlo solo (no hay nada que
      // restaurar: se lee el estado actual en cada consulta).
      where: { eventoId, participante: { estadoAsistencia: { not: 'rechazado' } } },
      _count: { participanteId: true },
    });

    return grupos.map((g) => ({
      diaSemana: g.diaSemana,
      bloqueHora: g.bloqueHora,
      disponibles: g._count.participanteId,
    }));
  }

  async findByParticipante(
    eventoId: string,
    participanteId: string,
  ): Promise<SlotDisponibilidad[]> {
    const slots = await this.prisma.disponibilidadSlot.findMany({
      where: { eventoId, participanteId },
      select: { diaSemana: true, bloqueHora: true },
    });
    return slots.map((s) => ({ diaSemana: s.diaSemana, bloqueHora: s.bloqueHora }));
  }

  async disponiblesEnRango(
    eventoId: string,
    diaSemana: number,
    bloqueHoraInicio: number,
    bloqueHoraFin: number,
  ): Promise<DisponibilidadEnRango> {
    // No se puede pedir "todos los bloques del rango" con groupBy+having de
    // Prisma cuando además hay que filtrar por una relación (estadoAsistencia
    // != rechazado): se trae fila por fila y se cuenta en memoria, mismo
    // criterio de exclusión que ya usa heatmapForEvento (Item 4).
    const filas = await this.prisma.disponibilidadSlot.findMany({
      where: {
        eventoId,
        diaSemana,
        bloqueHora: { gte: bloqueHoraInicio, lt: bloqueHoraFin },
        participante: { estadoAsistencia: { not: 'rechazado' } },
      },
      select: { participanteId: true, bloqueHora: true },
    });

    const bloquesPorParticipante = new Map<string, Set<number>>();
    for (const fila of filas) {
      const bloques = bloquesPorParticipante.get(fila.participanteId) ?? new Set<number>();
      bloques.add(fila.bloqueHora);
      bloquesPorParticipante.set(fila.participanteId, bloques);
    }

    const bloquesNecesarios = bloqueHoraFin - bloqueHoraInicio;
    const disponibles = [...bloquesPorParticipante.values()].filter(
      (bloques) => bloques.size >= bloquesNecesarios,
    ).length;

    const total = await this.prisma.participante.count({
      where: { eventoId, estadoAsistencia: { not: 'rechazado' } },
    });

    return { disponibles, total };
  }
}

