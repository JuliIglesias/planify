import { PersonaBusqueda, Usuario } from '../entities';

export interface CrearUsuarioData {
  username: string;
  email: string;
  passwordHash: string;
}

export interface ActualizarPerfilData {
  username?: string;
  avatarUrl?: string | null;
  idiomaPreferido?: string;
}

export interface UsuarioRepository {
  findById(id: string): Promise<Usuario | null>;
  findByEmail(email: string): Promise<Usuario | null>;

  /** Username único — para login por username y para validar unicidad. */
  findByUsername(username: string): Promise<Usuario | null>;
  findManyByIds(ids: string[]): Promise<Usuario[]>;

  /** HU-27 — registro de una cuenta real. */
  create(data: CrearUsuarioData): Promise<Usuario>;

  /** HU-30 — editar perfil (username, avatar, idioma). */
  updateProfile(id: string, data: ActualizarPerfilData): Promise<Usuario>;

  /** HU-29 — recuperación de contraseña. */
  updatePassword(id: string, passwordHash: string): Promise<void>;

  /** HU-31 — buscar personas para agregar como amigas (por username o email). */
  search(query: string, exceptoUsuarioId: string): Promise<PersonaBusqueda[]>;
}
