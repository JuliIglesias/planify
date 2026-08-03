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
  const SesionOrganizador({required this.usuarioId, required this.nombre});
  final String usuarioId;
  final String nombre;
}

class SesionAnonima extends Session {
  const SesionAnonima({required this.eventoId, required this.nombre});
  final String eventoId;
  final String nombre;
}

class SessionController extends AsyncNotifier<Session> {
  @override
  Future<Session> build() async {
    final storage = ref.watch(tokenStorageProvider);

    // Si quedó un evento guardado, el anónimo vuelve directo ahí (seguimiento F1).
    final eventoId = await storage.read(StorageKeys.anonEventId);
    final participantToken = await storage.read(StorageKeys.participantToken);
    if (eventoId != null && participantToken != null) {
      return SesionAnonima(eventoId: eventoId, nombre: '');
    }

    return const SinSesion();
  }

  Future<void> loginOrganizador(String email, String password) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final api = ref.read(authRepositoryProvider);
      final storage = ref.read(tokenStorageProvider);

      final res = await api.login(email, password);
      await storage.write(StorageKeys.organizerToken, res.token);

      return SesionOrganizador(usuarioId: res.usuarioId, nombre: res.nombre);
    });
  }

  /// HU-27 — registro de una cuenta real; deja la sesión iniciada.
  Future<void> registrar(String nombre, String email, String password) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final api = ref.read(authRepositoryProvider);
      final storage = ref.read(tokenStorageProvider);

      final res = await api.register(nombre, email, password);
      await storage.write(StorageKeys.organizerToken, res.token);

      return SesionOrganizador(usuarioId: res.usuarioId, nombre: res.nombre);
    });
  }

  /// HU-01/HU-02/HU-03 — el anónimo se une a un evento existente por link.
  /// Nunca crea eventos.
  Future<void> unirseComoAnonimo({
    required String eventoId,
    required String nombreDisplay,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final api = ref.read(authRepositoryProvider);
      final storage = ref.read(tokenStorageProvider);

      final res = await api.unirseComoAnonimo(
        eventoId: eventoId,
        nombreDisplay: nombreDisplay,
      );

      await storage.write(StorageKeys.participantToken, res.tokenSesion);
      await storage.write(StorageKeys.anonEventId, eventoId);

      return SesionAnonima(eventoId: eventoId, nombre: nombreDisplay);
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
