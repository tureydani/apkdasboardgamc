import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../models/session_user.dart';
import '../services/auth_service.dart';

enum SessionStatus { unknown, authenticated, unauthenticated }

/// Estado global de sesión, disponible en toda la app vía Provider.
/// No guarda contraseñas: solo recuerda qué tipo de login se usó por
/// última vez para poder restaurar la sesión al reabrir la app (las
/// cookies de NextAuth ya persisten en disco vía PersistCookieJar).
class SessionProvider extends ChangeNotifier {
  final _authService = AuthService();
  final _storage = const FlutterSecureStorage();

  SessionStatus status = SessionStatus.unknown;
  SessionUser? user;
  String? errorMessage;
  bool loading = false;

  Future<void> restore() async {
    try {
      final restored = await _authService.fetchSession();
      user = restored;
      status = SessionStatus.authenticated;
    } catch (_) {
      status = SessionStatus.unauthenticated;
    }
    notifyListeners();
  }

  Future<bool> loginInstitution(String email, String password) async {
    loading = true;
    errorMessage = null;
    notifyListeners();
    try {
      user = await _authService.loginInstitution(email: email, password: password);
      status = SessionStatus.authenticated;
      await _storage.write(key: 'last_login_type', value: 'institution');
      return true;
    } on AuthException catch (e) {
      errorMessage = e.message;
      return false;
    } catch (e) {
      errorMessage = 'No se pudo conectar con el servidor. Verifica tu conexión.';
      return false;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<bool> loginCitizen(String phoneNumber, String password) async {
    loading = true;
    errorMessage = null;
    notifyListeners();
    try {
      user = await _authService.loginCitizen(phoneNumber: phoneNumber, password: password);
      status = SessionStatus.authenticated;
      await _storage.write(key: 'last_login_type', value: 'citizen');
      return true;
    } on AuthException catch (e) {
      errorMessage = e.message;
      return false;
    } catch (e) {
      errorMessage = 'No se pudo conectar con el servidor. Verifica tu conexión.';
      return false;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await _authService.logout();
    user = null;
    status = SessionStatus.unauthenticated;
    notifyListeners();
  }
}
