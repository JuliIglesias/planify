import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/api_exception.dart';
import '../../../core/models/models.dart';
import '../../../core/network/api_client.dart';

/// Tanda 6, Item 5 — heatmap de disponibilidad de los miembros de UN grupo
/// (reemplaza la vieja "coincidencias con todos los amigos" de Perfil).
class DisponibilidadDeGrupo {
  const DisponibilidadDeGrupo({required this.totalPersonas, required this.slots});
  final int totalPersonas;
  final List<HeatmapSlot> slots;

  factory DisponibilidadDeGrupo.fromJson(Map<String, dynamic> json) => DisponibilidadDeGrupo(
        totalPersonas: json['totalPersonas'] as int? ?? 0,
        slots: ((json['slots'] as List<dynamic>?) ?? [])
            .map((s) => HeatmapSlot.fromJson(s as Map<String, dynamic>))
            .toList(),
      );
}

/// SCRUM-8 (grupos implícitos) y SCRUM-14 (gestión de miembros, Duda #12.2).
abstract interface class GroupsRepository {
  /// Datos ya armados para la pantalla Groups, con badges y contadores.
  Future<List<GrupoResumen>> resumen();

  /// Lista simple, para elegir grupo al crear un evento (HU-05).
  Future<List<GrupoResumen>> mios();

  /// HU-34 — actualizar el nombre del grupo.
  Future<void> actualizar({required String grupoId, String? nombre});

  /// Item 5 (Tanda 6) — subir la foto del grupo desde la galería nativa.
  Future<void> subirImagen({
    required String grupoId,
    required List<int> bytes,
    required String nombreArchivo,
  });

  /// Item 5 (Tanda 6) — disponibilidad agregada de los miembros de este grupo.
  Future<DisponibilidadDeGrupo> disponibilidadDeGrupo(String grupoId);

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
  Future<void> actualizar({required String grupoId, String? nombre}) => ejecutar(() async {
        final data = <String, dynamic>{};
        if (nombre != null) data['nombre'] = nombre;
        await _dio.patch<void>('/groups/$grupoId', data: data);
      });

  @override
  Future<void> subirImagen({
    required String grupoId,
    required List<int> bytes,
    required String nombreArchivo,
  }) =>
      ejecutar(() async {
        final form = FormData.fromMap({
          'imagen': MultipartFile.fromBytes(bytes, filename: nombreArchivo),
        });
        await _dio.post<void>('/groups/$grupoId/avatar', data: form);
      });

  @override
  Future<DisponibilidadDeGrupo> disponibilidadDeGrupo(String grupoId) => ejecutar(() async {
        final res = await _dio.get<Map<String, dynamic>>('/groups/$grupoId/availability-matches');
        return DisponibilidadDeGrupo.fromJson(res.data ?? {});
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
