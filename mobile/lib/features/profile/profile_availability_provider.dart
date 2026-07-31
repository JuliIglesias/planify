import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/token_storage.dart';
import '../../core/widgets/weekly_availability_grid.dart';

class ProfileAvailabilityNotifier extends AsyncNotifier<Set<AvailabilitySlot>> {
  @override
  Future<Set<AvailabilitySlot>> build() async {
    final storage = ref.watch(tokenStorageProvider);
    final raw = await storage.read(StorageKeys.profileAvailability);
    if (raw == null || raw.isEmpty) return {};
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list.map((item) {
        final map = item as Map<String, dynamic>;
        return AvailabilitySlot(map['diaSemana'] as int, map['bloqueHora'] as int);
      }).toSet();
    } catch (_) {
      return {};
    }
  }

  Future<void> guardar(Set<AvailabilitySlot> slots) async {
    state = AsyncData(slots);
    final storage = ref.read(tokenStorageProvider);
    final encoded = jsonEncode(
      slots.map((s) => {'diaSemana': s.diaSemana, 'bloqueHora': s.bloqueHora}).toList(),
    );
    await storage.write(StorageKeys.profileAvailability, encoded);
  }
}

final profileAvailabilityProvider =
    AsyncNotifierProvider<ProfileAvailabilityNotifier, Set<AvailabilitySlot>>(
  ProfileAvailabilityNotifier.new,
);
