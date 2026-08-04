import { BadRequestError, ForbiddenError, NotFoundError } from '../../common/errors';
import { AsistenciaEstado, Evento, Participante } from '../../domain/entities';
import {
  Clock,
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
  /** Rango de fechas calendario del evento (Item 1, ver docs/adrs/0001-rango-fechas-evento.md). */
  rangoInicio: string | Date;
  rangoFin: string | Date;
}

/** Item 1 — cuántas veces se extiende el rango solo antes de pedirle al organizador que decida. */
export const MAX_EXTENSIONES_RANGO = 1;
/** Item 1 — cuánto se extiende el rango cada vez que vence sin horario confirmado. */
export const DIAS_EXTENSION_RANGO = 14;

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
    private readonly clock: Clock,
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

    const rangoInicio = new Date(input.rangoInicio);
    const rangoFin = new Date(input.rangoFin);
    if (Number.isNaN(rangoInicio.getTime()) || Number.isNaN(rangoFin.getTime())) {
      throw new BadRequestError('rangoInicio y rangoFin son requeridos y deben ser fechas válidas');
    }
    if (rangoInicio > rangoFin) {
      throw new BadRequestError('rangoInicio no puede ser posterior a rangoFin');
    }
    if (rangoFin < this.clock.now()) {
      throw new BadRequestError('rangoFin no puede estar en el pasado');
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
      username: m.username,
    }));

    const resultado = await this.eventos.createWithOrganizer({
      grupoId,
      nombre,
      lugarTexto: lugar,
      organizadorUsuarioId: usuarioId,
      rangoInicio,
      rangoFin,
      organizadorUsername: usuario.username,
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

  /**
   * Item 1 — si el rango de fechas venció sin que se confirme un horario, lo
   * extiende `DIAS_EXTENSION_RANGO` días y notifica a los participantes. Es
   * lazy (se llama al entrar al evento, mismo patrón que H-09), no hay cron.
   * Después de `MAX_EXTENSIONES_RANGO` extensiones deja de extender solo:
   * a partir de ahí `necesitaDecisionRango` avisa que el organizador tiene
   * que decidir a mano (cancelar o forzar una fecha).
   */
  async chequearExtensionRango(eventoId: string): Promise<Evento> {
    const evento = await this.eventos.findById(eventoId);
    if (!evento) throw new NotFoundError('Evento no encontrado');

    if (evento.estado !== 'planificacion') return evento;
    if (this.clock.now() <= evento.rangoFin) return evento;
    if (evento.extensionesRango >= MAX_EXTENSIONES_RANGO) return evento;

    const nuevoRangoFin = new Date(
      evento.rangoFin.getTime() + DIAS_EXTENSION_RANGO * 24 * 60 * 60 * 1000,
    );
    const extendido = await this.eventos.extenderRango(eventoId, nuevoRangoFin);

    // El sistema no tiene un actor humano acá: se usa al organizador
    // (creadoPor ya es su participanteId), igual que el resto del log del evento.
    await this.log.registrar({
      eventoId,
      tipo: ActivityType.rangoExtendido,
      actorParticipanteId: evento.creadoPor,
      payload: {
        rangoFinAnterior: evento.rangoFin.toISOString(),
        rangoFinNuevo: nuevoRangoFin.toISOString(),
      },
    });

    return extendido;
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
