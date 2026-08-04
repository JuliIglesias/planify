import { PrismaClient } from '@prisma/client';

import {
  BcryptPasswordHasher,
  ConsolePushNotifier,
  InMemoryDeviceRegistry,
  JwtTokenService,
  SystemClock,
  UuidGenerator,
} from './infrastructure/servicios-externos';
import { PrismaUsuarioRepository } from './infrastructure/prisma/usuario.prisma.repository';
import { PrismaAmistadRepository } from './infrastructure/prisma/amistad.prisma.repository';
import { PrismaGrupoRepository } from './infrastructure/prisma/grupo.prisma.repository';
import { PrismaEventoRepository } from './infrastructure/prisma/evento.prisma.repository';
import { PrismaParticipanteRepository } from './infrastructure/prisma/participante.prisma.repository';
import { PrismaInvitacionRepository } from './infrastructure/prisma/invitacion.prisma.repository';
import { PrismaDisponibilidadRepository } from './infrastructure/prisma/disponibilidad.prisma.repository';
import { PrismaTareaRepository } from './infrastructure/prisma/tarea.prisma.repository';
import { PrismaGastoRepository } from './infrastructure/prisma/gasto.prisma.repository';
import { PrismaDeudaRepository } from './infrastructure/prisma/deuda.prisma.repository';
import { PrismaLogActividadRepository } from './infrastructure/prisma/log-actividad.prisma.repository';
import { PrismaProfileAvailabilityRepository } from './infrastructure/prisma/profile-availability.prisma.repository';
import { PrismaLocationRepository } from './infrastructure/prisma/location.prisma.repository';
import { S3ImageStorageRepository } from './infrastructure/aws/s3-image-storage.repository';

import { ActivityLogService } from './modules/activity-log/activity-log.service';
import { AuthService } from './modules/auth/auth.service';
import { FriendsService } from './modules/friends/friends.service';
import { FriendProfileService } from './modules/friends/friend-profile.service';
import { UsersService } from './modules/users/users.service';
import { NotificationsService } from './modules/notifications/notifications.service';
import { AiEventsService } from './modules/ai-events/ai-events.service';
import { ProfileAvailabilityService } from './modules/profile/profile-availability.service';
import { LocationsService } from './modules/profile/locations.service';
import {
  GeminiEventGenerator,
  HeuristicEventGenerator,
} from './infrastructure/ai/event-generators';
import { AvailabilityService } from './modules/availability/availability.service';
import { DebtsService } from './modules/debts/debts.service';
import { EventsService } from './modules/events/events.service';
import { EventsQueryService } from './modules/events/events.queries';
import { ExpensesService } from './modules/expenses/expenses.service';
import { GroupsService } from './modules/groups/groups.service';
import { InvitationsService } from './modules/invitations/invitations.service';
import { ParticipantsService } from './modules/participants/participants.service';
import { TasksService } from './modules/tasks/tasks.service';
import { TokenService } from './domain/repositories';
import { RequestHandler } from 'express';
import { crearOrganizerGuard, crearParticipantGuard } from './middlewares/guards';

/**
 * Composition root: el ÚNICO lugar donde se decide qué implementación concreta
 * usa cada servicio.
 *
 * Cambiar de Prisma a otro ORM, o de JWT propio a Cognito (SCRUM-14), es tocar
 * este archivo y nada más — ningún servicio conoce a sus dependencias reales.
 */
export interface Container {
  prisma: PrismaClient;
  tokens: TokenService;
  /** Guards ya cableados con sus dependencias, listos para montar en las rutas. */
  guards: {
    soloOrganizador: RequestHandler;
    soloParticipante: RequestHandler;
  };
  auth: AuthService;
  friends: FriendsService;
  friendProfile: FriendProfileService;
  users: UsersService;
  notifications: NotificationsService;
  aiEvents: AiEventsService;
  profileAvailability: ProfileAvailabilityService;
  locations: LocationsService;
  participants: ParticipantsService;
  invitations: InvitationsService;
  events: EventsService;
  eventsQuery: EventsQueryService;
  availability: AvailabilityService;
  groups: GroupsService;
  tasks: TasksService;
  expenses: ExpensesService;
  debts: DebtsService;
  activityLog: ActivityLogService;
}

