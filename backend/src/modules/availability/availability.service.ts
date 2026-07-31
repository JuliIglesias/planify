import { BadRequestError, NotFoundError } from '../../common/errors';
import { Evento } from '../../domain/entities';
import {
  DisponibilidadRepository,
  EventoRepository,
  SlotDisponibilidad,
  SlotHeatmap,
} from '../../domain/repositories';
import { ActivityLogService } from '../activity-log/activity-log.service';
import { ActivityType } from '../activity-log/activity-log.types';
import { EventsService } from '../events/events.service';

const DIAS_SEMANA = 7;
const BLOQUES_POR_DIA = 24;

/**
 * SCRUM-9 — HU-07/HU-08/HU-09. Es el corazón del MVP: cada uno marca cuándo
 * puede, el heatmap muestra dónde coinciden y el organizador cierra el horario.
 * La fecha del evento sale de acá, no del formulario de creación (Duda F4).
 */
export class AvailabilityService {
  constructor(
    private readonly disponibilidad: DisponibilidadRepository,
    private readonly eventos: EventoRepository,
    private readonly events: EventsService,
    private readonly log: ActivityLogService,
  ) {}

  /** HU-07 — reemplaza la disponibilidad del participante en ese evento. */
  async guardar(
    eventoId: string,
    participanteId: string,
    slots: SlotDisponibilidad[],
  ): Promise<void> {
    if (!Array.isArray(slots)) throw new BadRequestError('slots debe ser un array');

    for (const slot of slots) {
      if (!Number.isInteger(slot.diaSemana) || slot.diaSemana < 0 || slot.diaSemana >= DIAS_SEMANA) {
        throw new BadRequestError(`diaSemana inválido: ${slot.diaSemana} (esperado 0..6)`);
      }
      if (
        !Number.isInteger(slot.bloqueHora) ||
        slot.bloqueHora < 0 ||
        slot.bloqueHora >= BLOQUES_POR_DIA
      ) {
        throw new BadRequestError(`bloqueHora inválido: ${slot.bloqueHora} (esperado 0..23)`);
      }
    }

    const evento = await this.eventos.findById(eventoId);
    if (!evento) throw new NotFoundError('Evento no encontrado');
    if (evento.estado === 'cancelado') throw new BadRequestError('El evento está cancelado');

    await this.disponibilidad.replaceForParticipante(eventoId, participanteId, slots);

    await this.log.registrar({
      eventoId,
      tipo: ActivityType.disponibilidadCargada,
      actorParticipanteId: participanteId,
      payload: { bloques: slots.length },
    });
  }

  /** HU-08 — cuántos pueden en cada bloque. */
  async heatmap(eventoId: string): Promise<SlotHeatmap[]> {
    return this.disponibilidad.heatmapForEvento(eventoId);
  }

  /** Obtiene los bloques de disponibilidad guardados por un participante en un evento. */
  async obtenerDeParticipante(
    eventoId: string,
    participanteId: string,
  ): Promise<SlotDisponibilidad[]> {
    const evento = await this.eventos.findById(eventoId);
    if (!evento) throw new NotFoundError('Evento no encontrado');
    return this.disponibilidad.findByParticipante(eventoId, participanteId);
  }


  /** HU-09 — el organizador fija el horario a partir del heatmap. */
  async confirmarHorario(
    usuarioId: string,
    eventoId: string,
    fechaHoraInicio: Date,
  ): Promise<Evento> {
    if (Number.isNaN(fechaHoraInicio.getTime())) {
      throw new BadRequestError('fechaHoraInicio inválida');
    }

    const evento = await this.eventos.findById(eventoId);
    if (!evento) throw new NotFoundError('Evento no encontrado');
    if (evento.estado === 'cancelado') throw new BadRequestError('El evento está cancelado');

    const organizador = await this.events.exigirOrganizador(eventoId, usuarioId);

    const confirmado = await this.eventos.confirmarHorario(eventoId, fechaHoraInicio);

    await this.log.registrar({
      eventoId,
      tipo: ActivityType.horarioConfirmado,
      actorParticipanteId: organizador.id,
      payload: { fechaHoraInicio: fechaHoraInicio.toISOString() },
    });

    return confirmado;
  }
}
