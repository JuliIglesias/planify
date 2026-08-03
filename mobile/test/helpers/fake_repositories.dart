import 'package:planify/core/models/models.dart';
import 'package:planify/features/auth/data/auth_repository.dart';
import 'package:planify/features/balances/data/balances_repository.dart';
import 'package:planify/features/events/data/activity_log_repository.dart';
import 'package:planify/features/events/data/availability_repository.dart';
import 'package:planify/features/events/data/events_repository.dart';
import 'package:planify/features/events/data/expenses_repository.dart';
import 'package:planify/features/events/data/tasks_repository.dart';
import 'package:planify/features/groups/data/groups_repository.dart';

/// Repositorios falsos para los tests de pantalla.
///
/// Existen gracias a que las pantallas dependen de las interfaces y no de Dio:
/// se puede probar toda la UI sin red ni backend levantado.

class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({this.fallaLogin = false});

  final bool fallaLogin;
  final List<String> llamadas = [];

  @override
  Future<SesionOrganizadorDto> login(String email, String password) async {
    llamadas.add('login:$email');
    if (fallaLogin) throw Exception('Credenciales inválidas');
    return const SesionOrganizadorDto(
      token: 'token-test',
      usuarioId: 'usr-1',
      nombre: 'Julieta Iglesias',
    );
  }

  @override
  Future<SesionOrganizadorDto> register(String nombre, String email, String password) async {
    llamadas.add('register:$email');
    if (fallaLogin) throw Exception('No se pudo registrar');
    return SesionOrganizadorDto(token: 'token-test', usuarioId: 'usr-1', nombre: nombre);
  }

  @override
  Future<SesionAnonimaDto> unirseComoAnonimo({
    required String eventoId,
    required String nombreDisplay,
  }) async {
    llamadas.add('anonimo:$eventoId:$nombreDisplay');
    return const SesionAnonimaDto(participanteId: 'part-1', tokenSesion: 'tok-anon');
  }

  @override
  Future<String> resolverInvitacion(String token) async => 'evt-1';

  @override
  Future<String> unirseConInvitacion(String token) async {
    llamadas.add('unirseConInvitacion:$token');
    return 'evt-1';
  }
}

class FakeEventsRepository implements EventsRepository {
  FakeEventsRepository({
    this.eventos = const [],
    this.historialEventos = const [],
    DetalleEvento? detalleEvento,
  }) : detalleEvento = detalleEvento ?? detalleDeEjemplo();

  List<EventoResumen> eventos;
  List<EventoHistorial> historialEventos;
  DetalleEvento detalleEvento;
  final List<String> llamadas = [];

  static DetalleEvento detalleDeEjemplo({
    String estado = 'planificacion',
    List<Tarea> tareas = const [],
    bool conOrganizador = true,
    // Por defecto la muestra es la vista del organizador; los tests del caso
    // anónimo pasan soyOrganizador: false (H-04).
    bool? soyOrganizador,
    // Item 4 — para testear qué respondió "yo" en asistencia.
    String miEstadoAsistencia = 'confirmado',
  }) =>
      DetalleEvento(
        id: 'evt-1',
        nombre: 'Asado en lo de Marcos',
        lugarTexto: 'Casa de Nacho',
        estado: estado,
        miParticipanteId: 'part-1',
        soyOrganizador: soyOrganizador ?? conOrganizador,
        participantes: [
          if (conOrganizador)
            Participante(
              id: 'part-1',
              nombreDisplay: 'Marcos',
              esOrganizador: true,
              estadoAsistencia: miEstadoAsistencia,
            ),
          const Participante(id: 'part-2', nombreDisplay: 'Sofía', esAnonimo: true),
        ],
        tareas: tareas,
      );

  @override
  Future<List<EventoResumen>> proximos() async => eventos;

  @override
  Future<List<EventoHistorial>> historial() async => historialEventos;

  @override
  Future<DetalleEvento> detalle(String eventoId) async => detalleEvento;

  @override
  Future<String> crear({
    required String nombre,
    required String lugarTexto,
    String? grupoId,
    String? nuevoGrupoNombre,
    List<String>? miembroUsuarioIds,
  }) async {
    llamadas.add('crear:$nombre:$lugarTexto:${grupoId ?? nuevoGrupoNombre}');
    return 'evt-nuevo';
  }

  @override
  Future<void> responderAsistencia({
    required String eventoId,
    required bool confirma,
  }) async {
    llamadas.add('asistencia:$confirma');
  }

  @override
  Future<void> cancelar(String eventoId) async => llamadas.add('cancelar:$eventoId');

  @override
  Future<String> crearInvitacion(String eventoId) async => 'inv-token';
}

class FakeAvailabilityRepository implements AvailabilityRepository {
  FakeAvailabilityRepository({
    this.slots = const [],
    this.misSlots = const [],
  });

  List<HeatmapSlot> slots;
  List<({int diaSemana, int bloqueHora})> misSlots;
  final List<String> llamadas = [];

