import 'package:dio/dio.dart';

/// Error de dominio de la app, sin rastros de Dio.
///
/// Las pantallas nunca ven un `DioException`: así, si mañana se cambia el
/// cliente HTTP, la UI no se entera. También evita mostrarle al usuario
/// mensajes técnicos como "connection refused".
class ApiException implements Exception {
  const ApiException(this.mensaje, {this.statusCode, this.esDeRed = false});

  final String mensaje;
  final int? statusCode;
  final bool esDeRed;

  /// Traduce un error de Dio al lenguaje de la app.
  factory ApiException.desdeDio(DioException e) {
    final esTimeoutOSinConexion = switch (e.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.receiveTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.connectionError =>
        true,
      _ => false,
    };

    if (esTimeoutOSinConexion) {
      return const ApiException('No pudimos conectarnos al servidor', esDeRed: true);
    }

    final data = e.response?.data;
    final mensajeServidor = data is Map<String, dynamic> ? data['error'] as String? : null;

    return ApiException(
      mensajeServidor ?? 'Error inesperado del servidor',
      statusCode: e.response?.statusCode,
    );
  }

  @override
  String toString() => mensaje;
}

/// Ejecuta una llamada HTTP traduciendo cualquier fallo a [ApiException].
Future<T> ejecutar<T>(Future<T> Function() llamada) async {
  try {
    return await llamada();
  } on DioException catch (e) {
    throw ApiException.desdeDio(e);
  }
}
