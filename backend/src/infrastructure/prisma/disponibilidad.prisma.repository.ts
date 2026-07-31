import { PrismaClient } from '@prisma/client';
import {
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
      where: { eventoId },
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
}

