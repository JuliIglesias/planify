import 'package:planify/core/models/models.dart';
import 'package:planify/features/auth/data/auth_repository.dart';
import 'package:planify/features/balances/data/balances_repository.dart';
import 'package:planify/features/events/data/activity_log_repository.dart';
import 'package:planify/features/events/data/availability_repository.dart';
import 'package:planify/features/events/data/events_repository.dart';
import 'package:planify/features/events/data/expenses_repository.dart';
import 'package:planify/features/events/data/tasks_repository.dart';
import 'package:planify/features/friends/data/friends_repository.dart';
import 'package:planify/features/groups/data/groups_repository.dart';
import 'package:planify/features/profile/data/profile_repository.dart';

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
      username: 'julieta_iglesias',
    );
  }

  @override
  Future<SesionOrganizadorDto> register(String username, String email, String password) async {
    llamadas.add('register:$email');
    if (fallaLogin) throw Exception('No se pudo registrar');
    return SesionOrganizadorDto(token: 'token-test', usuarioId: 'usr-1', username: username);
  }

  @override
  Future<SesionAnonimaDto> unirseComoAnonimo({
    required String eventoId,
    required String username,
  }) async {
    llamadas.add('anonimo:$eventoId:$username');
    return SesionAnonimaDto(participanteId: 'part-1', tokenSesion: 'tok-anon', username: username);
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
    // Item 5 — para testear el horario ya fijado por el organizador.
    DateTime? fechaHoraInicio,
    // Item 2 — para testear que un nombre largo se muestra completo.
    String nombre = 'Asado en lo de Marcos',
    // Item 1 — rango de fechas calendario del evento.
    DateTime? rangoInicio,
    DateTime? rangoFin,
    bool necesitaDecisionRango = false,
    DateTime? fechaHoraFin,
  }) =>
      DetalleEvento(
        id: 'evt-1',
        grupoId: 'g1',
        nombre: nombre,
        lugarTexto: 'Casa de Nacho',
        estado: estado,
        fechaHoraInicio: fechaHoraInicio,
        rangoInicio: rangoInicio ?? DateTime(2026, 8, 1),
        rangoFin: rangoFin ?? DateTime(2026, 8, 20),
        necesitaDecisionRango: necesitaDecisionRango,
        fechaHoraFin: fechaHoraFin,
        miParticipanteId: 'part-1',
        soyOrganizador: soyOrganizador ?? conOrganizador,
        participantes: [
          if (conOrganizador)
            Participante(
              id: 'part-1',
              username: 'Marcos',
              esOrganizador: true,
              estadoAsistencia: miEstadoAsistencia,
            ),
          const Participante(id: 'part-2', username: 'Sofía', esAnonimo: true),
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
    required DateTime rangoInicio,
    required DateTime rangoFin,
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
    this.enRango = (disponibles: 0, total: 0),
  });

  List<HeatmapSlot> slots;
  List<({int diaSemana, int bloqueHora})> misSlots;
  // Item 5 — resultado fijo que devuelve disponiblesEnRango en los tests.
  ({int disponibles, int total}) enRango;
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
  Future<({int disponibles, int total})> disponiblesEnRango({
    required String eventoId,
    required int diaSemana,
    required int horaInicio,
    required int horaFin,
  }) async {
    llamadas.add('disponiblesEnRango:$diaSemana:$horaInicio:$horaFin');
    return enRango;
  }

  @override
  Future<void> confirmarHorario({
    required String eventoId,
    required DateTime fechaHoraInicio,
    required DateTime fechaHoraFin,
  }) async {
    llamadas.add(
      'confirmar:${fechaHoraInicio.toIso8601String()}:${fechaHoraFin.toIso8601String()}',
    );
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

  @override
  Future<void> descompletar({required String eventoId, required String tareaId}) async {
    llamadas.add('descompletar:$tareaId');
  }

  @override
  Future<void> desasignar({required String eventoId, required String tareaId}) async {
    llamadas.add('desasignar:$tareaId');
  }

  @override
  Future<void> eliminar({required String eventoId, required String tareaId}) async {
    llamadas.add('eliminar:$tareaId');
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
  FakeActivityLogRepository({
    this.entradas = const [],
    this.recientesEntradas = const [],
    this.pageSize = 20,
  });

  List<ActividadLog> entradas;
  List<ActividadLog> recientesEntradas;
  final int pageSize;

  /// Tanda 6, Item 2 — cada cursor pedido, para verificar la paginación.
  final List<DateTime?> llamadasRecientes = [];

  @override
  Future<List<ActividadLog>> listar(String eventoId) async => entradas;

  @override
  Future<List<ActividadLog>> recientes({DateTime? before}) async {
    llamadasRecientes.add(before);
    final ordenadas = [...recientesEntradas]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final filtradas =
        before == null ? ordenadas : ordenadas.where((e) => e.createdAt.isBefore(before)).toList();
    return filtradas.take(pageSize).toList();
  }

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
        username: 'Marcos',
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
  Future<void> actualizar({
    required String grupoId,
    String? nombre,
  }) async {
    llamadas.add('actualizar:$grupoId:$nombre');
  }

  @override
  Future<void> subirImagen({
    required String grupoId,
    required List<int> bytes,
    required String nombreArchivo,
  }) async {
    llamadas.add('subirImagen:$grupoId:$nombreArchivo');
  }

  DisponibilidadDeGrupo disponibilidad =
      const DisponibilidadDeGrupo(totalPersonas: 0, slots: []);

  @override
  Future<DisponibilidadDeGrupo> disponibilidadDeGrupo(String grupoId) async {
    llamadas.add('disponibilidadDeGrupo:$grupoId');
    return disponibilidad;
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

/// Tanda 6, Item 5 — ya no expone coincidencias con "todos los amigos" (eso
/// se eliminó de Perfil); solo la disponibilidad semanal individual y
/// ubicaciones favoritas.
class FakeProfileRepository implements ProfileRepository {
  FakeProfileRepository({List<SlotSimple>? slots}) : slots = slots ?? const [];

  List<SlotSimple> slots;
  final List<UbicacionFavorita> ubicaciones = [];
  final List<String> llamadas = [];

  @override
  Future<List<SlotSimple>> obtenerDisponibilidad() async => slots;

  @override
  Future<void> guardarDisponibilidad(List<SlotSimple> nuevos) async {
    slots = nuevos;
    llamadas.add('guardarDisponibilidad:${nuevos.length}');
  }

  @override
  Future<List<UbicacionFavorita>> listarUbicaciones() async => ubicaciones;

  @override
  Future<UbicacionFavorita> crearUbicacion(String etiqueta, String texto) async {
    final u = UbicacionFavorita(id: 'ubi-${ubicaciones.length + 1}', etiqueta: etiqueta, texto: texto);
    ubicaciones.add(u);
    return u;
  }

  @override
  Future<void> eliminarUbicacion(String id) async {
    ubicaciones.removeWhere((u) => u.id == id);
  }
}

class FakeFriendsRepository implements FriendsRepository {
  FakeFriendsRepository({
    this.resultadosBusqueda = const [],
    this.amigos = const [],
    this.solicitudes = const [],
    this.enviadas = const [],
    PerfilAmigo? perfil,
  }) : perfil = perfil ?? perfilDeEjemplo();

  List<Persona> resultadosBusqueda;
  List<Persona> amigos;
  List<SolicitudAmistad> solicitudes;
  /// F1 — semilla de `solicitudesEnviadas()` (nombre distinto al del método
  /// de la interfaz, que Dart no permite reusar para un campo).
  List<SolicitudEnviada> enviadas;
  PerfilAmigo perfil;
  final List<String> llamadas = [];

  static PerfilAmigo perfilDeEjemplo({
    Persona persona = const Persona(id: 'u2', username: 'Sofía', email: 'sofia@mail.com'),
    List<SlotComparado> heatmapComparado = const [],
    List<EventoCompartido> eventosEnComun = const [],
    List<GrupoCompartido> gruposEnComun = const [],
  }) =>
      PerfilAmigo(
        persona: persona,
        heatmapComparado: heatmapComparado,
        eventosEnComun: eventosEnComun,
        gruposEnComun: gruposEnComun,
      );

  @override
  Future<List<Persona>> buscar(String query) async {
    llamadas.add('buscar:$query');
    return resultadosBusqueda;
  }

  @override
  Future<List<Persona>> listar() async => amigos;

  @override
  Future<List<SolicitudAmistad>> solicitudesPendientes() async => solicitudes;

  @override
  Future<List<SolicitudEnviada>> solicitudesEnviadas() async => enviadas;

  @override
  Future<void> enviarSolicitud(String usuarioId) async {
    llamadas.add('enviarSolicitud:$usuarioId');
  }

  @override
  Future<void> aceptar(String amistadId) async {
    llamadas.add('aceptar:$amistadId');
  }

  @override
  Future<PerfilAmigo> perfilDe(String usuarioId) async {
    llamadas.add('perfilDe:$usuarioId');
    return perfil;
  }
}
