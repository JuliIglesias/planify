import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/api_exception.dart';
import '../../../core/network/api_client.dart';

class SesionOrganizadorDto {
  const SesionOrganizadorDto({
    required this.token,
    required this.usuarioId,
    required this.nombre,
  });

  final String token;
  final String usuarioId;
  final String nombre;
}

class SesionAnonimaDto {
  const SesionAnonimaDto({required this.participanteId, required this.tokenSesion});

  final String participanteId;
  final String tokenSesion;
}

/// SCRUM-7 — acceso a la app. Las pantallas dependen de esta interfaz, no de Dio.
abstract interface class AuthRepository {
  /// HU-41 — login del organizador semilla / usuario registrado.
  Future<SesionOrganizadorDto> login(String email, String password);

  /// HU-27 — registro de una cuenta real.
  Future<SesionOrganizadorDto> register(String nombre, String email, String password);

  /// HU-01/HU-03 — un anónimo se une a un evento existente.
  Future<SesionAnonimaDto> unirseComoAnonimo({
    required String eventoId,
    required String nombreDisplay,
  });

  /// HU-02 — resuelve un link de invitación al id del evento.
  Future<String> resolverInvitacion(String token);
}

class AuthRepositoryHttp implements AuthRepository {
  const AuthRepositoryHttp(this._dio);

  final Dio _dio;

  @override
  Future<SesionOrganizadorDto> login(String email, String password) => ejecutar(() async {
        final res = await _dio.post<Map<String, dynamic>>(
          '/auth/login',
          data: {'email': email, 'password': password},
        );
        final usuario = res.data!['usuario'] as Map<String, dynamic>;
        return SesionOrganizadorDto(
          token: res.data!['token'] as String,
          usuarioId: usuario['id'] as String,
          nombre: usuario['nombre'] as String,
        );
      });

  @override
  Future<SesionOrganizadorDto> register(String nombre, String email, String password) =>
      ejecutar(() async {
        final res = await _dio.post<Map<String, dynamic>>(
          '/auth/register',
          data: {'nombre': nombre, 'email': email, 'password': password},
        );
        final usuario = res.data!['usuario'] as Map<String, dynamic>;
        return SesionOrganizadorDto(
          token: res.data!['token'] as String,
          usuarioId: usuario['id'] as String,
          nombre: usuario['nombre'] as String,
        );
      });

  @override
  Future<SesionAnonimaDto> unirseComoAnonimo({
    required String eventoId,
    required String nombreDisplay,
  }) =>
      ejecutar(() async {
        final res = await _dio.post<Map<String, dynamic>>(
          '/participants/anonymous',
          data: {'eventoId': eventoId, 'nombreDisplay': nombreDisplay},
        );
        return SesionAnonimaDto(
          participanteId: res.data!['participanteId'] as String,
          tokenSesion: res.data!['tokenSesion'] as String,
        );
      });

  @override
  Future<String> resolverInvitacion(String token) => ejecutar(() async {
        final res = await _dio.get<Map<String, dynamic>>('/invitations/$token');
        return res.data!['eventoId'] as String;
      });
}

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepositoryHttp(ref.watch(apiClientProvider)),
);
