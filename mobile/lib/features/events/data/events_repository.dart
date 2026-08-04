import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/api_exception.dart';
import '../../../core/models/models.dart';
import '../../../core/network/api_client.dart';

/// SCRUM-8/SCRUM-10 — ciclo de vida del evento.
abstract interface class EventsRepository {
  /// Home — próximos eventos del usuario.
  Future<List<EventoResumen>> proximos();

  /// Historial — eventos pasados con su estado de saldo.
  Future<List<EventoHistorial>> historial();

  Future<DetalleEvento> detalle(String eventoId);

  /// HU-06 — creación en 2 pasos. Devuelve el id del evento creado.
  /// Item 1 — el rango de fechas calendario se elige junto al nombre/lugar,
  /// en el mismo paso 1 (NFR#3 sigue siendo 2 pasos).
  Future<String> crear({
    required String nombre,
    required String lugarTexto,
    required DateTime rangoInicio,
    required DateTime rangoFin,
    String? grupoId,
    String? nuevoGrupoNombre,
    List<String>? miembroUsuarioIds,
  });

  /// HU-10 — confirmar o rechazar asistencia.
  Future<void> responderAsistencia({required String eventoId, required bool confirma});

  /// HU-11 — cancelar (solo organizador).
  Future<void> cancelar(String eventoId);

  /// HU-02 — genera el link de invitación al evento.
  Future<String> crearInvitacion(String eventoId);
}

class EventsRepositoryHttp implements EventsRepository {
  const EventsRepositoryHttp(this._dio);

  final Dio _dio;

  @override
  Future<List<EventoResumen>> proximos() => ejecutar(() async {
        final res = await _dio.get<List<dynamic>>('/events/upcoming');
        return (res.data ?? [])
            .map((e) => EventoResumen.fromJson(e as Map<String, dynamic>))
            .toList();
      });

  @override
  Future<List<EventoHistorial>> historial() => ejecutar(() async {
        final res = await _dio.get<List<dynamic>>('/events/history');
        return (res.data ?? [])
            .map((e) => EventoHistorial.fromJson(e as Map<String, dynamic>))
            .toList();
      });

  @override
  Future<DetalleEvento> detalle(String eventoId) => ejecutar(() async {
        final res = await _dio.get<Map<String, dynamic>>('/events/$eventoId');
        return DetalleEvento.fromJson(res.data ?? {});
      });

  @override
  Future<String> crear({
    required String nombre,
    required String lugarTexto,
    required DateTime rangoInicio,
    required DateTime rangoFin,
    String? grupoId,
    String? nuevoGrupoNombre,
    List<String>? miembroUsuarioIds,
  }) =>
      ejecutar(() async {
        final res = await _dio.post<Map<String, dynamic>>(
          '/events',
          data: {
            'nombre': nombre,
            'lugarTexto': lugarTexto,
            'rangoInicio': rangoInicio.toIso8601String(),
            'rangoFin': rangoFin.toIso8601String(),
            if (grupoId != null) 'grupoId': grupoId,
            if (nuevoGrupoNombre != null) 'nuevoGrupoNombre': nuevoGrupoNombre,
            if (miembroUsuarioIds != null) 'miembroUsuarioIds': miembroUsuarioIds,
          },
        );
        return (res.data!['evento'] as Map<String, dynamic>)['id'] as String;
      });

  @override
  Future<void> responderAsistencia({required String eventoId, required bool confirma}) =>
      ejecutar(() async {
        await _dio.patch<void>(
          '/events/$eventoId/attendance',
          data: {'estado': confirma ? 'confirmado' : 'rechazado'},
        );
      });

  @override
  Future<void> cancelar(String eventoId) => ejecutar(() async {
        await _dio.patch<void>('/events/$eventoId/cancel');
      });

  @override
  Future<String> crearInvitacion(String eventoId) => ejecutar(() async {
        final res = await _dio.post<Map<String, dynamic>>(
          '/invitations',
          data: {'eventoId': eventoId},
        );
        return res.data!['tokenUnico'] as String;
      });
}

final eventsRepositoryProvider = Provider<EventsRepository>(
  (ref) => EventsRepositoryHttp(ref.watch(apiClientProvider)),
);
