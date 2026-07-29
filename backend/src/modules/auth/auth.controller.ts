import { Request, Response } from 'express';
import { loginOrganizer } from './auth.service';
import { BadRequestError } from '../../common/errors';

export async function login(req: Request, res: Response) {
  const { email, password } = req.body ?? {};
  if (!email || !password) throw new BadRequestError('email y password son requeridos');

  const result = await loginOrganizer(email, password);
  res.json(result);
}
