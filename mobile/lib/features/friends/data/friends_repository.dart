import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/api_exception.dart';
import '../../../core/network/api_client.dart';

/// Una persona (amiga o resultado de búsqueda). id = usuarioId.
class Persona {
  const Persona({required this.id, required this.username, this.email, this.avatarUrl});
  final String id;
  final String username;
  /// El username ya es único, pero el email se sigue mostrando en gris
  /// debajo (como una sola unidad visual) porque ayuda a reconocer a la
  /// persona sin acordarse el username exacto — en búsqueda, en la lista
  /// de amigos y en solicitudes pendientes por igual.
  final String? email;
  /// Item 4 — solo viaja en el perfil de amigo (`GET /friends/:id/profile`);
  /// las demás listas de amigos no lo necesitan.
  final String? avatarUrl;

  factory Persona.fromJson(Map<String, dynamic> json) => Persona(
        id: json['id'] as String,
        username: json['username'] as String? ?? '',
        email: json['email'] as String?,
        avatarUrl: json['avatarUrl'] as String?,
      );
}

/// Item 4 — un bloque de la disponibilidad semanal comparada con un amigo.
enum EstadoSlotComparado { ambos, soloYo, soloAmigo }

class SlotComparado {
  const SlotComparado(this.diaSemana, this.bloqueHora, this.estado);
  final int diaSemana;
  final int bloqueHora;
  final EstadoSlotComparado estado;

  factory SlotComparado.fromJson(Map<String, dynamic> json) => SlotComparado(
        json['diaSemana'] as int,
        json['bloqueHora'] as int,
        switch (json['estado'] as String?) {
          'ambos' => EstadoSlotComparado.ambos,
          'soloYo' => EstadoSlotComparado.soloYo,
          _ => EstadoSlotComparado.soloAmigo,
        },
      );
}

/// Item 4 — evento donde tanto yo como el amigo somos participantes.
class EventoCompartido {
  const EventoCompartido({
    required this.id,
    required this.nombre,
    required this.lugarTexto,
    required this.estado,
    this.fechaHoraInicio,
  });
  final String id;
  final String nombre;
  final String lugarTexto;
  final String estado;
  final DateTime? fechaHoraInicio;

  factory EventoCompartido.fromJson(Map<String, dynamic> json) => EventoCompartido(
        id: json['id'] as String,
        nombre: json['nombre'] as String? ?? '',
        lugarTexto: json['lugarTexto'] as String? ?? '',
        estado: json['estado'] as String? ?? 'planificacion',
        fechaHoraInicio: json['fechaHoraInicio'] != null
            ? DateTime.tryParse(json['fechaHoraInicio'] as String)
            : null,
      );
}

/// Item 4 — grupo donde tanto yo como el amigo somos miembros.
class GrupoCompartido {
  const GrupoCompartido({required this.id, required this.nombre, this.avatarUrl});
  final String id;
  final String nombre;
  final String? avatarUrl;

  factory GrupoCompartido.fromJson(Map<String, dynamic> json) => GrupoCompartido(
        id: json['id'] as String,
        nombre: json['nombre'] as String? ?? '',
        avatarUrl: json['avatarUrl'] as String?,
      );
}

/// Item 4 — perfil de solo lectura de un amigo.
class PerfilAmigo {
  const PerfilAmigo({
    required this.persona,
    required this.heatmapComparado,
    required this.eventosEnComun,
    required this.gruposEnComun,
  });
  final Persona persona;
  final List<SlotComparado> heatmapComparado;
  final List<EventoCompartido> eventosEnComun;
  final List<GrupoCompartido> gruposEnComun;

  factory PerfilAmigo.fromJson(Map<String, dynamic> json) => PerfilAmigo(
        persona: Persona.fromJson(json['persona'] as Map<String, dynamic>),
        heatmapComparado: ((json['heatmapComparado'] as List<dynamic>?) ?? [])
            .map((s) => SlotComparado.fromJson(s as Map<String, dynamic>))
            .toList(),
        eventosEnComun: ((json['eventosEnComun'] as List<dynamic>?) ?? [])
            .map((e) => EventoCompartido.fromJson(e as Map<String, dynamic>))
            .toList(),
        gruposEnComun: ((json['gruposEnComun'] as List<dynamic>?) ?? [])
            .map((g) => GrupoCompartido.fromJson(g as Map<String, dynamic>))
            .toList(),
      );
}

