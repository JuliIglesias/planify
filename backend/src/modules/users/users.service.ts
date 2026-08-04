import { BadRequestError, NotFoundError } from '../../common/errors';
import { UsuarioRepository } from '../../domain/repositories';

export interface PerfilPublico {
  id: string;
  username: string;
  email: string;
  avatarUrl: string | null;
  idiomaPreferido: string;
}

export interface ActualizarPerfilInput {
  username?: string;
  avatarUrl?: string | null;
  idiomaPreferido?: string;
}

/** SCRUM-14 — HU-30: ver y editar el perfil del usuario registrado. */
export class UsersService {
  constructor(private readonly usuarios: UsuarioRepository) {}

  async miPerfil(usuarioId: string): Promise<PerfilPublico> {
    const usuario = await this.usuarios.findById(usuarioId);
    if (!usuario) throw new NotFoundError('Usuario no encontrado');
    return this.aPublico(usuario);
  }

  async actualizar(usuarioId: string, input: ActualizarPerfilInput): Promise<PerfilPublico> {
    const username = input.username?.trim();
    if (input.username !== undefined && !username) {
      throw new BadRequestError('El username no puede quedar vacío');
    }
    if (input.idiomaPreferido !== undefined && !['es', 'en'].includes(input.idiomaPreferido)) {
      throw new BadRequestError('Idioma no soportado (es | en)');
    }

    if (username !== undefined) {
      const existente = await this.usuarios.findByUsername(username);
      if (existente && existente.id !== usuarioId) {
        throw new BadRequestError('Ese username ya está en uso');
      }
    }

    const actualizado = await this.usuarios.updateProfile(usuarioId, {
      ...(username !== undefined ? { username } : {}),
      ...(input.avatarUrl !== undefined ? { avatarUrl: input.avatarUrl } : {}),
      ...(input.idiomaPreferido !== undefined ? { idiomaPreferido: input.idiomaPreferido } : {}),
    });
    return this.aPublico(actualizado);
  }

  private aPublico(u: {
    id: string;
    username: string;
    email: string;
    avatarUrl: string | null;
    idiomaPreferido: string;
  }): PerfilPublico {
    return {
      id: u.id,
      username: u.username,
      email: u.email,
      avatarUrl: u.avatarUrl,
      idiomaPreferido: u.idiomaPreferido,
    };
  }
}
