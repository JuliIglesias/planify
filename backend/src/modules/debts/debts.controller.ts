import { Response } from 'express';
import { getEventDebts, getUserBalance, settleDebt } from './debts.service';
import { ParticipantRequest } from '../../middlewares/participantGuard';
import { OrganizerRequest } from '../../middlewares/organizerGuard';
import { UnauthorizedError } from '../../common/errors';

export async function eventDebts(req: ParticipantRequest, res: Response) {
  res.json(await getEventDebts(String(req.params.id)));
}

// HU-16/HU-17 — alimenta la pantalla Balances.
export async function myBalance(req: OrganizerRequest, res: Response) {
  if (!req.usuarioId) throw new UnauthorizedError();
  res.json(await getUserBalance(req.usuarioId));
}

export async function settle(req: ParticipantRequest, res: Response) {
  if (!req.participanteId) throw new UnauthorizedError();
  res.json(await settleDebt(String(req.params.debtId), req.participanteId));
}
