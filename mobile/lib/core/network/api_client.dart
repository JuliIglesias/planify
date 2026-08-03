import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'token_storage.dart';

final apiClientProvider = Provider<Dio>((ref) {
  final storage = ref.watch(tokenStorageProvider);

  final dio = Dio(
    BaseOptions(
      // 10.0.2.2 es el localhost de la máquina desde el emulador de Android
      // (dev, HTTP directo al backend). Al desplegar, apuntar al proxy TLS del
      // ambiente demo por HTTPS — NFR#7, cifrado en tránsito (ver infra/Caddyfile):
      //   flutter run --dart-define=PLANIFY_API_URL=https://<dominio-demo>
      baseUrl: const String.fromEnvironment(
        'PLANIFY_API_URL',
        defaultValue: 'http://10.0.2.2:3000',
      ),
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ),
  );

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        // Los dos caminos de sesión del MVP conviven: organizador (JWT) y
        // anónimo (token de participante). Ver docs/02-decisiones.md Duda #19.
        final organizerToken = await storage.read(StorageKeys.organizerToken);
        if (organizerToken != null) {
          options.headers['Authorization'] = 'Bearer $organizerToken';
        }

        final participantToken = await storage.read(StorageKeys.participantToken);
        if (participantToken != null) {
          options.headers['X-Participant-Token'] = participantToken;
        }

        handler.next(options);
      },
    ),
  );

  return dio;
});
