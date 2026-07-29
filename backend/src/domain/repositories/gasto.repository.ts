import { GastoCompleto, MontoParticipante, PersonaRef } from '../entities';

export interface CrearGastoData {
  eventoId: string;
  descripcion: string;
  montoTotal: string;
  creadoPor: string;
  acreedores: MontoParticipante[];
  deudores: MontoParticipante[];
}

export interface GastoDetallado extends GastoCompleto {
  creador: PersonaRef;
}

export interface GastoRepository {
  create(data: CrearGastoData): Promise<GastoCompleto>;
  listByEvento(eventoId: string): Promise<GastoDetallado[]>;

  /** Solo los montos: es lo único que el motor de deudas necesita (HU-15). */
  listMontosByEvento(eventoId: string): Promise<GastoCompleto[]>;

  contarPorEvento(eventoIds: string[]): Promise<Record<string, number>>;
}
