import 'package:planify/core/network/token_storage.dart';

/// Storage en memoria para los tests: el real usa canales de plataforma que no
/// existen en un test de widget y dejan la sesión colgada en estado "loading".
class FakeTokenStorage implements TokenStorage {
  FakeTokenStorage([Map<String, String>? inicial]) : _data = {...?inicial};

  final Map<String, String> _data;

  @override
  Future<String?> read(String key) async => _data[key];

  @override
  Future<void> write(String key, String value) async => _data[key] = value;

  @override
  Future<void> delete(String key) async => _data.remove(key);
}
