import { BadRequestError, NotFoundError } from '../../common/errors';
import { UsuarioRepository } from '../../domain/repositories';

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

/** SCRUM-14 — HU-30: ver y editar el perfil del usuario registrado. */
export class UsersService {
  constructor(private readonly usuarios: UsuarioRepository) {}

  async miPerfil(usuarioId: string): Promise<PerfilPublico> {
    const usuario = await this.usuarios.findById(usuarioId);
    if (!usuario) throw new NotFoundError('Usuario no encontrado');
    return this.aPublico(usuario);
  }

  async actualizar(usuarioId: string, input: ActualizarPerfilInput): Promise<PerfilPublico> {
    const nombre = input.nombre?.trim();
    if (input.nombre !== undefined && !nombre) {
      throw new BadRequestError('El nombre no puede quedar vacío');
    }
    if (input.idiomaPreferido !== undefined && !['es', 'en'].includes(input.idiomaPreferido)) {
      throw new BadRequestError('Idioma no soportado (es | en)');
    }

    const actualizado = await this.usuarios.updateProfile(usuarioId, {
      ...(nombre !== undefined ? { nombre } : {}),
      ...(input.avatarUrl !== undefined ? { avatarUrl: input.avatarUrl } : {}),
      ...(input.idiomaPreferido !== undefined ? { idiomaPreferido: input.idiomaPreferido } : {}),
    });
    return this.aPublico(actualizado);
  }

  private aPublico(u: {
    id: string;
    nombre: string;
    email: string;
    avatarUrl: string | null;
    idiomaPreferido: string;
  }): PerfilPublico {
    return {
      id: u.id,
      nombre: u.nombre,
      email: u.email,
      avatarUrl: u.avatarUrl,
      idiomaPreferido: u.idiomaPreferido,
    };
  }
}
