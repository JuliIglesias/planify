import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/api_exception.dart';
import '../../../core/models/models.dart';
import '../../../core/network/api_client.dart';

/// SCRUM-8 (grupos implícitos) y SCRUM-14 (gestión de miembros, Duda #12.2).
abstract interface class GroupsRepository {
  /// Datos ya armados para la pantalla Groups, con badges y contadores.
  Future<List<GrupoResumen>> resumen();

  /// Lista simple, para elegir grupo al crear un evento (HU-05).
  Future<List<GrupoResumen>> mios();

  /// HU-34 — renombrar el grupo.
  Future<void> renombrar({required String grupoId, required String nombre});

  /// HU-32 — sumar un amigo registrado al grupo.
  Future<void> agregarMiembro({required String grupoId, required String usuarioId});

  /// HU-33 — abandonar el grupo.
  Future<void> abandonar(String grupoId);
}

class GroupsRepositoryHttp implements GroupsRepository {
  const GroupsRepositoryHttp(this._dio);

  final Dio _dio;

  @override
  Future<List<GrupoResumen>> resumen() => ejecutar(() async {
        final res = await _dio.get<List<dynamic>>('/groups/overview');
        return (res.data ?? [])
            .map((g) => GrupoResumen.fromJson(g as Map<String, dynamic>))
            .toList();
      });

  @override
  Future<List<GrupoResumen>> mios() => ejecutar(() async {
        final res = await _dio.get<List<dynamic>>('/groups/mine');
        return (res.data ?? [])
            .map((g) => GrupoResumen.fromJson(g as Map<String, dynamic>))
            .toList();
      });

  @override
  Future<void> renombrar({required String grupoId, required String nombre}) =>
      ejecutar(() async {
        await _dio.patch<void>('/groups/$grupoId', data: {'nombre': nombre});
      });

  @override
  Future<void> agregarMiembro({required String grupoId, required String usuarioId}) =>
      ejecutar(() async {
        await _dio.post<void>('/groups/$grupoId/members', data: {'usuarioId': usuarioId});
      });

  @override
  Future<void> abandonar(String grupoId) => ejecutar(() async {
        await _dio.delete<void>('/groups/$grupoId/members/me');
      });
}

final groupsRepositoryProvider = Provider<GroupsRepository>(
  (ref) => GroupsRepositoryHttp(ref.watch(apiClientProvider)),
);
