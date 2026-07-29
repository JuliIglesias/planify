import { Response } from 'express';
import { getActivityLog, getUnreadCounts, markAsRead } from './activity-log.service';
import { ParticipantRequest } from '../../middlewares/participantGuard';
import { OrganizerRequest } from '../../middlewares/organizerGuard';
import { UnauthorizedError } from '../../common/errors';

export async function list(req: ParticipantRequest, res: Response) {
  const eventoId = String(req.params.id);
  const log = await getActivityLog(eventoId);

  // Abrir el log marca el evento como leído (HU-25).
  if (req.participanteId) await markAsRead(req.participanteId);

  res.json(log);
}

export async function unread(req: OrganizerRequest, res: Response) {
  if (!req.usuarioId) throw new UnauthorizedError();
  res.json(await getUnreadCounts(req.usuarioId));
}
