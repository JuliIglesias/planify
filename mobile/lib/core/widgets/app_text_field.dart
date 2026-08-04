import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Variantes de comportamiento del [AppTextField].
///
/// - [text]     → primera letra del campo en mayúscula automáticamente.
/// - [email]    → sin capitalización; teclado de email (convención de email en minúscula).
/// - [password] → sin capitalización; texto oculto.
/// - [money]    → sin capitalización; teclado numérico con decimal.
///               El formatter de miles/decimales lo inyecta [AppTextField]
///               automáticamente desde [AppMoneyInputFormatter] cuando se
///               usa esta variante (ver `money_format.dart`).
enum AppTextFieldVariant { text, email, password, money }

/// Input reutilizable de toda la app (tanda-4 / Item 1).
///
/// Reemplaza los [TextField] y [TextFormField] sueltos para centralizar:
/// - capitalización automática de la primera letra (variante [text]).
/// - tipo de teclado y comportamiento por variante.
/// - integración futura con formatters de dinero (variante [money]).
///
/// EXCEPCIÓN: el campo de email en Login no capitaliza (usa variante [email]).
/// EXCEPCIÓN: el campo de contraseña usa variante [password] (obscureText).
class AppTextField extends StatefulWidget {
  const AppTextField({
    super.key,
    this.variant = AppTextFieldVariant.text,
    this.controller,
    this.focusNode,
    this.decoration,
    this.onChanged,
    this.onSubmitted,
    this.enabled = true,
    this.autofocus = false,
    this.textAlign = TextAlign.start,
    this.maxLines = 1,
    this.inputFormatters,
    this.textInputAction,
    this.initialValue,
  }) : assert(
          controller == null || initialValue == null,
          'No se puede usar controller e initialValue al mismo tiempo.',
        );

  final AppTextFieldVariant variant;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final InputDecoration? decoration;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final bool enabled;
  final bool autofocus;
  final TextAlign textAlign;
  final int? maxLines;
  final List<TextInputFormatter>? inputFormatters;
  final TextInputAction? textInputAction;

  /// Solo para uso sin [controller] (como el antiguo [TextFormField.initialValue]).
  final String? initialValue;

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  late TextEditingController _controller;
  bool _ownsController = false;

  @override
  void initState() {
    super.initState();
    if (widget.controller != null) {
      _controller = widget.controller!;
    } else {
      _controller = TextEditingController(text: widget.initialValue ?? '');
      _ownsController = true;
    }

    if (widget.variant == AppTextFieldVariant.text) {
      _controller.addListener(_capitalizarPrimeraLetra);
    }
  }

  @override
  void didUpdateWidget(AppTextField old) {
    super.didUpdateWidget(old);
    // Si cambia el controller externo, reenganchamos el listener.
    if (old.controller != widget.controller) {
      if (old.variant == AppTextFieldVariant.text && old.controller != null) {
        old.controller!.removeListener(_capitalizarPrimeraLetra);
      }
      if (_ownsController) {
        _controller.removeListener(_capitalizarPrimeraLetra);
        _controller.dispose();
      }
      if (widget.controller != null) {
        _controller = widget.controller!;
        _ownsController = false;
      } else {
        _controller = TextEditingController(text: widget.initialValue ?? '');
        _ownsController = true;
      }
      if (widget.variant == AppTextFieldVariant.text) {
        _controller.addListener(_capitalizarPrimeraLetra);
      }
    }
  }

  @override
  void dispose() {
    if (widget.variant == AppTextFieldVariant.text) {
      _controller.removeListener(_capitalizarPrimeraLetra);
    }
    if (_ownsController) _controller.dispose();
    super.dispose();
  }

  /// Capitaliza solo la primera letra del campo completo.
  ///
  /// "carne corte asado" → "Carne corte asado" (sentence case, no title case).
  /// Se activa en cada keystroke pero solo modifica cuando el primer carácter
  /// es minúscula y la selección ya pasó de él, para no interferir con el
  /// cursor del usuario.
  void _capitalizarPrimeraLetra() {
    final texto = _controller.text;
    if (texto.isEmpty) return;

    final primerChar = texto[0];
    final primerMayus = primerChar.toUpperCase();
    if (primerChar == primerMayus) return; // ya está en mayúscula o es no-letra

    // Solo capitaliza; no mueve el cursor.
    final selection = _controller.selection;
    _controller.value = _controller.value.copyWith(
      text: primerMayus + texto.substring(1),
      selection: selection,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isPassword = widget.variant == AppTextFieldVariant.password;
    final isMoney = widget.variant == AppTextFieldVariant.money;
    final isEmail = widget.variant == AppTextFieldVariant.email;

    TextInputType keyboardType;
    if (isEmail) {
      keyboardType = TextInputType.emailAddress;
    } else if (isPassword) {
      keyboardType = TextInputType.text;
    } else if (isMoney) {
      keyboardType = const TextInputType.numberWithOptions(decimal: true);
    } else {
      keyboardType = TextInputType.text;
    }

    // Los formatters del caller se combinan con los propios de la variante.
    final List<TextInputFormatter> formatters = [
      ...?widget.inputFormatters,
    ];

    return TextField(
      controller: _controller,
      focusNode: widget.focusNode,
      enabled: widget.enabled,
      autofocus: widget.autofocus,
      obscureText: isPassword,
      keyboardType: keyboardType,
      textAlign: widget.textAlign,
      maxLines: isPassword ? 1 : widget.maxLines,
      decoration: widget.decoration,
      inputFormatters: formatters.isEmpty ? null : formatters,
      textInputAction: widget.textInputAction,
      onChanged: widget.onChanged,
      onSubmitted: widget.onSubmitted,
    );
  }
}
