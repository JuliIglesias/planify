import { PrismaClient } from '@prisma/client';
import {
  ProfileAvailabilityRepository,
  SlotDeUsuario,
  SlotDisponibilidad,
} from '../../domain/repositories';

export class PrismaProfileAvailabilityRepository implements ProfileAvailabilityRepository {
  constructor(private readonly prisma: PrismaClient) {}

  async replaceForUsuario(usuarioId: string, slots: SlotDisponibilidad[]): Promise<void> {
    await this.prisma.$transaction([
      this.prisma.disponibilidadPerfil.deleteMany({ where: { usuarioId } }),
      this.prisma.disponibilidadPerfil.createMany({
        data: slots.map((s) => ({
          usuarioId,
          diaSemana: s.diaSemana,
          bloqueHora: s.bloqueHora,
        })),
      }),
    ]);
  }

  async findByUsuario(usuarioId: string): Promise<SlotDisponibilidad[]> {
    const rows = await this.prisma.disponibilidadPerfil.findMany({ where: { usuarioId } });
    return rows.map((r) => ({ diaSemana: r.diaSemana, bloqueHora: r.bloqueHora }));
  }

  async slotsDeUsuarios(usuarioIds: string[]): Promise<SlotDeUsuario[]> {
    const rows = await this.prisma.disponibilidadPerfil.findMany({
      where: { usuarioId: { in: usuarioIds } },
    });
    return rows.map((r) => ({
      usuarioId: r.usuarioId,
      diaSemana: r.diaSemana,
      bloqueHora: r.bloqueHora,
    }));
  }
}
