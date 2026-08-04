/**
 * Contratos (ports) que los servicios necesitan para hacer su trabajo.
 *
 * Cada interfaz es chica y específica del caso de uso que la consume — no hay
 * un "RepositorioDeTodo" (principio de segregación de interfaces). Los servicios
 * dependen de estos contratos, nunca de Prisma (inversión de dependencias).
 *
 * Las implementaciones concretas viven en `src/infrastructure/prisma/`.
 */
export * from './usuario.repository';
export * from './amistad.repository';
export * from './grupo.repository';
export * from './evento.repository';
export * from './participante.repository';
export * from './invitacion.repository';
export * from './disponibilidad.repository';
export * from './profile-availability.repository';
export * from './image-storage.repository';
export * from './location.repository';
export * from './tarea.repository';
export * from './gasto.repository';
export * from './deuda.repository';
export * from './log-actividad.repository';
export * from './notifications.repository';
export * from './ai-events.repository';
export * from './servicios-externos';
