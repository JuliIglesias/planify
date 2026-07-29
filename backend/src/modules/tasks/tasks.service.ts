import { prisma } from '../../common/prisma';
import { BadRequestError, NotFoundError } from '../../common/errors';
import { logActivity, ActivityType } from '../activity-log/activity-log.service';

/**
 * SCRUM-12 — HU-20 a HU-23. Las "actividades" del evento: cosas que hay que
 * hacer antes de la juntada (comprar carne, hielo…) que alguien toma.
 * Estados: no_asignado → pendiente → completado (Duda #4).
 */

export async function createTask(eventoId: string, participanteId: string, titulo: string) {
  if (!titulo?.trim()) throw new BadRequestError('titulo es requerido');

  const evento = await prisma.evento.findUnique({ where: { id: eventoId } });
  if (!evento) throw new NotFoundError('Evento no encontrado');

  const tarea = await prisma.tarea.create({
    data: { eventoId, titulo: titulo.trim(), creadoPor: participanteId, estado: 'no_asignado' },
  });

  await logActivity(prisma, {
    eventoId,
    tipo: ActivityType.tareaCreada,
    actorParticipanteId: participanteId,
    payload: { tareaId: tarea.id, titulo: tarea.titulo },
  });

  return tarea;
}

export async function listTasks(eventoId: string) {
  return prisma.tarea.findMany({
    where: { eventoId },
    orderBy: { createdAt: 'asc' },
    include: {
      asignado: { select: { id: true, nombreDisplay: true } },
      creador: { select: { id: true, nombreDisplay: true } },
    },
  });
}

/**
 * HU-21/HU-22 — cualquier miembro puede tomar una tarea o asignársela a otro
 * (Duda #6: no es un permiso exclusivo del organizador).
 */
export async function assignTask(tareaId: string, actorParticipanteId: string, asignadoA: string) {
  const tarea = await prisma.tarea.findUnique({ where: { id: tareaId } });
  if (!tarea) throw new NotFoundError('Tarea no encontrada');

  const actualizada = await prisma.tarea.update({
    where: { id: tareaId },
    data: { asignadoA, estado: 'pendiente' },
    include: { asignado: { select: { id: true, nombreDisplay: true } } },
  });

  await logActivity(prisma, {
    eventoId: tarea.eventoId,
    tipo: ActivityType.tareaAsignada,
    actorParticipanteId,
    payload: { tareaId, titulo: tarea.titulo, asignadoA },
  });

  return actualizada;
}

export async function completeTask(tareaId: string, participanteId: string) {
  const tarea = await prisma.tarea.findUnique({ where: { id: tareaId } });
  if (!tarea) throw new NotFoundError('Tarea no encontrada');
  if (tarea.estado === 'completado') throw new BadRequestError('La tarea ya está completada');

  const actualizada = await prisma.tarea.update({
    where: { id: tareaId },
    data: { estado: 'completado' },
  });

  await logActivity(prisma, {
    eventoId: tarea.eventoId,
    tipo: ActivityType.tareaCompletada,
    actorParticipanteId: participanteId,
    payload: { tareaId, titulo: tarea.titulo },
  });

  return actualizada;
}
