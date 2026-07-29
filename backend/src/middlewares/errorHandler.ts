import { NextFunction, Request, Response } from 'express';
import { HttpError } from '../common/errors';

// Middleware de error centralizado — reemplaza los ExceptionFilters de Nest.
export function errorHandler(err: unknown, _req: Request, res: Response, _next: NextFunction) {
  if (err instanceof HttpError) {
    return res.status(err.status).json({ error: err.message });
  }

  console.error(err);
  return res.status(500).json({ error: 'Error interno del servidor' });
}

export function notFoundHandler(req: Request, res: Response) {
  res.status(404).json({ error: `Ruta no encontrada: ${req.method} ${req.originalUrl}` });
}
