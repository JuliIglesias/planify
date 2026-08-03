/**
 * Puertos de notificaciones push (SCRUM-15, NFR#8).
 *
 * Los servicios dependen de estas interfaces, no de SNS/Pinpoint. Cambiar el
 * proveedor real es escribir una implementación nueva y cablearla en
 * `container.ts` — ningún servicio se entera.
 */

export interface MensajePush {
  titulo: string;
  cuerpo: string;
  data?: Record<string, string>;
}

/** Envía notificaciones a un conjunto de device tokens. */
export interface PushNotifier {
  enviar(deviceTokens: string[], mensaje: MensajePush): Promise<void>;
}

/** Guarda qué dispositivos tiene cada usuario, para saber a dónde notificar. */
export interface DeviceRegistry {
  registrar(usuarioId: string, deviceToken: string): Promise<void>;
  tokensDe(usuarioIds: string[]): Promise<string[]>;
}
