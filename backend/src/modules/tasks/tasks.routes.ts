import { Router } from 'express';
import { create, list, assign, complete } from './tasks.controller';
import { participantGuard } from '../../middlewares/participantGuard';

// SCRUM-12 (17/09-30/09) — HU-20 a HU-23.
export const tasksRouter = Router();

tasksRouter.post('/events/:id/tasks', participantGuard, create);
tasksRouter.get('/events/:id/tasks', participantGuard, list);
tasksRouter.patch('/events/:id/tasks/:taskId/assign', participantGuard, assign);
tasksRouter.patch('/events/:id/tasks/:taskId/complete', participantGuard, complete);
