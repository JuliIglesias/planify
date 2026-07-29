import { BadRequestError, ForbiddenError, NotFoundError } from '../../common/errors';
import { Evento, Grupo } from '../../domain/entities';
import {
  Clock,
  EventoRepository,
  GastoRepository,
  GrupoConMiembros,
  GrupoRepository,
  TareaRepository,
  UsuarioRepository,
} from '../../domain/repositories';
import { ActivityLogService } from '../activity-log/activity-log.service';

/** Cuánto tiempo un evento se muestra como "NUEVO" en la pantalla Groups. */
const VENTANA_EVENTO_NUEVO_HS = 48;

export interface ResumenGrupo {
  id: string;
  nombre: string;
  avatarUrl: string | null;
  miembros: { id: string; nombre: string }[];
  noLeidos: number;
  tieneEventoNuevo: boolean;
  proximoEvento: {
    id: string;
    nombre: string;
    lugarTexto: string;
    estado: string;
    fechaHoraInicio: Date | null;
    confirmados: number;
    tareasPendientes: number;
    gastos: number;
  } | null;
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
  ) {}

  async listarDe(usuarioId: string): Promise<GrupoConMiembros[]> {
    return this.grupos.listByUsuario(usuarioId);
  }

  /** Datos ya armados para la pantalla Groups, incluidos los badges. */
  async resumenPara(usuarioId: string): Promise<ResumenGrupo[]> {
    const [grupos, noLeidosPorEvento, proximos] = await Promise.all([
      this.grupos.listByUsuario(usuarioId),
      this.log.contarNoLeidasPorEvento(usuarioId),
      this.eventos.listUpcomingForUsuario(usuarioId),
    ]);

    const eventosPorGrupo = await Promise.all(
      grupos.map((g) => this.eventos.listByGrupo(g.id)),
    );

    // Los contadores se piden una sola vez para todos los eventos, en vez de
    // una consulta por grupo (evita el N+1).
    const idsProximos = eventosPorGrupo
      .map((eventos) => this.proximoDe(eventos)?.id)
      .filter((id): id is string => Boolean(id));

    const [tareasPendientes, gastosPorEvento] = await Promise.all([
      this.tareas.contarPendientesPorEvento(idsProximos),
      this.gastos.contarPorEvento(idsProximos),
    ]);

    const confirmadosPorEvento = new Map(proximos.map((e) => [e.id, e.confirmados]));
    const corte = new Date(
      this.clock.now().getTime() - VENTANA_EVENTO_NUEVO_HS * 60 * 60 * 1000,
    );

    return grupos.map((grupo, i) => {
      const eventos = eventosPorGrupo[i];
      const proximo = this.proximoDe(eventos);

      return {
        id: grupo.id,
        nombre: grupo.nombre,
        avatarUrl: grupo.avatarUrl,
        miembros: grupo.miembros,
        // El contador del grupo es la suma de todos sus eventos (Duda #2).
        noLeidos: eventos.reduce((acc, e) => acc + (noLeidosPorEvento[e.id] ?? 0), 0),
        tieneEventoNuevo: eventos.some((e) => e.createdAt > corte),
        proximoEvento: proximo
          ? {
              id: proximo.id,
              nombre: proximo.nombre,
              lugarTexto: proximo.lugarTexto,
              estado: proximo.estado,
              fechaHoraInicio: proximo.fechaHoraInicio,
              confirmados: confirmadosPorEvento.get(proximo.id) ?? 0,
              tareasPendientes: tareasPendientes[proximo.id] ?? 0,
              gastos: gastosPorEvento[proximo.id] ?? 0,
            }
          : null,
      };
    });
  }

  /** El evento activo más próximo del grupo: es el que se ve en la card. */
  private proximoDe(eventos: Evento[]): Evento | null {
    return (
      eventos.find((e) => e.estado === 'planificacion' || e.estado === 'confirmado') ?? null
    );
  }

  /** HU-34 — renombrar el grupo. Cualquier miembro puede. */
  async renombrar(grupoId: string, usuarioId: string, nombre: string): Promise<Grupo> {
    const limpio = nombre?.trim();
    if (!limpio) throw new BadRequestError('nombre es requerido');

    await this.exigirMiembro(grupoId, usuarioId);
    return this.grupos.rename(grupoId, limpio);
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
