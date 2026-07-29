import { Prisma, PrismaClient } from '@prisma/client';
import { GastoCompleto } from '../../domain/entities';
import { CrearGastoData, GastoDetallado, GastoRepository } from '../../domain/repositories';
import { decimalToString } from './mappers';

/** Forma mínima que necesitan los mappers de abajo. */
type FilaGasto = {
  id: string;
  eventoId: string;
  descripcion: string;
  montoTotal: Prisma.Decimal;
  creadoPor: string;
  fecha: Date;
  acreedores: { participanteId: string; montoAportado: Prisma.Decimal }[];
  deudores: { participanteId: string; montoAdeudado: Prisma.Decimal }[];
};

/** Un solo lugar donde se traduce una fila de gasto al dominio. */
function toGastoCompleto(row: FilaGasto): GastoCompleto {
  return {
    id: row.id,
    eventoId: row.eventoId,
    descripcion: row.descripcion,
    montoTotal: decimalToString(row.montoTotal),
    creadoPor: row.creadoPor,
    fecha: row.fecha,
    acreedores: row.acreedores.map((a) => ({
      participanteId: a.participanteId,
      monto: decimalToString(a.montoAportado),
    })),
    deudores: row.deudores.map((d) => ({
      participanteId: d.participanteId,
      monto: decimalToString(d.montoAdeudado),
    })),
  };
}

export class PrismaGastoRepository implements GastoRepository {
  constructor(private readonly prisma: PrismaClient) {}

  async create(data: CrearGastoData): Promise<GastoCompleto> {
    const row = await this.prisma.gasto.create({
      data: {
        eventoId: data.eventoId,
        descripcion: data.descripcion,
        montoTotal: data.montoTotal,
        creadoPor: data.creadoPor,
        acreedores: {
          create: data.acreedores.map((a) => ({
            participanteId: a.participanteId,
            montoAportado: a.monto,
          })),
        },
        deudores: {
          create: data.deudores.map((d) => ({
            participanteId: d.participanteId,
            montoAdeudado: d.monto,
          })),
        },
      },
      include: { acreedores: true, deudores: true },
    });

    return toGastoCompleto(row);
  }

  async listByEvento(eventoId: string): Promise<GastoDetallado[]> {
    const rows = await this.prisma.gasto.findMany({
      where: { eventoId },
      orderBy: { fecha: 'desc' },
      include: {
        acreedores: true,
        deudores: true,
        creador: { select: { id: true, nombreDisplay: true } },
      },
    });

    return rows.map((row) => ({
      ...toGastoCompleto(row),
      creador: { id: row.creador.id, nombre: row.creador.nombreDisplay },
    }));
  }

  async listMontosByEvento(eventoId: string): Promise<GastoCompleto[]> {
    const rows = await this.prisma.gasto.findMany({
      where: { eventoId },
      include: { acreedores: true, deudores: true },
    });

    return rows.map(toGastoCompleto);
  }

  async contarPorEvento(eventoIds: string[]): Promise<Record<string, number>> {
    const grupos = await this.prisma.gasto.groupBy({
      by: ['eventoId'],
      where: { eventoId: { in: eventoIds } },
      _count: { id: true },
    });

    return Object.fromEntries(grupos.map((g) => [g.eventoId, g._count.id]));
  }
}
