import { PrismaClient, Prisma } from '@prisma/client';
import { LogActividad } from '../../domain/entities';
import {
  CrearLogData,
  EntradaLog,
  EntradaLogConEvento,
  LogActividadRepository,
} from '../../domain/repositories';
import { toLogActividad } from './mappers';

export class PrismaLogActividadRepository implements LogActividadRepository {
  constructor(private readonly prisma: PrismaClient) {}

  async create(data: CrearLogData): Promise<LogActividad> {
    const row = await this.prisma.logActividad.create({
      data: {
        eventoId: data.eventoId,
        tipo: data.tipo,
        actorParticipanteId: data.actorParticipanteId,
        payload: (data.payload ?? undefined) as Prisma.InputJsonValue | undefined,
      },
    });
    return toLogActividad(row);
  }

  async listByEvento(eventoId: string): Promise<EntradaLog[]> {
    const rows = await this.prisma.logActividad.findMany({
      where: { eventoId },
      orderBy: { createdAt: 'desc' },
      include: { actor: { select: { id: true, username: true } } },
    });

    return rows.map((row) => ({
      ...toLogActividad(row),
      actor: { id: row.actor.id, username: row.actor.username },
    }));
  }

  async listRecientesPorEventos(
    eventoIds: string[],
    limite: number,
    before?: Date,
  ): Promise<EntradaLogConEvento[]> {
    if (eventoIds.length === 0) return [];

    const rows = await this.prisma.logActividad.findMany({
      where: {
        eventoId: { in: eventoIds },
        ...(before ? { createdAt: { lt: before } } : {}),
      },
      orderBy: { createdAt: 'desc' },
      take: limite,
      include: {
        actor: { select: { id: true, username: true } },
        evento: { select: { nombre: true } },
      },
    });

    return rows.map((row) => ({
      ...toLogActividad(row),
      actor: { id: row.actor.id, username: row.actor.username },
      eventoNombre: row.evento.nombre,
    }));
  }

  async contarNoLeidas(
    eventoId: string,
    participanteId: string,
    desde: Date | null,
  ): Promise<number> {
    return this.prisma.logActividad.count({
      where: {
        eventoId,
        // Lo que uno mismo hizo no cuenta como "sin leer".
        actorParticipanteId: { not: participanteId },
        ...(desde ? { createdAt: { gt: desde } } : {}),
      },
    });
  }
}
