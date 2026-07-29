import { NextFunction, Request, RequestHandler, Response } from 'express';

/**
 * Envuelve un handler async para que las promesas rechazadas lleguen al
 * middleware de error. Sin esto, un `await` que falla dentro de un handler
 * queda como unhandled rejection y la request se cuelga.
 */
export function asyncHandler<Req extends Request = Request>(
  handler: (req: Req, res: Response, next: NextFunction) => Promise<unknown>,
): RequestHandler {
  return (req, res, next) => {
    Promise.resolve(handler(req as Req, res, next)).catch(next);
  };
}
