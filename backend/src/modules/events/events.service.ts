import { BadRequestError, ForbiddenError, NotFoundError } from '../../common/errors';
import { AsistenciaEstado, Evento, Participante } from '../../domain/entities';
import {
  EventoRepository,
  GrupoRepository,
  ParticipanteRepository,
  UsuarioRepository,
} from '../../domain/repositories';
import { ActivityLogService } from '../activity-log/activity-log.service';
import { ActivityType } from '../activity-log/activity-log.types';

export interface CrearEventoInput {
  nombre: string;
  lugarTexto: string;
  /** Grupo existente (HU-05)… */
  grupoId?: string;
  /** …o miembros sueltos, que crean un grupo nuevo (HU-04). */
  nuevoGrupoNombre?: string;
  miembroUsuarioIds?: string[];
}

/**
 * SCRUM-8 — creación de evento en 2 pasos (HU-06, NFR#3) y cancelación (HU-11).
 * Todo evento pertenece a un grupo (Duda #1) y lo crea un usuario registrado,
 * nunca un anónimo (Duda #19).
 */
export class EventsService {
  constructor(
    private readonly eventos: EventoRepository,
    private readonly grupos: GrupoRepository,
    private readonly participantes: ParticipanteRepository,
    private readonly usuarios: UsuarioRepository,
    private readonly log: ActivityLogService,
  ) {}

  async crear(
    usuarioId: string,
    input: CrearEventoInput,
  ): Promise<{ evento: Evento; organizador: Participante }> {
    const nombre = input.nombre?.trim();
    const lugar = input.lugarTexto?.trim();

    if (!nombre) throw new BadRequestError('nombre es requerido');
    if (!lugar) throw new BadRequestError('lugarTexto es requerido');
    if (!input.grupoId && !input.nuevoGrupoNombre?.trim()) {
      throw new BadRequestError(
        'Se requiere grupoId (grupo existente) o nuevoGrupoNombre (HU-04/HU-05)',
      );
    }

    const usuario = await this.usuarios.findById(usuarioId);
    if (!usuario) throw new NotFoundError('Usuario no encontrado');

    const grupoId = input.grupoId
      ? await this.validarGrupoExistente(input.grupoId, usuarioId)
      : (await this.grupos.create(input.nuevoGrupoNombre!.trim(), [
          usuarioId,
          ...(input.miembroUsuarioIds ?? []),
        ])).id;

    // Todos los miembros registrados del grupo se vuelven participantes del
    // evento (H-01): así aparecen para asignarles gastos/tareas y pueden
    // confirmar asistencia. El organizador se excluye porque ya lo crea
    // `createWithOrganizer`.
    const miembros = await this.grupos.listMiembros(grupoId);
    const otrosMiembros = miembros.filter((m) => m.id !== usuarioId).map((m) => ({
      usuarioId: m.id,
      nombre: m.nombre,
    }));

    const resultado = await this.eventos.createWithOrganizer({
      grupoId,
      nombre,
      lugarTexto: lugar,
      organizadorUsuarioId: usuarioId,
      organizadorNombre: usuario.nombre,
      otrosMiembros,
    });

    await this.log.registrar({
      eventoId: resultado.evento.id,
      tipo: ActivityType.eventoCreado,
      actorParticipanteId: resultado.organizador.id,
      payload: { nombre, lugar },
    });

    return resultado;
  }

  /** HU-11 — cancelar. Permiso exclusivo del organizador (Duda #6). */
  async cancelar(usuarioId: string, eventoId: string): Promise<Evento> {
    const evento = await this.eventos.findById(eventoId);
    if (!evento) throw new NotFoundError('Evento no encontrado');
    if (evento.estado === 'cancelado') {
      throw new BadRequestError('El evento ya está cancelado');
    }

    const organizador = await this.exigirOrganizador(eventoId, usuarioId);

    const cancelado = await this.eventos.updateEstado(eventoId, 'cancelado');
    // Los anónimos pierden el acceso: su identidad solo vivía para este evento.
    await this.participantes.invalidarSesionesAnonimas(eventoId);

    await this.log.registrar({
      eventoId,
      tipo: ActivityType.eventoCancelado,
      actorParticipanteId: organizador.id,
    });

    return cancelado;
  }

  /** HU-10 — confirmar o rechazar asistencia. Cualquier participante puede. */
  async responderAsistencia(
    participanteId: string,
    estado: Extract<AsistenciaEstado, 'confirmado' | 'rechazado'>,
  ): Promise<Participante> {
    const participante = await this.participantes.findById(participanteId);
    if (!participante) throw new NotFoundError('Participante no encontrado');

    const evento = await this.eventos.findById(participante.eventoId);
    if (evento?.estado === 'cancelado') {
      throw new BadRequestError('El evento está cancelado');
    }

    const actualizado = await this.participantes.updateAsistencia(participanteId, estado);

    await this.log.registrar({
      eventoId: participante.eventoId,
      tipo: ActivityType.asistenciaConfirmada,
      actorParticipanteId: participanteId,
      payload: { estado },
    });

    return actualizado;
  }

  /** Compartido por cancelar, confirmar horario y cerrar gastos. */
  async exigirOrganizador(eventoId: string, usuarioId: string): Promise<Participante> {
    const organizador = await this.participantes.findByEventoAndUsuario(eventoId, usuarioId);
    if (!organizador?.esOrganizador) {
      throw new ForbiddenError('Solo el organizador puede realizar esta acción');
    }
    return organizador;
  }

  private async validarGrupoExistente(grupoId: string, usuarioId: string): Promise<string> {
    const esMiembro = await this.grupos.esMiembro(grupoId, usuarioId);
    if (!esMiembro) {
      throw new ForbiddenError('No sos miembro de ese grupo');
    }
    return grupoId;
  }
}
