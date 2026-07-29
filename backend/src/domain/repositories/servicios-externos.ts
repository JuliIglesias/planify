/**
 * Servicios externos abstraídos. Cambiar bcrypt por argon2, o el emisor de
 * tokens por Cognito (SCRUM-14), es cambiar una implementación en
 * `src/infrastructure/` sin tocar ni un servicio.
 */

export interface PasswordHasher {
  hash(plano: string): Promise<string>;
  compare(plano: string, hash: string): Promise<boolean>;
}

export interface TokenOrganizador {
  usuarioId: string;
  email: string;
}

export interface TokenService {
  sign(payload: TokenOrganizador): string;
  verify(token: string): TokenOrganizador;
}

/** Existe para poder testear reglas que dependen del tiempo (ej. badge "NUEVO"). */
export interface Clock {
  now(): Date;
}

/** Generador de identificadores opacos (tokens de sesión, de invitación). */
export interface IdGenerator {
  generate(): string;
}
