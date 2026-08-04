import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Toggle en forma de píldora — misma estructura visual que la Navbar
/// (Item 1, Tanda 6): contenedor blanco translúcido, opción no seleccionada
/// en "celestito" y la seleccionada con chip blanco + texto azul principal.
///
/// Genérico para reusarse donde haga falta (hoy: Todo/Me deben/Debo en
/// Gastos — Item 4).
class PillToggle<T> extends StatelessWidget {
  const PillToggle({super.key, required this.options, required this.selected, required this.onChanged});

  final List<({T value, String label})> options;
  final T selected;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          for (final opcion in options)
            Expanded(
              child: GestureDetector(
                onTap: () => onChanged(opcion.value),
                behavior: HitTestBehavior.opaque,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: opcion.value == selected
                      ? BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.08),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        )
                      : null,
                  child: Text(
                    opcion.label,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: opcion.value == selected
                              ? AppColors.primary
                              : AppColors.inactiveBlue,
                          fontWeight:
                              opcion.value == selected ? FontWeight.bold : FontWeight.normal,
                        ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
