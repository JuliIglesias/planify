import { PrismaClient } from '@prisma/client';
import { Container } from '../src/container';
import { crearOrganizerGuard, crearParticipantGuard } from '../src/middlewares/guards';

import { ActivityLogService } from '../src/modules/activity-log/activity-log.service';
import { AuthService } from '../src/modules/auth/auth.service';
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
  FakeClock,
  FakeDeudaRepository,
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
    grupos: FakeGrupoRepository;
    eventos: FakeEventoRepository;
    participantes: FakeParticipanteRepository;
    invitaciones: FakeInvitacionRepository;
    disponibilidad: FakeDisponibilidadRepository;
    tareas: FakeTareaRepository;
    gastos: FakeGastoRepository;
    deudas: FakeDeudaRepository;
    logs: FakeLogActividadRepository;
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
  const grupos = new FakeGrupoRepository();
  const participantes = new FakeParticipanteRepository();
  const eventos = new FakeEventoRepository(participantes);
  const invitaciones = new FakeInvitacionRepository();
  const disponibilidad = new FakeDisponibilidadRepository();
  const tareas = new FakeTareaRepository();
  const gastos = new FakeGastoRepository();
  // Recibe los participantes para poder resolver nombre y usuarioId de cada
  // parte, que es lo que agrupa la compensación cruzada (FR9).
  const deudas = new FakeDeudaRepository(participantes);
  const logs = new FakeLogActividadRepository();

  const activityLog = new ActivityLogService(logs, participantes, clock);
  const auth = new AuthService(usuarios, hasher, tokens);
  const participants = new ParticipantsService(participantes, eventos, ids, activityLog);
  const invitations = new InvitationsService(invitaciones, eventos, ids, clock);
  const events = new EventsService(eventos, grupos, participantes, usuarios, activityLog);
  const eventsQuery = new EventsQueryService(eventos, participantes, deudas, tareas, gastos);
  const availability = new AvailabilityService(disponibilidad, eventos, events, activityLog);
  const groups = new GroupsService(grupos, eventos, usuarios, tareas, gastos, activityLog, clock);
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
      grupos,
      eventos,
      participantes,
      invitaciones,
      disponibilidad,
      tareas,
      gastos,
      deudas,
      logs,
    },
  };
}
