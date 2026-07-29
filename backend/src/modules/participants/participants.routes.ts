import { Router } from 'express';
import { createAnonymous } from './participants.controller';

export const participantsRouter = Router();

// POST /participants/anonymous — HU-01
participantsRouter.post('/anonymous', createAnonymous);
