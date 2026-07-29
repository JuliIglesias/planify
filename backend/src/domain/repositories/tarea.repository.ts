import { PersonaRef, Tarea, TareaEstado } from '../entities';

export interface TareaConAsignado extends Tarea {
  asignado: PersonaRef | null;
}

export interface TareaRepository {
  findById(id: string): Promise<Tarea | null>;
  listByEvento(eventoId: string): Promise<TareaConAsignado[]>;
  contarPendientesPorEvento(eventoIds: string[]): Promise<Record<string, number>>;

  create(eventoId: string, titulo: string, creadoPor: string): Promise<Tarea>;
  asignar(id: string, asignadoA: string): Promise<TareaConAsignado>;
  cambiarEstado(id: string, estado: TareaEstado): Promise<Tarea>;
}
