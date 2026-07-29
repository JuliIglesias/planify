import { NextFunction, Request, Response } from 'express';
import { UnauthorizedError } from '../common/errors';
import { verifyOrganizerToken } from '../common/jwt';

export interface OrganizerRequest extends Request {
  usuarioId?: string;
}

// Requiere estar logueado como el usuario organizador semilla (HU-41, ver Duda #19).
// Reemplaza el auth de Cognito hasta que SCRUM-14 (auth completa) lo reemplace.
export function organizerGuard(req: OrganizerRequest, _res: Response, next: NextFunction) {
  const header = req.headers.authorization;
  if (!header?.startsWith('Bearer ')) {
    throw new UnauthorizedError('Falta el token de organizador');
  }

  try {
    const payload = verifyOrganizerToken(header.slice('Bearer '.length));
    req.usuarioId = payload.usuarioId;
    next();
  } catch {
    throw new UnauthorizedError('Token de organizador inválido o expirado');
  }
}
