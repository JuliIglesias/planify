import { PrismaClient } from '@prisma/client';
import { Container } from '../src/container';
import { crearOrganizerGuard, crearParticipantGuard } from '../src/middlewares/guards';

import { ActivityLogService } from '../src/modules/activity-log/activity-log.service';
import { AuthService } from '../src/modules/auth/auth.service';
import { FriendsService } from '../src/modules/friends/friends.service';
import { UsersService } from '../src/modules/users/users.service';
import { NotificationsService } from '../src/modules/notifications/notifications.service';
import { AiEventsService } from '../src/modules/ai-events/ai-events.service';
import { HeuristicEventGenerator } from '../src/infrastructure/ai/event-generators';
import { ProfileAvailabilityService } from '../src/modules/profile/profile-availability.service';
import { LocationsService } from '../src/modules/profile/locations.service';
import { AvailabilityService } from '../src/modules/availability/availability.service';
import { DebtsService } from '../src/modules/debts/debts.service';
import { EventsService } from '../src/modules/events/events.service';
import { EventsQueryService } from '../src/modules/events/events.queries';
import { ExpensesService } from '../src/modules/expenses/expenses.service';
import { GroupsService } from '../src/modules/groups/groups.service';
import { InvitationsService } from '../src/modules/invitations/invitations.service';
import { ParticipantsService } from '../src/modules/participants/participants.service';
import { TasksService } from '../src/modules/tasks/tasks.service';

import {
  FakeAmistadRepository,
  FakeClock,
  FakeDeviceRegistry,
  FakeDeudaRepository,
  FakeLocationRepository,
  FakeProfileAvailabilityRepository,
  FakePushNotifier,
  FakeDisponibilidadRepository,
  FakeEventoRepository,
  FakeGastoRepository,
  FakeGrupoRepository,
  FakeIdGenerator,
  FakeInvitacionRepository,
  FakeLogActividadRepository,
  FakeParticipanteRepository,
  FakePasswordHasher,
  FakeTareaRepository,
  FakeTokenService,
  FakeUsuarioRepository,
} from './fakes';

export interface TestContainer {
  container: Container;
  repos: {
    usuarios: FakeUsuarioRepository;
    amistades: FakeAmistadRepository;
    grupos: FakeGrupoRepository;
    eventos: FakeEventoRepository;
    participantes: FakeParticipanteRepository;
    invitaciones: FakeInvitacionRepository;
    disponibilidad: FakeDisponibilidadRepository;
    tareas: FakeTareaRepository;
    gastos: FakeGastoRepository;
    deudas: FakeDeudaRepository;
    logs: FakeLogActividadRepository;
    push: FakePushNotifier;
  };
  clock: FakeClock;
}

/**
 * Container equivalente al de producción pero con repositorios en memoria.
 *
 * Es el mismo cableado de `src/container.ts` cambiando solo las
 * implementaciones: permite levantar la API entera en un test, sin Postgres.
 */
export function createTestContainer(): TestContainer {
  const clock = new FakeClock();
  const ids = new FakeIdGenerator();
  const hasher = new FakePasswordHasher();
  const tokens = new FakeTokenService();

  const usuarios = new FakeUsuarioRepository();
  const amistades = new FakeAmistadRepository(usuarios);
  const grupos = new FakeGrupoRepository(usuarios);
  const participantes = new FakeParticipanteRepository();
  const eventos = new FakeEventoRepository(participantes);
  const invitaciones = new FakeInvitacionRepository();
  const disponibilidad = new FakeDisponibilidadRepository();
  const disponibilidadPerfil = new FakeProfileAvailabilityRepository();
  const ubicaciones = new FakeLocationRepository();
  const tareas = new FakeTareaRepository();
  const gastos = new FakeGastoRepository();
  // Recibe los participantes para poder resolver nombre y usuarioId de cada
  // parte, que es lo que agrupa la compensación cruzada (FR9).
  const deudas = new FakeDeudaRepository(participantes);
  const logs = new FakeLogActividadRepository();

  const push = new FakePushNotifier();
  const deviceRegistry = new FakeDeviceRegistry();
  const notifications = new NotificationsService(participantes, deviceRegistry, push);
  const activityLog = new ActivityLogService(logs, participantes, clock, notifications);
  const auth = new AuthService(usuarios, hasher, tokens);
  const friends = new FriendsService(amistades, usuarios);
  const users = new UsersService(usuarios);
  const aiEvents = new AiEventsService(new HeuristicEventGenerator(), amistades);
  const profileAvailability = new ProfileAvailabilityService(disponibilidadPerfil, amistades);
  const locations = new LocationsService(ubicaciones);
  const participants = new ParticipantsService(participantes, eventos, ids, activityLog);
  const invitations = new InvitationsService(invitaciones, eventos, ids, clock);
  const events = new EventsService(eventos, grupos, participantes, usuarios, activityLog);
  const eventsQuery = new EventsQueryService(
    eventos,
    participantes,
    deudas,
    tareas,
    gastos,
    clock,
  );
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
  );
  const tasks = new TasksService(tareas, eventos, participantes, activityLog);
  const debts = new DebtsService(deudas, gastos, participantes, eventos, activityLog, clock);
  const expenses = new ExpensesService(
    gastos,
    eventos,
    participantes,
    debts,
    events,
    activityLog,
  );

  const container: Container = {
    // Ningún test toca la base: el cliente real nunca se usa.
    prisma: null as unknown as PrismaClient,
    tokens,
    guards: {
      soloOrganizador: crearOrganizerGuard(tokens),
      soloParticipante: crearParticipantGuard(tokens, participantes),
    },
    auth,
    friends,
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

  return {
    container,
    clock,
    repos: {
      usuarios,
      amistades,
      grupos,
      eventos,
      participantes,
      invitaciones,
      disponibilidad,
      tareas,
      gastos,
      deudas,
      logs,
      push,
    },
  };
}
