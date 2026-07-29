import { Request, Response } from 'express';

// Handler placeholder para módulos que todavía no se implementaron (post-MVP,
// ver docs/01-plan-de-ejecucion.md §5 para la épica/historia y fecha de Jira de cada uno).
export function notImplemented(epic: string, hint: string) {
  return (_req: Request, res: Response) => {
    res.status(501).json({
      error: 'Not implemented yet',
      epic,
      hint,
    });
  };
}
