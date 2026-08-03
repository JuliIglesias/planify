/** HU-B5 — ubicación usual guardada como favorita. */
export interface UbicacionFavorita {
  id: string;
  usuarioId: string;
  etiqueta: string;
  texto: string;
}

export interface LocationRepository {
  listByUsuario(usuarioId: string): Promise<UbicacionFavorita[]>;
  create(usuarioId: string, etiqueta: string, texto: string): Promise<UbicacionFavorita>;
  findById(id: string): Promise<UbicacionFavorita | null>;
  delete(id: string): Promise<void>;
}
