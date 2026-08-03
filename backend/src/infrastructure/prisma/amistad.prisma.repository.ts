import { PrismaClient } from '@prisma/client';
import { Amistad, PersonaRef } from '../../domain/entities';
import { AmistadRepository, SolicitudAmistad } from '../../domain/repositories';

function toAmistad(row: {
  id: string;
  usuarioId1: string;
  usuarioId2: string;
  estado: string;
  createdAt: Date;
}): Amistad {
  return {
    id: row.id,
    usuarioId1: row.usuarioId1,
    usuarioId2: row.usuarioId2,
    estado: row.estado as Amistad['estado'],
    createdAt: row.createdAt,
  };
}

export class PrismaAmistadRepository implements AmistadRepository {
  constructor(private readonly prisma: PrismaClient) {}

  async crear(solicitanteId: string, receptorId: string): Promise<Amistad> {
    const row = await this.prisma.amistad.create({
      data: { usuarioId1: solicitanteId, usuarioId2: receptorId },
    });
    return toAmistad(row);
  }

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

  async aceptar(id: string): Promise<Amistad> {
    const row = await this.prisma.amistad.update({
      where: { id },
      data: { estado: 'aceptada' },
    });
    return toAmistad(row);
  }

  async listAmigos(usuarioId: string): Promise<PersonaRef[]> {
    const rows = await this.prisma.amistad.findMany({
      where: {
        estado: 'aceptada',
        OR: [{ usuarioId1: usuarioId }, { usuarioId2: usuarioId }],
      },
      include: {
        usuario1: { select: { id: true, nombre: true } },
        usuario2: { select: { id: true, nombre: true } },
      },
    });
    return rows.map((a) => {
      const otro = a.usuarioId1 === usuarioId ? a.usuario2 : a.usuario1;
      return { id: otro.id, nombre: otro.nombre };
    });
  }

  async listSolicitudesRecibidas(usuarioId: string): Promise<SolicitudAmistad[]> {
    const rows = await this.prisma.amistad.findMany({
      where: { estado: 'pendiente', usuarioId2: usuarioId },
      include: { usuario1: { select: { id: true, nombre: true } } },
    });
    return rows.map((a) => ({
      amistadId: a.id,
      de: { id: a.usuario1.id, nombre: a.usuario1.nombre },
    }));
  }
}
