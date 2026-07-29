/// Modelos de dominio de la app. Se parsean a mano (sin codegen) para que el
/// equipo pueda leer exactamente qué llega de la API mientras aprende el stack.
library;

class Participante {
  const Participante({
    required this.id,
    required this.nombreDisplay,
    this.estadoAsistencia = 'sin_confirmar',
    this.esOrganizador = false,
  });

  final String id;
  final String nombreDisplay;
  final String estadoAsistencia;
  final bool esOrganizador;

  factory Participante.fromJson(Map<String, dynamic> json) => Participante(
        id: json['id'] as String,
        nombreDisplay: json['nombreDisplay'] as String? ?? '',
        estadoAsistencia: json['estadoAsistencia'] as String? ?? 'sin_confirmar',
        esOrganizador: json['esOrganizador'] as bool? ?? false,
      );
}

class EventoResumen {
  const EventoResumen({
    required this.id,
    required this.nombre,
    required this.lugarTexto,
    required this.estado,
    required this.participantes,
    this.fechaHoraInicio,
    this.grupoNombre,
    this.confirmados = 0,
  });

  final String id;
  final String nombre;
  final String lugarTexto;
  final String estado;
  final List<Participante> participantes;
  final DateTime? fechaHoraInicio;
  final String? grupoNombre;
  final int confirmados;

  factory EventoResumen.fromJson(Map<String, dynamic> json) => EventoResumen(
        id: json['id'] as String,
        nombre: json['nombre'] as String? ?? '',
        lugarTexto: json['lugarTexto'] as String? ?? '',
        estado: json['estado'] as String? ?? 'planificacion',
        fechaHoraInicio: json['fechaHoraInicio'] != null
            ? DateTime.tryParse(json['fechaHoraInicio'] as String)
            : null,
        grupoNombre: (json['grupo'] as Map<String, dynamic>?)?['nombre'] as String?,
        confirmados: json['confirmados'] as int? ?? 0,
        participantes: ((json['participantes'] as List<dynamic>?) ?? [])
            .map((p) => Participante.fromJson(p as Map<String, dynamic>))
            .toList(),
      );
}

class GrupoResumen {
  const GrupoResumen({
    required this.id,
    required this.nombre,
    required this.miembros,
    this.noLeidos = 0,
    this.tieneEventoNuevo = false,
    this.proximoEvento,
  });

  final String id;
  final String nombre;
  final List<String> miembros;
  final int noLeidos;
  final bool tieneEventoNuevo;
  final ProximoEvento? proximoEvento;

  factory GrupoResumen.fromJson(Map<String, dynamic> json) => GrupoResumen(
        id: json['id'] as String,
        nombre: json['nombre'] as String? ?? '',
        miembros: ((json['miembros'] as List<dynamic>?) ?? [])
            .map((m) => (m as Map<String, dynamic>)['nombre'] as String? ?? '')
            .toList(),
        noLeidos: json['noLeidos'] as int? ?? 0,
        tieneEventoNuevo: json['tieneEventoNuevo'] as bool? ?? false,
        proximoEvento: json['proximoEvento'] != null
            ? ProximoEvento.fromJson(json['proximoEvento'] as Map<String, dynamic>)
            : null,
      );
}

class ProximoEvento {
  const ProximoEvento({
    required this.id,
    required this.nombre,
    required this.lugarTexto,
    required this.estado,
    this.fechaHoraInicio,
    this.confirmados = 0,
    this.tareasPendientes = 0,
    this.gastos = 0,
  });

  final String id;
  final String nombre;
  final String lugarTexto;
  final String estado;
  final DateTime? fechaHoraInicio;
  final int confirmados;
  final int tareasPendientes;
  final int gastos;

  factory ProximoEvento.fromJson(Map<String, dynamic> json) => ProximoEvento(
        id: json['id'] as String,
        nombre: json['nombre'] as String? ?? '',
        lugarTexto: json['lugarTexto'] as String? ?? '',
        estado: json['estado'] as String? ?? 'planificacion',
        fechaHoraInicio: json['fechaHoraInicio'] != null
            ? DateTime.tryParse(json['fechaHoraInicio'] as String)
            : null,
        confirmados: json['confirmados'] as int? ?? 0,
        tareasPendientes: json['tareasPendientes'] as int? ?? 0,
        gastos: json['gastos'] as int? ?? 0,
      );
}

