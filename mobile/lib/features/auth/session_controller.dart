import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'data/auth_repository.dart';
import '../../core/network/token_storage.dart';

/// Quién está usando la app. En el MVP hay dos caminos (Duda #19):
///  - organizador: usuario semilla logueado, único que puede crear eventos
///  - anónimo: entró por link de invitación, solo participa
sealed class Session {
  const Session();
}

class SinSesion extends Session {
  const SinSesion();
}

class SesionOrganizador extends Session {
  const SesionOrganizador({required this.usuarioId, required this.username});
  final String usuarioId;
  final String username;
}

class SesionAnonima extends Session {
  const SesionAnonima({required this.eventoId, required this.username});
  final String eventoId;
  final String username;
}

class SessionController extends AsyncNotifier<Session> {
  @override
  Future<Session> build() async {
    final storage = ref.watch(tokenStorageProvider);

    // Si quedó un evento guardado, el anónimo vuelve directo ahí (seguimiento F1).
    final eventoId = await storage.read(StorageKeys.anonEventId);
    final participantToken = await storage.read(StorageKeys.participantToken);
    if (eventoId != null && participantToken != null) {
      return SesionAnonima(eventoId: eventoId, username: '');
    }

    return const SinSesion();
  }

  /// HU-41/HU-28 — el identificador puede ser el email o el username.
  Future<void> loginOrganizador(String identificador, String password) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final api = ref.read(authRepositoryProvider);
      final storage = ref.read(tokenStorageProvider);

      final res = await api.login(identificador, password);
      await storage.write(StorageKeys.organizerToken, res.token);

      return SesionOrganizador(usuarioId: res.usuarioId, username: res.username);
    });
  }

  /// HU-27 — registro de una cuenta real; deja la sesión iniciada.
  Future<void> registrar(String username, String email, String password) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final api = ref.read(authRepositoryProvider);
      final storage = ref.read(tokenStorageProvider);

      final res = await api.register(username, email, password);
      await storage.write(StorageKeys.organizerToken, res.token);

      return SesionOrganizador(usuarioId: res.usuarioId, username: res.username);
    });
  }

  /// HU-01/HU-02/HU-03 — el anónimo se une a un evento existente por link.
  /// Nunca crea eventos. El username final puede diferir del pedido si el
  /// backend tuvo que auto-sufijarlo por colisión (ver docs/05-fixes.md).
  Future<void> unirseComoAnonimo({
    required String eventoId,
    required String username,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final api = ref.read(authRepositoryProvider);
      final storage = ref.read(tokenStorageProvider);

      final res = await api.unirseComoAnonimo(
        eventoId: eventoId,
        username: username,
      );

      await storage.write(StorageKeys.participantToken, res.tokenSesion);
      await storage.write(StorageKeys.anonEventId, eventoId);

      return SesionAnonima(eventoId: eventoId, username: res.username);
    });
  }

  Future<void> cerrarSesion() async {
    final storage = ref.read(tokenStorageProvider);
    await storage.delete(StorageKeys.organizerToken);
    await storage.delete(StorageKeys.participantToken);
    await storage.delete(StorageKeys.anonEventId);
    state = const AsyncData(SinSesion());
  }
}

final sessionControllerProvider =
    AsyncNotifierProvider<SessionController, Session>(SessionController.new);
