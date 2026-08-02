/// Modelos de dominio de la app. Se parsean a mano (sin codegen) para que el
/// equipo pueda leer exactamente qué llega de la API mientras aprende el stack.
library;

class Participante {
  const Participante({
    required this.id,
    required this.nombreDisplay,
    this.estadoAsistencia = 'sin_confirmar',
    this.esOrganizador = false,
    this.esAnonimo = false,
  });

  final String id;
  final String nombreDisplay;
  final String estadoAsistencia;
  final bool esOrganizador;
  final bool esAnonimo;

  factory Participante.fromJson(Map<String, dynamic> json) => Participante(
        id: json['id'] as String,
        nombreDisplay: json['nombreDisplay'] as String? ?? '',
        estadoAsistencia: json['estadoAsistencia'] as String? ?? 'sin_confirmar',
        esOrganizador: json['esOrganizador'] as bool? ?? false,
        esAnonimo: json['esAnonimo'] as bool? ?? false,
      );
}

/// Detalle completo del evento, con lo que necesita la pantalla para decidir
/// qué acciones mostrar (cancelar y cerrar gastos son solo del organizador).
class DetalleEvento {
  const DetalleEvento({
    required this.id,
    required this.nombre,
    required this.lugarTexto,
    required this.estado,
    required this.participantes,
    required this.tareas,
    this.fechaHoraInicio,
    this.gastos = 0,
  });

  final String id;
  final String nombre;
  final String lugarTexto;
  final String estado;
  final List<Participante> participantes;
  final List<Tarea> tareas;
  final DateTime? fechaHoraInicio;
  final int gastos;

  bool get estaCancelado => estado == 'cancelado';
  bool get estaFinalizado => estado == 'finalizado';

  /// El participante que representa al usuario actual, si es el organizador.
  Participante? get organizador =>
      participantes.where((p) => p.esOrganizador).firstOrNull;

