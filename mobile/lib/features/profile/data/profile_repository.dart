import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/api_exception.dart';
import '../../../core/models/models.dart';
import '../../../core/network/api_client.dart';

/// SCRUM-14 (FR12) — gestión de identidad: ver y editar el perfil propio.
abstract interface class ProfileRepository {
  /// GET /me — el perfil del usuario logueado.
  Future<PerfilUsuario> perfil();

  /// PATCH /me/profile — actualiza los campos que se pasen.
  Future<PerfilUsuario> actualizar({
    String? nombre,
    String? avatarUrl,
    String? idiomaPreferido,
  });
}

class ProfileRepositoryHttp implements ProfileRepository {
  const ProfileRepositoryHttp(this._dio);

  final Dio _dio;

  @override
  Future<PerfilUsuario> perfil() => ejecutar(() async {
        final res = await _dio.get<Map<String, dynamic>>('/me');
        return PerfilUsuario.fromJson(res.data ?? {});
      });

  @override
  Future<PerfilUsuario> actualizar({
    String? nombre,
    String? avatarUrl,
    String? idiomaPreferido,
  }) =>
      ejecutar(() async {
        final res = await _dio.patch<Map<String, dynamic>>(
          '/me/profile',
          data: {
            if (nombre != null) 'nombre': nombre,
            if (avatarUrl != null) 'avatarUrl': avatarUrl,
            if (idiomaPreferido != null) 'idiomaPreferido': idiomaPreferido,
          },
        );
        return PerfilUsuario.fromJson(res.data ?? {});
      });
}

final profileRepositoryProvider = Provider<ProfileRepository>(
  (ref) => ProfileRepositoryHttp(ref.watch(apiClientProvider)),
);

/// El perfil del usuario logueado. Se refresca tras editarlo.
final perfilProvider = FutureProvider<PerfilUsuario>(
  (ref) => ref.watch(profileRepositoryProvider).perfil(),
);
