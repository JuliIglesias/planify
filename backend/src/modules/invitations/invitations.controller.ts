import { Response } from 'express';
import { createInvitation, resolveInvitation } from './invitations.service';
import { BadRequestError } from '../../common/errors';
import { OrganizerRequest } from '../../middlewares/organizerGuard';
import { Request } from 'express';

export async function create(req: OrganizerRequest, res: Response) {
  const { eventoId } = req.body ?? {};
  if (!eventoId) throw new BadRequestError('eventoId es requerido');

  const invitacion = await createInvitation(eventoId);
  res.status(201).json(invitacion);
}

export async function resolve(req: Request, res: Response) {
  const invitacion = await resolveInvitation(String(req.params.token));
  res.json(invitacion);
}
