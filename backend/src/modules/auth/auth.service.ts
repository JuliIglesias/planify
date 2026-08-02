import { BadRequestError, ConflictError, UnauthorizedError } from '../../common/errors';
import { PasswordHasher, TokenService, UsuarioRepository } from '../../domain/repositories';

export interface ResultadoLogin {
  token: string;
  usuario: { id: string; nombre: string; email: string };
}

/** Longitud mínima de contraseña para el registro (FR11). */
const MIN_PASSWORD = 6;
const EMAIL_RE = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

/**
 * HU-41 — login del organizador semilla (T-07). Sin Cognito todavía (Duda #19).
 *
 * No sabe nada de bcrypt ni de JWT: depende de las abstracciones `PasswordHasher`
 * y `TokenService`, así que migrar a Cognito en SCRUM-14 no toca esta clase.
 */
export class AuthService {
  constructor(
    private readonly usuarios: UsuarioRepository,
    private readonly hasher: PasswordHasher,
    private readonly tokens: TokenService,
  ) {}

  /**
   * FR11 (HU-27) — alta de cuenta registrada. Sin Cognito todavía: se guarda el
   * hash con el mismo `PasswordHasher` que usa el login, así que migrar a
   * Cognito en SCRUM-14 no cambia este flujo desde el punto de vista del cliente.
   */
  async register(nombre: string, email: string, password: string): Promise<ResultadoLogin> {
    const nombreLimpio = nombre?.trim();
    const emailLimpio = email?.trim().toLowerCase();

    if (!nombreLimpio) throw new BadRequestError('nombre es requerido');
    if (!emailLimpio || !EMAIL_RE.test(emailLimpio)) {
      throw new BadRequestError('email inválido');
    }
    if (!password || password.length < MIN_PASSWORD) {
      throw new BadRequestError(`La contraseña debe tener al menos ${MIN_PASSWORD} caracteres`);
    }

    const existente = await this.usuarios.findByEmail(emailLimpio);
    if (existente) throw new ConflictError('Ya existe una cuenta con ese email');

    const passwordHash = await this.hasher.hash(password);
    const usuario = await this.usuarios.create({
      nombre: nombreLimpio,
      email: emailLimpio,
      passwordHash,
    });

    return {
      token: this.tokens.sign({ usuarioId: usuario.id, email: usuario.email }),
      usuario: { id: usuario.id, nombre: usuario.nombre, email: usuario.email },
    };
  }

  async login(email: string, password: string): Promise<ResultadoLogin> {
    const usuario = await this.usuarios.findByEmail(email);
    // Mismo mensaje para usuario inexistente y contraseña incorrecta: decir
    // cuál de las dos falló permitiría descubrir qué emails están registrados.
    if (!usuario) throw new UnauthorizedError('Credenciales inválidas');

    const valido = await this.hasher.compare(password, usuario.passwordHash);
    if (!valido) throw new UnauthorizedError('Credenciales inválidas');

    return {
      token: this.tokens.sign({ usuarioId: usuario.id, email: usuario.email }),
      usuario: { id: usuario.id, nombre: usuario.nombre, email: usuario.email },
    };
  }
}
