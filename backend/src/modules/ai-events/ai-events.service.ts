import { BadRequestError } from '../../common/errors';
import { PersonaRef } from '../../domain/entities';
import { AmistadRepository, EventGenerator } from '../../domain/repositories';

/**
 * Borrador de evento generado por IA (SCRUM-17). Nunca crea el evento: es un
 * borrador **editable** que el organizador confirma en el wizard (HU-42, regla
 * de "nunca auto-crear sin revisión humana", plan §7).
 */
export interface BorradorEvento {
  nombre: string;
  lugar: string;
  tareasSugeridas: string[];
  /** Amigos ya registrados que matchearon con los nombres del texto (HU-43). */
  amigosSugeridos: PersonaRef[];
  /** Nombres mencionados que no matchearon con ningún amigo. */
  nombresSinMatch: string[];
}

export class AiEventsService {
  constructor(
    private readonly generator: EventGenerator,
    private readonly amistades: AmistadRepository,
  ) {}

  /** HU-42/43/44b — arma un borrador de evento a partir de texto libre. */
  async generarDesdeTexto(usuarioId: string, descripcion: string): Promise<BorradorEvento> {
    const limpio = descripcion?.trim();
    if (!limpio || limpio.length < 3) {
      throw new BadRequestError('Describí el evento con un poco más de detalle');
    }

    const generado = await this.generator.generar(limpio);
    const amigos = await this.amistades.listAmigos(usuarioId);

    const amigosSugeridos: PersonaRef[] = [];
    const nombresSinMatch: string[] = [];

    for (const mencionado of generado.nombresMencionados) {
      const m = mencionado.toLowerCase();
      const match = amigos.find((a) => {
        const username = a.username.toLowerCase();
        return username.includes(m) || m.includes(username.split(/\s+/)[0]);
      });
      if (match) {
        if (!amigosSugeridos.some((x) => x.id === match.id)) amigosSugeridos.push(match);
      } else {
        nombresSinMatch.push(mencionado);
      }
    }

    return {
      nombre: generado.nombre,
      lugar: generado.lugar,
      tareasSugeridas: generado.tareasSugeridas,
      amigosSugeridos,
      nombresSinMatch,
    };
  }
}
