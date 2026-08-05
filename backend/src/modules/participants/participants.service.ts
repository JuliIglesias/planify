import { BadRequestError, NotFoundError, UnauthorizedError } from '../../common/errors';
import { Evento, Participante } from '../../domain/entities';
import {
  DeudaRepository,
  EventoRepository,
  IdGenerator,
  ParticipanteRepository,
  PasswordHasher,
  UsuarioRepository,
} from '../../domain/repositories';
import { ActivityLogService } from '../activity-log/activity-log.service';
import { ActivityType } from '../activity-log/activity-log.types';

export interface SesionAnonima {
  participanteId: string;
  tokenSesion: string;
  username: string;
}

const PIN_MIN_LARGO = 4;

/**
 * HU-01/HU-03 — un anónimo se une a un evento eligiendo un username visible
 * y un PIN (G1, ver docs/adrs/0003-identidad-anonima-por-evento.md). Un
 * anónimo nunca crea eventos (Duda #19).
 *
 * G1 — reglas de identidad anónima:
 *  1. Solo se entra por link de invitación a un evento puntual + username
 *     (ya era así — no existe un camino anónimo "sin evento").
 *  2. Volver a entrar al MISMO evento con el MISMO username + PIN recupera
 *     la MISMA fila de `Participante` (mismo historial), no crea una nueva.
 *  3. El mismo username no se puede usar para entrar a OTRO evento mientras
 *     el primero sigue "activo" (ver `puedeLiberarUsername`). Se libera
 *     cuando ese evento termina Y sus deudas quedan saldadas.
 */
export class ParticipantsService {
  constructor(
    private readonly participantes: ParticipanteRepository,
    private readonly usuarios: UsuarioRepository,
    private readonly eventos: EventoRepository,
    private readonly ids: IdGenerator,
    private readonly log: ActivityLogService,
    private readonly hasher: PasswordHasher,
    private readonly deudas: DeudaRepository,
  ) {}

  async unirseComoAnonimo(
    eventoId: string,
    username: string,
    pin: string,
  ): Promise<SesionAnonima> {
    const deseado = username?.trim();
    if (!deseado) throw new BadRequestError('username es requerido');
    if (!pin || pin.length < PIN_MIN_LARGO) {
      throw new BadRequestError(`El PIN debe tener al menos ${PIN_MIN_LARGO} caracteres`);
    }

    const evento = await this.eventos.findById(eventoId);
    if (!evento) throw new NotFoundError('Evento no encontrado');
    if (evento.estado === 'cancelado' || evento.estado === 'finalizado') {
      throw new BadRequestError('El evento ya no acepta nuevos participantes');
    }

    // G1 regla 2 — ¿ya hay alguien con este username EN ESTE evento? Si sí,
    // esto es un reingreso: valida el PIN y devuelve la MISMA fila, en vez
    // de crear una nueva.
    const existente = await this.participantes.findAnonimoPorEventoYUsername(eventoId, deseado);
    if (existente) {
      return this.reingresar(existente, pin);
    }

    // No existe en ESTE evento: antes de crear una fila nueva, hay que
    // asegurarse de que el username esté libre — ni de una cuenta
    // registrada, ni de un anónimo en OTRO evento todavía activo (regla 3).
    await this.exigirUsernameLibre(deseado, eventoId);

    const pinHash = await this.hasher.hash(pin);
    const participante = await this.participantes.createAnonimo({
      eventoId,
      username: deseado,
      tokenSesion: this.ids.generate(),
      pinHash,
    });

    await this.log.registrar({
      eventoId,
      tipo: ActivityType.participanteSeUnio,
      actorParticipanteId: participante.id,
      payload: { username: deseado },
    });

    return {
      participanteId: participante.id,
      tokenSesion: participante.tokenSesion ?? '',
      username: deseado,
    };
  }

