import 'package:dio/dio.dart';

import '../core/api_client.dart';
import '../models/session_user.dart';

class AuthException implements Exception {
  final String message;
  AuthException(this.message);
  @override
  String toString() => message;
}

/// Replica el flujo de NextAuth Credentials que usa el dashboard web:
/// 1) GET /api/auth/csrf
/// 2) POST /api/auth/callback/institution (email/password) o
///    POST /api/auth/callback/citizen (phoneNumber/password)
/// 3) GET /api/auth/session para confirmar y obtener los datos del usuario
class AuthService {
  final _client = ApiClient.instance;

  Future<SessionUser> loginInstitution({
    required String email,
    required String password,
  }) async {
    await _client.ensureReady();
    final csrf = await _client.fetchCsrfToken();

    final res = await _client.dio.post(
      '/api/auth/callback/institution',
      data: {
        'csrfToken': csrf,
        'email': email,
        'password': password,
        'redirect': 'false',
        'json': 'true',
      },
      options: Options(
        contentType: Headers.formUrlEncodedContentType,
        followRedirects: false,
        validateStatus: (s) => s != null && s < 500,
      ),
    );

    // NextAuth responde 302 hacia la página de error si las credenciales
    // son inválidas (location contiene "error="), o hacia "/" si es válido.
    final location = res.headers.value('location') ?? '';
    if (res.statusCode == 302 && location.contains('error=')) {
      throw AuthException('Correo o contraseña incorrectos.');
    }

    return fetchSession();
  }

  Future<SessionUser> loginCitizen({
    required String phoneNumber,
    required String password,
  }) async {
    await _client.ensureReady();
    final csrf = await _client.fetchCsrfToken();

    final res = await _client.dio.post(
      '/api/auth/callback/citizen',
      data: {
        'csrfToken': csrf,
        'phoneNumber': phoneNumber,
        'password': password,
        'redirect': 'false',
        'json': 'true',
      },
      options: Options(
        contentType: Headers.formUrlEncodedContentType,
        followRedirects: false,
        validateStatus: (s) => s != null && s < 500,
      ),
    );

    final location = res.headers.value('location') ?? '';
    if (res.statusCode == 302 && location.contains('error=')) {
      throw AuthException('Teléfono o contraseña incorrectos.');
    }

    return fetchSession();
  }

  Future<SessionUser> fetchSession() async {
    await _client.ensureReady();
    final res = await _client.dio.get('/api/auth/session');
    final data = res.data;
    if (data == null || data is! Map || data['user'] == null) {
      throw AuthException('No se pudo iniciar sesión. Verifica tus datos.');
    }
    return SessionUser.fromJson(Map<String, dynamic>.from(data['user']));
  }

  Future<void> logout() async {
    await _client.ensureReady();
    final csrf = await _client.fetchCsrfToken();
    await _client.dio.post(
      '/api/auth/signout',
      data: {'csrfToken': csrf, 'json': 'true'},
      options: Options(contentType: Headers.formUrlEncodedContentType),
    );
    await _client.clearCookies();
  }
}
