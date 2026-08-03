import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/api_exception.dart';
import '../../../core/network/api_client.dart';
import '../../friends/data/friends_repository.dart';

/// Borrador de evento generado por IA (SCRUM-17, HU-42/43/44b). Es editable: el
/// organizador confirma en el wizard, nunca se crea automáticamente.
class BorradorEvento {
  const BorradorEvento({
    required this.nombre,
    required this.lugar,
    required this.tareasSugeridas,
    required this.amigosSugeridos,
    required this.nombresSinMatch,
  });

  final String nombre;
  final String lugar;
  final List<String> tareasSugeridas;
  final List<Persona> amigosSugeridos;
  final List<String> nombresSinMatch;

  factory BorradorEvento.fromJson(Map<String, dynamic> json) => BorradorEvento(
        nombre: json['nombre'] as String? ?? '',
        lugar: json['lugar'] as String? ?? '',
        tareasSugeridas: ((json['tareasSugeridas'] as List<dynamic>?) ?? [])
            .map((t) => t as String)
            .toList(),
        amigosSugeridos: ((json['amigosSugeridos'] as List<dynamic>?) ?? [])
            .map((p) => Persona.fromJson(p as Map<String, dynamic>))
            .toList(),
        nombresSinMatch: ((json['nombresSinMatch'] as List<dynamic>?) ?? [])
            .map((n) => n as String)
            .toList(),
      );
}

abstract interface class AiEventsRepository {
  Future<BorradorEvento> generar(String descripcion);
}

class AiEventsRepositoryHttp implements AiEventsRepository {
  const AiEventsRepositoryHttp(this._dio);
  final Dio _dio;

  @override
  Future<BorradorEvento> generar(String descripcion) => ejecutar(() async {
        final res = await _dio.post<Map<String, dynamic>>(
          '/events/generate-from-text',
          data: {'descripcion': descripcion},
        );
        return BorradorEvento.fromJson(res.data ?? {});
      });
}

final aiEventsRepositoryProvider = Provider<AiEventsRepository>(
  (ref) => AiEventsRepositoryHttp(ref.watch(apiClientProvider)),
);