export function createContainer(prisma: PrismaClient): Container {
  // ── Servicios externos ──────────────────────────────────────────────────
  const clock = new SystemClock();
  const ids = new UuidGenerator();
  const hasher = new BcryptPasswordHasher();
  const tokens = new JwtTokenService(
    process.env.JWT_SECRET ?? 'dev-secret-change-me',
    process.env.JWT_EXPIRES_IN ?? '7d',
  );

  // ── Repositorios ────────────────────────────────────────────────────────
  const usuarios = new PrismaUsuarioRepository(prisma);
  const amistades = new PrismaAmistadRepository(prisma);
  const grupos = new PrismaGrupoRepository(prisma);
  const eventos = new PrismaEventoRepository(prisma);
  const participantes = new PrismaParticipanteRepository(prisma);
  const invitaciones = new PrismaInvitacionRepository(prisma);
  const disponibilidad = new PrismaDisponibilidadRepository(prisma);
  const disponibilidadPerfil = new PrismaProfileAvailabilityRepository(prisma);
  const ubicaciones = new PrismaLocationRepository(prisma);
  const tareas = new PrismaTareaRepository(prisma);
  const gastos = new PrismaGastoRepository(prisma);
  const deudas = new PrismaDeudaRepository(prisma);
  const logs = new PrismaLogActividadRepository(prisma);

  // ── Servicios externos de notificaciones (SCRUM-15) ──────────────────────
  // Implementaciones por defecto: loguean el push y guardan devices en memoria.
  // En producción se reemplazan por SNS/Pinpoint tocando solo estas dos líneas.
  const push = new ConsolePushNotifier();
  const deviceRegistry = new InMemoryDeviceRegistry();

  // ── Almacenamiento de imágenes (Tanda 6, Item 5) ─────────────────────────
  // Mismo cliente S3 para AWS real y para LocalStack en desarrollo: solo
  // cambia el endpoint (AWS_S3_ENDPOINT vacío en prod, LocalStack en local).
  const imagenes = new S3ImageStorageRepository({
    bucket: process.env.AWS_S3_BUCKET ?? 'planify-dev',
    region: process.env.AWS_REGION ?? 'us-east-1',
    endpoint: process.env.AWS_S3_ENDPOINT || undefined,
    forcePathStyle: process.env.AWS_S3_FORCE_PATH_STYLE === 'true',
    publicBaseUrl: process.env.AWS_S3_PUBLIC_BASE_URL || undefined,
    accessKeyId: process.env.AWS_ACCESS_KEY_ID || undefined,
    secretAccessKey: process.env.AWS_SECRET_ACCESS_KEY || undefined,
  });

  // ── Servicios de negocio ────────────────────────────────────────────────
  const notifications = new NotificationsService(participantes, deviceRegistry, push);
  const activityLog = new ActivityLogService(logs, participantes, clock, notifications);

  // Generador de eventos por IA (SCRUM-17): Gemini si hay API key, si no la
  // heurística offline. Ambos cumplen el mismo contrato (Duda #21).
  const heuristico = new HeuristicEventGenerator();
  const eventGenerator = process.env.GEMINI_API_KEY
    ? new GeminiEventGenerator(process.env.GEMINI_API_KEY, heuristico)
    : heuristico;

  const auth = new AuthService(usuarios, participantes, hasher, tokens);
  const friends = new FriendsService(amistades, usuarios);
  const friendProfile = new FriendProfileService(
    amistades,
    usuarios,
    disponibilidadPerfil,
    grupos,
    participantes,
    eventos,
  );
  const users = new UsersService(usuarios);
  const aiEvents = new AiEventsService(eventGenerator, amistades);
  const profileAvailability = new ProfileAvailabilityService(disponibilidadPerfil);
  const locations = new LocationsService(ubicaciones);
  const participants = new ParticipantsService(participantes, usuarios, eventos, ids, activityLog);
  const invitations = new InvitationsService(invitaciones, eventos, ids, clock);
  const events = new EventsService(eventos, grupos, participantes, usuarios, activityLog, clock);
  const eventsQuery = new EventsQueryService(eventos, participantes, deudas, tareas, gastos, clock);
  const availability = new AvailabilityService(disponibilidad, eventos, events, activityLog);
  const groups = new GroupsService(
    grupos,
    eventos,
    usuarios,
    tareas,
    gastos,
    activityLog,
    clock,
    participantes,
    invitations,
    disponibilidadPerfil,
    imagenes,
  );
  const tasks = new TasksService(tareas, eventos, participantes, activityLog);
  const debts = new DebtsService(
    deudas,
    gastos,
    participantes,
    eventos,
    activityLog,
    clock,
  );
  const expenses = new ExpensesService(
    gastos,
    eventos,
    participantes,
    debts,
    events,
    activityLog,
  );

  return {
    prisma,
    tokens,
    guards: {
      soloOrganizador: crearOrganizerGuard(tokens),
      soloParticipante: crearParticipantGuard(tokens, participantes),
    },
    auth,
    friends,
    friendProfile,
    users,
    notifications,
    aiEvents,
    profileAvailability,
    locations,
    participants,
    invitations,
    events,
    eventsQuery,
    availability,
    groups,
    tasks,
    expenses,
    debts,
    activityLog,
  };
}
