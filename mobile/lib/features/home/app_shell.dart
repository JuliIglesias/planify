import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/widgets/app_scaffold.dart';
import '../balances/balances_screen.dart';
import '../events/create_event_screen.dart';
import '../events/widgets/quick_expense_sheet.dart';
import '../groups/groups_screen.dart';
import '../profile/profile_screen.dart';
import 'home_screen.dart';

/// Contenedor de las 4 pantallas raíz con el bottom nav
/// (docs/00-ui-entendimiento.md §1).
class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  int _index = 0;

  // A1/A2 — mide la altura REAL de la navbar (ahora "hug content", sin
  // `height` fijo) para publicarla en `bottomNavHeightProvider`, y así las
  // 4 pantallas raíz saben cuánto padding inferior necesitan para no quedar
  // tapadas por la barra flotante (`extendBody: true`).
  final _navKey = GlobalKey();

  void _medirNavbar() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final box = _navKey.currentContext?.findRenderObject() as RenderBox?;
      if (box == null || !box.hasSize) return;
      final alto = box.size.height;
      if (ref.read(bottomNavHeightProvider) != alto) {
        ref.read(bottomNavHeightProvider.notifier).set(alto);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Se remide en cada build: el contenido de la navbar es estático (los
    // mismos 4 ítems siempre), pero esto la mantiene correcta ante cambios
    // de tamaño de fuente del sistema, rotación, etc. sin costo real (es un
    // solo `RenderBox.size` leído después del frame).
    _medirNavbar();

    return Scaffold(
      extendBody: true,
      body: SafeArea(
        bottom: false,
        child: IndexedStack(
          index: _index,
          children: const [
            HomeScreen(),
            GroupsScreen(),
            BalancesScreen(),
            ProfileScreen(),
          ],
        ),
      ),
      // El FAB no aparece en Perfil: ahí no hay nada que crear.
      // Item 4 (Tanda 6) — es contextual: en Gastos (Saldos) crea un GASTO,
      // no un evento (eso queda para Home y Grupos).
      floatingActionButton: _index == 3
          ? null
          : FloatingActionButton(
              onPressed: () => _index == 2
                  ? iniciarCrearGastoRapido(context, ref)
                  : Navigator.of(context).push(
                      MaterialPageRoute<void>(builder: (_) => const CreateEventScreen()),
                    ),
              child: const Icon(Icons.add),
            ),
      bottomNavigationBar: AppBottomNav(
        key: _navKey,
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
      ),
    );
  }
}
