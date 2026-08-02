import { PrismaClient } from '@prisma/client';

import {
  BcryptPasswordHasher,
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

import { ActivityLogService } from './modules/activity-log/activity-log.service';
import { AuthService } from './modules/auth/auth.service';
import { AvailabilityService } from './modules/availability/availability.service';
import { DebtsService } from './modules/debts/debts.service';
import { EventsService } from './modules/events/events.service';
import { EventsQueryService } from './modules/events/events.queries';
import { ExpensesService } from './modules/expenses/expenses.service';
import { GroupsService } from './modules/groups/groups.service';
import { InvitationsService } from './modules/invitations/invitations.service';
import { ParticipantsService } from './modules/participants/participants.service';
import { TasksService } from './modules/tasks/tasks.service';
import { UsersService } from './modules/users/users.service';
import { FriendsService } from './modules/friends/friends.service';
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
  users: UsersService;
  friends: FriendsService;
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
  const tareas = new PrismaTareaRepository(prisma);
  const gastos = new PrismaGastoRepository(prisma);
  const deudas = new PrismaDeudaRepository(prisma);
  const logs = new PrismaLogActividadRepository(prisma);

  // ── Servicios de negocio ────────────────────────────────────────────────
  const activityLog = new ActivityLogService(logs, participantes, clock);

  const auth = new AuthService(usuarios, hasher, tokens);
  const users = new UsersService(usuarios);
  const friends = new FriendsService(amistades, usuarios);
  const participants = new ParticipantsService(participantes, eventos, ids, activityLog);
  const invitations = new InvitationsService(invitaciones, eventos, ids, clock);
  const events = new EventsService(eventos, grupos, participantes, usuarios, activityLog);
  const eventsQuery = new EventsQueryService(eventos, participantes, deudas, tareas, gastos);
  const availability = new AvailabilityService(disponibilidad, eventos, events, activityLog);
  const groups = new GroupsService(
    grupos,
    eventos,
    usuarios,
    tareas,
    gastos,
    activityLog,
    clock,
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
    users,
    friends,
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
