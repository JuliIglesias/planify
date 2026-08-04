/**
 * Entidades del dominio.
 *
 * Son tipos propios, no los que genera Prisma. La razón: si mañana se cambia
 * de ORM (o se agrega un caché, o una API externa), los servicios no se enteran.
 * Solo `src/infrastructure/` conoce Prisma.
 *
 * Los montos viajan como `string` decimal ("1234.56") en vez de `number` para
 * no perder precisión — el cálculo real se hace en centavos enteros dentro del
 * motor de deudas (NFR#4, exactitud financiera).
 */

export type EventoEstado = 'planificacion' | 'confirmado' | 'cancelado' | 'finalizado';
export type AsistenciaEstado = 'sin_confirmar' | 'confirmado' | 'rechazado';
export type TareaEstado = 'no_asignado' | 'pendiente' | 'completado';
export type DeudaEstado = 'pagar' | 'pendiente' | 'saldado';
export type AmistadEstado = 'pendiente' | 'aceptada';

export interface Usuario {
  id: string;
  nombre: string;
  email: string;
  passwordHash: string;
  avatarUrl: string | null;
  idiomaPreferido: string;
  createdAt: Date;
}

export interface Grupo {
  id: string;
  nombre: string;
  avatarUrl: string | null;
  createdAt: Date;
}

export interface MiembroGrupo {
  id: string;
  grupoId: string;
  usuarioId: string;
  fechaUnion: Date;
}

export interface Evento {
  id: string;
  grupoId: string;
  nombre: string;
  lugarTexto: string;
  estado: EventoEstado;
  fechaHoraInicio: Date | null;
  /** Item 5 — fin del rango horario confirmado (ver docs/adrs/0002-rango-horario-evento.md). */
  fechaHoraFin: Date | null;
  creadoPor: string;
  createdAt: Date;
}

export interface Participante {
  id: string;
  eventoId: string;
  usuarioId: string | null;
  nombreDisplay: string;
  esAnonimo: boolean;
  esOrganizador: boolean;
  tokenSesion: string | null;
  estadoAsistencia: AsistenciaEstado;
  ultimaLecturaAt: Date | null;
  createdAt: Date;
}

export interface Invitacion {
  id: string;
  eventoId: string;
  tokenUnico: string;
  expiraEn: Date | null;
  usosMaximos: number | null;
}

export interface DisponibilidadSlot {
  id: string;
  participanteId: string;
  eventoId: string;
  diaSemana: number;
  bloqueHora: number;
}

export interface Tarea {
  id: string;
  eventoId: string;
  titulo: string;
  estado: TareaEstado;
  asignadoA: string | null;
  creadoPor: string;
  createdAt: Date;
}

export interface Gasto {
  id: string;
  eventoId: string;
  descripcion: string;
  montoTotal: string;
  creadoPor: string;
  fecha: Date;
}

export interface MontoParticipante {
  participanteId: string;
  monto: string;
}

export interface GastoCompleto extends Gasto {
  acreedores: MontoParticipante[];
  deudores: MontoParticipante[];
}

export interface DeudaSimplificada {
  id: string;
  eventoId: string;
  deudorParticipanteId: string;
  acreedorParticipanteId: string;
  monto: string;
  estado: DeudaEstado;
  saldadoEn: Date | null;
}

export interface LogActividad {
  id: string;
  eventoId: string;
  tipo: string;
  actorParticipanteId: string;
  payload: Record<string, unknown> | null;
  createdAt: Date;
}

export interface Amistad {
  id: string;
  usuarioId1: string;
  usuarioId2: string;
  estado: AmistadEstado;
  createdAt: Date;
}

/** Referencia liviana a una persona, para mostrar en listas. */
export interface PersonaRef {
  id: string;
  nombre: string;
}

/**
 * Item 3 (Fase 4) — resultado de buscar gente para agregar de amiga. Lleva
 * el email además del nombre porque el nombre no es único: la pantalla de
 * Amigos lo muestra en gris debajo para desambiguar entre resultados
 * parecidos, sin necesidad de un campo "username" separado.
 */
export interface PersonaBusqueda extends PersonaRef {
  email: string;
}
