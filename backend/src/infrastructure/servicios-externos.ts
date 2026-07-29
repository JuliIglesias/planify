import { randomUUID } from 'crypto';
import bcrypt from 'bcryptjs';
import jwt from 'jsonwebtoken';
import {
  Clock,
  IdGenerator,
  PasswordHasher,
  TokenOrganizador,
  TokenService,
} from '../domain/repositories';

export class BcryptPasswordHasher implements PasswordHasher {
  constructor(private readonly rounds = 10) {}

  hash(plano: string): Promise<string> {
    return bcrypt.hash(plano, this.rounds);
  }

  compare(plano: string, hash: string): Promise<boolean> {
    return bcrypt.compare(plano, hash);
  }
}

/**
 * Emisor de tokens propio, para el organizador semilla del MVP (HU-41).
 * Cuando llegue SCRUM-14, se reemplaza por una implementación contra Cognito
 * sin tocar ningún servicio: alcanza con cambiar el wiring en container.ts.
 */
export class JwtTokenService implements TokenService {
  constructor(
    private readonly secret: string,
    private readonly expiresIn: string,
  ) {}

  sign(payload: TokenOrganizador): string {
    return jwt.sign(payload, this.secret, { expiresIn: this.expiresIn } as jwt.SignOptions);
  }

  verify(token: string): TokenOrganizador {
    return jwt.verify(token, this.secret) as TokenOrganizador;
  }
}

export class SystemClock implements Clock {
  now(): Date {
    return new Date();
  }
}

export class UuidGenerator implements IdGenerator {
  generate(): string {
    return randomUUID();
  }
}
