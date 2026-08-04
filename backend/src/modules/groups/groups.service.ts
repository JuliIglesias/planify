import { BadRequestError, ForbiddenError, NotFoundError } from '../../common/errors';
import { Evento, Grupo } from '../../domain/entities';
import {
  Clock,
  EventoRepository,
  GastoRepository,
  GrupoConMiembros,
  GrupoRepository,
  ImageStorageRepository,
  ParticipanteRepository,
  ProfileAvailabilityRepository,
  SlotHeatmap,
  TareaRepository,
  UsuarioRepository,
} from '../../domain/repositories';
import { ActivityLogService } from '../activity-log/activity-log.service';
import { InvitationsService } from '../invitations/invitations.service';

/** Cuánto tiempo un evento se muestra como "NUEVO" en la pantalla Groups. */
const VENTANA_EVENTO_NUEVO_HS = 48;

/** Un archivo ya leído en memoria (multer), listo para subir. */
export interface ArchivoImagen {
  buffer: Buffer;
  mimeType: string;
}

/**
 * Tanda 6, Item 5 — heatmap de disponibilidad scopeado a los miembros de UN
 * grupo puntual. Reemplaza a la vieja "coincidencias con TODOS los amigos"
 * (HU-B4, eliminada de Perfil): la disponibilidad agregada de varias personas
 * solo tiene sentido en el contexto de un grupo específico.
 */
export interface CoincidenciasDeGrupo {
  /** Cantidad de miembros del grupo considerados. */
  totalPersonas: number;
  /** Por bloque, cuántos de esos miembros tienen ese horario libre. */
  slots: SlotHeatmap[];
}

export interface EventoDeGrupo {
  id: string;
  nombre: string;
  lugarTexto: string;
  estado: string;
  fechaHoraInicio: Date | null;
  confirmados: number;
  tareasPendientes: number;
  gastos: number;
}

export interface ResumenGrupo {
  id: string;
  nombre: string;
  avatarUrl: string | null;
  miembros: { id: string; username: string }[];
  noLeidos: number;
  tieneEventoNuevo: boolean;
  /**
   * Item 1 — TODOS los eventos activos del grupo (antes solo se exponía el
   * más próximo bajo `proximoEvento`). El carrusel de Groups necesita la
   * lista completa para el drill-down por grupo.
   */
  eventos: EventoDeGrupo[];
}

/**
 * SCRUM-8 (grupos implícitos) + SCRUM-14 (gestión de miembros, Duda #12.2).
 * Un grupo se crea solo al armar un evento con gente suelta (HU-04); después
 * se puede renombrar, sumar amigos registrados o abandonarlo.
 */
export class GroupsService {
  constructor(
    private readonly grupos: GrupoRepository,
    private readonly eventos: EventoRepository,
    private readonly usuarios: UsuarioRepository,
    private readonly tareas: TareaRepository,
    private readonly gastos: GastoRepository,
    private readonly log: ActivityLogService,
    private readonly clock: Clock,
    private readonly participantes: ParticipanteRepository,
    private readonly invitations: InvitationsService,
    private readonly disponibilidadPerfil: ProfileAvailabilityRepository,
    private readonly imagenes: ImageStorageRepository,
  ) {}

  async listarDe(usuarioId: string): Promise<GrupoConMiembros[]> {
    return this.grupos.listByUsuario(usuarioId);
  }

