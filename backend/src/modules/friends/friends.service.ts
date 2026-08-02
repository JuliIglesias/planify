import {
  BadRequestError,
  ConflictError,
  ForbiddenError,
  NotFoundError,
} from '../../common/errors';
import { PersonaRef } from '../../domain/entities';
import { AmistadRepository, UsuarioRepository } from '../../domain/repositories';

/** Estado de la relación con otra persona, para pintar el botón correcto. */
export type RelacionEstado =
  | 'ninguno'
  | 'amigo'
  | 'pendiente_enviada'
  | 'pendiente_recibida';

export interface SolicitudPendiente {
  amistadId: string;
  solicitante: PersonaRef;
}

/** Un amigo, con el id de la relación para poder eliminarla. */
export interface AmigoDto {
  id: string;
  nombre: string;
  amistadId: string;
}

export interface ResultadoBusqueda {
  id: string;
  nombre: string;
  email: string;
  relacion: RelacionEstado;
}

/**
 * SCRUM-14 (FR13) — gestión de amigos entre usuarios registrados. Los anónimos
 * no tienen amigos: su identidad vive solo mientras dura el evento (Duda #5).
 */
export class FriendsService {
  constructor(
    private readonly amistades: AmistadRepository,
    private readonly usuarios: UsuarioRepository,
  ) {}

  /** HU-31 — enviar una solicitud de amistad. */
  async enviarSolicitud(deUsuarioId: string, aUsuarioId: string): Promise<void> {
    if (!aUsuarioId) throw new BadRequestError('usuarioId es requerido');
    if (aUsuarioId === deUsuarioId) {
      throw new BadRequestError('No podés agregarte a vos mismo');
    }

    const destino = await this.usuarios.findById(aUsuarioId);
    if (!destino) throw new NotFoundError('El usuario no existe');

    const existente = await this.amistades.findEntre(deUsuarioId, aUsuarioId);
    if (existente) {
      throw new ConflictError(
        existente.estado === 'aceptada'
          ? 'Ya son amigos'
          : 'Ya hay una solicitud pendiente entre ustedes',
      );
    }

    await this.amistades.create(deUsuarioId, aUsuarioId);
  }

  /** HU-31 — aceptar una solicitud recibida. Solo el destinatario puede. */
  async aceptar(usuarioId: string, amistadId: string): Promise<void> {
    const amistad = await this.amistades.findById(amistadId);
    if (!amistad) throw new NotFoundError('Solicitud no encontrada');
    if (amistad.estado === 'aceptada') return; // idempotente

    if (amistad.usuarioId2 !== usuarioId) {
      throw new ForbiddenError('Solo quien recibió la solicitud puede aceptarla');
    }

    await this.amistades.aceptar(amistadId);
  }

  /** Rechazar una solicitud recibida o eliminar una amistad existente. */
  async eliminar(usuarioId: string, amistadId: string): Promise<void> {
    const amistad = await this.amistades.findById(amistadId);
    if (!amistad) throw new NotFoundError('Amistad no encontrada');

    if (amistad.usuarioId1 !== usuarioId && amistad.usuarioId2 !== usuarioId) {
      throw new ForbiddenError('No formás parte de esta amistad');
    }

    await this.amistades.eliminar(amistadId);
  }

  /** HU-31 — mis amigos, con el id de la relación para poder eliminarla. */
  async listarAmigos(usuarioId: string): Promise<AmigoDto[]> {
    const amistades = await this.amistades.listAceptadasDe(usuarioId);
    const otros = amistades.map((a) => ({
      amistadId: a.id,
      otroId: a.usuarioId1 === usuarioId ? a.usuarioId2 : a.usuarioId1,
    }));

    const usuarios = await this.usuarios.findManyByIds(otros.map((o) => o.otroId));
    const porId = new Map(usuarios.map((u) => [u.id, u.nombre]));

    return otros.map((o) => ({
      id: o.otroId,
      nombre: porId.get(o.otroId) ?? o.otroId,
      amistadId: o.amistadId,
    }));
  }

  /** Solicitudes de amistad que me llegaron y todavía no acepté. */
  async listarPendientes(usuarioId: string): Promise<SolicitudPendiente[]> {
    const pendientes = await this.amistades.listPendientesRecibidas(usuarioId);
    const solicitantes = await this.usuarios.findManyByIds(
      pendientes.map((a) => a.usuarioId1),
    );
    const porId = new Map(solicitantes.map((u) => [u.id, u.nombre]));

    return pendientes.map((a) => ({
      amistadId: a.id,
      solicitante: { id: a.usuarioId1, nombre: porId.get(a.usuarioId1) ?? a.usuarioId1 },
    }));
  }

  /** Buscar usuarios para agregar, con el estado de la relación ya resuelto. */
  async buscar(usuarioId: string, termino: string): Promise<ResultadoBusqueda[]> {
    const limpio = termino?.trim();
    if (!limpio) return [];

    const encontrados = await this.usuarios.search(limpio, usuarioId);

    return Promise.all(
      encontrados.map(async (u) => ({
        id: u.id,
        nombre: u.nombre,
        email: u.email,
        relacion: await this.relacionCon(usuarioId, u.id),
      })),
    );
  }

  private async relacionCon(usuarioId: string, otroId: string): Promise<RelacionEstado> {
    const amistad = await this.amistades.findEntre(usuarioId, otroId);
    if (!amistad) return 'ninguno';
    if (amistad.estado === 'aceptada') return 'amigo';
    return amistad.usuarioId1 === usuarioId ? 'pendiente_enviada' : 'pendiente_recibida';
  }
}
