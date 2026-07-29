import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/api_exception.dart';
import '../../../core/models/models.dart';
import '../../../core/network/api_client.dart';

/// SCRUM-11 — HU-16/HU-17/HU-18.
abstract interface class BalancesRepository {
  /// Balance neto agregado y saldos por persona.
  Future<Balance> miBalance();

  /// Deudas simplificadas de un evento puntual.
  Future<List<DeudaEvento>> deudasDelEvento(String eventoId);

  /// HU-18 — marcar una deuda como saldada.
  Future<void> saldar({required String eventoId, required String deudaId});
}

class BalancesRepositoryHttp implements BalancesRepository {
  const BalancesRepositoryHttp(this._dio);

  final Dio _dio;

  @override
  Future<Balance> miBalance() => ejecutar(() async {
        final res = await _dio.get<Map<String, dynamic>>('/me/balance');
        return Balance.fromJson(res.data ?? {});
      });

  @override
  Future<List<DeudaEvento>> deudasDelEvento(String eventoId) => ejecutar(() async {
        final res = await _dio.get<List<dynamic>>('/events/$eventoId/debts');
        return (res.data ?? [])
            .map((d) => DeudaEvento.fromJson(d as Map<String, dynamic>))
            .toList();
      });

  @override
  Future<void> saldar({required String eventoId, required String deudaId}) =>
      ejecutar(() async {
        await _dio.patch<void>('/events/$eventoId/debts/$deudaId/settle');
      });
}

final balancesRepositoryProvider = Provider<BalancesRepository>(
  (ref) => BalancesRepositoryHttp(ref.watch(apiClientProvider)),
);
