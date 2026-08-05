import 'package:characters/characters.dart';

/// Iniciales de un nombre para el fallback de avatar — "Juan Pérez" → "JP",
/// "Juan" → "J". Único lugar donde vive esta lógica (docs/06-design-system.md
/// §2.2 — antes estaba duplicada en `AvatarStack` y en `groups_screen.dart`).
String initialsOf(String nombre) {
  final partes = nombre.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
  if (partes.isEmpty) return '?';
  if (partes.length == 1) return partes.first.characters.first.toUpperCase();
  return (partes.first.characters.first + partes[1].characters.first).toUpperCase();
}
