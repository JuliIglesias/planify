import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/api_exception.dart';
import '../../../core/models/models.dart';
import '../../../core/network/api_client.dart';

/// SCRUM-13 — HU-24/HU-25. Es el feed de actividad del evento, no un chat de
/// mensajería libre (Duda #9).
abstract interface class ActivityLogRepository {
  /// Trae el feed. Consultarlo marca el evento como leído (HU-25).
  Future<List<ActividadLog>> listar(String eventoId);

  /// Actividad reciente de todos los eventos del usuario (feed de Home).
  Future<List<ActividadLog>> recientes();

  /// Contadores de actividad sin leer, por evento.
  Future<Map<String, int>> noLeidas();
}

class ActivityLogRepositoryHttp implements ActivityLogRepository {
  const ActivityLogRepositoryHttp(this._dio);

  final Dio _dio;

  @override
  Future<List<ActividadLog>> listar(String eventoId) => ejecutar(() async {
        final res = await _dio.get<List<dynamic>>('/events/$eventoId/activity-log');
        return (res.data ?? [])
            .map((a) => ActividadLog.fromJson(a as Map<String, dynamic>))
            .toList();
      });

  @override
  Future<List<ActividadLog>> recientes() => ejecutar(() async {
        final res = await _dio.get<List<dynamic>>('/me/activity');
        return (res.data ?? [])
            .map((a) => ActividadLog.fromJson(a as Map<String, dynamic>))
            .toList();
      });

  @override
  Future<Map<String, int>> noLeidas() => ejecutar(() async {
        final res = await _dio.get<Map<String, dynamic>>('/me/unread');
        return (res.data ?? {}).map((k, v) => MapEntry(k, v as int));
      });
}

final activityLogRepositoryProvider = Provider<ActivityLogRepository>(
  (ref) => ActivityLogRepositoryHttp(ref.watch(apiClientProvider)),
);
