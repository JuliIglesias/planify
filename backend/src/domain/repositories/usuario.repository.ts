import { Usuario } from '../entities';

export interface CrearUsuarioData {
  nombre: string;
  email: string;
  passwordHash: string;
}

/** Campos editables del perfil (FR12). Todos opcionales: se actualiza lo que venga. */
export interface ActualizarPerfilData {
  nombre?: string;
  avatarUrl?: string | null;
  idiomaPreferido?: string;
}

export interface UsuarioRepository {
  findById(id: string): Promise<Usuario | null>;
  findByEmail(email: string): Promise<Usuario | null>;
  findManyByIds(ids: string[]): Promise<Usuario[]>;

  /** FR11 — alta de cuenta registrada. */
  create(data: CrearUsuarioData): Promise<Usuario>;
  /** FR12 — edición de perfil. */
  updateProfile(id: string, data: ActualizarPerfilData): Promise<Usuario>;

  /** Búsqueda para agregar amigos (FR13): por nombre o email, excluyendo a uno. */
  search(termino: string, excluirUsuarioId: string): Promise<Usuario[]>;
}
