import { PrismaClient } from '@prisma/client';
import { DeudaSimplificada } from '../../domain/entities';
import { DeudaConPersonas, DeudaRepository, NuevaDeuda } from '../../domain/repositories';
import { toDeuda } from './mappers';

const CON_PERSONAS = {
  deudor: { select: { id: true, nombreDisplay: true, usuarioId: true } },
  acreedor: { select: { id: true, nombreDisplay: true, usuarioId: true } },
  evento: { select: { nombre: true } },
} as const;

type FilaConPersonas = Parameters<typeof toDeuda>[0] & {
  deudor: { id: string; nombreDisplay: string; usuarioId: string | null };
  acreedor: { id: string; nombreDisplay: string; usuarioId: string | null };
  evento: { nombre: string };
};

function toDeudaConPersonas(row: FilaConPersonas): DeudaConPersonas {
  return {
    ...toDeuda(row),
    deudor: {
      id: row.deudor.id,
      nombre: row.deudor.nombreDisplay,
      usuarioId: row.deudor.usuarioId,
    },
    acreedor: {
      id: row.acreedor.id,
      nombre: row.acreedor.nombreDisplay,
      usuarioId: row.acreedor.usuarioId,
    },
    eventoNombre: row.evento.nombre,
  };
}

export class PrismaDeudaRepository implements DeudaRepository {
  constructor(private readonly prisma: PrismaClient) {}

  async findById(id: string): Promise<DeudaSimplificada | null> {
    const row = await this.prisma.deudaSimplificada.findUnique({ where: { id } });
    return row ? toDeuda(row) : null;
  }

  async listByEvento(eventoId: string): Promise<DeudaConPersonas[]> {
    const rows = await this.prisma.deudaSimplificada.findMany({
      where: { eventoId },
      include: CON_PERSONAS,
    });
    return rows.map(toDeudaConPersonas);
  }

  async listByParticipantes(participanteIds: string[]): Promise<DeudaConPersonas[]> {
    const rows = await this.prisma.deudaSimplificada.findMany({
      where: {
        OR: [
          { deudorParticipanteId: { in: participanteIds } },
          { acreedorParticipanteId: { in: participanteIds } },
        ],
      },
      include: CON_PERSONAS,
    });
    return rows.map(toDeudaConPersonas);
  }

  async reemplazarEvento(
    eventoId: string,
    deudas: NuevaDeuda[],
  ): Promise<DeudaSimplificada[]> {
    // Atómico: si el insert falla, el evento no puede quedar sin sus deudas.
    const filas = await this.prisma.$transaction(async (tx) => {
      await tx.deudaSimplificada.deleteMany({ where: { eventoId } });

      if (deudas.length > 0) {
        await tx.deudaSimplificada.createMany({
          data: deudas.map((d) => ({ eventoId, ...d })),
        });
      }

      return tx.deudaSimplificada.findMany({ where: { eventoId } });
    });

    return filas.map(toDeuda);
  }

  async marcarSaldada(id: string, cuando: Date): Promise<DeudaSimplificada> {
    const row = await this.prisma.deudaSimplificada.update({
      where: { id },
      data: { estado: 'saldado', saldadoEn: cuando },
    });
    return toDeuda(row);
  }

  async marcarSaldadasEnLote(ids: string[], cuando: Date): Promise<number> {
    if (ids.length === 0) return 0;

    const { count } = await this.prisma.deudaSimplificada.updateMany({
      where: { id: { in: ids } },
      data: { estado: 'saldado', saldadoEn: cuando },
    });

    return count;
  }

  async contarPendientes(eventoId: string): Promise<number> {
    return this.prisma.deudaSimplificada.count({
      where: { eventoId, estado: { not: 'saldado' } },
    });
  }

  async contarTotal(eventoId: string): Promise<number> {
    return this.prisma.deudaSimplificada.count({ where: { eventoId } });
  }
}
