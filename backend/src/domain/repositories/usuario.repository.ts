import { Usuario } from '../entities';

export interface UsuarioRepository {
  findById(id: string): Promise<Usuario | null>;
  findByEmail(email: string): Promise<Usuario | null>;
  findManyByIds(ids: string[]): Promise<Usuario[]>;
}
