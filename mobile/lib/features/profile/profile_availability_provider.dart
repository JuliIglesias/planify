import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/token_storage.dart';
import '../../core/widgets/weekly_availability_grid.dart';
import 'data/profile_repository.dart';

/// Disponibilidad semanal de perfil. Ahora se persiste en el backend (H-14) con
/// una **caché local** de fallback: si no hay red (o es sesión anónima, que no
/// tiene endpoint de perfil), se usa lo guardado en el dispositivo.
class ProfileAvailabilityNotifier extends AsyncNotifier<Set<AvailabilitySlot>> {
  @override
  Future<Set<AvailabilitySlot>> build() async {
    // 1) Intentar el backend.
    try {
      final slots = await ref.read(profileRepositoryProvider).obtenerDisponibilidad();
      final set = slots.map((s) => AvailabilitySlot(s.diaSemana, s.bloqueHora)).toSet();
      await _cachearLocal(set);
      return set;
    } catch (_) {
      // 2) Fallback: caché local.
      return _leerLocal();
    }
  }

  Future<void> guardar(Set<AvailabilitySlot> slots) async {
    state = AsyncData(slots);
    await _cachearLocal(slots);
    // Best-effort al backend: si falla (offline/anon), queda al menos en local.
    try {
      await ref.read(profileRepositoryProvider).guardarDisponibilidad(
            slots.map((s) => (diaSemana: s.diaSemana, bloqueHora: s.bloqueHora)).toList(),
          );
    } catch (_) {
      // Se reintenta la próxima vez que se guarde.
    }
  }

  Future<Set<AvailabilitySlot>> _leerLocal() async {
    final raw = await ref.read(tokenStorageProvider).read(StorageKeys.profileAvailability);
    if (raw == null || raw.isEmpty) return {};
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((item) => AvailabilitySlot(
                (item as Map<String, dynamic>)['diaSemana'] as int,
                item['bloqueHora'] as int,
              ))
          .toSet();
    } catch (_) {
      return {};
    }
  }

  Future<void> _cachearLocal(Set<AvailabilitySlot> slots) async {
    final encoded = jsonEncode(
      slots.map((s) => {'diaSemana': s.diaSemana, 'bloqueHora': s.bloqueHora}).toList(),
    );
    await ref.read(tokenStorageProvider).write(StorageKeys.profileAvailability, encoded);
  }
}

final profileAvailabilityProvider =
    AsyncNotifierProvider<ProfileAvailabilityNotifier, Set<AvailabilitySlot>>(
  ProfileAvailabilityNotifier.new,
);
