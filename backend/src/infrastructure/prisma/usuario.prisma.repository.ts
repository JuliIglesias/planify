import { PrismaClient } from '@prisma/client';
import { Usuario } from '../../domain/entities';
import { UsuarioRepository } from '../../domain/repositories';
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
}
