import { Response } from 'express';
import { setAvailability, getHeatmap, confirmSchedule } from './availability.service';
import { ParticipantRequest } from '../../middlewares/participantGuard';
import { OrganizerRequest } from '../../middlewares/organizerGuard';
import { BadRequestError, UnauthorizedError } from '../../common/errors';

export async function submit(req: ParticipantRequest, res: Response) {
  if (!req.participanteId) throw new UnauthorizedError();
  const { slots } = req.body ?? {};
  await setAvailability(String(req.params.id), req.participanteId, slots);
  res.status(204).send();
}

export async function heatmap(req: OrganizerRequest, res: Response) {
  const data = await getHeatmap(String(req.params.id));
  res.json(data);
}

export async function confirm(req: OrganizerRequest, res: Response) {
  if (!req.usuarioId) throw new UnauthorizedError();
  const { fechaHoraInicio } = req.body ?? {};
  if (!fechaHoraInicio) throw new BadRequestError('fechaHoraInicio es requerido');

  const evento = await confirmSchedule(req.usuarioId, String(req.params.id), new Date(fechaHoraInicio));
  res.json(evento);
}
