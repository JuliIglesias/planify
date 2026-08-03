import { PersonaBusqueda, Usuario } from '../entities';

export interface CrearUsuarioData {
  nombre: string;
  email: string;
  passwordHash: string;
}

export interface ActualizarPerfilData {
  nombre?: string;
  avatarUrl?: string | null;
  idiomaPreferido?: string;
}

export interface UsuarioRepository {
  findById(id: string): Promise<Usuario | null>;
  findByEmail(email: string): Promise<Usuario | null>;
  findManyByIds(ids: string[]): Promise<Usuario[]>;

  /** HU-27 — registro de una cuenta real. */
  create(data: CrearUsuarioData): Promise<Usuario>;

  /** HU-30 — editar perfil (nombre, avatar, idioma). */
  updateProfile(id: string, data: ActualizarPerfilData): Promise<Usuario>;

  /** HU-29 — recuperación de contraseña. */
  updatePassword(id: string, passwordHash: string): Promise<void>;

  /** HU-31 — buscar personas para agregar como amigas (por nombre o email). */
  search(query: string, exceptoUsuarioId: string): Promise<PersonaBusqueda[]>;
}
