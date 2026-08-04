import { PrismaClient } from '@prisma/client';
import { Tarea, TareaEstado } from '../../domain/entities';
import { TareaConAsignado, TareaRepository } from '../../domain/repositories';
import { toTarea } from './mappers';

export class PrismaTareaRepository implements TareaRepository {
  constructor(private readonly prisma: PrismaClient) {}

  async findById(id: string): Promise<Tarea | null> {
    const row = await this.prisma.tarea.findUnique({ where: { id } });
    return row ? toTarea(row) : null;
  }

  async listByEvento(eventoId: string): Promise<TareaConAsignado[]> {
    const rows = await this.prisma.tarea.findMany({
      where: { eventoId },
      orderBy: { createdAt: 'asc' },
      include: { asignado: { select: { id: true, username: true } } },
    });

    return rows.map((row) => ({
      ...toTarea(row),
      asignado: row.asignado
        ? { id: row.asignado.id, username: row.asignado.username }
        : null,
    }));
  }

  async contarPendientesPorEvento(eventoIds: string[]): Promise<Record<string, number>> {
    const grupos = await this.prisma.tarea.groupBy({
      by: ['eventoId'],
      where: { eventoId: { in: eventoIds }, estado: { not: 'completado' } },
      _count: { id: true },
    });

    return Object.fromEntries(grupos.map((g) => [g.eventoId, g._count.id]));
  }

  async create(eventoId: string, titulo: string, creadoPor: string): Promise<Tarea> {
    const row = await this.prisma.tarea.create({
      data: { eventoId, titulo, creadoPor, estado: 'no_asignado' },
    });
    return toTarea(row);
  }

  async asignar(id: string, asignadoA: string): Promise<TareaConAsignado> {
    const row = await this.prisma.tarea.update({
      where: { id },
      data: { asignadoA, estado: 'pendiente' },
      include: { asignado: { select: { id: true, username: true } } },
    });

    return {
      ...toTarea(row),
      asignado: row.asignado
        ? { id: row.asignado.id, username: row.asignado.username }
        : null,
    };
  }

  async cambiarEstado(id: string, estado: TareaEstado): Promise<Tarea> {
    const row = await this.prisma.tarea.update({ where: { id }, data: { estado } });
    return toTarea(row);
  }
}
