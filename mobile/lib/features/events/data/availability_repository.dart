import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/api_exception.dart';
import '../../../core/models/models.dart';
import '../../../core/network/api_client.dart';

/// SCRUM-9 — HU-07/HU-08/HU-09. El corazón del MVP.
abstract interface class AvailabilityRepository {
  /// HU-07 — reemplaza la disponibilidad del participante en el evento.
  Future<void> guardar({
    required String eventoId,
    required List<({int diaSemana, int bloqueHora})> slots,
  });

  /// Obtiene los bloques de disponibilidad guardados por mi usuario en el evento.
  Future<List<({int diaSemana, int bloqueHora})>> obtenerMiDisponibilidad(String eventoId);

  /// HU-08 — cuántos participantes pueden en cada bloque.
  Future<List<HeatmapSlot>> heatmap(String eventoId);

  /// Item 5 — cuántos participantes están libres en TODO un rango horario
  /// propuesto (no en un bloque suelto), para elegir la hora de fin con
  /// esa información.
  Future<({int disponibles, int total})> disponiblesEnRango({
    required String eventoId,
    required int diaSemana,
    required int horaInicio,
    required int horaFin,
  });

  /// HU-09 — el organizador fija el horario a partir del heatmap. Item 5: es
  /// un RANGO (inicio y fin), no un instante.
  Future<void> confirmarHorario({
    required String eventoId,
    required DateTime fechaHoraInicio,
    required DateTime fechaHoraFin,
  });
}

class AvailabilityRepositoryHttp implements AvailabilityRepository {
  const AvailabilityRepositoryHttp(this._dio);

  final Dio _dio;

  @override
  Future<void> guardar({
    required String eventoId,
    required List<({int diaSemana, int bloqueHora})> slots,
  }) =>
      ejecutar(() async {
        await _dio.post<void>(
          '/events/$eventoId/availability',
          data: {
            'slots': slots
                .map((s) => {'diaSemana': s.diaSemana, 'bloqueHora': s.bloqueHora})
                .toList(),
          },
        );
      });

  @override
  Future<List<({int diaSemana, int bloqueHora})>> obtenerMiDisponibilidad(String eventoId) =>
      ejecutar(() async {
        final res = await _dio.get<List<dynamic>>('/events/$eventoId/availability/me');
        return (res.data ?? [])
            .map((s) {
              final map = s as Map<String, dynamic>;
              return (
                diaSemana: map['diaSemana'] as int,
                bloqueHora: map['bloqueHora'] as int,
              );
            })
            .toList();
      });

  @override
  Future<List<HeatmapSlot>> heatmap(String eventoId) => ejecutar(() async {
        final res = await _dio.get<List<dynamic>>('/events/$eventoId/availability/heatmap');
        return (res.data ?? [])
            .map((s) => HeatmapSlot.fromJson(s as Map<String, dynamic>))
            .toList();
      });

  @override
  Future<({int disponibles, int total})> disponiblesEnRango({
    required String eventoId,
    required int diaSemana,
    required int horaInicio,
    required int horaFin,
  }) =>
      ejecutar(() async {
        final res = await _dio.get<Map<String, dynamic>>(
          '/events/$eventoId/availability/range',
          queryParameters: {
            'diaSemana': diaSemana,
            'horaInicio': horaInicio,
            'horaFin': horaFin,
          },
        );
        return (
          disponibles: res.data?['disponibles'] as int? ?? 0,
          total: res.data?['total'] as int? ?? 0,
        );
      });

  @override
  Future<void> confirmarHorario({
    required String eventoId,
    required DateTime fechaHoraInicio,
    required DateTime fechaHoraFin,
  }) =>
      ejecutar(() async {
        await _dio.patch<void>(
          '/events/$eventoId/confirm',
          data: {
            'fechaHoraInicio': fechaHoraInicio.toIso8601String(),
            'fechaHoraFin': fechaHoraFin.toIso8601String(),
          },
        );
      });
}

final availabilityRepositoryProvider = Provider<AvailabilityRepository>(
  (ref) => AvailabilityRepositoryHttp(ref.watch(apiClientProvider)),
);

final myEventAvailabilityProvider =
    FutureProvider.family<List<({int diaSemana, int bloqueHora})>, String>(
  (ref, eventoId) =>
      ref.watch(availabilityRepositoryProvider).obtenerMiDisponibilidad(eventoId),
);