/// Una solicitud de amistad pendiente recibida.
class SolicitudAmistad {
  const SolicitudAmistad({required this.amistadId, required this.de});
  final String amistadId;
  final Persona de;

  factory SolicitudAmistad.fromJson(Map<String, dynamic> json) => SolicitudAmistad(
        amistadId: json['amistadId'] as String,
        de: Persona.fromJson(json['de'] as Map<String, dynamic>),
      );
}

/// F1 — una solicitud de amistad pendiente que envié yo, todavía sin
/// aceptar (distinta de [SolicitudAmistad], que es la que me mandaron).
class SolicitudEnviada {
  const SolicitudEnviada({required this.amistadId, required this.para});
  final String amistadId;
  final Persona para;

  factory SolicitudEnviada.fromJson(Map<String, dynamic> json) => SolicitudEnviada(
        amistadId: json['amistadId'] as String,
        para: Persona.fromJson(json['para'] as Map<String, dynamic>),
      );
}

/// SCRUM-14 — HU-31/HU-32: amigos.
abstract interface class FriendsRepository {
  Future<List<Persona>> buscar(String query);
  Future<List<Persona>> listar();
  Future<List<SolicitudAmistad>> solicitudesPendientes();
  /// F1 — las que envié yo (distintas de [solicitudesPendientes], recibidas).
  Future<List<SolicitudEnviada>> solicitudesEnviadas();
  Future<void> enviarSolicitud(String usuarioId);
  Future<void> aceptar(String amistadId);

  /// Item 4 — perfil de solo lectura de un amigo (disponibilidad comparada
  /// + eventos/grupos en común).
  Future<PerfilAmigo> perfilDe(String usuarioId);
}

class FriendsRepositoryHttp implements FriendsRepository {
  const FriendsRepositoryHttp(this._dio);
  final Dio _dio;

  @override
  Future<List<Persona>> buscar(String query) => ejecutar(() async {
        final res = await _dio.get<List<dynamic>>(
          '/users/search',
          queryParameters: {'q': query},
        );
        return (res.data ?? [])
            .map((p) => Persona.fromJson(p as Map<String, dynamic>))
            .toList();
      });

  @override
  Future<List<Persona>> listar() => ejecutar(() async {
        final res = await _dio.get<List<dynamic>>('/friends');
        return (res.data ?? [])
            .map((p) => Persona.fromJson(p as Map<String, dynamic>))
            .toList();
      });

  @override
  Future<List<SolicitudAmistad>> solicitudesPendientes() => ejecutar(() async {
        final res = await _dio.get<List<dynamic>>('/friends/requests');
        return (res.data ?? [])
            .map((s) => SolicitudAmistad.fromJson(s as Map<String, dynamic>))
            .toList();
      });

  @override
  Future<List<SolicitudEnviada>> solicitudesEnviadas() => ejecutar(() async {
        final res = await _dio.get<List<dynamic>>('/friends/requests/sent');
        return (res.data ?? [])
            .map((s) => SolicitudEnviada.fromJson(s as Map<String, dynamic>))
            .toList();
      });

  @override
  Future<void> enviarSolicitud(String usuarioId) => ejecutar(() async {
        await _dio.post<void>('/friends/request', data: {'usuarioId': usuarioId});
      });

  @override
  Future<void> aceptar(String amistadId) => ejecutar(() async {
        await _dio.post<void>('/friends/$amistadId/accept');
      });

  @override
  Future<PerfilAmigo> perfilDe(String usuarioId) => ejecutar(() async {
        final res = await _dio.get<Map<String, dynamic>>('/friends/$usuarioId/profile');
        return PerfilAmigo.fromJson(res.data ?? {});
      });
}

final friendsRepositoryProvider = Provider<FriendsRepository>(
  (ref) => FriendsRepositoryHttp(ref.watch(apiClientProvider)),
);

/// Amigos del usuario (para selectores de miembros).
final friendsProvider = FutureProvider<List<Persona>>(
  (ref) => ref.watch(friendsRepositoryProvider).listar(),
);
