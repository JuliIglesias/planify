import { prisma } from '../../common/prisma';
import { NotFoundError } from '../../common/errors';
import { getUnreadCounts } from '../activity-log/activity-log.service';

/** Home — "Próximos eventos": confirmados o en planificación, más cercanos primero. */
export async function getUpcomingEvents(usuarioId: string) {
  const eventos = await prisma.evento.findMany({
    where: {
      participantes: { some: { usuarioId } },
      estado: { in: ['planificacion', 'confirmado'] },
    },
    orderBy: [{ fechaHoraInicio: 'asc' }, { createdAt: 'desc' }],
    include: {
      grupo: { select: { id: true, nombre: true } },
      participantes: { select: { id: true, nombreDisplay: true, estadoAsistencia: true } },
    },
  });

  return eventos.map(serializeEventSummary);
}

/**
 * Groups — cada card muestra el grupo con su evento más próximo y contadores.
 * El badge "NUEVO" marca eventos creados hace poco dentro del grupo (Duda #2).
 */
export async function getGroupsOverview(usuarioId: string) {
  const grupos = await prisma.grupo.findMany({
    where: { miembros: { some: { usuarioId } } },
    include: {
      miembros: { include: { usuario: { select: { id: true, nombre: true, avatarUrl: true } } } },
      eventos: {
        orderBy: [{ fechaHoraInicio: 'asc' }, { createdAt: 'desc' }],
        include: {
          participantes: { select: { id: true, estadoAsistencia: true } },
          tareas: { select: { id: true, estado: true } },
          gastos: { select: { id: true } },
        },
      },
    },
  });

  const { porGrupo } = await getUnreadCounts(usuarioId);
  const hace48hs = new Date(Date.now() - 48 * 60 * 60 * 1000);

  return grupos.map((grupo) => {
    const activos = grupo.eventos.filter((e) => e.estado === 'planificacion' || e.estado === 'confirmado');
    const proximo = activos[0];

    return {
      id: grupo.id,
      nombre: grupo.nombre,
      avatarUrl: grupo.avatarUrl,
      miembros: grupo.miembros.map((m) => ({
        id: m.usuario.id,
        nombre: m.usuario.nombre,
        avatarUrl: m.usuario.avatarUrl,
      })),
      noLeidos: porGrupo[grupo.id] ?? 0,
      // "NUEVO" = hay un evento creado en las últimas 48hs en este grupo.
      tieneEventoNuevo: grupo.eventos.some((e) => e.createdAt > hace48hs),
      proximoEvento: proximo
        ? {
            id: proximo.id,
            nombre: proximo.nombre,
            lugarTexto: proximo.lugarTexto,
            estado: proximo.estado,
            fechaHoraInicio: proximo.fechaHoraInicio,
            confirmados: proximo.participantes.filter((p) => p.estadoAsistencia === 'confirmado').length,
            tareasPendientes: proximo.tareas.filter((t) => t.estado !== 'completado').length,
            gastos: proximo.gastos.length,
          }
        : null,
    };
  });
}

/**
 * Historial — eventos pasados agrupados por mes, con el estado de saldos.
 * Usa los mismos 3 estados que Balances (Duda #2: "historial trabaja igual").
 */
export async function getHistory(usuarioId: string) {
  const participaciones = await prisma.participante.findMany({
    where: { usuarioId },
    select: { id: true },
  });
  const misIds = participaciones.map((p) => p.id);

  const eventos = await prisma.evento.findMany({
    where: {
      participantes: { some: { usuarioId } },
      estado: { in: ['finalizado', 'cancelado', 'confirmado'] },
    },
    orderBy: { createdAt: 'desc' },
    include: {
      participantes: { select: { id: true, nombreDisplay: true } },
      deudas: true,
    },
  });

  return eventos.map((evento) => {
    const misDeudas = evento.deudas.filter(
      (d) =>
        (misIds.includes(d.deudorParticipanteId) || misIds.includes(d.acreedorParticipanteId)) &&
        d.estado !== 'saldado',
    );

    const debo = misDeudas.filter((d) => misIds.includes(d.deudorParticipanteId));
    const meDeben = misDeudas.filter((d) => misIds.includes(d.acreedorParticipanteId));

    let estadoSaldo: 'pagar' | 'pendiente' | 'saldado' = 'saldado';
    if (debo.length > 0) estadoSaldo = 'pagar';
    else if (meDeben.length > 0) estadoSaldo = 'pendiente';

    const montoRelevante = (debo.length > 0 ? debo : meDeben).reduce(
      (acc, d) => acc + Number(d.monto),
      0,
    );

    return {
      id: evento.id,
      nombre: evento.nombre,
      lugarTexto: evento.lugarTexto,
      estado: evento.estado,
      fechaHoraInicio: evento.fechaHoraInicio,
      createdAt: evento.createdAt,
      participantes: evento.participantes,
      estadoSaldo,
      monto: montoRelevante.toFixed(2),
    };
  });
}

/** Detalle completo de un evento — pantalla de evento + log de actividad. */
export async function getEventDetail(eventoId: string) {
  const evento = await prisma.evento.findUnique({
    where: { id: eventoId },
    include: {
      grupo: { select: { id: true, nombre: true } },
      participantes: {
        select: { id: true, nombreDisplay: true, estadoAsistencia: true, esOrganizador: true, esAnonimo: true },
      },
      tareas: { include: { asignado: { select: { id: true, nombreDisplay: true } } } },
      gastos: { include: { acreedores: true, deudores: true } },
    },
  });

  if (!evento) throw new NotFoundError('Evento no encontrado');
  return evento;
}

function serializeEventSummary(evento: {
  id: string;
  nombre: string;
  lugarTexto: string;
  estado: string;
  fechaHoraInicio: Date | null;
  grupo: { id: string; nombre: string };
  participantes: { id: string; nombreDisplay: string; estadoAsistencia: string }[];
}) {
  return {
    id: evento.id,
    nombre: evento.nombre,
    lugarTexto: evento.lugarTexto,
    estado: evento.estado,
    fechaHoraInicio: evento.fechaHoraInicio,
    grupo: evento.grupo,
    participantes: evento.participantes,
    confirmados: evento.participantes.filter((p) => p.estadoAsistencia === 'confirmado').length,
  };
}
