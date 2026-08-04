import { BadRequestError, NotFoundError } from '../../common/errors';
import {
  EventoRepository,
  IdGenerator,
  ParticipanteRepository,
  UsuarioRepository,
} from '../../domain/repositories';
import { ActivityLogService } from '../activity-log/activity-log.service';
import { ActivityType } from '../activity-log/activity-log.types';

export interface SesionAnonima {
  participanteId: string;
  tokenSesion: string;
  /** Puede diferir del pedido si hubo que auto-sufijarlo por colisión. */
  username: string;
}

/**
 * HU-01/HU-03 — un anónimo se une a un evento eligiendo un username visible.
 * Su token vive en el dispositivo y solo vale mientras el evento siga abierto
 * (Duda #5). Un anónimo nunca crea eventos (Duda #19).
 */
export class ParticipantsService {
  constructor(
    private readonly participantes: ParticipanteRepository,
    private readonly usuarios: UsuarioRepository,
    private readonly eventos: EventoRepository,
    private readonly ids: IdGenerator,
    private readonly log: ActivityLogService,
  ) {}

  async unirseComoAnonimo(eventoId: string, username: string): Promise<SesionAnonima> {
    const deseado = username?.trim();
    if (!deseado) throw new BadRequestError('username es requerido');

    const evento = await this.eventos.findById(eventoId);
    if (!evento) throw new NotFoundError('Evento no encontrado');
    if (evento.estado === 'cancelado' || evento.estado === 'finalizado') {
      throw new BadRequestError('El evento ya no acepta nuevos participantes');
    }

    const usernameUnico = await this.resolverUsernameUnico(deseado);

    const participante = await this.participantes.createAnonimo({
      eventoId,
      username: usernameUnico,
      tokenSesion: this.ids.generate(),
    });

    await this.log.registrar({
      eventoId,
      tipo: ActivityType.participanteSeUnio,
      actorParticipanteId: participante.id,
      payload: { username: usernameUnico },
    });

    return {
      participanteId: participante.id,
      // createAnonimo siempre lo genera, pero el tipo es nullable porque los
      // participantes registrados no tienen token de sesión.
      tokenSesion: participante.tokenSesion ?? '',
      username: usernameUnico,
    };
  }

  /**
   * Un anónimo puede elegir cualquier username (a diferencia del registro,
   * acá nunca se rechaza el pedido): si ya está tomado — por una cuenta
   * registrada o por otro anónimo, en cualquier evento — se le agrega un
   * sufijo numérico hasta encontrar uno libre.
   */
  private async resolverUsernameUnico(deseado: string): Promise<string> {
    let candidato = deseado;
    let sufijo = 1;
    while (await this.estaTomado(candidato)) {
      sufijo += 1;
      candidato = `${deseado}${sufijo}`;
    }
    return candidato;
  }

  private async estaTomado(username: string): Promise<boolean> {
    const [porUsuario, porAnonimo] = await Promise.all([
      this.usuarios.findByUsername(username.toLowerCase()),
      this.participantes.existsUsernameAnonimo(username),
    ]);
    return !!porUsuario || porAnonimo;
  }
}
