import { Router } from 'express';
import { create, list, close } from './expenses.controller';
import { participantGuard } from '../../middlewares/participantGuard';
import { organizerGuard } from '../../middlewares/organizerGuard';

// SCRUM-11 (10/09-30/09) — HU-13/HU-14/HU-19.
export const expensesRouter = Router();

expensesRouter.post('/events/:id/expenses', participantGuard, create);
expensesRouter.get('/events/:id/expenses', participantGuard, list);
expensesRouter.patch('/events/:id/expenses/close', organizerGuard, close);
