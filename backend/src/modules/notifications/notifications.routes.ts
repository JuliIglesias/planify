import { Router } from 'express';
import { notImplemented } from '../../common/notImplemented';

// SCRUM-15 (15/10-28/10) — HU-35, vía SNS/Pinpoint. Nota: el backend solo está
// encendido para testing/demo, así que NFR#8 (99% < 60s) se valida solo en esas
// ventanas (ver docs/02-decisiones.md Duda #8 revisada).
export const notificationsRouter = Router();

notificationsRouter.post('/notifications/register-device', notImplemented('SCRUM-15', 'HU-35 registrar device para push'));
