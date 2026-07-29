import { Response } from 'express';
import { createTask, listTasks, assignTask, completeTask } from './tasks.service';
import { ParticipantRequest } from '../../middlewares/participantGuard';
import { BadRequestError, UnauthorizedError } from '../../common/errors';

export async function create(req: ParticipantRequest, res: Response) {
  if (!req.participanteId) throw new UnauthorizedError();
  const tarea = await createTask(String(req.params.id), req.participanteId, req.body?.titulo);
  res.status(201).json(tarea);
}

export async function list(req: ParticipantRequest, res: Response) {
  res.json(await listTasks(String(req.params.id)));
}

export async function assign(req: ParticipantRequest, res: Response) {
  if (!req.participanteId) throw new UnauthorizedError();
  // Sin `asignadoA` explícito, el participante se está tomando la tarea (HU-21).
  const asignadoA = req.body?.asignadoA ?? req.participanteId;
  if (!asignadoA) throw new BadRequestError('asignadoA es requerido');
  res.json(await assignTask(String(req.params.taskId), req.participanteId, asignadoA));
}

export async function complete(req: ParticipantRequest, res: Response) {
  if (!req.participanteId) throw new UnauthorizedError();
  res.json(await completeTask(String(req.params.taskId), req.participanteId));
}
