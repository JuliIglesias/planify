/**
 * Tipos de actividad del evento (SCRUM-13).
 *
 * Agregar uno nuevo es sumar una constante acá y emitirla donde corresponda:
 * ni el repositorio ni la pantalla necesitan cambiar (principio abierto/cerrado).
 * El texto que ve el usuario se resuelve en el cliente vía i18n, así que el
 * backend nunca manda strings traducidos.
 */
export const ActivityType = {
  eventoCreado: 'evento_creado',
  horarioConfirmado: 'horario_confirmado',
  eventoCancelado: 'evento_cancelado',
  asistenciaConfirmada: 'asistencia_confirmada',
  disponibilidadCargada: 'disponibilidad_cargada',
  gastoAgregado: 'gasto_agregado',
  deudaSaldada: 'deuda_saldada',
  tareaCreada: 'tarea_creada',
  tareaAsignada: 'tarea_asignada',
  tareaCompletada: 'tarea_completada',
  participanteSeUnio: 'participante_se_unio',
  gastosCerrados: 'gastos_cerrados',
} as const;

export type ActivityTypeValue = (typeof ActivityType)[keyof typeof ActivityType];
