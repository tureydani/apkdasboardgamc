import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Preferencia local (no vinculada al backend, no requiere sesión) de si
/// este dispositivo debe compartir su ubicación en vivo mientras una unidad
/// está EN_CAMINO. Apagarla no cancela ni afecta el despacho en sí — solo
/// detiene el envío de posición GPS de [UnitTrackingService]; la central
/// deja de ver la ruta en vivo hasta que se reactive.
class GpsPreferenceService {
  GpsPreferenceService._();

  static const _storage = FlutterSecureStorage();
  static const _key = 'gps_sharing_enabled';

  static Future<bool> isSharingEnabled() async {
    final value = await _storage.read(key: _key);
    return value != 'false'; // Activado por defecto.
  }

  static Future<void> setSharingEnabled(bool enabled) {
    return _storage.write(key: _key, value: enabled ? 'true' : 'false');
  }
}
