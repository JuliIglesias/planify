import { Router } from 'express';
import { eventDebts, myBalance, settle } from './debts.controller';
import { participantGuard } from '../../middlewares/participantGuard';
import { organizerGuard } from '../../middlewares/organizerGuard';

// SCRUM-11 — HU-15 (motor de deudas), HU-16/HU-17 (balances), HU-18 (saldar).
export const debtsRouter = Router();

debtsRouter.get('/events/:id/debts', participantGuard, eventDebts);
debtsRouter.get('/me/balance', organizerGuard, myBalance);
debtsRouter.patch('/events/:id/debts/:debtId/settle', participantGuard, settle);
