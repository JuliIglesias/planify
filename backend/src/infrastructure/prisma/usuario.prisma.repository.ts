import { PrismaClient } from '@prisma/client';
import { PersonaBusqueda, Usuario } from '../../domain/entities';
import {
  ActualizarPerfilData,
  CrearUsuarioData,
  UsuarioRepository,
} from '../../domain/repositories';
import { toUsuario } from './mappers';

export class PrismaUsuarioRepository implements UsuarioRepository {
  constructor(private readonly prisma: PrismaClient) {}

  async findById(id: string): Promise<Usuario | null> {
    const row = await this.prisma.usuario.findUnique({ where: { id } });
    return row ? toUsuario(row) : null;
  }

  async findByEmail(email: string): Promise<Usuario | null> {
    const row = await this.prisma.usuario.findUnique({ where: { email } });
    return row ? toUsuario(row) : null;
  }

  async findByUsername(username: string): Promise<Usuario | null> {
    const row = await this.prisma.usuario.findUnique({ where: { username } });
    return row ? toUsuario(row) : null;
  }

  async findManyByIds(ids: string[]): Promise<Usuario[]> {
    const rows = await this.prisma.usuario.findMany({ where: { id: { in: ids } } });
    return rows.map(toUsuario);
  }

  async create(data: CrearUsuarioData): Promise<Usuario> {
    const row = await this.prisma.usuario.create({
      data: { username: data.username, email: data.email, passwordHash: data.passwordHash },
    });
    return toUsuario(row);
  }

  async updateProfile(id: string, data: ActualizarPerfilData): Promise<Usuario> {
    const row = await this.prisma.usuario.update({
      where: { id },
      data: {
        ...(data.username !== undefined ? { username: data.username } : {}),
        ...(data.avatarUrl !== undefined ? { avatarUrl: data.avatarUrl } : {}),
        ...(data.idiomaPreferido !== undefined ? { idiomaPreferido: data.idiomaPreferido } : {}),
      },
    });
    return toUsuario(row);
  }

  async updatePassword(id: string, passwordHash: string): Promise<void> {
    await this.prisma.usuario.update({ where: { id }, data: { passwordHash } });
  }

  async search(query: string, exceptoUsuarioId: string): Promise<PersonaBusqueda[]> {
    const rows = await this.prisma.usuario.findMany({
      where: {
        id: { not: exceptoUsuarioId },
        OR: [
          { username: { contains: query, mode: 'insensitive' } },
          { email: { contains: query, mode: 'insensitive' } },
        ],
      },
      select: { id: true, username: true, email: true },
      take: 20,
      orderBy: { username: 'asc' },
    });
    return rows.map((u) => ({ id: u.id, username: u.username, email: u.email }));
  }
}
