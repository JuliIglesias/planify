import { Grupo, PersonaRef } from '../entities';

export interface GrupoConMiembros extends Grupo {
  miembros: PersonaRef[];
}

export interface GrupoRepository {
  findById(id: string): Promise<Grupo | null>;
  listByUsuario(usuarioId: string): Promise<GrupoConMiembros[]>;

  create(nombre: string, usuarioIds: string[]): Promise<Grupo>;
  rename(id: string, nombre: string): Promise<Grupo>;

  esMiembro(grupoId: string, usuarioId: string): Promise<boolean>;
  contarMiembros(grupoId: string): Promise<number>;
  agregarMiembro(grupoId: string, usuarioId: string): Promise<void>;
  quitarMiembro(grupoId: string, usuarioId: string): Promise<void>;
}
