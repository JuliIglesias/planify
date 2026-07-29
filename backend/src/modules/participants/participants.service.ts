import { randomUUID } from 'crypto';
import { prisma } from '../../common/prisma';
import { BadRequestError, NotFoundError } from '../../common/errors';

// HU-01 / HU-03 — un anónimo se une a un evento eligiendo un nombre visible.
// El token_sesion vive en local storage del dispositivo (mobile) y solo es válido
// mientras el evento no esté cancelado/finalizado (ver Duda #5 y #19).
export async function joinAsAnonymous(eventoId: string, nombreDisplay: string) {
  if (!nombreDisplay?.trim()) throw new BadRequestError('nombreDisplay es requerido');

  const evento = await prisma.evento.findUnique({ where: { id: eventoId } });
  if (!evento) throw new NotFoundError('Evento no encontrado');
  if (evento.estado === 'cancelado' || evento.estado === 'finalizado') {
    throw new BadRequestError('El evento ya no acepta nuevos participantes');
  }

  const participante = await prisma.participante.create({
    data: {
      eventoId,
      nombreDisplay: nombreDisplay.trim(),
      esAnonimo: true,
      tokenSesion: randomUUID(),
    },
  });

  return { participanteId: participante.id, tokenSesion: participante.tokenSesion };
}
