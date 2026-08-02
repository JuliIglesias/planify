import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/api_exception.dart';
import '../../../core/network/api_client.dart';

/// Quién puso plata en un gasto. Soporta varios acreedores (FR7 del charter).
class AporteGasto {
  const AporteGasto({required this.participanteId, required this.monto});

  final String participanteId;
  final String monto;

  Map<String, dynamic> toJson() => {'participanteId': participanteId, 'monto': monto};
}

/// SCRUM-11 — HU-13/HU-14/HU-19.
abstract interface class ExpensesRepository {
  /// Crea un gasto (FR7). Admite **varios acreedores** ([acreedores], cada uno
  /// con cuánto puso) y **varios deudores**:
  ///  - [dividirEntre]: ids entre los que se reparte en partes iguales (el
  ///    backend reparte los centavos sobrantes). Si se omite junto con
  ///    [deudores], se divide entre todos los participantes.
  ///  - [deudores]: montos explícitos por deudor, si se quiere un reparto no
  ///    equitativo.
  Future<void> crear({
    required String eventoId,
    required String descripcion,
    required String montoTotal,
    required List<AporteGasto> acreedores,
    List<String>? dividirEntre,
    List<AporteGasto>? deudores,
  });

  /// HU-19 — cerrar los gastos del evento (solo organizador).
  Future<void> cerrar(String eventoId);
}

class ExpensesRepositoryHttp implements ExpensesRepository {
  const ExpensesRepositoryHttp(this._dio);

  final Dio _dio;

  @override
  Future<void> crear({
    required String eventoId,
    required String descripcion,
    required String montoTotal,
    required List<AporteGasto> acreedores,
    List<String>? dividirEntre,
    List<AporteGasto>? deudores,
  }) =>
      ejecutar(() async {
        await _dio.post<void>(
          '/events/$eventoId/expenses',
          data: {
            'descripcion': descripcion,
            'montoTotal': montoTotal,
            'acreedores': acreedores.map((a) => a.toJson()).toList(),
            if (dividirEntre != null) 'dividirEntre': dividirEntre,
            if (deudores != null) 'deudores': deudores.map((d) => d.toJson()).toList(),
          },
        );
      });

  @override
  Future<void> cerrar(String eventoId) => ejecutar(() async {
        await _dio.patch<void>('/events/$eventoId/expenses/close');
      });
}

final expensesRepositoryProvider = Provider<ExpensesRepository>(
  (ref) => ExpensesRepositoryHttp(ref.watch(apiClientProvider)),
);
