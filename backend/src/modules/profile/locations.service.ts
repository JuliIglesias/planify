import { BadRequestError, ForbiddenError, NotFoundError } from '../../common/errors';
import { LocationRepository, UbicacionFavorita } from '../../domain/repositories';

/** HU-B5 — ubicaciones usuales guardadas como favoritas. */
export class LocationsService {
  constructor(private readonly ubicaciones: LocationRepository) {}

  async listar(usuarioId: string): Promise<UbicacionFavorita[]> {
    return this.ubicaciones.listByUsuario(usuarioId);
  }

  async crear(usuarioId: string, etiqueta: string, texto: string): Promise<UbicacionFavorita> {
    const et = etiqueta?.trim();
    const tx = texto?.trim();
    if (!et) throw new BadRequestError('etiqueta es requerida');
    if (!tx) throw new BadRequestError('texto es requerido');
    return this.ubicaciones.create(usuarioId, et, tx);
  }

  async eliminar(usuarioId: string, id: string): Promise<void> {
    const ubicacion = await this.ubicaciones.findById(id);
    if (!ubicacion) throw new NotFoundError('Ubicación no encontrada');
    if (ubicacion.usuarioId !== usuarioId) {
      throw new ForbiddenError('No es tu ubicación');
    }
    await this.ubicaciones.delete(id);
  }
}
