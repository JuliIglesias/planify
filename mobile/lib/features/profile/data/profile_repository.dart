import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/api_exception.dart';
import '../../../core/models/models.dart';
import '../../../core/network/api_client.dart';

typedef SlotSimple = ({int diaSemana, int bloqueHora});

class CoincidenciasAmigos {
  const CoincidenciasAmigos({required this.totalPersonas, required this.slots});
  final int totalPersonas;
  final List<HeatmapSlot> slots;
}

class UbicacionFavorita {
  const UbicacionFavorita({required this.id, required this.etiqueta, required this.texto});
  final String id;
  final String etiqueta;
  final String texto;

  factory UbicacionFavorita.fromJson(Map<String, dynamic> json) => UbicacionFavorita(
        id: json['id'] as String,
        etiqueta: json['etiqueta'] as String? ?? '',
        texto: json['texto'] as String? ?? '',
      );
}

/// SCRUM-14/HU-B4/HU-B5 — disponibilidad de perfil, coincidencias entre amigos
/// y ubicaciones favoritas.
abstract interface class ProfileRepository {
  Future<List<SlotSimple>> obtenerDisponibilidad();
  Future<void> guardarDisponibilidad(List<SlotSimple> slots);
  Future<CoincidenciasAmigos> coincidenciasConAmigos();
  Future<List<UbicacionFavorita>> listarUbicaciones();
  Future<UbicacionFavorita> crearUbicacion(String etiqueta, String texto);
  Future<void> eliminarUbicacion(String id);
}

class ProfileRepositoryHttp implements ProfileRepository {
  const ProfileRepositoryHttp(this._dio);
  final Dio _dio;

  @override
  Future<List<SlotSimple>> obtenerDisponibilidad() => ejecutar(() async {
        final res = await _dio.get<List<dynamic>>('/me/availability');
        return (res.data ?? [])
            .map((s) => (
                  diaSemana: (s as Map<String, dynamic>)['diaSemana'] as int,
                  bloqueHora: s['bloqueHora'] as int,
                ))
            .toList();
      });

  @override
  Future<void> guardarDisponibilidad(List<SlotSimple> slots) => ejecutar(() async {
        await _dio.put<void>('/me/availability', data: {
          'slots': slots.map((s) => {'diaSemana': s.diaSemana, 'bloqueHora': s.bloqueHora}).toList(),
        });
      });

  @override
  Future<CoincidenciasAmigos> coincidenciasConAmigos() => ejecutar(() async {
        final res = await _dio.get<Map<String, dynamic>>('/me/availability/friend-matches');
        final data = res.data ?? {};
        return CoincidenciasAmigos(
          totalPersonas: data['totalPersonas'] as int? ?? 0,
          slots: ((data['slots'] as List<dynamic>?) ?? [])
              .map((s) => HeatmapSlot.fromJson(s as Map<String, dynamic>))
              .toList(),
        );
      });

  @override
  Future<List<UbicacionFavorita>> listarUbicaciones() => ejecutar(() async {
        final res = await _dio.get<List<dynamic>>('/me/locations');
        return (res.data ?? [])
            .map((u) => UbicacionFavorita.fromJson(u as Map<String, dynamic>))
            .toList();
      });

  @override
  Future<UbicacionFavorita> crearUbicacion(String etiqueta, String texto) => ejecutar(() async {
        final res = await _dio.post<Map<String, dynamic>>(
          '/me/locations',
          data: {'etiqueta': etiqueta, 'texto': texto},
        );
        return UbicacionFavorita.fromJson(res.data ?? {});
      });

  @override
  Future<void> eliminarUbicacion(String id) => ejecutar(() async {
        await _dio.delete<void>('/me/locations/$id');
      });
}

final profileRepositoryProvider = Provider<ProfileRepository>(
  (ref) => ProfileRepositoryHttp(ref.watch(apiClientProvider)),
);

/// Ubicaciones favoritas (para el paso 1 de creación de evento).
final favoriteLocationsProvider = FutureProvider<List<UbicacionFavorita>>(
  (ref) => ref.watch(profileRepositoryProvider).listarUbicaciones(),
);
