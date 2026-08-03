import { PrismaClient } from '@prisma/client';
import { LocationRepository, UbicacionFavorita } from '../../domain/repositories';

export class PrismaLocationRepository implements LocationRepository {
  constructor(private readonly prisma: PrismaClient) {}

  async listByUsuario(usuarioId: string): Promise<UbicacionFavorita[]> {
    const rows = await this.prisma.ubicacionFavorita.findMany({
      where: { usuarioId },
      orderBy: { createdAt: 'desc' },
    });
    return rows.map(this.toEntity);
  }

  async create(usuarioId: string, etiqueta: string, texto: string): Promise<UbicacionFavorita> {
    const row = await this.prisma.ubicacionFavorita.create({
      data: { usuarioId, etiqueta, texto },
    });
    return this.toEntity(row);
  }

  async findById(id: string): Promise<UbicacionFavorita | null> {
    const row = await this.prisma.ubicacionFavorita.findUnique({ where: { id } });
    return row ? this.toEntity(row) : null;
  }

  async delete(id: string): Promise<void> {
    await this.prisma.ubicacionFavorita.delete({ where: { id } });
  }

  private toEntity = (row: {
    id: string;
    usuarioId: string;
    etiqueta: string;
    texto: string;
  }): UbicacionFavorita => ({
    id: row.id,
    usuarioId: row.usuarioId,
    etiqueta: row.etiqueta,
    texto: row.texto,
  });
}
