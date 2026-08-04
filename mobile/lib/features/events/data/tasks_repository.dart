import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/api_exception.dart';
import '../../../core/models/models.dart';
import '../../../core/network/api_client.dart';

/// SCRUM-12 — HU-20 a HU-23.
abstract interface class TasksRepository {
  Future<List<Tarea>> listar(String eventoId);

  /// HU-20 — crear una tarea del evento.
  Future<void> crear({required String eventoId, required String titulo});

  /// HU-21/HU-22 — tomarla o asignársela a otro participante.
  /// Sin [asignadoA], el que llama se la está tomando.
  Future<void> asignar({
    required String eventoId,
    required String tareaId,
    String? asignadoA,
  });

  /// HU-23 — marcarla como completada.
  Future<void> completar({required String eventoId, required String tareaId});

  Future<void> descompletar({required String eventoId, required String tareaId});
  Future<void> desasignar({required String eventoId, required String tareaId});
  Future<void> eliminar({required String eventoId, required String tareaId});
}

class TasksRepositoryHttp implements TasksRepository {
  const TasksRepositoryHttp(this._dio);

  final Dio _dio;

  @override
  Future<List<Tarea>> listar(String eventoId) => ejecutar(() async {
        final res = await _dio.get<List<dynamic>>('/events/$eventoId/tasks');
        return (res.data ?? [])
            .map((t) => Tarea.fromJson(t as Map<String, dynamic>))
            .toList();
      });

  @override
  Future<void> crear({required String eventoId, required String titulo}) =>
      ejecutar(() async {
        await _dio.post<void>('/events/$eventoId/tasks', data: {'titulo': titulo});
      });

  @override
  Future<void> asignar({
    required String eventoId,
    required String tareaId,
    String? asignadoA,
  }) =>
      ejecutar(() async {
        await _dio.patch<void>(
          '/events/$eventoId/tasks/$tareaId/assign',
          data: asignadoA != null ? {'asignadoA': asignadoA} : null,
        );
      });

  @override
  Future<void> completar({required String eventoId, required String tareaId}) =>
      ejecutar(() async {
        await _dio.patch<void>('/events/$eventoId/tasks/$tareaId/complete');
      });

  @override
  Future<void> descompletar({required String eventoId, required String tareaId}) =>
      ejecutar(() async {
        await _dio.patch<void>('/events/$eventoId/tasks/$tareaId/uncomplete');
      });

  @override
  Future<void> desasignar({required String eventoId, required String tareaId}) =>
      ejecutar(() async {
        await _dio.patch<void>('/events/$eventoId/tasks/$tareaId/unassign');
      });

  @override
  Future<void> eliminar({required String eventoId, required String tareaId}) =>
      ejecutar(() async {
        await _dio.delete<void>('/events/$eventoId/tasks/$tareaId');
      });
}

final tasksRepositoryProvider = Provider<TasksRepository>(
  (ref) => TasksRepositoryHttp(ref.watch(apiClientProvider)),
);
