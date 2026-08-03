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

  async findManyByIds(ids: string[]): Promise<Usuario[]> {
    const rows = await this.prisma.usuario.findMany({ where: { id: { in: ids } } });
    return rows.map(toUsuario);
  }

  async create(data: CrearUsuarioData): Promise<Usuario> {
    const row = await this.prisma.usuario.create({
      data: { nombre: data.nombre, email: data.email, passwordHash: data.passwordHash },
    });
    return toUsuario(row);
  }

  async updateProfile(id: string, data: ActualizarPerfilData): Promise<Usuario> {
    const row = await this.prisma.usuario.update({
      where: { id },
      data: {
        ...(data.nombre !== undefined ? { nombre: data.nombre } : {}),
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
          { nombre: { contains: query, mode: 'insensitive' } },
          { email: { contains: query, mode: 'insensitive' } },
        ],
      },
      select: { id: true, nombre: true, email: true },
      take: 20,
      orderBy: { nombre: 'asc' },
    });
    return rows.map((u) => ({ id: u.id, nombre: u.nombre, email: u.email }));
  }
}
