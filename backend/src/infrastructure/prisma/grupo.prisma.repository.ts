import { PrismaClient } from '@prisma/client';
import { Grupo, PersonaRef } from '../../domain/entities';
import { GrupoConMiembros, GrupoRepository } from '../../domain/repositories';

export class PrismaGrupoRepository implements GrupoRepository {
  constructor(private readonly prisma: PrismaClient) {}

  async findById(id: string): Promise<Grupo | null> {
    return this.prisma.grupo.findUnique({ where: { id } });
  }

  async listByUsuario(usuarioId: string): Promise<GrupoConMiembros[]> {
    const rows = await this.prisma.grupo.findMany({
      where: { miembros: { some: { usuarioId } } },
      include: {
        miembros: { include: { usuario: { select: { id: true, username: true } } } },
      },
      orderBy: { createdAt: 'desc' },
    });

    return rows.map((grupo) => ({
      id: grupo.id,
      nombre: grupo.nombre,
      avatarUrl: grupo.avatarUrl,
      createdAt: grupo.createdAt,
      miembros: grupo.miembros.map((m) => ({ id: m.usuario.id, username: m.usuario.username })),
    }));
  }

  async listMiembros(grupoId: string): Promise<PersonaRef[]> {
    const filas = await this.prisma.miembroGrupo.findMany({
      where: { grupoId },
      include: { usuario: { select: { id: true, username: true } } },
    });
    return filas.map((m) => ({ id: m.usuario.id, username: m.usuario.username }));
  }

  async create(nombre: string, usuarioIds: string[]): Promise<Grupo> {
    return this.prisma.grupo.create({
      data: {
        nombre,
        miembros: { create: [...new Set(usuarioIds)].map((usuarioId) => ({ usuarioId })) },
      },
    });
  }

  async rename(id: string, nombre: string): Promise<Grupo> {
    return this.prisma.grupo.update({ where: { id }, data: { nombre } });
  }

  async esMiembro(grupoId: string, usuarioId: string): Promise<boolean> {
    const count = await this.prisma.miembroGrupo.count({ where: { grupoId, usuarioId } });
    return count > 0;
  }

  async contarMiembros(grupoId: string): Promise<number> {
    return this.prisma.miembroGrupo.count({ where: { grupoId } });
  }

  async agregarMiembro(grupoId: string, usuarioId: string): Promise<void> {
    // upsert en vez de create: agregar dos veces al mismo amigo no debe explotar.
    await this.prisma.miembroGrupo.upsert({
      where: { grupoId_usuarioId: { grupoId, usuarioId } },
      update: {},
      create: { grupoId, usuarioId },
    });
  }

  async quitarMiembro(grupoId: string, usuarioId: string): Promise<void> {
    await this.prisma.miembroGrupo.deleteMany({ where: { grupoId, usuarioId } });
  }
}
