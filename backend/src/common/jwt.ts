import jwt from 'jsonwebtoken';

const JWT_SECRET = process.env.JWT_SECRET ?? 'dev-secret-change-me';
const JWT_EXPIRES_IN = process.env.JWT_EXPIRES_IN ?? '7d';

export interface OrganizerJwtPayload {
  usuarioId: string;
  email: string;
}

export function signOrganizerToken(payload: OrganizerJwtPayload): string {
  return jwt.sign(payload, JWT_SECRET, { expiresIn: JWT_EXPIRES_IN } as jwt.SignOptions);
}

export function verifyOrganizerToken(token: string): OrganizerJwtPayload {
  return jwt.verify(token, JWT_SECRET) as OrganizerJwtPayload;
}
