import { BadRequestError, UnauthorizedError } from '../../common/errors';
import {
  ParticipanteRepository,
  PasswordHasher,
  TokenService,
  UsuarioRepository,
} from '../../domain/repositories';

export interface ResultadoLogin {
  token: string;
  usuario: { id: string; username: string; email: string };
}

const EMAIL_RE = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
const USERNAME_RE = /^[a-z0-9_]{3,30}$/;

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
    private readonly participantes: ParticipanteRepository,
    private readonly hasher: PasswordHasher,
    private readonly tokens: TokenService,
  ) {}

  /** HU-28 — el identificador puede ser el email o el username. */
  async login(identificador: string, password: string): Promise<ResultadoLogin> {
    const limpio = identificador?.trim().toLowerCase();
    const usuario = limpio && EMAIL_RE.test(limpio)
      ? await this.usuarios.findByEmail(limpio)
      : await this.usuarios.findByUsername(limpio ?? '');
    // Mismo mensaje para usuario inexistente y contraseña incorrecta: decir
    // cuál de las dos falló permitiría descubrir qué cuentas están registradas.
    if (!usuario) throw new UnauthorizedError('Credenciales inválidas');

    const valido = await this.hasher.compare(password, usuario.passwordHash);
    if (!valido) throw new UnauthorizedError('Credenciales inválidas');

    return this.resultado(usuario.id, usuario.username, usuario.email);
  }

  /**
   * HU-27 — registro de una cuenta real. El username es la identidad pública
   * de la persona (reemplaza al viejo "nombre") y debe ser único: ni otra
   * cuenta registrada ni un participante anónimo (de cualquier evento) pueden
   * tenerlo ya. Acá se rechaza en vez de auto-sufijar (a diferencia de
   * `ParticipantsService.unirseComoAnonimo`) porque es una cuenta real: mutar
   * en silencio el username que la persona eligió sería sorprendente.
   */
  async register(username: string, email: string, password: string): Promise<ResultadoLogin> {
    const limpioUsername = username?.trim().toLowerCase();
    const limpioEmail = email?.trim().toLowerCase();

    if (!limpioUsername || !USERNAME_RE.test(limpioUsername)) {
      throw new BadRequestError(
        'username inválido (3 a 30 caracteres: minúsculas, números o guion bajo)',
      );
    }
    if (!limpioEmail || !EMAIL_RE.test(limpioEmail)) {
      throw new BadRequestError('email inválido');
    }
    if (!password || password.length < 6) {
      throw new BadRequestError('la contraseña debe tener al menos 6 caracteres');
    }

    const yaExisteEmail = await this.usuarios.findByEmail(limpioEmail);
    if (yaExisteEmail) throw new BadRequestError('Ya existe una cuenta con ese email');

    const yaExisteUsername = await this.usuarios.findByUsername(limpioUsername);
    if (yaExisteUsername) throw new BadRequestError('Ese username ya está en uso');

    const usadoPorAnonimo = await this.participantes.existsUsernameAnonimo(limpioUsername);
    if (usadoPorAnonimo) throw new BadRequestError('Ese username ya está en uso');

    const passwordHash = await this.hasher.hash(password);
    const usuario = await this.usuarios.create({
      username: limpioUsername,
      email: limpioEmail,
      passwordHash,
    });

    return this.resultado(usuario.id, usuario.username, usuario.email);
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

  private resultado(id: string, username: string, email: string): ResultadoLogin {
    return {
      token: this.tokens.sign({ usuarioId: id, email }),
      usuario: { id, username, email },
    };
  }
}
