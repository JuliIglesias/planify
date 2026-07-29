import { randomUUID } from 'crypto';
import { prisma } from '../../common/prisma';
import { BadRequestError, NotFoundError } from '../../common/errors';

// HU-02 — link de invitación que lleva directo al evento.
export async function createInvitation(eventoId: string) {
  const evento = await prisma.evento.findUnique({ where: { id: eventoId } });
  if (!evento) throw new NotFoundError('Evento no encontrado');

  const invitacion = await prisma.invitacion.create({
    data: { eventoId, tokenUnico: randomUUID() },
  });

  return invitacion;
}

export async function resolveInvitation(tokenUnico: string) {
  const invitacion = await prisma.invitacion.findUnique({
    where: { tokenUnico },
    include: { evento: true },
  });
  if (!invitacion) throw new NotFoundError('Invitación no encontrada');
  if (invitacion.expiraEn && invitacion.expiraEn < new Date()) {
    throw new BadRequestError('La invitación expiró');
  }
  if (invitacion.evento.estado === 'cancelado' || invitacion.evento.estado === 'finalizado') {
    throw new BadRequestError('El evento ya no está disponible');
  }

  return invitacion;
}
