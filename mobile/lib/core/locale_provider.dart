import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'network/token_storage.dart';

/// Idioma elegido por el usuario (NFR#6, H-13). El MVP arranca en español
/// ([F5](../../docs/02-decisiones.md)), pero ahora se puede cambiar a inglés y
/// la preferencia queda guardada en el dispositivo.
class LocaleNotifier extends AsyncNotifier<Locale> {
  @override
  Future<Locale> build() async {
    final storage = ref.watch(tokenStorageProvider);
    final code = await storage.read(StorageKeys.localeCode);
    return Locale(code == 'en' ? 'en' : 'es');
  }

  Future<void> cambiar(String code) async {
    final normalizado = code == 'en' ? 'en' : 'es';
    state = AsyncData(Locale(normalizado));
    await ref.read(tokenStorageProvider).write(StorageKeys.localeCode, normalizado);
  }
}

final localeProvider = AsyncNotifierProvider<LocaleNotifier, Locale>(LocaleNotifier.new);
