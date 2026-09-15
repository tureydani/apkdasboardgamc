import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Preferencia de apariencia (claro/oscuro), elegida en Más → Apariencia.
/// Por defecto la app usa el tema claro (fondo blanco); el oscuro es opt-in.
class ThemeProvider extends ChangeNotifier {
  static const _storageKey = 'theme_mode';
  final _storage = const FlutterSecureStorage();

  ThemeMode _mode = ThemeMode.light;
  ThemeMode get mode => _mode;
  bool get isDark => _mode == ThemeMode.dark;

  Future<void> restore() async {
    final saved = await _storage.read(key: _storageKey);
    _mode = saved == 'dark' ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }

  Future<void> setDark(bool value) async {
    _mode = value ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
    await _storage.write(key: _storageKey, value: value ? 'dark' : 'light');
  }
}