  /** Datos ya armados para la pantalla Groups, incluidos los badges. */
  async resumenPara(usuarioId: string): Promise<ResumenGrupo[]> {
    const [grupos, noLeidosPorEvento, proximos] = await Promise.all([
      this.grupos.listByUsuario(usuarioId),
      this.log.contarNoLeidasPorEvento(usuarioId),
      this.eventos.listUpcomingForUsuario(usuarioId, this.clock.now()),
    ]);

    const eventosPorGrupo = await Promise.all(
      grupos.map((g) => this.eventos.listByGrupo(g.id)),
    );
    const activosPorGrupo = eventosPorGrupo.map((eventos) => this.activosDe(eventos));

    // Los contadores se piden una sola vez para todos los eventos activos de
    // todos los grupos, en vez de una consulta por evento (evita el N+1).
    const idsActivos = activosPorGrupo.flatMap((eventos) => eventos.map((e) => e.id));

    const [tareasPendientes, gastosPorEvento] = await Promise.all([
      this.tareas.contarPendientesPorEvento(idsActivos),
      this.gastos.contarPorEvento(idsActivos),
    ]);

    const confirmadosPorEvento = new Map(proximos.map((e) => [e.id, e.confirmados]));
    const corte = new Date(
      this.clock.now().getTime() - VENTANA_EVENTO_NUEVO_HS * 60 * 60 * 1000,
    );

    return grupos.map((grupo, i) => {
      const eventos = eventosPorGrupo[i];
      const activos = activosPorGrupo[i];

      return {
        id: grupo.id,
        nombre: grupo.nombre,
        avatarUrl: grupo.avatarUrl,
        miembros: grupo.miembros,
        // El contador del grupo es la suma de todos sus eventos (Duda #2).
        noLeidos: eventos.reduce((acc, e) => acc + (noLeidosPorEvento[e.id] ?? 0), 0),
        tieneEventoNuevo: eventos.some((e) => e.createdAt > corte),
        eventos: activos.map((evento) => ({
          id: evento.id,
          nombre: evento.nombre,
          lugarTexto: evento.lugarTexto,
          estado: evento.estado,
          fechaHoraInicio: evento.fechaHoraInicio,
          confirmados: confirmadosPorEvento.get(evento.id) ?? 0,
          tareasPendientes: tareasPendientes[evento.id] ?? 0,
          gastos: gastosPorEvento[evento.id] ?? 0,
        })),
      };
    });
  }

  /** Eventos del grupo todavía activos (no finalizados ni cancelados). */
  private activosDe(eventos: Evento[]): Evento[] {
    return eventos.filter((e) => e.estado === 'planificacion' || e.estado === 'confirmado');
  }

  /** HU-34 — actualizar grupo (nombre e imagen). Cualquier miembro puede. */
  async actualizar(
    grupoId: string,
    usuarioId: string,
    datos: { nombre?: string; avatarUrl?: string | null },
  ): Promise<Grupo> {
    await this.exigirMiembro(grupoId, usuarioId);

    const updateData: { nombre?: string; avatarUrl?: string | null } = {};
    if (datos.nombre !== undefined) {
      const limpio = datos.nombre?.trim();
      if (!limpio) throw new BadRequestError('nombre no puede estar vacío');
      updateData.nombre = limpio;
    }
    if (datos.avatarUrl !== undefined) {
      updateData.avatarUrl = datos.avatarUrl;
    }

    if (Object.keys(updateData).length === 0) {
      const g = await this.grupos.findById(grupoId);
      if (!g) throw new NotFoundError('Grupo no encontrado');
      return g;
    }

    return this.grupos.actualizar(grupoId, updateData);
  }

  /**
   * Tanda 6, Item 5 — subir una foto de grupo desde el explorador nativo del
   * dispositivo (reemplaza el viejo diálogo de pegar una URL). El archivo ya
   * viene leído en memoria (multer); acá solo se valida la membresía, se sube
   * a S3/LocalStack y se persiste la URL resultante.
   */
  async actualizarImagen(
    grupoId: string,
    usuarioId: string,
    archivo: ArchivoImagen,
  ): Promise<Grupo> {
    await this.exigirMiembro(grupoId, usuarioId);

    const avatarUrl = await this.imagenes.subir(`grupos/${grupoId}`, archivo.buffer, archivo.mimeType);
    return this.grupos.actualizar(grupoId, { avatarUrl });
  }

  /**
   * Tanda 6, Item 5 — heatmap de disponibilidad de los miembros de ESTE
   * grupo (reemplaza la vieja "disponibilidad entre todos los amigos" de
   * Perfil, que mezclaba a todos tus amigos sin importar el grupo).
   */
  async disponibilidadDeGrupo(grupoId: string, usuarioId: string): Promise<CoincidenciasDeGrupo> {
    await this.exigirMiembro(grupoId, usuarioId);

    const miembros = await this.grupos.listMiembros(grupoId);
    const ids = miembros.map((m) => m.id);
    const slots = await this.disponibilidadPerfil.slotsDeUsuarios(ids);

    const conteo = new Map<string, number>();
    for (const s of slots) {
      const clave = `${s.diaSemana}:${s.bloqueHora}`;
      conteo.set(clave, (conteo.get(clave) ?? 0) + 1);
    }

    return {
      totalPersonas: ids.length,
      slots: [...conteo.entries()].map(([clave, disponibles]) => {
        const [diaSemana, bloqueHora] = clave.split(':').map(Number);
        return { diaSemana, bloqueHora, disponibles };
      }),
    };
  }

