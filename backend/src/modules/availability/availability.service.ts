import { prisma } from '../../common/prisma';
import { BadRequestError, ForbiddenError, NotFoundError } from '../../common/errors';

interface Slot {
  diaSemana: number; // 0=lunes .. 6=domingo
  bloqueHora: number; // bloques de 30 min, 0..47
}

// HU-07 — el participante carga su disponibilidad semanal para el evento.
// Reemplaza (no acumula) los slots previos del participante para ese evento.
export async function setAvailability(eventoId: string, participanteId: string, slots: Slot[]) {
  if (!Array.isArray(slots)) throw new BadRequestError('slots debe ser un array');

  return prisma.$transaction([
    prisma.disponibilidadSlot.deleteMany({ where: { eventoId, participanteId } }),
    prisma.disponibilidadSlot.createMany({
      data: slots.map((s) => ({ eventoId, participanteId, diaSemana: s.diaSemana, bloqueHora: s.bloqueHora })),
    }),
  ]);
}

// HU-08 — heatmap: cantidad de participantes disponibles por bloque horario.
export async function getHeatmap(eventoId: string) {
  const slots = await prisma.disponibilidadSlot.groupBy({
    by: ['diaSemana', 'bloqueHora'],
    where: { eventoId },
    _count: { participanteId: true },
  });

  return slots.map((s) => ({
    diaSemana: s.diaSemana,
    bloqueHora: s.bloqueHora,
    disponibles: s._count.participanteId,
  }));
}

// HU-09 — el organizador confirma un horario de inicio a partir del heatmap.
export async function confirmSchedule(usuarioId: string, eventoId: string, fechaHoraInicio: Date) {
  const evento = await prisma.evento.findUnique({ where: { id: eventoId } });
  if (!evento) throw new NotFoundError('Evento no encontrado');

  const organizador = await prisma.participante.findFirst({
    where: { eventoId, usuarioId, esOrganizador: true },
  });
  if (!organizador) throw new ForbiddenError('Solo el organizador puede confirmar el horario');

  const eventoActualizado = await prisma.evento.update({
    where: { id: eventoId },
    data: { estado: 'confirmado', fechaHoraInicio },
  });

  // TODO(SCRUM-13/HU-24): emitir LOG_ACTIVIDAD "horario_confirmado" cuando el módulo
  // activity-log esté implementado. TODO(SCRUM-15/HU-35): disparar notificación push.

  return eventoActualizado;
}
