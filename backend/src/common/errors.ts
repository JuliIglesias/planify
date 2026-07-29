export class HttpError extends Error {
  constructor(
    public status: number,
    message: string,
  ) {
    super(message);
    this.name = 'HttpError';
  }
}

export class NotFoundError extends HttpError {
  constructor(message = 'Recurso no encontrado') {
    super(404, message);
  }
}

export class UnauthorizedError extends HttpError {
  constructor(message = 'No autenticado') {
    super(401, message);
  }
}

export class ForbiddenError extends HttpError {
  constructor(message = 'No autorizado para esta acción') {
    super(403, message);
  }
}

export class BadRequestError extends HttpError {
  constructor(message = 'Solicitud inválida') {
    super(400, message);
  }
}
