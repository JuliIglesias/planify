import { PrismaClient } from '@prisma/client';
import { AsistenciaEstado, Evento, EventoEstado, Participante } from '../../domain/entities';
import {
  CrearEventoData,
  EventoConResumen,
  EventoRepository,
} from '../../domain/repositories';
import { toEvento, toParticipante } from './mappers';

const RESUMEN_INCLUDE = {
  grupo: { select: { nombre: true } },
  participantes: {
    select: { id: true, nombreDisplay: true, estadoAsistencia: true },
  },
} as const;

export class PrismaEventoRepository implements EventoRepository {
  constructor(private readonly prisma: PrismaClient) {}

  async findById(id: string): Promise<Evento | null> {
    const row = await this.prisma.evento.findUnique({ where: { id } });
    return row ? toEvento(row) : null;
  }

  async createWithOrganizer(
    data: CrearEventoData,
  ): Promise<{ evento: Evento; organizador: Participante }> {
    // Transacción: un evento sin su organizador sería un estado inválido
    // (nadie podría cancelarlo ni cerrar sus gastos).
    return this.prisma.$transaction(async (tx) => {
      const creado = await tx.evento.create({
        data: {
          grupoId: data.grupoId,
          nombre: data.nombre,
          lugarTexto: data.lugarTexto,
          creadoPor: '', // se completa abajo, cuando existe el participante
        },
      });

      const organizador = await tx.participante.create({
        data: {
          eventoId: creado.id,
          usuarioId: data.organizadorUsuarioId,
          nombreDisplay: data.organizadorNombre,
          esOrganizador: true,
          estadoAsistencia: 'confirmado',
        },
      });

      const evento = await tx.evento.update({
        where: { id: creado.id },
        data: { creadoPor: organizador.id },
      });

      return { evento: toEvento(evento), organizador: toParticipante(organizador) };
    });
  }

  async updateEstado(id: string, estado: EventoEstado): Promise<Evento> {
    const row = await this.prisma.evento.update({ where: { id }, data: { estado } });
    return toEvento(row);
  }

  async confirmarHorario(id: string, fechaHoraInicio: Date): Promise<Evento> {
    const row = await this.prisma.evento.update({
      where: { id },
      data: { estado: 'confirmado', fechaHoraInicio },
    });
    return toEvento(row);
  }

  async listUpcomingForUsuario(usuarioId: string): Promise<EventoConResumen[]> {
    const rows = await this.prisma.evento.findMany({
      where: {
        participantes: { some: { usuarioId } },
        estado: { in: ['planificacion', 'confirmado'] },
      },
      orderBy: [{ fechaHoraInicio: 'asc' }, { createdAt: 'desc' }],
      include: RESUMEN_INCLUDE,
    });

    return rows.map(this.toResumen);
  }

  async listPastForUsuario(usuarioId: string): Promise<EventoConResumen[]> {
    const rows = await this.prisma.evento.findMany({
      where: {
        participantes: { some: { usuarioId } },
        estado: { in: ['finalizado', 'cancelado', 'confirmado'] },
      },
      orderBy: { createdAt: 'desc' },
      include: RESUMEN_INCLUDE,
    });

    return rows.map(this.toResumen);
  }

  async listByGrupo(grupoId: string): Promise<Evento[]> {
    const rows = await this.prisma.evento.findMany({
      where: { grupoId },
      orderBy: [{ fechaHoraInicio: 'asc' }, { createdAt: 'desc' }],
    });
    return rows.map(toEvento);
  }

  private toResumen = (row: {
    id: string;
    grupoId: string;
    nombre: string;
    lugarTexto: string;
    estado: string;
    fechaHoraInicio: Date | null;
    creadoPor: string;
    createdAt: Date;
    grupo: { nombre: string };
    participantes: { id: string; nombreDisplay: string; estadoAsistencia: string }[];
  }): EventoConResumen => ({
    ...toEvento(row),
    grupoNombre: row.grupo.nombre,
    participantes: row.participantes.map((p) => ({
      id: p.id,
      nombreDisplay: p.nombreDisplay,
      estadoAsistencia: p.estadoAsistencia as AsistenciaEstado,
    })),
    confirmados: row.participantes.filter((p) => p.estadoAsistencia === 'confirmado').length,
  });
}
