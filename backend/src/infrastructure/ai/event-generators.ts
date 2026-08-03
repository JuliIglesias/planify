import { EventGenerator, EventoGenerado } from '../../domain/repositories';

/** Tareas típicas por tipo de evento (heurística). */
const TAREAS_POR_TIPO: { claves: string[]; tareas: string[] }[] = [
  { claves: ['asado', 'parrilla'], tareas: ['Comprar carne', 'Comprar bebidas', 'Llevar hielo', 'Comprar carbón'] },
  { claves: ['cumple', 'cumpleaños'], tareas: ['Comprar torta', 'Comprar bebidas', 'Organizar decoración'] },
  { claves: ['cine', 'película', 'pelicula'], tareas: ['Comprar entradas', 'Elegir horario'] },
  { claves: ['futbol', 'fútbol', 'fulbo'], tareas: ['Reservar cancha', 'Llevar pelota', 'Armar equipos'] },
  { claves: ['picnic', 'playa'], tareas: ['Llevar comida', 'Llevar bebidas', 'Llevar mantel'] },
  { claves: ['cena', 'comida'], tareas: ['Reservar lugar', 'Definir menú'] },
];

function capitalizar(texto: string): string {
  const limpio = texto.trim();
  return limpio.length === 0 ? limpio : limpio[0].toUpperCase() + limpio.slice(1);
}

/**
 * Generador heurístico, sin llamadas externas. Es el fallback de HU-42 (si la
 * IA falla o no hay API key, el usuario igual obtiene un borrador y no se bloquea
 * la creación). Extrae nombre, lugar (tras "en"), personas (tras "con") y tareas
 * típicas por palabra clave.
 */
export class HeuristicEventGenerator implements EventGenerator {
  async generar(descripcion: string): Promise<EventoGenerado> {
    const texto = descripcion.trim();
    const bajo = texto.toLowerCase();

    // Lugar: lo que sigue a " en ", cortado antes de " con ".
    let lugar = '';
    const enMatch = /\ben\s+(.+?)(?:\s+con\s+|[.,;]|$)/i.exec(texto);
    if (enMatch) lugar = capitalizar(enMatch[1].trim());

    // Personas mencionadas: lo que sigue a " con ", separado por "y"/",".
    const nombresMencionados: string[] = [];
    const conMatch = /\bcon\s+(.+?)(?:[.,;]|\ben\s+|$)/i.exec(texto);
    if (conMatch) {
      for (const parte of conMatch[1].split(/\s*(?:,|y|e)\s+/i)) {
        const nombre = parte.trim();
        // Solo tokens que parezcan nombres propios (empiezan en mayúscula).
        if (nombre.length > 1 && /^[A-ZÁÉÍÓÚÑ]/.test(nombre)) {
          nombresMencionados.push(nombre.split(/\s+/)[0]);
        }
      }
    }

    // Nombre del evento: tipo detectado, o el texto recortado.
    const tipo = TAREAS_POR_TIPO.find((t) => t.claves.some((c) => bajo.includes(c)));
    const nombre = tipo
      ? capitalizar(tipo.claves[0])
      : capitalizar(texto.split(/[.,;]/)[0]).slice(0, 60);

    return {
      nombre: nombre || 'Nuevo evento',
      lugar,
      tareasSugeridas: tipo?.tareas ?? [],
      nombresMencionados,
    };
  }
}

/**
 * Generador con **Gemini** (SCRUM-17, Duda #21: acceso gratuito de la facultad).
 * Pide salida JSON estructurada. Ante cualquier error (sin API key, timeout,
 * respuesta inválida) delega en el `fallback` heurístico — nunca bloquea la
 * creación del evento (HU-42, riesgo técnico del plan §7).
 */
export class GeminiEventGenerator implements EventGenerator {
  constructor(
    private readonly apiKey: string,
    private readonly fallback: EventGenerator,
    private readonly model = 'gemini-1.5-flash',
    private readonly timeoutMs = 8000,
  ) {}

  async generar(descripcion: string): Promise<EventoGenerado> {
    try {
      const url =
        `https://generativelanguage.googleapis.com/v1beta/models/${this.model}:generateContent` +
        `?key=${this.apiKey}`;

      const prompt =
        'Sos un asistente que arma eventos a partir de una descripción en español. ' +
        'Respondé SOLO un JSON con esta forma exacta, sin texto extra: ' +
        '{"nombre": string, "lugar": string, "tareasSugeridas": string[], "nombresMencionados": string[]}. ' +
        `Descripción: """${descripcion}"""`;

      const controller = new AbortController();
      const timer = setTimeout(() => controller.abort(), this.timeoutMs);
      let res: Response;
      try {
        res = await fetch(url, {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({
            contents: [{ parts: [{ text: prompt }] }],
            generationConfig: { responseMimeType: 'application/json' },
          }),
          signal: controller.signal,
        });
      } finally {
        clearTimeout(timer);
      }

      if (!res.ok) throw new Error(`Gemini respondió ${res.status}`);
      const json = (await res.json()) as {
        candidates?: { content?: { parts?: { text?: string }[] } }[];
      };
      const texto = json.candidates?.[0]?.content?.parts?.[0]?.text ?? '';
      const parsed = JSON.parse(texto) as Partial<EventoGenerado>;

      return {
        nombre: (parsed.nombre ?? '').toString().slice(0, 80) || 'Nuevo evento',
        lugar: (parsed.lugar ?? '').toString().slice(0, 120),
        tareasSugeridas: Array.isArray(parsed.tareasSugeridas)
          ? parsed.tareasSugeridas.map(String).slice(0, 10)
          : [],
        nombresMencionados: Array.isArray(parsed.nombresMencionados)
          ? parsed.nombresMencionados.map(String).slice(0, 20)
          : [],
      };
    } catch {
      // Fallback manual: la IA no debe bloquear la creación (HU-42).
      return this.fallback.generar(descripcion);
    }
  }
}
