import { BadRequestError, NotFoundError } from '../../common/errors';
import {
  EventoRepository,
  IdGenerator,
  ParticipanteRepository,
} from '../../domain/repositories';
import { ActivityLogService } from '../activity-log/activity-log.service';
import { ActivityType } from '../activity-log/activity-log.types';

export interface SesionAnonima {
  participanteId: string;
  tokenSesion: string;
}

/**
 * HU-01/HU-03 — un anónimo se une a un evento eligiendo un nombre visible.
 * Su token vive en el dispositivo y solo vale mientras el evento siga abierto
 * (Duda #5). Un anónimo nunca crea eventos (Duda #19).
 */
export class ParticipantsService {
  constructor(
    private readonly participantes: ParticipanteRepository,
    private readonly eventos: EventoRepository,
    private readonly ids: IdGenerator,
    private readonly log: ActivityLogService,
  ) {}

  async unirseComoAnonimo(eventoId: string, nombreDisplay: string): Promise<SesionAnonima> {
    const nombre = nombreDisplay?.trim();
    if (!nombre) throw new BadRequestError('nombreDisplay es requerido');

    const evento = await this.eventos.findById(eventoId);
    if (!evento) throw new NotFoundError('Evento no encontrado');
    if (evento.estado === 'cancelado' || evento.estado === 'finalizado') {
      throw new BadRequestError('El evento ya no acepta nuevos participantes');
    }

    const participante = await this.participantes.createAnonimo({
      eventoId,
      nombreDisplay: nombre,
      tokenSesion: this.ids.generate(),
    });

    await this.log.registrar({
      eventoId,
      tipo: ActivityType.participanteSeUnio,
      actorParticipanteId: participante.id,
      payload: { nombre },
    });

    return {
      participanteId: participante.id,
      // createAnonimo siempre lo genera, pero el tipo es nullable porque los
      // participantes registrados no tienen token de sesión.
      tokenSesion: participante.tokenSesion ?? '',
    };
  }
}