class EventoHistorial {
  const EventoHistorial({
    required this.id,
    required this.nombre,
    required this.estadoSaldo,
    required this.monto,
    required this.participantes,
    this.fechaHoraInicio,
    this.createdAt,
  });

  final String id;
  final String nombre;
  final String estadoSaldo;
  final String monto;
  final List<String> participantes;
  final DateTime? fechaHoraInicio;
  final DateTime? createdAt;

  DateTime get fechaOrdenamiento => fechaHoraInicio ?? createdAt ?? DateTime(2000);

  factory EventoHistorial.fromJson(Map<String, dynamic> json) => EventoHistorial(
        id: json['id'] as String,
        nombre: json['nombre'] as String? ?? '',
        estadoSaldo: json['estadoSaldo'] as String? ?? 'saldado',
        monto: json['monto'] as String? ?? '0.00',
        fechaHoraInicio: json['fechaHoraInicio'] != null
            ? DateTime.tryParse(json['fechaHoraInicio'] as String)
            : null,
        createdAt: json['createdAt'] != null
            ? DateTime.tryParse(json['createdAt'] as String)
            : null,
        participantes: ((json['participantes'] as List<dynamic>?) ?? [])
            .map((p) => (p as Map<String, dynamic>)['nombreDisplay'] as String? ?? '')
            .toList(),
      );
}

class Balance {
  const Balance({
    required this.balanceNeto,
    required this.meDeben,
    required this.debo,
    required this.saldos,
  });

  final String balanceNeto;
  final String meDeben;
  final String debo;
  final List<SaldoPorPersona> saldos;

  factory Balance.fromJson(Map<String, dynamic> json) => Balance(
        balanceNeto: json['balanceNeto'] as String? ?? '0.00',
        meDeben: json['meDeben'] as String? ?? '0.00',
        debo: json['debo'] as String? ?? '0.00',
        saldos: ((json['saldos'] as List<dynamic>?) ?? [])
            .map((s) => SaldoPorPersona.fromJson(s as Map<String, dynamic>))
            .toList(),
      );

  static const empty = Balance(
    balanceNeto: '0.00',
    meDeben: '0.00',
    debo: '0.00',
    saldos: [],
  );
}

class SaldoPorPersona {
  const SaldoPorPersona({
    required this.id,
    required this.nombre,
    required this.monto,
    required this.estado,
  });

  final String id;
  final String nombre;
  final String monto;
  final String estado;

  factory SaldoPorPersona.fromJson(Map<String, dynamic> json) => SaldoPorPersona(
        id: json['id'] as String,
        nombre: json['nombre'] as String? ?? '',
        monto: json['monto'] as String? ?? '0.00',
        estado: json['estado'] as String? ?? 'saldado',
      );
}

class ActividadLog {
  const ActividadLog({
    required this.id,
    required this.tipo,
    required this.actorNombre,
    required this.createdAt,
    this.payload,
  });

  final String id;
  final String tipo;
  final String actorNombre;
  final DateTime createdAt;
  final Map<String, dynamic>? payload;

  factory ActividadLog.fromJson(Map<String, dynamic> json) => ActividadLog(
        id: json['id'] as String,
        tipo: json['tipo'] as String? ?? '',
        actorNombre:
            (json['actor'] as Map<String, dynamic>?)?['nombreDisplay'] as String? ?? '',
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
        payload: json['payload'] as Map<String, dynamic>?,
      );
}

class Tarea {
  const Tarea({
    required this.id,
    required this.titulo,
    required this.estado,
    this.asignadoNombre,
  });

  final String id;
  final String titulo;
  final String estado;
  final String? asignadoNombre;

  factory Tarea.fromJson(Map<String, dynamic> json) => Tarea(
        id: json['id'] as String,
        titulo: json['titulo'] as String? ?? '',
        estado: json['estado'] as String? ?? 'no_asignado',
        asignadoNombre:
            (json['asignado'] as Map<String, dynamic>?)?['nombreDisplay'] as String?,
      );
}

class HeatmapSlot {
  const HeatmapSlot({
    required this.diaSemana,
    required this.bloqueHora,
    required this.disponibles,
  });

  final int diaSemana;
  final int bloqueHora;
  final int disponibles;

  factory HeatmapSlot.fromJson(Map<String, dynamic> json) => HeatmapSlot(
        diaSemana: json['diaSemana'] as int? ?? 0,
        bloqueHora: json['bloqueHora'] as int? ?? 0,
        disponibles: json['disponibles'] as int? ?? 0,
      );
}
