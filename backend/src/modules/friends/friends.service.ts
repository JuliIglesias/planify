import { BadRequestError, ForbiddenError, NotFoundError } from '../../common/errors';
import { PersonaBusqueda } from '../../domain/entities';
import {
  AmistadRepository,
  SolicitudAmistad,
  SolicitudEnviada,
  UsuarioRepository,
} from '../../domain/repositories';
import { ActivityLogService } from '../activity-log/activity-log.service';
import { ActivityType } from '../activity-log/activity-log.types';

/**
 * SCRUM-14 — HU-31: gestión de amigos. Una amistad se solicita y se acepta;
 * recién ahí las dos personas se ven como amigas. Reutiliza el modelo `Amistad`
 * (usuarioId1 = solicitante, usuarioId2 = receptor).
 */
export class FriendsService {
  constructor(
    private readonly amistades: AmistadRepository,
    private readonly usuarios: UsuarioRepository,
    // F2 — opcional a propósito, mismo criterio que en `ActivityLogService`:
    // los tests que no prueban notificaciones no tienen que construirlo.
    private readonly activityLog?: ActivityLogService,
  ) {}

  /** HU-31 — buscar personas para agregar (por nombre o email). */
  async buscar(usuarioId: string, query: string): Promise<PersonaBusqueda[]> {
    const limpio = query?.trim();
    if (!limpio || limpio.length < 2) return [];
    return this.usuarios.search(limpio, usuarioId);
  }

  /** HU-31 — enviar una solicitud de amistad. */
  async enviarSolicitud(solicitanteId: string, receptorId: string): Promise<void> {
    if (solicitanteId === receptorId) {
      throw new BadRequestError('No podés agregarte a vos mismo');
    }
    const receptor = await this.usuarios.findById(receptorId);
    if (!receptor) throw new NotFoundError('La persona no existe');

    const existente = await this.amistades.findEntre(solicitanteId, receptorId);
    if (existente) {
      throw new BadRequestError(
        existente.estado === 'aceptada' ? 'Ya son amigos' : 'Ya hay una solicitud pendiente',
      );
    }

    await this.amistades.crear(solicitanteId, receptorId);

    // F2 — el receptor se entera de que le llegó una solicitud. Best-effort:
    // si falla, no revierte la solicitud ya creada (mismo criterio que el
    // push de `ActivityLogService.registrar`).
    if (this.activityLog) {
      try {
        await this.activityLog.registrarPersonal({
          usuarioId: receptorId,
          tipo: ActivityType.solicitudAmistad,
          actorUsuarioId: solicitanteId,
        });
      } catch {
        // No debería tumbar el flujo de "enviar solicitud" ya confirmado.
      }
    }
  }

  /** HU-31 — aceptar una solicitud recibida. */
  async aceptar(usuarioId: string, amistadId: string): Promise<void> {
    const amistad = await this.amistades.findById(amistadId);
    if (!amistad) throw new NotFoundError('Solicitud no encontrada');
    // Solo el receptor (usuarioId2) puede aceptar.
    if (amistad.usuarioId2 !== usuarioId) {
      throw new ForbiddenError('No podés aceptar esta solicitud');
    }
    if (amistad.estado === 'aceptada') return;
    await this.amistades.aceptar(amistadId);
  }

  /** Amigos aceptados. Item 3 — con email, para desambiguar visualmente. */
  async listar(usuarioId: string): Promise<PersonaBusqueda[]> {
    return this.amistades.listAmigos(usuarioId);
  }

  /** Solicitudes pendientes recibidas. */
  async solicitudesPendientes(usuarioId: string): Promise<SolicitudAmistad[]> {
    return this.amistades.listSolicitudesRecibidas(usuarioId);
  }

  /** F1 — solicitudes pendientes que envié yo, todavía sin aceptar. */
  async solicitudesEnviadas(usuarioId: string): Promise<SolicitudEnviada[]> {
    return this.amistades.listSolicitudesEnviadas(usuarioId);
  }
}
