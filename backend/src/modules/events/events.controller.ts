import { Response } from 'express';
import { createEvent, cancelEvent, setAttendance } from './events.service';
import {
  getUpcomingEvents,
  getGroupsOverview,
  getHistory,
  getEventDetail,
} from './events.queries';
import { OrganizerRequest } from '../../middlewares/organizerGuard';
import { ParticipantRequest } from '../../middlewares/participantGuard';
import { BadRequestError, UnauthorizedError } from '../../common/errors';

export async function create(req: OrganizerRequest, res: Response) {
  if (!req.usuarioId) throw new UnauthorizedError();
  const result = await createEvent(req.usuarioId, req.body ?? {});
  res.status(201).json(result);
}

export async function cancel(req: OrganizerRequest, res: Response) {
  if (!req.usuarioId) throw new UnauthorizedError();
  await cancelEvent(req.usuarioId, String(req.params.id));
  res.status(204).send();
}

export async function attendance(req: ParticipantRequest, res: Response) {
  const { estado } = req.body ?? {};
  if (estado !== 'confirmado' && estado !== 'rechazado') {
    throw new BadRequestError('estado debe ser "confirmado" o "rechazado"');
  }
  if (!req.participanteId) throw new UnauthorizedError();

  const participante = await setAttendance(req.participanteId, estado);
  res.json(participante);
}

// Listados que alimentan Home, Groups e Historial en la app.
export async function upcoming(req: OrganizerRequest, res: Response) {
  if (!req.usuarioId) throw new UnauthorizedError();
  res.json(await getUpcomingEvents(req.usuarioId));
}

export async function groupsOverview(req: OrganizerRequest, res: Response) {
  if (!req.usuarioId) throw new UnauthorizedError();
  res.json(await getGroupsOverview(req.usuarioId));
}

export async function history(req: OrganizerRequest, res: Response) {
  if (!req.usuarioId) throw new UnauthorizedError();
  res.json(await getHistory(req.usuarioId));
}

export async function detail(req: ParticipantRequest, res: Response) {
  res.json(await getEventDetail(String(req.params.id)));
}
