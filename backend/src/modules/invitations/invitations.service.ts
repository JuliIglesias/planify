import { BadRequestError, NotFoundError } from '../../common/errors';
import { Invitacion } from '../../domain/entities';
import {
  Clock,
  EventoRepository,
  IdGenerator,
  InvitacionRepository,
} from '../../domain/repositories';

/** HU-02 — link de invitación que lleva directo al evento. */
export class InvitationsService {
  constructor(
    private readonly invitaciones: InvitacionRepository,
    private readonly eventos: EventoRepository,
    private readonly ids: IdGenerator,
    private readonly clock: Clock,
  ) {}

  async crear(eventoId: string): Promise<Invitacion> {
    const evento = await this.eventos.findById(eventoId);
    if (!evento) throw new NotFoundError('Evento no encontrado');

    return this.invitaciones.create(eventoId, this.ids.generate());
  }

  async resolver(tokenUnico: string): Promise<Invitacion> {
    const invitacion = await this.invitaciones.findByToken(tokenUnico);
    if (!invitacion) throw new NotFoundError('Invitación no encontrada');

    if (invitacion.expiraEn && invitacion.expiraEn < this.clock.now()) {
      throw new BadRequestError('La invitación expiró');
    }

    const evento = await this.eventos.findById(invitacion.eventoId);
    if (!evento) throw new NotFoundError('Evento no encontrado');
    if (evento.estado === 'cancelado' || evento.estado === 'finalizado') {
      throw new BadRequestError('El evento ya no está disponible');
    }

    return invitacion;
  }
}
