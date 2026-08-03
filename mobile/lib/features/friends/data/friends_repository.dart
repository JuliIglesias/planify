import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/api_exception.dart';
import '../../../core/network/api_client.dart';

/// Una persona (amiga o resultado de búsqueda). id = usuarioId.
class Persona {
  const Persona({required this.id, required this.nombre, this.email});
  final String id;
  final String nombre;
  /// Item 3 (Fase 4) — solo viaja en los resultados de búsqueda (no en la
  /// lista de amigos ni en solicitudes pendientes). Como el nombre no es
  /// único, la pantalla de Amigos lo muestra en gris para desambiguar.
  final String? email;

  factory Persona.fromJson(Map<String, dynamic> json) => Persona(
        id: json['id'] as String,
        nombre: json['nombre'] as String? ?? '',
        email: json['email'] as String?,
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

/// SCRUM-14 — HU-31/HU-32: amigos.
abstract interface class FriendsRepository {
  Future<List<Persona>> buscar(String query);
  Future<List<Persona>> listar();
  Future<List<SolicitudAmistad>> solicitudesPendientes();
  Future<void> enviarSolicitud(String usuarioId);
  Future<void> aceptar(String amistadId);
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
  Future<void> enviarSolicitud(String usuarioId) => ejecutar(() async {
        await _dio.post<void>('/friends/request', data: {'usuarioId': usuarioId});
      });

  @override
  Future<void> aceptar(String amistadId) => ejecutar(() async {
        await _dio.post<void>('/friends/$amistadId/accept');
      });
}

final friendsRepositoryProvider = Provider<FriendsRepository>(
  (ref) => FriendsRepositoryHttp(ref.watch(apiClientProvider)),
);

/// Amigos del usuario (para selectores de miembros).
final friendsProvider = FutureProvider<List<Persona>>(
  (ref) => ref.watch(friendsRepositoryProvider).listar(),
);
