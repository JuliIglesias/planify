import { Response } from 'express';
import { listGroupsForUser } from './groups.service';
import { getGroupsOverview } from '../events/events.queries';
import { OrganizerRequest } from '../../middlewares/organizerGuard';
import { UnauthorizedError } from '../../common/errors';

// GET /groups/mine — HU-05 (equivalente a "GET /users/:id/groups" del plan,
// simplificado para no requerir un módulo `users` completo todavía).
export async function mine(req: OrganizerRequest, res: Response) {
  if (!req.usuarioId) throw new UnauthorizedError();
  const grupos = await listGroupsForUser(req.usuarioId);
  res.json(grupos);
}

// GET /groups/overview — datos ya armados para la pantalla Groups.
export async function overview(req: OrganizerRequest, res: Response) {
  if (!req.usuarioId) throw new UnauthorizedError();
  res.json(await getGroupsOverview(req.usuarioId));
}
