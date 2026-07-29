import { Router } from 'express';
import { create, resolve } from './invitations.controller';
import { organizerGuard } from '../../middlewares/organizerGuard';

export const invitationsRouter = Router();

// POST /invitations — organizador genera el link (HU-02)
invitationsRouter.post('/', organizerGuard, create);
// GET /invitations/:token — cualquiera (anónimo incluido) resuelve el link
invitationsRouter.get('/:token', resolve);
