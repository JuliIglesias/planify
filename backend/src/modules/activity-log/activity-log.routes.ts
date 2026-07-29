import { Router } from 'express';
import { list, unread } from './activity-log.controller';
import { participantGuard } from '../../middlewares/participantGuard';
import { organizerGuard } from '../../middlewares/organizerGuard';

// SCRUM-13 (01/10-14/10) — HU-24/HU-25. Es el log de actividad del evento,
// no un chat de mensajería libre (ver docs/02-decisiones.md Duda #9 y #20).
export const activityLogRouter = Router();

activityLogRouter.get('/events/:id/activity-log', participantGuard, list);
activityLogRouter.get('/me/unread', organizerGuard, unread);
