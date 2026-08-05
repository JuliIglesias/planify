import 'package:flutter/material.dart';

import 'app_avatar.dart';

/// Fila "persona" — avatar + nombre + subtítulo opcional + acción/trailing.
/// docs/06-design-system.md §6.1: consolida el `ListTile`/`CheckboxListTile`
/// que hoy arma cada pantalla de Amigos por separado (mis amigos,
/// solicitudes recibidas/enviadas, selector de amigos, perfil de amigo).
class AppPersonRow extends StatelessWidget {
  const AppPersonRow({
    super.key,
    required this.nombre,
    this.subtitulo,
    this.avatarUrl,
    this.trailing,
    this.onTap,
    this.leadingRadius = 22,
  });

  final String nombre;
  final String? subtitulo;
  final String? avatarUrl;

  /// Botón/badge/checkbox al final de la fila — `null` para una fila de
  /// solo lectura.
  final Widget? trailing;
  final VoidCallback? onTap;
  final double leadingRadius;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListTile(
      onTap: onTap,
      leading: AppAvatar(nombre: nombre, imageUrl: avatarUrl, radius: leadingRadius),
      title: Text(nombre, style: theme.textTheme.titleSmall),
      subtitle: subtitulo != null ? Text(subtitulo!, style: theme.textTheme.bodySmall) : null,
      trailing: trailing,
    );
  }
}
