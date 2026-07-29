import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/api_exception.dart';
import '../../../core/models/models.dart';
import '../../../core/network/api_client.dart';

/// SCRUM-11 — HU-16/HU-17/HU-18.
abstract interface class BalancesRepository {
  /// Balance neto agregado y saldos por persona, ya compensados entre eventos.
  Future<Balance> miBalance();

  /// FR9 — desglose de la relación con una persona: qué se debe en cada
  /// evento y cuánto queda después de compensar.
  Future<DetalleConPersona> detalleConPersona(String personaId);

  /// FR9 — salda **toda** la relación con una persona: cierra las deudas de
  /// todos los eventos, en ambos sentidos.
  Future<void> saldarConPersona(String personaId);

  /// Deudas de un evento puntual, sin compensar con otros eventos.
  Future<List<DeudaEvento>> deudasDelEvento(String eventoId);

  /// HU-18 — saldar una deuda puntual desde el evento.
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
  Future<DetalleConPersona> detalleConPersona(String personaId) => ejecutar(() async {
        final res = await _dio.get<Map<String, dynamic>>('/me/balance/$personaId');
        return DetalleConPersona.fromJson(res.data ?? {});
      });

  @override
  Future<void> saldarConPersona(String personaId) => ejecutar(() async {
        await _dio.post<void>('/me/balance/$personaId/settle');
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
