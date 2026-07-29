import { Router } from 'express';
import { login } from './auth.controller';

export const authRouter = Router();

// POST /auth/login — HU-41
authRouter.post('/login', login);
