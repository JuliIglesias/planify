import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/models.dart';
import 'api_client.dart';

/// Repositorio único contra la API. Todas las pantallas pasan por acá, así que
/// si cambia una ruta del backend, se toca en un solo lugar.
class PlanifyApi {
  PlanifyApi(this._dio);

  final Dio _dio;

  // ── Auth (HU-41) ────────────────────────────────────────────────────────
  Future<({String token, String nombre, String usuarioId})> login(
    String email,
    String password,
  ) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/auth/login',
      data: {'email': email, 'password': password},
    );
    final usuario = res.data!['usuario'] as Map<String, dynamic>;
    return (
      token: res.data!['token'] as String,
      nombre: usuario['nombre'] as String,
      usuarioId: usuario['id'] as String,
    );
  }

  // ── Acceso anónimo (HU-01/HU-02) ────────────────────────────────────────
  Future<({String participanteId, String tokenSesion})> joinAnonymous({
    required String eventoId,
    required String nombreDisplay,
  }) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/participants/anonymous',
      data: {'eventoId': eventoId, 'nombreDisplay': nombreDisplay},
    );
    return (
      participanteId: res.data!['participanteId'] as String,
      tokenSesion: res.data!['tokenSesion'] as String,
    );
  }

  Future<String> resolveInvitation(String token) async {
    final res = await _dio.get<Map<String, dynamic>>('/invitations/$token');
    return res.data!['eventoId'] as String;
  }

  // ── Home / Groups / Historial ───────────────────────────────────────────
  Future<List<EventoResumen>> upcomingEvents() async {
    final res = await _dio.get<List<dynamic>>('/events/upcoming');
    return (res.data ?? [])
        .map((e) => EventoResumen.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<GrupoResumen>> groupsOverview() async {
    final res = await _dio.get<List<dynamic>>('/groups/overview');
    return (res.data ?? [])
        .map((g) => GrupoResumen.fromJson(g as Map<String, dynamic>))
        .toList();
  }

  Future<List<EventoHistorial>> history() async {
    final res = await _dio.get<List<dynamic>>('/events/history');
    return (res.data ?? [])
        .map((e) => EventoHistorial.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ── Balances (HU-16/HU-17/HU-18) ────────────────────────────────────────
  Future<Balance> myBalance() async {
    final res = await _dio.get<Map<String, dynamic>>('/me/balance');
    return Balance.fromJson(res.data ?? {});
  }

  Future<void> settleDebt({required String eventoId, required String deudaId}) =>
      _dio.patch<void>('/events/$eventoId/debts/$deudaId/settle');

  // ── Eventos (HU-06/HU-10/HU-11) ─────────────────────────────────────────
  Future<String> createEvent({
    required String nombre,
    required String lugarTexto,
    String? grupoId,
    String? nuevoGrupoNombre,
    List<String>? miembroUsuarioIds,
  }) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/events',
      data: {
        'nombre': nombre,
        'lugarTexto': lugarTexto,
        if (grupoId != null) 'grupoId': grupoId,
        if (nuevoGrupoNombre != null) 'nuevoGrupoNombre': nuevoGrupoNombre,
        if (miembroUsuarioIds != null) 'miembroUsuarioIds': miembroUsuarioIds,
      },
    );
    return (res.data!['evento'] as Map<String, dynamic>)['id'] as String;
  }

  Future<Map<String, dynamic>> eventDetail(String eventoId) async {
    final res = await _dio.get<Map<String, dynamic>>('/events/$eventoId');
    return res.data ?? {};
  }

  Future<void> setAttendance({required String eventoId, required bool confirma}) =>
      _dio.patch<void>(
        '/events/$eventoId/attendance',
        data: {'estado': confirma ? 'confirmado' : 'rechazado'},
      );

  Future<void> cancelEvent(String eventoId) =>
      _dio.patch<void>('/events/$eventoId/cancel');

  // ── Disponibilidad (HU-07/HU-08/HU-09) ──────────────────────────────────
  Future<void> submitAvailability({
    required String eventoId,
    required List<({int diaSemana, int bloqueHora})> slots,
  }) =>
      _dio.post<void>(
        '/events/$eventoId/availability',
        data: {
          'slots': slots
              .map((s) => {'diaSemana': s.diaSemana, 'bloqueHora': s.bloqueHora})
              .toList(),
        },
      );

  Future<List<HeatmapSlot>> heatmap(String eventoId) async {
    final res = await _dio.get<List<dynamic>>('/events/$eventoId/availability/heatmap');
    return (res.data ?? [])
        .map((s) => HeatmapSlot.fromJson(s as Map<String, dynamic>))
        .toList();
  }

  Future<void> confirmSchedule({
    required String eventoId,
    required DateTime fechaHoraInicio,
  }) =>
      _dio.patch<void>(
        '/events/$eventoId/confirm',
        data: {'fechaHoraInicio': fechaHoraInicio.toIso8601String()},
      );

  // ── Tareas (HU-20 a HU-23) ──────────────────────────────────────────────
  Future<List<Tarea>> tasks(String eventoId) async {
    final res = await _dio.get<List<dynamic>>('/events/$eventoId/tasks');
    return (res.data ?? []).map((t) => Tarea.fromJson(t as Map<String, dynamic>)).toList();
  }

  Future<void> createTask({required String eventoId, required String titulo}) =>
      _dio.post<void>('/events/$eventoId/tasks', data: {'titulo': titulo});

  Future<void> assignTask({required String eventoId, required String tareaId}) =>
      _dio.patch<void>('/events/$eventoId/tasks/$tareaId/assign');

  Future<void> completeTask({required String eventoId, required String tareaId}) =>
      _dio.patch<void>('/events/$eventoId/tasks/$tareaId/complete');

  // ── Gastos (HU-13/HU-14) ────────────────────────────────────────────────
  Future<void> createExpense({
    required String eventoId,
    required String descripcion,
    required String montoTotal,
    required String pagadorParticipanteId,
  }) =>
      _dio.post<void>(
        '/events/$eventoId/expenses',
        data: {
          'descripcion': descripcion,
          'montoTotal': montoTotal,
          'acreedores': [
            {'participanteId': pagadorParticipanteId, 'monto': montoTotal},
          ],
        },
      );

  // ── Log de actividad (HU-24) ────────────────────────────────────────────
  Future<List<ActividadLog>> activityLog(String eventoId) async {
    final res = await _dio.get<List<dynamic>>('/events/$eventoId/activity-log');
    return (res.data ?? [])
        .map((a) => ActividadLog.fromJson(a as Map<String, dynamic>))
        .toList();
  }
}

final planifyApiProvider = Provider<PlanifyApi>(
  (ref) => PlanifyApi(ref.watch(apiClientProvider)),
);
