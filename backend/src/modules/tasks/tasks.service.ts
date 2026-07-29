import { BadRequestError, NotFoundError } from '../../common/errors';
import { Tarea } from '../../domain/entities';
import {
  EventoRepository,
  ParticipanteRepository,
  TareaConAsignado,
  TareaRepository,
} from '../../domain/repositories';
import { ActivityLogService } from '../activity-log/activity-log.service';
import { ActivityType } from '../activity-log/activity-log.types';

/**
 * SCRUM-12 — HU-20 a HU-23. Las "actividades" del evento: lo que hay que hacer
 * antes de la juntada (comprar la carne, el hielo…) y alguien toma.
 * Estados: no_asignado → pendiente → completado (Duda #4).
 */
export class TasksService {
  constructor(
    private readonly tareas: TareaRepository,
    private readonly eventos: EventoRepository,
    private readonly participantes: ParticipanteRepository,
    private readonly log: ActivityLogService,
  ) {}

  async crear(eventoId: string, participanteId: string, titulo: string): Promise<Tarea> {
    const limpio = titulo?.trim();
    if (!limpio) throw new BadRequestError('titulo es requerido');

    const evento = await this.eventos.findById(eventoId);
    if (!evento) throw new NotFoundError('Evento no encontrado');
    if (evento.estado === 'cancelado') throw new BadRequestError('El evento está cancelado');

    const tarea = await this.tareas.create(eventoId, limpio, participanteId);

    await this.log.registrar({
      eventoId,
      tipo: ActivityType.tareaCreada,
      actorParticipanteId: participanteId,
      payload: { tareaId: tarea.id, titulo: limpio },
    });

    return tarea;
  }

  async listar(eventoId: string): Promise<TareaConAsignado[]> {
    return this.tareas.listByEvento(eventoId);
  }

  /**
   * HU-21/HU-22 — tomar una tarea o asignársela a otro. Cualquier miembro
   * puede hacerlo, no es exclusivo del organizador (Duda #6).
   */
  async asignar(
    tareaId: string,
    actorParticipanteId: string,
    asignadoA: string,
  ): Promise<TareaConAsignado> {
    const tarea = await this.tareas.findById(tareaId);
    if (!tarea) throw new NotFoundError('Tarea no encontrada');
    if (tarea.estado === 'completado') {
      throw new BadRequestError('La tarea ya está completada');
    }

    // Solo se puede asignar a alguien que participe de este evento.
    const destinatario = await this.participantes.findById(asignadoA);
    if (!destinatario || destinatario.eventoId !== tarea.eventoId) {
      throw new BadRequestError('El asignado no participa de este evento');
    }

    const actualizada = await this.tareas.asignar(tareaId, asignadoA);

    await this.log.registrar({
      eventoId: tarea.eventoId,
      tipo: ActivityType.tareaAsignada,
      actorParticipanteId,
      payload: {
        tareaId,
        titulo: tarea.titulo,
        asignadoA,
        // Distingue "me la tomé" de "se la asigné a alguien" en el feed.
        autoAsignada: actorParticipanteId === asignadoA,
      },
    });

    return actualizada;
  }

  async completar(tareaId: string, participanteId: string): Promise<Tarea> {
    const tarea = await this.tareas.findById(tareaId);
    if (!tarea) throw new NotFoundError('Tarea no encontrada');
    if (tarea.estado === 'completado') {
      throw new BadRequestError('La tarea ya está completada');
    }

    const actualizada = await this.tareas.cambiarEstado(tareaId, 'completado');

    await this.log.registrar({
      eventoId: tarea.eventoId,
      tipo: ActivityType.tareaCompletada,
      actorParticipanteId: participanteId,
      payload: { tareaId, titulo: tarea.titulo },
    });

    return actualizada;
  }
}
