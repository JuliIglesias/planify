import { ForbiddenError, NotFoundError } from '../../common/errors';
import { EventoEstado } from '../../domain/entities';
import {
  AmistadRepository,
  EventoRepository,
  GrupoRepository,
  ParticipanteRepository,
  ProfileAvailabilityRepository,
  UsuarioRepository,
} from '../../domain/repositories';

/** Item 4 (Fase 5) — un bloque de la disponibilidad semanal comparada entre dos personas. */
export interface SlotComparado {
  diaSemana: number;
  bloqueHora: number;
  /** Nunca "ninguno": esos bloques directamente no vienen en la lista (mismo criterio que el heatmap normal). */
  estado: 'ambos' | 'soloYo' | 'soloAmigo';
}

export interface EventoCompartido {
  id: string;
  nombre: string;
  lugarTexto: string;
  estado: EventoEstado;
  fechaHoraInicio: Date | null;
}

export interface GrupoCompartido {
  id: string;
  nombre: string;
  avatarUrl: string | null;
}

export interface PerfilAmigo {
  persona: { id: string; username: string; email: string; avatarUrl: string | null };
  heatmapComparado: SlotComparado[];
  eventosEnComun: EventoCompartido[];
  gruposEnComun: GrupoCompartido[];
}

/**
 * Item 4 (Fase 5) — perfil de solo lectura de un amigo: disponibilidad
 * comparada (solo esa dupla, no todos los amigos como HU-B4), y eventos y
 * grupos que se comparten con él/ella. Solo accesible entre amigos
 * (`Amistad.estado === 'aceptada'`), en cualquiera de los dos sentidos.
 */
export class FriendProfileService {
  constructor(
    private readonly amistades: AmistadRepository,
    private readonly usuarios: UsuarioRepository,
    private readonly disponibilidad: ProfileAvailabilityRepository,
    private readonly grupos: GrupoRepository,
    private readonly participantes: ParticipanteRepository,
    private readonly eventos: EventoRepository,
  ) {}

  async obtener(usuarioId: string, amigoId: string): Promise<PerfilAmigo> {
    const amistad = await this.amistades.findEntre(usuarioId, amigoId);
    if (!amistad || amistad.estado !== 'aceptada') {
      throw new ForbiddenError('Solo podés ver el perfil de tus amigos');
    }

    const amigo = await this.usuarios.findById(amigoId);
    if (!amigo) throw new NotFoundError('Usuario no encontrado');

    const [slots, misGrupos, susGrupos, misParticipaciones, susParticipaciones] =
      await Promise.all([
        this.disponibilidad.slotsDeUsuarios([usuarioId, amigoId]),
        this.grupos.listByUsuario(usuarioId),
        this.grupos.listByUsuario(amigoId),
        this.participantes.listByUsuario(usuarioId),
        this.participantes.listByUsuario(amigoId),
      ]);

    const idsGruposDelAmigo = new Set(susGrupos.map((g) => g.id));
    const gruposEnComun: GrupoCompartido[] = misGrupos
      .filter((g) => idsGruposDelAmigo.has(g.id))
      .map((g) => ({ id: g.id, nombre: g.nombre, avatarUrl: g.avatarUrl }));

    const misEventoIds = new Set(misParticipaciones.map((p) => p.eventoId));
    const eventoIdsComunes = [
      ...new Set(
        susParticipaciones
          .map((p) => p.eventoId)
          .filter((eventoId) => misEventoIds.has(eventoId)),
      ),
    ];
    const eventosCrudos = await Promise.all(
      eventoIdsComunes.map((id) => this.eventos.findById(id)),
    );
    const eventosEnComun: EventoCompartido[] = eventosCrudos
      .filter((e): e is NonNullable<typeof e> => e !== null)
      .map((e) => ({
        id: e.id,
        nombre: e.nombre,
        lugarTexto: e.lugarTexto,
        estado: e.estado,
        fechaHoraInicio: e.fechaHoraInicio,
      }));

    return {
      persona: {
        id: amigo.id,
        username: amigo.username,
        email: amigo.email,
        avatarUrl: amigo.avatarUrl,
      },
      heatmapComparado: this.compararSlots(usuarioId, amigoId, slots),
      eventosEnComun,
      gruposEnComun,
    };
  }

  private compararSlots(
    usuarioId: string,
    amigoId: string,
    slots: { usuarioId: string; diaSemana: number; bloqueHora: number }[],
  ): SlotComparado[] {
    const porSlot = new Map<string, { mio: boolean; suyo: boolean }>();
    for (const s of slots) {
      if (s.usuarioId !== usuarioId && s.usuarioId !== amigoId) continue;
      const clave = `${s.diaSemana}:${s.bloqueHora}`;
      const actual = porSlot.get(clave) ?? { mio: false, suyo: false };
      if (s.usuarioId === usuarioId) actual.mio = true;
      if (s.usuarioId === amigoId) actual.suyo = true;
      porSlot.set(clave, actual);
    }

    return [...porSlot.entries()].map(([clave, { mio, suyo }]) => {
      const [diaSemana, bloqueHora] = clave.split(':').map(Number);
      return {
        diaSemana,
        bloqueHora,
        estado: mio && suyo ? 'ambos' : mio ? 'soloYo' : 'soloAmigo',
      } as SlotComparado;
    });
  }
}