  /**
   * HU-32 — sumar un amigo al grupo. Solo usuarios registrados: un anónimo
   * no pertenece a un grupo persistente (Duda #6).
   */
  async agregarMiembro(
    grupoId: string,
    usuarioId: string,
    nuevoUsuarioId: string,
  ): Promise<void> {
    await this.exigirMiembro(grupoId, usuarioId);

    const nuevo = await this.usuarios.findById(nuevoUsuarioId);
    if (!nuevo) throw new NotFoundError('El usuario a agregar no existe');

    const yaEsta = await this.grupos.esMiembro(grupoId, nuevoUsuarioId);
    if (yaEsta) throw new BadRequestError('Esa persona ya es miembro del grupo');

    await this.grupos.agregarMiembro(grupoId, nuevoUsuarioId);

    // Duda #12.2: sumar un amigo al grupo le da visibilidad de todos sus
    // eventos. Se materializa como participante de cada evento aún activo, para
    // que aparezca al asignar gastos/tareas y pueda confirmar asistencia (H-01).
    await this.materializarParticipantesActivos(grupoId, nuevoUsuarioId, nuevo.username);
  }

  /**
   * Item 2 — un usuario registrado se une por su cuenta a través de un link de
   * invitación (en vez de entrar como anónimo). Reutiliza la misma
   * materialización de H-01: pasa a ser miembro del grupo y participante de
   * sus eventos activos, con su cuenta real.
   */
  async unirsePorInvitacion(
    tokenInvitacion: string,
    usuarioId: string,
  ): Promise<{ eventoId: string; grupoId: string }> {
    const invitacion = await this.invitations.resolver(tokenInvitacion);

    const evento = await this.eventos.findById(invitacion.eventoId);
    if (!evento) throw new NotFoundError('Evento no encontrado');

    const usuario = await this.usuarios.findById(usuarioId);
    if (!usuario) throw new NotFoundError('Usuario no encontrado');

    const yaEsMiembro = await this.grupos.esMiembro(evento.grupoId, usuarioId);
    if (!yaEsMiembro) {
      await this.grupos.agregarMiembro(evento.grupoId, usuarioId);
      await this.materializarParticipantesActivos(evento.grupoId, usuarioId, usuario.username);
    } else {
      // Reutilizó un link de un grupo del que ya es miembro: igual asegura
      // que quede participante de ESTE evento puntual (idempotente, H-01).
      await this.participantes.createParaUsuario({
        eventoId: evento.id,
        usuarioId,
        username: usuario.username,
      });
    }

    return { eventoId: evento.id, grupoId: evento.grupoId };
  }

  private async materializarParticipantesActivos(
    grupoId: string,
    usuarioId: string,
    username: string,
  ): Promise<void> {
    const eventos = await this.eventos.listByGrupo(grupoId);
    const activos = eventos.filter(
      (e) => e.estado === 'planificacion' || e.estado === 'confirmado',
    );
    for (const evento of activos) {
      await this.participantes.createParaUsuario({
        eventoId: evento.id,
        usuarioId,
        username,
      });
    }
  }

  /**
   * HU-33 — abandonar el grupo. Se bloquea si quedaría vacío: un grupo sin
   * miembros dejaría sus eventos huérfanos y sin nadie que pueda gestionarlos.
   */
  async abandonar(grupoId: string, usuarioId: string): Promise<void> {
    await this.exigirMiembro(grupoId, usuarioId);

    const miembros = await this.grupos.contarMiembros(grupoId);
    if (miembros <= 1) {
      throw new BadRequestError(
        'No podés abandonar el grupo si sos el único miembro',
      );
    }

    await this.grupos.quitarMiembro(grupoId, usuarioId);
  }

  private async exigirMiembro(grupoId: string, usuarioId: string): Promise<void> {
    const grupo = await this.grupos.findById(grupoId);
    if (!grupo) throw new NotFoundError('Grupo no encontrado');

    const esMiembro = await this.grupos.esMiembro(grupoId, usuarioId);
    if (!esMiembro) throw new ForbiddenError('No sos miembro de este grupo');
  }
}
