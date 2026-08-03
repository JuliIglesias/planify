import { randomUUID } from 'crypto';
import bcrypt from 'bcryptjs';
import jwt from 'jsonwebtoken';
import {
  Clock,
  DeviceRegistry,
  IdGenerator,
  MensajePush,
  PasswordHasher,
  PushNotifier,
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

/**
 * SCRUM-15 — envío de push. Implementación por defecto: loguea la notificación.
 * En producción se reemplaza por una contra **SNS/Pinpoint** (cambiando solo el
 * wiring en container.ts). El SLA de NFR#8 (<60s) aplica mientras el ambiente
 * demo esté encendido (Duda #8).
 */
export class ConsolePushNotifier implements PushNotifier {
  async enviar(deviceTokens: string[], mensaje: MensajePush): Promise<void> {
    if (deviceTokens.length === 0) return;
    console.log(
      `[push] → ${deviceTokens.length} dispositivo(s): "${mensaje.titulo}" — ${mensaje.cuerpo}`,
    );
  }
}

/**
 * Registro de dispositivos en memoria. Suficiente para el ambiente demo (se
 * pierde al reiniciar). En producción se persiste en una tabla o en Pinpoint.
 */
export class InMemoryDeviceRegistry implements DeviceRegistry {
  private readonly porUsuario = new Map<string, Set<string>>();

  async registrar(usuarioId: string, deviceToken: string): Promise<void> {
    const set = this.porUsuario.get(usuarioId) ?? new Set<string>();
    set.add(deviceToken);
    this.porUsuario.set(usuarioId, set);
  }

  async tokensDe(usuarioIds: string[]): Promise<string[]> {
    const tokens: string[] = [];
    for (const id of usuarioIds) {
      for (const t of this.porUsuario.get(id) ?? []) tokens.push(t);
    }
    return tokens;
  }
}
