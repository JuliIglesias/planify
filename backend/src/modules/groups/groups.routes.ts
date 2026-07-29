import { Router } from 'express';
import { mine, overview } from './groups.controller';
import { organizerGuard } from '../../middlewares/organizerGuard';

export const groupsRouter = Router();

groupsRouter.get('/mine', organizerGuard, mine);
groupsRouter.get('/overview', organizerGuard, overview);
