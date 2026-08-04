import 'package:flutter/material.dart';

/// Diálogo base de la app (tanda-4 / Item 3).
///
/// Equivalente a [AlertDialog] pero con [insetPadding] fijo de 16 px
/// horizontales para que el modal ocupe el ancho del dispositivo menos
/// 16 px de margen a cada lado (en lugar de los 40 px que usa Material por
/// defecto, que generan un modal demasiado angosto en pantallas medianas).
///
/// Uso:
/// ```dart
/// showDialog(
///   context: context,
///   builder: (_) => AppDialog(
///     title: Text('Título'),
///     content: Text('Contenido'),
///     actions: [
///       TextButton(...),
///       FilledButton(...),
///     ],
///   ),
/// );
/// ```
class AppDialog extends StatelessWidget {
  const AppDialog({
    super.key,
    this.title,
    this.content,
    this.actions,
    this.scrollable = false,
    this.contentPadding,
    this.actionsPadding,
    this.titlePadding,
  });

  final Widget? title;
  final Widget? content;
  final List<Widget>? actions;
  final bool scrollable;
  final EdgeInsetsGeometry? contentPadding;
  final EdgeInsetsGeometry? actionsPadding;
  final EdgeInsetsGeometry? titlePadding;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      // 16 px a cada lado → el modal usa el ancho completo de la pantalla
      // menos 32 px totales (consistente con los márgenes del resto de la UI).
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      title: title,
      content: content,
      actions: actions,
      scrollable: scrollable,
      contentPadding: contentPadding,
      actionsPadding: actionsPadding,
      titlePadding: titlePadding,
    );
  }
}