  factory DetalleEvento.fromJson(Map<String, dynamic> json) => DetalleEvento(
        id: json['id'] as String? ?? '',
        nombre: json['nombre'] as String? ?? '',
        lugarTexto: json['lugarTexto'] as String? ?? '',
        estado: json['estado'] as String? ?? 'planificacion',
        fechaHoraInicio: json['fechaHoraInicio'] != null
            ? DateTime.tryParse(json['fechaHoraInicio'] as String)
            : null,
        gastos: json['gastos'] as int? ?? 0,
        participantes: ((json['participantes'] as List<dynamic>?) ?? [])
            .map((p) => Participante.fromJson(p as Map<String, dynamic>))
            .toList(),
        tareas: ((json['tareas'] as List<dynamic>?) ?? [])
            .map((t) => Tarea.fromJson(t as Map<String, dynamic>))
            .toList(),
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

/// Deuda simplificada dentro de un evento (resultado del motor HU-15).
class DeudaEvento {
  const DeudaEvento({
    required this.id,
    required this.deudorId,
    required this.deudorNombre,
    required this.acreedorId,
    required this.acreedorNombre,
    required this.monto,
    required this.estado,
  });

  final String id;
  final String deudorId;
  final String deudorNombre;
  final String acreedorId;
  final String acreedorNombre;
  final String monto;
  final String estado;

  bool get estaSaldada => estado == 'saldado';

  factory DeudaEvento.fromJson(Map<String, dynamic> json) {
    final deudor = json['deudor'] as Map<String, dynamic>?;
    final acreedor = json['acreedor'] as Map<String, dynamic>?;
    return DeudaEvento(
      id: json['id'] as String,
      deudorId: json['deudorParticipanteId'] as String? ?? '',
      deudorNombre: deudor?['nombre'] as String? ?? '',
      acreedorId: json['acreedorParticipanteId'] as String? ?? '',
      acreedorNombre: acreedor?['nombre'] as String? ?? '',
      monto: json['monto'] as String? ?? '0.00',
      estado: json['estado'] as String? ?? 'pendiente',
    );
  }
}

/// Una deuda concreta de un evento, dentro del detalle con una persona (FR9).
class DeudaDeEvento {
  const DeudaDeEvento({
    required this.id,
    required this.eventoId,
    required this.eventoNombre,
    required this.monto,
    required this.yoDebo,
  });

  final String id;
  final String eventoId;
  final String eventoNombre;
  final String monto;

  /// `true` si en ESE evento la deuda es mía hacia la otra persona.
  final bool yoDebo;

  factory DeudaDeEvento.fromJson(Map<String, dynamic> json) => DeudaDeEvento(
        id: json['id'] as String,
        eventoId: json['eventoId'] as String? ?? '',
        eventoNombre: json['eventoNombre'] as String? ?? '',
        monto: json['monto'] as String? ?? '0.00',
        yoDebo: json['yoDebo'] as bool? ?? false,
      );
}

/// Relación completa con una persona: qué se debe en cada evento y cuánto
/// queda después de compensar (FR9).
class DetalleConPersona {
  const DetalleConPersona({
    required this.personaId,
    required this.nombre,
    required this.monto,
    required this.estado,
    required this.totalQueDebo,
    required this.totalQueMeDebe,
    required this.deudas,
  });

  final String personaId;
  final String nombre;

  /// Neto ya compensado, siempre positivo. El signo lo da [estado].
  final String monto;
  final String estado;
  final String totalQueDebo;
  final String totalQueMeDebe;
  final List<DeudaDeEvento> deudas;

  bool get estaSaldado => estado == 'saldado';

  /// Hay compensación real cuando hay deudas en los dos sentidos.
  bool get hayCompensacion =>
      deudas.any((d) => d.yoDebo) && deudas.any((d) => !d.yoDebo);

  factory DetalleConPersona.fromJson(Map<String, dynamic> json) => DetalleConPersona(
        personaId: json['personaId'] as String? ?? '',
        nombre: json['nombre'] as String? ?? '',
        monto: json['monto'] as String? ?? '0.00',
        estado: json['estado'] as String? ?? 'saldado',
        totalQueDebo: json['totalQueDebo'] as String? ?? '0.00',
        totalQueMeDebe: json['totalQueMeDebe'] as String? ?? '0.00',
        deudas: ((json['deudas'] as List<dynamic>?) ?? [])
            .map((d) => DeudaDeEvento.fromJson(d as Map<String, dynamic>))
            .toList(),
      );
}

class ActividadLog {
  const ActividadLog({
    required this.id,
    required this.tipo,
    required this.actorNombre,
    required this.createdAt,
    this.eventoId,
    this.eventoNombre,
    this.payload,
  });

  final String id;
  final String tipo;
  final String actorNombre;
  final DateTime createdAt;

  /// Solo vienen en el feed de Home, donde hace falta saber de qué evento es.
  final String? eventoId;
  final String? eventoNombre;
  final Map<String, dynamic>? payload;

  factory ActividadLog.fromJson(Map<String, dynamic> json) {
    final actor = json['actor'] as Map<String, dynamic>?;
    return ActividadLog(
      id: json['id'] as String,
      tipo: json['tipo'] as String? ?? '',
      // El backend serializa PersonaRef como `nombre`.
      actorNombre: (actor?['nombre'] ?? actor?['nombreDisplay']) as String? ?? '',
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
      eventoId: json['eventoId'] as String?,
      eventoNombre: json['eventoNombre'] as String?,
      payload: json['payload'] as Map<String, dynamic>?,
    );
  }
}

class Tarea {
  const Tarea({
    required this.id,
    required this.titulo,
    required this.estado,
    this.asignadoId,
    this.asignadoNombre,
  });

  final String id;
  final String titulo;
  final String estado;
  final String? asignadoId;
  final String? asignadoNombre;

  bool get estaCompletada => estado == 'completado';
  bool get estaSinAsignar => estado == 'no_asignado';

  factory Tarea.fromJson(Map<String, dynamic> json) {
    final asignado = json['asignado'] as Map<String, dynamic>?;
    return Tarea(
      id: json['id'] as String,
      titulo: json['titulo'] as String? ?? '',
      estado: json['estado'] as String? ?? 'no_asignado',
      asignadoId: asignado?['id'] as String?,
      // El backend serializa el nombre como `nombre` en TareaConAsignado.
      asignadoNombre: (asignado?['nombre'] ?? asignado?['nombreDisplay']) as String?,
    );
  }
}

/// Perfil del usuario registrado (FR12 · GET /me).
class PerfilUsuario {
  const PerfilUsuario({
    required this.id,
    required this.nombre,
    required this.email,
    required this.idiomaPreferido,
    this.avatarUrl,
  });

  final String id;
  final String nombre;
  final String email;
  final String idiomaPreferido;
  final String? avatarUrl;

  factory PerfilUsuario.fromJson(Map<String, dynamic> json) => PerfilUsuario(
        id: json['id'] as String? ?? '',
        nombre: json['nombre'] as String? ?? '',
        email: json['email'] as String? ?? '',
        idiomaPreferido: json['idiomaPreferido'] as String? ?? 'es',
        avatarUrl: json['avatarUrl'] as String?,
      );
}

/// Un amigo (FR13). Trae el id de la relación ([amistadId]) para poder
/// eliminarla, además del id del usuario.
class Amigo {
  const Amigo({required this.id, required this.nombre, required this.amistadId});

  final String id;
  final String nombre;
  final String amistadId;

  factory Amigo.fromJson(Map<String, dynamic> json) => Amigo(
        id: json['id'] as String? ?? '',
        nombre: json['nombre'] as String? ?? '',
        amistadId: json['amistadId'] as String? ?? '',
      );
}

/// Solicitud de amistad recibida y todavía sin aceptar (FR13).
class SolicitudAmistad {
  const SolicitudAmistad({
    required this.amistadId,
    required this.solicitanteId,
    required this.solicitanteNombre,
  });

  final String amistadId;
  final String solicitanteId;
  final String solicitanteNombre;

  factory SolicitudAmistad.fromJson(Map<String, dynamic> json) {
    final solicitante = json['solicitante'] as Map<String, dynamic>?;
    return SolicitudAmistad(
      amistadId: json['amistadId'] as String? ?? '',
      solicitanteId: solicitante?['id'] as String? ?? '',
      solicitanteNombre: solicitante?['nombre'] as String? ?? '',
    );
  }
}

/// Resultado de buscar usuarios para agregar como amigos (FR13), con el estado
/// de la relación ya resuelto por el backend.
class UsuarioBuscado {
  const UsuarioBuscado({
    required this.id,
    required this.nombre,
    required this.email,
    required this.relacion,
  });

  final String id;
  final String nombre;
  final String email;

  /// 'ninguno' | 'amigo' | 'pendiente_enviada' | 'pendiente_recibida'
  final String relacion;

  bool get sePuedeAgregar => relacion == 'ninguno';

  factory UsuarioBuscado.fromJson(Map<String, dynamic> json) => UsuarioBuscado(
        id: json['id'] as String? ?? '',
        nombre: json['nombre'] as String? ?? '',
        email: json['email'] as String? ?? '',
        relacion: json['relacion'] as String? ?? 'ninguno',
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
