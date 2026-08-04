import { Prisma } from '@prisma/client';
import * as D from '../../domain/entities';

/**
 * Traducción entre las filas de Prisma y las entidades del dominio.
 * Concentrar acá las conversiones evita que cada repositorio invente la suya
 * y que detalles del ORM (Decimal, JsonValue) se filtren a los servicios.
 */

/** Prisma devuelve Decimal; el dominio usa string para no perder precisión. */
export const decimalToString = (valor: Prisma.Decimal): string => valor.toString();

export function toUsuario(row: {
  id: string;
  username: string;
  email: string;
  passwordHash: string;
  avatarUrl: string | null;
  idiomaPreferido: string;
  createdAt: Date;
}): D.Usuario {
  return { ...row };
}

export function toEvento(row: {
  id: string;
  grupoId: string;
  nombre: string;
  lugarTexto: string;
  estado: string;
  fechaHoraInicio: Date | null;
  creadoPor: string;
  createdAt: Date;
}): D.Evento {
  return { ...row, estado: row.estado as D.EventoEstado };
}

export function toParticipante(row: {
  id: string;
  eventoId: string;
  usuarioId: string | null;
  username: string;
  esAnonimo: boolean;
  esOrganizador: boolean;
  tokenSesion: string | null;
  estadoAsistencia: string;
  ultimaLecturaAt: Date | null;
  createdAt: Date;
}): D.Participante {
  return { ...row, estadoAsistencia: row.estadoAsistencia as D.AsistenciaEstado };
}

export function toTarea(row: {
  id: string;
  eventoId: string;
  titulo: string;
  estado: string;
  asignadoA: string | null;
  creadoPor: string;
  createdAt: Date;
}): D.Tarea {
  return { ...row, estado: row.estado as D.TareaEstado };
}

export function toDeuda(row: {
  id: string;
  eventoId: string;
  deudorParticipanteId: string;
  acreedorParticipanteId: string;
  monto: Prisma.Decimal;
  estado: string;
  saldadoEn: Date | null;
}): D.DeudaSimplificada {
  return {
    ...row,
    monto: decimalToString(row.monto),
    estado: row.estado as D.DeudaEstado,
  };
}

export function toLogActividad(row: {
  id: string;
  eventoId: string;
  tipo: string;
  actorParticipanteId: string;
  payload: Prisma.JsonValue;
  createdAt: Date;
}): D.LogActividad {
  return {
    ...row,
    payload:
      row.payload && typeof row.payload === 'object' && !Array.isArray(row.payload)
        ? (row.payload as Record<string, unknown>)
        : null,
  };
}
