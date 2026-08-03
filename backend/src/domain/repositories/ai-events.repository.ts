/**
 * Puerto de generación de eventos por IA (SCRUM-17, HU-42/43/44b).
 *
 * El servicio depende de esta interfaz, no de Gemini. La implementación real
 * (Gemini) y la heurística offline conviven detrás del mismo contrato: cambiar
 * o combinar proveedores es tocar `container.ts`, no el servicio.
 */
export interface EventoGenerado {
  nombre: string;
  lugar: string;
  /** Tareas típicas sugeridas para ese evento (HU-44b). */
  tareasSugeridas: string[];
  /** Nombres de personas mencionadas en el texto (HU-43). */
  nombresMencionados: string[];
}

export interface EventGenerator {
  generar(descripcion: string): Promise<EventoGenerado>;
}
