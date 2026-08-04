import { Grupo, PersonaRef } from '../entities';

export interface GrupoConMiembros extends Grupo {
  miembros: PersonaRef[];
}

export interface GrupoRepository {
  findById(id: string): Promise<Grupo | null>;
  listByUsuario(usuarioId: string): Promise<GrupoConMiembros[]>;

  /** Miembros registrados de un grupo puntual (id = usuarioId, con su nombre). */
  listMiembros(grupoId: string): Promise<PersonaRef[]>;

  create(nombre: string, usuarioIds: string[]): Promise<Grupo>;
  actualizar(id: string, data: { nombre?: string, avatarUrl?: string | null }): Promise<Grupo>;

  esMiembro(grupoId: string, usuarioId: string): Promise<boolean>;
  contarMiembros(grupoId: string): Promise<number>;
  agregarMiembro(grupoId: string, usuarioId: string): Promise<void>;
  quitarMiembro(grupoId: string, usuarioId: string): Promise<void>;
}