  @override
  Future<void> guardar({
    required String eventoId,
    required List<({int diaSemana, int bloqueHora})> slots,
  }) async {
    misSlots = slots;
    llamadas.add('guardar:${slots.length}');
  }

  @override
  Future<List<({int diaSemana, int bloqueHora})>> obtenerMiDisponibilidad(String eventoId) async => misSlots;

  @override
  Future<List<HeatmapSlot>> heatmap(String eventoId) async => slots;

  @override
  Future<void> confirmarHorario({
    required String eventoId,
    required DateTime fechaHoraInicio,
  }) async {
    llamadas.add('confirmar:${fechaHoraInicio.toIso8601String()}');
  }
}

class FakeTasksRepository implements TasksRepository {
  FakeTasksRepository({this.tareas = const []});

  List<Tarea> tareas;
  final List<String> llamadas = [];

  @override
  Future<List<Tarea>> listar(String eventoId) async => tareas;

  @override
  Future<void> crear({required String eventoId, required String titulo}) async {
    llamadas.add('crear:$titulo');
  }

  @override
  Future<void> asignar({
    required String eventoId,
    required String tareaId,
    String? asignadoA,
  }) async {
    llamadas.add('asignar:$tareaId:${asignadoA ?? "yo"}');
  }

  @override
  Future<void> completar({required String eventoId, required String tareaId}) async {
    llamadas.add('completar:$tareaId');
  }
}

class FakeExpensesRepository implements ExpensesRepository {
  final List<String> llamadas = [];

  @override
  Future<void> crear({
    required String eventoId,
    required String descripcion,
    required String montoTotal,
    required List<AporteGasto> acreedores,
    List<AporteGasto>? deudores,
    List<String>? dividirEntre,
  }) async {
    llamadas.add('gasto:$descripcion:$montoTotal:${acreedores.first.participanteId}');
  }

  @override
  Future<void> cerrar(String eventoId) async => llamadas.add('cerrar:$eventoId');
}


class FakeActivityLogRepository implements ActivityLogRepository {
  FakeActivityLogRepository({this.entradas = const [], this.recientesEntradas = const []});

  List<ActividadLog> entradas;
  List<ActividadLog> recientesEntradas;

  @override
  Future<List<ActividadLog>> listar(String eventoId) async => entradas;

  @override
  Future<List<ActividadLog>> recientes() async => recientesEntradas;

  @override
  Future<Map<String, int>> noLeidas() async => const {};
}

class FakeBalancesRepository implements BalancesRepository {
  FakeBalancesRepository({
    this.balance = Balance.empty,
    this.deudas = const [],
    DetalleConPersona? detalle,
  }) : detalle = detalle ?? detalleDeEjemplo();

  Balance balance;
  List<DeudaEvento> deudas;
  DetalleConPersona detalle;
  final List<String> llamadas = [];

  /// Escenario típico de compensación cruzada (FR9): debo $500 en el asado y
  /// me deben $300 en el cine, así que quedan $200 a pagar.
  static DetalleConPersona detalleDeEjemplo() => const DetalleConPersona(
        personaId: 'usr-marcos',
        nombre: 'Marcos',
        monto: '200.00',
        estado: 'pagar',
        totalQueDebo: '500.00',
        totalQueMeDebe: '300.00',
        deudas: [
          DeudaDeEvento(
            id: 'd1',
            eventoId: 'e1',
            eventoNombre: 'Asado',
            monto: '500.00',
            yoDebo: true,
          ),
          DeudaDeEvento(
            id: 'd2',
            eventoId: 'e2',
            eventoNombre: 'Cine',
            monto: '300.00',
            yoDebo: false,
          ),
        ],
      );

  @override
  Future<Balance> miBalance() async => balance;

  @override
  Future<DetalleConPersona> detalleConPersona(String personaId) async {
    llamadas.add('detalle:$personaId');
    return detalle;
  }

  @override
  Future<void> saldarConPersona(String personaId) async {
    llamadas.add('saldarPersona:$personaId');
  }

  @override
  Future<List<DeudaEvento>> deudasDelEvento(String eventoId) async => deudas;

  @override
  Future<void> saldar({required String eventoId, required String deudaId}) async {
    llamadas.add('saldar:$deudaId');
  }
}

class FakeGroupsRepository implements GroupsRepository {
  FakeGroupsRepository({this.grupos = const []});

  List<GrupoResumen> grupos;
  final List<String> llamadas = [];

  @override
  Future<List<GrupoResumen>> resumen() async => grupos;

  @override
  Future<List<GrupoResumen>> mios() async => grupos;

  @override
  Future<void> renombrar({required String grupoId, required String nombre}) async {
    llamadas.add('renombrar:$grupoId:$nombre');
  }

  @override
  Future<void> agregarMiembro({
    required String grupoId,
    required String usuarioId,
  }) async {
    llamadas.add('agregar:$grupoId:$usuarioId');
  }

  @override
  Future<void> abandonar(String grupoId) async => llamadas.add('abandonar:$grupoId');
}
