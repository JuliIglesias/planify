import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/api_exception.dart';
import '../../../core/models/models.dart';
import '../../../core/network/api_client.dart';

/// SCRUM-14 (FR13) — gestión de amigos entre usuarios registrados.
abstract interface class FriendsRepository {
  /// GET /friends — mis amigos.
  Future<List<Amigo>> amigos();

  /// GET /friends/requests — solicitudes que me llegaron.
  Future<List<SolicitudAmistad>> pendientes();

  /// GET /users/search?q= — buscar usuarios para agregar.
  Future<List<UsuarioBuscado>> buscar(String termino);

  /// POST /friends — enviar una solicitud de amistad.
  Future<void> enviarSolicitud(String usuarioId);

  /// POST /friends/:id/accept — aceptar una solicitud recibida.
  Future<void> aceptar(String amistadId);

  /// DELETE /friends/:id — rechazar una solicitud o eliminar una amistad.
  Future<void> eliminar(String amistadId);
}

class FriendsRepositoryHttp implements FriendsRepository {
  const FriendsRepositoryHttp(this._dio);

  final Dio _dio;

  @override
  Future<List<Amigo>> amigos() => ejecutar(() async {
        final res = await _dio.get<List<dynamic>>('/friends');
        return (res.data ?? [])
            .map((a) => Amigo.fromJson(a as Map<String, dynamic>))
            .toList();
      });

  @override
  Future<List<SolicitudAmistad>> pendientes() => ejecutar(() async {
        final res = await _dio.get<List<dynamic>>('/friends/requests');
        return (res.data ?? [])
            .map((s) => SolicitudAmistad.fromJson(s as Map<String, dynamic>))
            .toList();
      });

  @override
  Future<List<UsuarioBuscado>> buscar(String termino) => ejecutar(() async {
        final res = await _dio.get<List<dynamic>>(
          '/users/search',
          queryParameters: {'q': termino},
        );
        return (res.data ?? [])
            .map((u) => UsuarioBuscado.fromJson(u as Map<String, dynamic>))
            .toList();
      });

  @override
  Future<void> enviarSolicitud(String usuarioId) => ejecutar(() async {
        await _dio.post<void>('/friends', data: {'usuarioId': usuarioId});
      });

  @override
  Future<void> aceptar(String amistadId) => ejecutar(() async {
        await _dio.post<void>('/friends/$amistadId/accept');
      });

  @override
  Future<void> eliminar(String amistadId) => ejecutar(() async {
        await _dio.delete<void>('/friends/$amistadId');
      });
}

final friendsRepositoryProvider = Provider<FriendsRepository>(
  (ref) => FriendsRepositoryHttp(ref.watch(apiClientProvider)),
);

final friendsProvider = FutureProvider<List<Amigo>>(
  (ref) => ref.watch(friendsRepositoryProvider).amigos(),
);

final friendRequestsProvider = FutureProvider<List<SolicitudAmistad>>(
  (ref) => ref.watch(friendsRepositoryProvider).pendientes(),
);
