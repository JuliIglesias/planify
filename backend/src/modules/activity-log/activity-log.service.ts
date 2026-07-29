import { Prisma } from '@prisma/client';
import { prisma } from '../../common/prisma';

/**
 * SCRUM-13 — HU-24/HU-25. Es el "chat" del charter, reinterpretado: un feed
 * automático de lo que pasa en el evento, sin mensajería libre (Duda #9).
 */
export const ActivityType = {
  eventoCreado: 'evento_creado',
  horarioConfirmado: 'horario_confirmado',
  eventoCancelado: 'evento_cancelado',
  asistenciaConfirmada: 'asistencia_confirmada',
  disponibilidadCargada: 'disponibilidad_cargada',
  gastoAgregado: 'gasto_agregado',
  deudaSaldada: 'deuda_saldada',
  tareaCreada: 'tarea_creada',
  tareaAsignada: 'tarea_asignada',
  tareaCompletada: 'tarea_completada',
  participanteSeUnio: 'participante_se_unio',
} as const;

export type ActivityTypeValue = (typeof ActivityType)[keyof typeof ActivityType];

/** Registra una entrada del log. Acepta un client de transacción para que el
 *  log se escriba atómicamente junto con la acción que lo origina. */
export async function logActivity(
  client: Prisma.TransactionClient | typeof prisma,
  params: {
    eventoId: string;
    tipo: ActivityTypeValue;
    actorParticipanteId: string;
    payload?: Prisma.InputJsonValue;
  },
) {
  return client.logActividad.create({
    data: {
      eventoId: params.eventoId,
      tipo: params.tipo,
      actorParticipanteId: params.actorParticipanteId,
      payload: params.payload,
    },
  });
}

export async function getActivityLog(eventoId: string) {
  const entries = await prisma.logActividad.findMany({
    where: { eventoId },
    orderBy: { createdAt: 'desc' },
    include: { actor: { select: { id: true, nombreDisplay: true } } },
  });

  return entries.map((e) => ({
    id: e.id,
    tipo: e.tipo,
    payload: e.payload,
    createdAt: e.createdAt,
    actor: e.actor,
  }));
}

/**
 * HU-25 — contador de actividad no leída. Cuenta las entradas posteriores a la
 * última lectura del participante en cada evento. A nivel grupo, la UI muestra
 * la suma de todos sus eventos (ver Duda #2).
 */
export async function getUnreadCounts(usuarioId: string) {
  const participaciones = await prisma.participante.findMany({
    where: { usuarioId },
    select: { id: true, eventoId: true, ultimaLecturaAt: true, evento: { select: { grupoId: true } } },
  });

  const porEvento: Record<string, number> = {};
  const porGrupo: Record<string, number> = {};

  for (const p of participaciones) {
    const count = await prisma.logActividad.count({
      where: {
        eventoId: p.eventoId,
        actorParticipanteId: { not: p.id },
        ...(p.ultimaLecturaAt ? { createdAt: { gt: p.ultimaLecturaAt } } : {}),
      },
    });

    porEvento[p.eventoId] = count;
    porGrupo[p.evento.grupoId] = (porGrupo[p.evento.grupoId] ?? 0) + count;
  }

  return { porEvento, porGrupo };
}

export async function markAsRead(participanteId: string) {
  return prisma.participante.update({
    where: { id: participanteId },
    data: { ultimaLecturaAt: new Date() },
  });
}
