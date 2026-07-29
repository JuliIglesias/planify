import { Request, Response } from 'express';
import { joinAsAnonymous } from './participants.service';
import { BadRequestError } from '../../common/errors';

export async function createAnonymous(req: Request, res: Response) {
  const { eventoId, nombreDisplay } = req.body ?? {};
  if (!eventoId) throw new BadRequestError('eventoId es requerido');

  const result = await joinAsAnonymous(eventoId, nombreDisplay);
  res.status(201).json(result);
}
