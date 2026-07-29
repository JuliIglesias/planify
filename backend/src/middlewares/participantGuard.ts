import { NextFunction, Request, Response } from 'express';
import { prisma } from '../common/prisma';
import { UnauthorizedError, NotFoundError } from '../common/errors';
import { verifyOrganizerToken } from '../common/jwt';

export interface ParticipantRequest extends Request {
  participanteId?: string;
}

// Identifica al Participante de la request, sea anónimo (X-Participant-Token, ver HU-01/Duda #5)
// u organizador logueado (Authorization: Bearer, ver HU-41) — ambos caminos conviven en el MVP.
export async function participantGuard(req: ParticipantRequest, _res: Response, next: NextFunction) {
  const eventoId = String(req.params.eventoId ?? req.params.id ?? '') || undefined;
  const participantToken = req.header('X-Participant-Token');
  const authHeader = req.headers.authorization;

  if (participantToken) {
    const participante = await prisma.participante.findUnique({ where: { tokenSesion: participantToken } });
    if (!participante) throw new UnauthorizedError('Token de participante inválido');
    req.participanteId = participante.id;
    return next();
  }

  if (authHeader?.startsWith('Bearer ')) {
    try {
      const payload = verifyOrganizerToken(authHeader.slice('Bearer '.length));
      if (!eventoId) throw new UnauthorizedError('Falta el evento en la ruta');
      const participante = await prisma.participante.findFirst({
        where: { eventoId, usuarioId: payload.usuarioId },
      });
      if (!participante) throw new NotFoundError('El organizador no es participante de este evento');
      req.participanteId = participante.id;
      return next();
    } catch (err) {
      if (err instanceof UnauthorizedError || err instanceof NotFoundError) throw err;
      throw new UnauthorizedError('Token de organizador inválido o expirado');
    }
  }

  throw new UnauthorizedError('Falta autenticación de participante u organizador');
}
