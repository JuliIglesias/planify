import {
  DeviceRegistry,
  ParticipanteRepository,
  PushNotifier,
} from '../../domain/repositories';
import { ActivityTypeValue } from '../activity-log/activity-log.types';

export interface NotificarActividadInput {
  eventoId: string;
  actorParticipanteId: string;
  tipo: ActivityTypeValue;
}

/** Texto corto por tipo de actividad, para el cuerpo de la notificación. */
const TEXTO: Record<string, string> = {
  gasto_agregado: 'Se agregó un gasto',
  deuda_saldada: 'Se saldó una deuda',
  tarea_creada: 'Se creó una tarea',
  tarea_asignada: 'Se asignó una tarea',
  tarea_completada: 'Se completó una tarea',
  horario_confirmado: 'Se confirmó el horario del evento',
  asistencia_confirmada: 'Alguien confirmó su asistencia',
  participante_se_unio: 'Alguien se unió al evento',
  disponibilidad_cargada: 'Alguien cargó su disponibilidad',
  evento_cancelado: 'El evento fue cancelado',
};

/**
 * SCRUM-15 — HU-35: notificaciones push ante actividad relevante.
 *
 * Se dispara desde `ActivityLogService.registrar` (un solo lugar). Notifica a
 * los participantes **registrados** del evento (los anónimos no tienen device),
 * salvo el propio actor.
 */
export class NotificationsService {
  constructor(
    private readonly participantes: ParticipanteRepository,
    private readonly devices: DeviceRegistry,
    private readonly push: PushNotifier,
  ) {}

  /** HU-35 — registrar el device del usuario para recibir push. */
  async registrarDevice(usuarioId: string, deviceToken: string): Promise<void> {
    await this.devices.registrar(usuarioId, deviceToken);
  }

  async notificarActividad(input: NotificarActividadInput): Promise<void> {
    const participantes = await this.participantes.listByEvento(input.eventoId);

    const destinatarios = participantes
      .filter((p) => p.usuarioId && p.id !== input.actorParticipanteId)
      .map((p) => p.usuarioId!) as string[];

    if (destinatarios.length === 0) return;

    const tokens = await this.devices.tokensDe(destinatarios);
    if (tokens.length === 0) return;

    await this.push.enviar(tokens, {
      titulo: 'Planify',
      cuerpo: TEXTO[input.tipo] ?? 'Nueva actividad en tu evento',
      data: { eventoId: input.eventoId, tipo: input.tipo },
    });
  }
}
