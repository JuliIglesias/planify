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
    select: { id: true, username: true, estadoAsistencia: true },
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
          rangoInicio: data.rangoInicio,
          rangoFin: data.rangoFin,
          creadoPor: '', // se completa abajo, cuando existe el participante
        },
      });

      const organizador = await tx.participante.create({
        data: {
          eventoId: creado.id,
          usuarioId: data.organizadorUsuarioId,
          username: data.organizadorUsername,
          esOrganizador: true,
          estadoAsistencia: 'confirmado',
        },
      });

      // Los demás miembros del grupo también participan del evento (H-01): sin
      // esto no aparecerían para asignarles gastos/tareas ni podrían confirmar.
      const otros = (data.otrosMiembros ?? []).filter(
        (m) => m.usuarioId !== data.organizadorUsuarioId,
      );
      if (otros.length > 0) {
        await tx.participante.createMany({
          data: otros.map((m) => ({
            eventoId: creado.id,
            usuarioId: m.usuarioId,
            username: m.username,
            esAnonimo: false,
            esOrganizador: false,
          })),
        });
      }

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

  async confirmarHorario(id: string, fechaHoraInicio: Date, fechaHoraFin: Date): Promise<Evento> {
    const row = await this.prisma.evento.update({
      where: { id },
      data: { estado: 'confirmado', fechaHoraInicio, fechaHoraFin },
    });
    return toEvento(row);
  }

  async extenderRango(id: string, nuevoRangoFin: Date): Promise<Evento> {
    const row = await this.prisma.evento.update({
      where: { id },
      data: { rangoFin: nuevoRangoFin, extensionesRango: { increment: 1 } },
    });
    return toEvento(row);
  }

  async listUpcomingForUsuario(usuarioId: string, ahora: Date): Promise<EventoConResumen[]> {
    const rows = await this.prisma.evento.findMany({
      where: {
        participantes: { some: { usuarioId } },
        // En planificación (sin fecha) o confirmado con fecha aún por venir.
        OR: [
          { estado: 'planificacion' },
          { estado: 'confirmado', fechaHoraInicio: null },
          { estado: 'confirmado', fechaHoraInicio: { gte: ahora } },
        ],
      },
      orderBy: [{ fechaHoraInicio: 'asc' }, { createdAt: 'desc' }],
      include: RESUMEN_INCLUDE,
    });

    return rows.map(this.toResumen);
  }

  async listHistoryForUsuario(usuarioId: string, finDeMesActual: Date): Promise<EventoConResumen[]> {
    const rows = await this.prisma.evento.findMany({
      where: {
        participantes: { some: { usuarioId } },
        // Terminado, cancelado, o cualquier evento (confirmado/borrador) antes del fin de mes actual.
        OR: [
          { estado: 'finalizado' },
          { estado: 'cancelado' },
          { fechaHoraInicio: { lt: finDeMesActual } },
        ],
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
    rangoInicio: Date;
    rangoFin: Date;
    extensionesRango: number;
    fechaHoraFin: Date | null;
    creadoPor: string;
    createdAt: Date;
    grupo: { nombre: string };
    participantes: { id: string; username: string; estadoAsistencia: string }[];
  }): EventoConResumen => ({
    ...toEvento(row),
    grupoNombre: row.grupo.nombre,
    participantes: row.participantes.map((p) => ({
      id: p.id,
      username: p.username,
      estadoAsistencia: p.estadoAsistencia as AsistenciaEstado,
    })),
    confirmados: row.participantes.filter((p) => p.estadoAsistencia === 'confirmado').length,
  });
}
