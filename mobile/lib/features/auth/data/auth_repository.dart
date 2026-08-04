import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/api_exception.dart';
import '../../../core/network/api_client.dart';

class SesionOrganizadorDto {
  const SesionOrganizadorDto({
    required this.token,
    required this.usuarioId,
    required this.username,
  });

  final String token;
  final String usuarioId;
  final String username;
}

class SesionAnonimaDto {
  const SesionAnonimaDto({
    required this.participanteId,
    required this.tokenSesion,
    required this.username,
  });

  final String participanteId;
  final String tokenSesion;

  /// Puede diferir del pedido si el backend tuvo que auto-sufijarlo por
  /// colisión con otro username ya existente (registrado o anónimo).
  final String username;
}

/// SCRUM-7 — acceso a la app. Las pantallas dependen de esta interfaz, no de Dio.
abstract interface class AuthRepository {
  /// HU-41 — login del organizador semilla / usuario registrado. El
  /// identificador puede ser el email o el username (username único —
  /// ver docs/05-fixes.md).
  Future<SesionOrganizadorDto> login(String identificador, String password);

  /// HU-27 — registro de una cuenta real.
  Future<SesionOrganizadorDto> register(String username, String email, String password);

  /// HU-01/HU-03 — un anónimo se une a un evento existente.
  Future<SesionAnonimaDto> unirseComoAnonimo({
    required String eventoId,
    required String username,
  });

  /// HU-02 — resuelve un link de invitación al id del evento.
  Future<String> resolverInvitacion(String token);

  /// Item 2 — un usuario ya autenticado (organizador/registrado) se une por
  /// su cuenta real a través de un link de invitación, sin pasar por el
  /// camino anónimo. Devuelve el id del evento al que se unió.
  Future<String> unirseConInvitacion(String token);
}

class AuthRepositoryHttp implements AuthRepository {
  const AuthRepositoryHttp(this._dio);

  final Dio _dio;

  @override
  Future<SesionOrganizadorDto> login(String identificador, String password) =>
      ejecutar(() async {
        final res = await _dio.post<Map<String, dynamic>>(
          '/auth/login',
          data: {'email': identificador, 'password': password},
        );
        final usuario = res.data!['usuario'] as Map<String, dynamic>;
        return SesionOrganizadorDto(
          token: res.data!['token'] as String,
          usuarioId: usuario['id'] as String,
          username: usuario['username'] as String,
        );
      });

  @override
  Future<SesionOrganizadorDto> register(String username, String email, String password) =>
      ejecutar(() async {
        final res = await _dio.post<Map<String, dynamic>>(
          '/auth/register',
          data: {'username': username, 'email': email, 'password': password},
        );
        final usuario = res.data!['usuario'] as Map<String, dynamic>;
        return SesionOrganizadorDto(
          token: res.data!['token'] as String,
          usuarioId: usuario['id'] as String,
          username: usuario['username'] as String,
        );
      });

  @override
  Future<SesionAnonimaDto> unirseComoAnonimo({
    required String eventoId,
    required String username,
  }) =>
      ejecutar(() async {
        final res = await _dio.post<Map<String, dynamic>>(
          '/participants/anonymous',
          data: {'eventoId': eventoId, 'username': username},
        );
        return SesionAnonimaDto(
          participanteId: res.data!['participanteId'] as String,
          tokenSesion: res.data!['tokenSesion'] as String,
          username: res.data!['username'] as String? ?? username,
        );
      });

  @override
  Future<String> resolverInvitacion(String token) => ejecutar(() async {
        final res = await _dio.get<Map<String, dynamic>>('/invitations/$token');
        return res.data!['eventoId'] as String;
      });

  @override
  Future<String> unirseConInvitacion(String token) => ejecutar(() async {
        final res = await _dio.post<Map<String, dynamic>>('/invitations/$token/join');
        return res.data!['eventoId'] as String;
      });
}

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepositoryHttp(ref.watch(apiClientProvider)),
);
