import { Response } from 'express';
import { createExpense, listExpenses, closeExpenses } from './expenses.service';
import { ParticipantRequest } from '../../middlewares/participantGuard';
import { OrganizerRequest } from '../../middlewares/organizerGuard';
import { UnauthorizedError } from '../../common/errors';

export async function create(req: ParticipantRequest, res: Response) {
  if (!req.participanteId) throw new UnauthorizedError();
  const gasto = await createExpense(String(req.params.id), req.participanteId, req.body ?? {});
  res.status(201).json(gasto);
}

export async function list(req: ParticipantRequest, res: Response) {
  res.json(await listExpenses(String(req.params.id)));
}

export async function close(req: OrganizerRequest, res: Response) {
  if (!req.usuarioId) throw new UnauthorizedError();
  res.json(await closeExpenses(String(req.params.id), req.usuarioId));
}
