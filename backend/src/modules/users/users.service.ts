import { BadRequestError, NotFoundError } from '../../common/errors';
import { UsuarioRepository } from '../../domain/repositories';

/** Vista pública del perfil: nunca incluye el hash de contraseña. */
export interface PerfilPublico {
  id: string;
  nombre: string;
  email: string;
  avatarUrl: string | null;
  idiomaPreferido: string;
}

export interface ActualizarPerfilInput {
  nombre?: string;
  avatarUrl?: string | null;
  idiomaPreferido?: string;
}

/** Idiomas soportados (Duda #15): español e inglés. */
const IDIOMAS = new Set(['es', 'en']);

/**
 * SCRUM-14 (FR12) — gestión de identidad en la plataforma: ver y editar el
 * perfil del usuario registrado. La búsqueda de usuarios para agregar amigos
 * vive en `FriendsService` (FR13).
 */
export class UsersService {
  constructor(private readonly usuarios: UsuarioRepository) {}

  async perfil(usuarioId: string): Promise<PerfilPublico> {
    const usuario = await this.usuarios.findById(usuarioId);
    if (!usuario) throw new NotFoundError('Usuario no encontrado');
    return this.aPublico(usuario.id, usuario);
  }

  async actualizar(usuarioId: string, input: ActualizarPerfilInput): Promise<PerfilPublico> {
    const usuario = await this.usuarios.findById(usuarioId);
    if (!usuario) throw new NotFoundError('Usuario no encontrado');

    const nombre = input.nombre?.trim();
    if (input.nombre !== undefined && !nombre) {
      throw new BadRequestError('El nombre no puede quedar vacío');
    }
    if (input.idiomaPreferido !== undefined && !IDIOMAS.has(input.idiomaPreferido)) {
      throw new BadRequestError('Idioma no soportado (es | en)');
    }

    const actualizado = await this.usuarios.updateProfile(usuarioId, {
      ...(nombre !== undefined ? { nombre } : {}),
      ...(input.avatarUrl !== undefined ? { avatarUrl: input.avatarUrl } : {}),
      ...(input.idiomaPreferido !== undefined
        ? { idiomaPreferido: input.idiomaPreferido }
        : {}),
    });

    return this.aPublico(actualizado.id, actualizado);
  }

  private aPublico(
    id: string,
    u: { nombre: string; email: string; avatarUrl: string | null; idiomaPreferido: string },
  ): PerfilPublico {
    return {
      id,
      nombre: u.nombre,
      email: u.email,
      avatarUrl: u.avatarUrl,
      idiomaPreferido: u.idiomaPreferido,
    };
  }
}
