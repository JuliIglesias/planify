import { BadRequestError, UnauthorizedError } from '../../common/errors';
import { PasswordHasher, TokenService, UsuarioRepository } from '../../domain/repositories';

export interface ResultadoLogin {
  token: string;
  usuario: { id: string; nombre: string; email: string };
}

const EMAIL_RE = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

/**
 * SCRUM-7 (login del organizador semilla, HU-41) + SCRUM-14 (auth completa:
 * registro HU-27, login HU-28, recuperación HU-29).
 *
 * No sabe nada de bcrypt ni de JWT: depende de las abstracciones `PasswordHasher`
 * y `TokenService`. Migrar a Cognito en producción es cambiar esas
 * implementaciones en `container.ts`, sin tocar esta clase.
 */
export class AuthService {
  constructor(
    private readonly usuarios: UsuarioRepository,
    private readonly hasher: PasswordHasher,
    private readonly tokens: TokenService,
  ) {}

  async login(email: string, password: string): Promise<ResultadoLogin> {
    const usuario = await this.usuarios.findByEmail(email.trim().toLowerCase());
    // Mismo mensaje para usuario inexistente y contraseña incorrecta: decir
    // cuál de las dos falló permitiría descubrir qué emails están registrados.
    if (!usuario) throw new UnauthorizedError('Credenciales inválidas');

    const valido = await this.hasher.compare(password, usuario.passwordHash);
    if (!valido) throw new UnauthorizedError('Credenciales inválidas');

    return this.resultado(usuario.id, usuario.nombre, usuario.email);
  }

  /** HU-27 — registro de una cuenta real. */
  async register(nombre: string, email: string, password: string): Promise<ResultadoLogin> {
    const limpioNombre = nombre?.trim();
    const limpioEmail = email?.trim().toLowerCase();

    if (!limpioNombre) throw new BadRequestError('nombre es requerido');
    if (!limpioEmail || !EMAIL_RE.test(limpioEmail)) {
      throw new BadRequestError('email inválido');
    }
    if (!password || password.length < 6) {
      throw new BadRequestError('la contraseña debe tener al menos 6 caracteres');
    }

    const yaExiste = await this.usuarios.findByEmail(limpioEmail);
    if (yaExiste) throw new BadRequestError('Ya existe una cuenta con ese email');

    const passwordHash = await this.hasher.hash(password);
    const usuario = await this.usuarios.create({
      nombre: limpioNombre,
      email: limpioEmail,
      passwordHash,
    });

    return this.resultado(usuario.id, usuario.nombre, usuario.email);
  }

  /**
   * HU-29 — solicitar recuperación. Devuelve un token de reset firmado. Siempre
   * responde igual (haya o no cuenta) para no filtrar qué emails existen.
   *
   * En producción, ese token se **envía por email** (no se devuelve en la
   * respuesta): la entrega depende de un proveedor de correo (SES/SendGrid), que
   * es una integración externa — ver docs/06-estado-final.md.
   */
  async solicitarReset(email: string): Promise<{ token: string | null }> {
    const usuario = await this.usuarios.findByEmail(email?.trim().toLowerCase() ?? '');
    if (!usuario) return { token: null };
    return { token: this.tokens.sign({ usuarioId: usuario.id, email: usuario.email }) };
  }

  /** HU-29 — confirmar el reset con el token y la nueva contraseña. */
  async confirmarReset(token: string, nuevaPassword: string): Promise<void> {
    if (!nuevaPassword || nuevaPassword.length < 6) {
      throw new BadRequestError('la contraseña debe tener al menos 6 caracteres');
    }
    let usuarioId: string;
    try {
      usuarioId = this.tokens.verify(token).usuarioId;
    } catch {
      throw new BadRequestError('Token de recuperación inválido o expirado');
    }
    const passwordHash = await this.hasher.hash(nuevaPassword);
    await this.usuarios.updatePassword(usuarioId, passwordHash);
  }

  private resultado(id: string, nombre: string, email: string): ResultadoLogin {
    return {
      token: this.tokens.sign({ usuarioId: id, email }),
      usuario: { id, nombre, email },
    };
  }
}
