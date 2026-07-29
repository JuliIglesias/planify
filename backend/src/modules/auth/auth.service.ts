import { UnauthorizedError } from '../../common/errors';
import { PasswordHasher, TokenService, UsuarioRepository } from '../../domain/repositories';

export interface ResultadoLogin {
  token: string;
  usuario: { id: string; nombre: string; email: string };
}

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