  /** G1 regla 2 — recupera la sesión existente si el PIN coincide. */
  private async reingresar(existente: Participante, pin: string): Promise<SesionAnonima> {
    const pinValido = existente.pinHash
      ? await this.hasher.compare(pin, existente.pinHash)
      : false;
    if (!pinValido) {
      throw new UnauthorizedError(
        'Ese username ya está en uso en este evento. Si sos vos, revisá el PIN.',
      );
    }

    // Mismo criterio que un login: se emite un token de sesión nuevo, no se
    // reusa el viejo (para que un token filtrado no siga sirviendo siempre).
    const actualizado = await this.participantes.regenerarTokenSesion(
      existente.id,
      this.ids.generate(),
    );

    return {
      participanteId: actualizado.id,
      tokenSesion: actualizado.tokenSesion ?? '',
      username: actualizado.username,
    };
  }

  /**
   * G1 regla 3 — rechaza (sin auto-sufijar, a diferencia del comportamiento
   * viejo) si el username ya lo tiene una cuenta registrada, o un anónimo en
   * otro evento que todavía no liberó el username. El mensaje sugiere una
   * alternativa disponible (pedido explícito del usuario).
   */
  private async exigirUsernameLibre(deseado: string, eventoIdActual: string): Promise<void> {
    const porUsuario = await this.usuarios.findByUsername(deseado.toLowerCase());
    if (porUsuario) {
      const sugerencia = await this.sugerirAlternativa(deseado);
      throw new BadRequestError(`El username "${deseado}" ya está en uso. Probá con "${sugerencia}".`);
    }

    const candidatos = await this.participantes.listAnonimosPorUsername(deseado);
    for (const candidato of candidatos) {
      if (candidato.eventoId === eventoIdActual) continue; // ya se chequeó antes, por las dudas.
      const evento = await this.eventos.findById(candidato.eventoId);
      if (!evento) continue;
      if (!(await this.puedeLiberarUsername(evento))) {
        const sugerencia = await this.sugerirAlternativa(deseado);
        throw new BadRequestError(
          `El username "${deseado}" ya está en uso en otro evento activo. Probá con "${sugerencia}".`,
        );
      }
    }
  }

  /**
   * G1 regla 3 — un evento "libera" los usernames de sus anónimos cuando
   * terminó (finalizado o cancelado) Y no quedan deudas pendientes de ese
   * evento: los anónimos todavía pueden necesitar saldar cuentas con otros
   * participantes, así que su identidad se mantiene hasta que eso se
   * resuelva (confirmado con el usuario — ver ADR 0003).
   */
  private async puedeLiberarUsername(evento: Evento): Promise<boolean> {
    if (evento.estado !== 'finalizado' && evento.estado !== 'cancelado') return false;
    const pendientes = await this.deudas.contarPendientes(evento.id);
    return pendientes === 0;
  }

  /** Primer username libre agregando un sufijo numérico, solo para sugerir. */
  private async sugerirAlternativa(deseado: string): Promise<string> {
    let candidato = deseado;
    let sufijo = 1;
    // Tope defensivo: nunca debería hacer falta iterar mucho para encontrar
    // uno libre, pero evita un loop infinito ante un caso patológico.
    for (let intento = 0; intento < 1000; intento++) {
      const libre =
        !(await this.usuarios.findByUsername(candidato.toLowerCase())) &&
        !(await this.estaBloqueadoEnOtroEvento(candidato));
      if (libre) return candidato;
      sufijo += 1;
      candidato = `${deseado}${sufijo}`;
    }
    return candidato;
  }

  private async estaBloqueadoEnOtroEvento(username: string): Promise<boolean> {
    const candidatos = await this.participantes.listAnonimosPorUsername(username);
    for (const candidato of candidatos) {
      const evento = await this.eventos.findById(candidato.eventoId);
      if (evento && !(await this.puedeLiberarUsername(evento))) return true;
    }
    return false;
  }
}
