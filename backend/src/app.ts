import express from 'express';
import cors from 'cors';
import helmet from 'helmet';

import { authRouter } from './modules/auth/auth.routes';
import { participantsRouter } from './modules/participants/participants.routes';
import { invitationsRouter } from './modules/invitations/invitations.routes';
import { eventsRouter } from './modules/events/events.routes';
import { groupsRouter } from './modules/groups/groups.routes';
import { tasksRouter } from './modules/tasks/tasks.routes';
import { expensesRouter } from './modules/expenses/expenses.routes';
import { debtsRouter } from './modules/debts/debts.routes';
import { activityLogRouter } from './modules/activity-log/activity-log.routes';
import { notificationsRouter } from './modules/notifications/notifications.routes';
import { aiEventsRouter } from './modules/ai-events/ai-events.routes';
import { errorHandler, notFoundHandler } from './middlewares/errorHandler';

export function createApp() {
  const app = express();

  app.use(helmet());
  app.use(cors());
  app.use(express.json());

  app.get('/health', (_req, res) => res.json({ status: 'ok' }));

  // MVP (SCRUM-7/8/9/10/18)
  app.use('/auth', authRouter);
  app.use('/participants', participantsRouter);
  app.use('/invitations', invitationsRouter);
  app.use('/events', eventsRouter);
  app.use('/groups', groupsRouter);

  // SCRUM-11/12/13 — implementados
  app.use('/', tasksRouter);
  app.use('/', expensesRouter);
  app.use('/', debtsRouter);
  app.use('/', activityLogRouter);

  // SCRUM-15/17 — comprometidos en Jira, todavía sin implementar (devuelven 501)
  app.use('/', notificationsRouter);
  app.use('/', aiEventsRouter);

  app.use(notFoundHandler);
  app.use(errorHandler);

  return app;
}
