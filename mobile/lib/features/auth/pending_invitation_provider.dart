import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Item 2 — token de invitación pendiente de aplicar.
///
/// El link de invitación solo dice a qué evento/grupo se está uniendo la
/// persona; no fuerza ningún camino de acceso. Se guarda acá (root de la app,
/// ver `_RootRouter` en `main.dart`) apenas llega el deep link, y se aplica
/// recién cuando hay una sesión real: si ya había una, de inmediato; si no,
/// después de que el usuario elija Ingresar, Crear cuenta o Continuar como
/// Anónimo en el Login.
class PendingInvitation extends Notifier<String?> {
  @override
  String? build() => null;

  void set(String? token) => state = token;
}

final pendingInvitationProvider =
    NotifierProvider<PendingInvitation, String?>(PendingInvitation.new);
