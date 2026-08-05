import { PrismaClient, Prisma } from '@prisma/client';
import {
  CrearNotificacionPersonalData,
  NotificacionPersonal,
  NotificacionPersonalConActor,
  NotificacionPersonalRepository,
} from '../../domain/repositories';

export class PrismaNotificacionPersonalRepository implements NotificacionPersonalRepository {
  constructor(private readonly prisma: PrismaClient) {}

  async crear(data: CrearNotificacionPersonalData): Promise<NotificacionPersonal> {
    const row = await this.prisma.notificacionPersonal.create({
      data: {
        usuarioId: data.usuarioId,
        tipo: data.tipo,
        actorUsuarioId: data.actorUsuarioId,
        payload: (data.payload ?? undefined) as Prisma.InputJsonValue | undefined,
      },
    });
    return {
      ...row,
      payload: (row.payload as Record<string, unknown> | null) ?? null,
    };
  }

  async listRecientes(
    usuarioId: string,
    limite: number,
    before?: Date,
  ): Promise<NotificacionPersonalConActor[]> {
    const rows = await this.prisma.notificacionPersonal.findMany({
      where: {
        usuarioId,
        ...(before ? { createdAt: { lt: before } } : {}),
      },
      orderBy: { createdAt: 'desc' },
      take: limite,
      include: { actor: { select: { id: true, username: true } } },
    });

    return rows.map((row) => ({
      id: row.id,
      usuarioId: row.usuarioId,
      tipo: row.tipo,
      actorUsuarioId: row.actorUsuarioId,
      payload: (row.payload as Record<string, unknown> | null) ?? null,
      createdAt: row.createdAt,
      actor: { id: row.actor.id, username: row.actor.username },
    }));
  }
}
