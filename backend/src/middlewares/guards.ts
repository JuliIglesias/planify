import { NextFunction, Request, RequestHandler, Response } from 'express';
import { NotFoundError, UnauthorizedError } from '../common/errors';
import { ParticipanteRepository, TokenService } from '../domain/repositories';

export interface OrganizerRequest extends Request {
  usuarioId?: string;
}

export interface ParticipantRequest extends Request {
  participanteId?: string;
  usuarioId?: string;
}

/**
 * Los guards se construyen con sus dependencias en vez de importarlas: así el
 * día que la autenticación pase a Cognito (SCRUM-14), se cambia la
 * implementación de TokenService en el container y esto sigue igual.
 */
export function crearOrganizerGuard(tokens: TokenService): RequestHandler {
  return (req: OrganizerRequest, _res: Response, next: NextFunction) => {
    const header = req.headers.authorization;
    if (!header?.startsWith('Bearer ')) {
      return next(new UnauthorizedError('Falta el token de organizador'));
    }

    try {
      const payload = tokens.verify(header.slice('Bearer '.length));
      req.usuarioId = payload.usuarioId;
      next();
    } catch {
      next(new UnauthorizedError('Token de organizador inválido o expirado'));
    }
  };
}

/**
 * Identifica al participante de la request. Los dos caminos del MVP conviven:
 * anónimo (X-Participant-Token) y organizador logueado (Authorization).
 */
export function crearParticipantGuard(
  tokens: TokenService,
  participantes: ParticipanteRepository,
): RequestHandler {
  return async (req: ParticipantRequest, _res: Response, next: NextFunction) => {
    try {
      const participantToken = req.header('X-Participant-Token');

      if (participantToken) {
        const participante = await participantes.findByTokenSesion(participantToken);
        if (!participante) throw new UnauthorizedError('Token de participante inválido');
        req.participanteId = participante.id;
        return next();
      }

      const authHeader = req.headers.authorization;
      if (!authHeader?.startsWith('Bearer ')) {
        throw new UnauthorizedError('Falta autenticación de participante u organizador');
      }

      let usuarioId: string;
      try {
        usuarioId = tokens.verify(authHeader.slice('Bearer '.length)).usuarioId;
      } catch {
        throw new UnauthorizedError('Token de organizador inválido o expirado');
      }

      const eventoId = String(req.params.eventoId ?? req.params.id ?? '');
      if (!eventoId) throw new UnauthorizedError('Falta el evento en la ruta');

      const participante = await participantes.findByEventoAndUsuario(eventoId, usuarioId);
      if (!participante) {
        throw new NotFoundError('No participás de este evento');
      }

      req.participanteId = participante.id;
      req.usuarioId = usuarioId;
      next();
    } catch (err) {
      next(err);
    }
  };
}
