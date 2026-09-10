import 'package:geolocator/geolocator.dart';

enum LocationResultStatus { success, serviceDisabled, permissionDenied, permissionDeniedForever, error }

class LocationResult {
  final LocationResultStatus status;
  final Position? position;

  const LocationResult(this.status, [this.position]);
}

/// Mismo flujo de permisos que arconde-gamc
/// (lib/core/services/location_service.dart): pide el permiso de ubicación
/// solo cuando el usuario lo necesita (botón "Mi ubicación"), no al abrir
/// la app.
class LocationService {
  static Future<Position?> getCurrentPosition() async {
    final result = await getCurrentPositionResult();
    return result.position;
  }

  static Future<LocationResult> getCurrentPositionResult() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return const LocationResult(LocationResultStatus.serviceDisabled);

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied) {
      return const LocationResult(LocationResultStatus.permissionDenied);
    }
    if (permission == LocationPermission.deniedForever) {
      return const LocationResult(LocationResultStatus.permissionDeniedForever);
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      return LocationResult(LocationResultStatus.success, position);
    } catch (_) {
      return const LocationResult(LocationResultStatus.error);
    }
  }
}
