import { PrismaClient } from '@prisma/client';
import { Amistad } from '../../domain/entities';
import { AmistadRepository } from '../../domain/repositories';
import { toAmistad } from './mappers';

export class PrismaAmistadRepository implements AmistadRepository {
  constructor(private readonly prisma: PrismaClient) {}

  async findById(id: string): Promise<Amistad | null> {
    const row = await this.prisma.amistad.findUnique({ where: { id } });
    return row ? toAmistad(row) : null;
  }

  async findEntre(usuarioA: string, usuarioB: string): Promise<Amistad | null> {
    const row = await this.prisma.amistad.findFirst({
      where: {
        OR: [
          { usuarioId1: usuarioA, usuarioId2: usuarioB },
          { usuarioId1: usuarioB, usuarioId2: usuarioA },
        ],
      },
    });
    return row ? toAmistad(row) : null;
  }

  async create(solicitanteId: string, destinatarioId: string): Promise<Amistad> {
    const row = await this.prisma.amistad.create({
      data: { usuarioId1: solicitanteId, usuarioId2: destinatarioId, estado: 'pendiente' },
    });
    return toAmistad(row);
  }

  async aceptar(id: string): Promise<Amistad> {
    const row = await this.prisma.amistad.update({
      where: { id },
      data: { estado: 'aceptada' },
    });
    return toAmistad(row);
  }

  async eliminar(id: string): Promise<void> {
    await this.prisma.amistad.delete({ where: { id } });
  }

  async listAceptadasDe(usuarioId: string): Promise<Amistad[]> {
    const rows = await this.prisma.amistad.findMany({
      where: {
        estado: 'aceptada',
        OR: [{ usuarioId1: usuarioId }, { usuarioId2: usuarioId }],
      },
      orderBy: { createdAt: 'desc' },
    });
    return rows.map(toAmistad);
  }

  async listPendientesRecibidas(usuarioId: string): Promise<Amistad[]> {
    const rows = await this.prisma.amistad.findMany({
      where: { estado: 'pendiente', usuarioId2: usuarioId },
      orderBy: { createdAt: 'desc' },
    });
    return rows.map(toAmistad);
  }
}
