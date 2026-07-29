import { Router } from 'express';
import { create, cancel, attendance, upcoming, history, detail } from './events.controller';
import { submit, heatmap, confirm } from '../availability/availability.controller';
import { organizerGuard } from '../../middlewares/organizerGuard';
import { participantGuard } from '../../middlewares/participantGuard';

export const eventsRouter = Router();

// Listados (Home e Historial). Van antes de '/:id' para que no los capture.
eventsRouter.get('/upcoming', organizerGuard, upcoming);
eventsRouter.get('/history', organizerGuard, history);

// SCRUM-8 — Creación de eventos (HU-06) y cancelación (HU-11)
eventsRouter.post('/', organizerGuard, create);
eventsRouter.get('/:id', participantGuard, detail);
eventsRouter.patch('/:id/cancel', organizerGuard, cancel);

// SCRUM-10 — Confirmación de asistencia (HU-10)
eventsRouter.patch('/:id/attendance', participantGuard, attendance);

// SCRUM-9 — Disponibilidad, heatmap y confirmación de horario (HU-07/HU-08/HU-09)
eventsRouter.post('/:id/availability', participantGuard, submit);
eventsRouter.get('/:id/availability/heatmap', participantGuard, heatmap);
eventsRouter.patch('/:id/confirm', organizerGuard, confirm);
