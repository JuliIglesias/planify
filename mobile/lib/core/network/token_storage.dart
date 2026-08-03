import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Claves de almacenamiento seguro.
/// [anonEventId] implementa el retorno del usuario anónimo a su evento
/// (docs/02-decisiones.md, Duda #5 / seguimiento F1).
abstract final class StorageKeys {
  static const organizerToken = 'organizer_token';
  static const participantToken = 'participant_token';
  static const anonEventId = 'anon_event_id';
  static const profileAvailability = 'profile_availability';
  static const localeCode = 'locale_code';
}

/// Interfaz mínima de almacenamiento. Existe para que el código de la app no
/// dependa de la firma exacta de flutter_secure_storage (que cambia entre
/// versiones) y para poder falsearla en tests sin canales de plataforma.
abstract interface class TokenStorage {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
  Future<void> delete(String key);
}

class SecureTokenStorage implements TokenStorage {
  const SecureTokenStorage(this._storage);

  final FlutterSecureStorage _storage;

  @override
  Future<String?> read(String key) => _storage.read(key: key);

  @override
  Future<void> write(String key, String value) => _storage.write(key: key, value: value);

  @override
  Future<void> delete(String key) => _storage.delete(key: key);
}

final tokenStorageProvider = Provider<TokenStorage>(
  (ref) => const SecureTokenStorage(FlutterSecureStorage()),
);
