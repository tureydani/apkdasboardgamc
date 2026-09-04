import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:path_provider/path_provider.dart';

import 'app_config.dart';

/// Cliente HTTP único para toda la app. Mantiene las cookies de sesión de
/// NextAuth (authjs.session-token) igual que lo haría un navegador, porque
/// el backend está montado sobre NextAuth con cookies HttpOnly, no tokens
/// Bearer.
class ApiClient {
  ApiClient._internal();
  static final ApiClient instance = ApiClient._internal();

  late final Dio dio = Dio(
    BaseOptions(
      baseUrl: AppConfig.baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 20),
      followRedirects: false,
      validateStatus: (status) => status != null && status < 500,
      headers: {'Accept': 'application/json'},
    ),
  );

  PersistCookieJar? _cookieJar;
  bool _ready = false;

  Future<void> ensureReady() async {
    if (_ready) return;
    final dir = await getApplicationDocumentsDirectory();
    _cookieJar = PersistCookieJar(
      ignoreExpires: true,
      storage: FileStorage('${dir.path}/.cookies/'),
    );
    dio.interceptors.add(CookieManager(_cookieJar!));
    _ready = true;
  }

  Future<void> clearCookies() async {
    await ensureReady();
    await _cookieJar?.deleteAll();
  }

  /// Obtiene el token CSRF que NextAuth exige antes de cualquier login
  /// (ver GET /api/auth/csrf en api-tests.http del proyecto web).
  Future<String> fetchCsrfToken() async {
    await ensureReady();
    final res = await dio.get('/api/auth/csrf');
    return res.data['csrfToken'] as String;
  }

  /// Todas las rutas /api/dashboard/** responden { ok: true, data: ... } o
  /// { ok: false, message: "..." } (ver src/lib/api/helpers.ts apiRoute).
  /// Este helper desenvuelve esa forma y lanza [ApiException] en error.
  dynamic _unwrap(Response res) {
    final body = res.data;
    if (body is Map && body.containsKey('ok')) {
      if (body['ok'] == true) return body['data'];
      throw ApiException(
        (body['message'] as String?) ?? 'Ocurrió un error inesperado.',
        statusCode: res.statusCode,
      );
    }
    // Algunas rutas legacy (ej. /api/citizens) no usan el envoltorio.
    if (res.statusCode != null && res.statusCode! >= 400) {
      throw ApiException('Error del servidor (${res.statusCode}).', statusCode: res.statusCode);
    }
    return body;
  }

  Future<dynamic> get(String path, {Map<String, dynamic>? query}) async {
    await ensureReady();
    final res = await dio.get(path, queryParameters: query);
    return _unwrap(res);
  }

  Future<dynamic> post(String path, {Map<String, dynamic>? body}) async {
    await ensureReady();
    final res = await dio.post(path, data: body ?? {});
    return _unwrap(res);
  }

  Future<dynamic> put(String path, {Map<String, dynamic>? body}) async {
    await ensureReady();
    final res = await dio.put(path, data: body ?? {});
    return _unwrap(res);
  }

  Future<dynamic> patch(String path, {Map<String, dynamic>? body}) async {
    await ensureReady();
    final res = await dio.patch(path, data: body ?? {});
    return _unwrap(res);
  }

  Future<dynamic> delete(String path, {Map<String, dynamic>? body}) async {
    await ensureReady();
    final res = await dio.delete(path, data: body);
    return _unwrap(res);
  }
}

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  ApiException(this.message, {this.statusCode});
  @override
  String toString() => message;
}
