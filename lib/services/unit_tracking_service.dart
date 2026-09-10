import 'dart:async';

import 'package:geolocator/geolocator.dart';

import '../core/services/location_service.dart';
import '../core/tracking_config.dart';
import 'dispatch_service.dart';

/// Envía la ubicación de la unidad al backend mientras una asignación está
/// EN_CAMINO (POST /api/dashboard/dispatch/[id]/tracking, ya existente —
/// ver DispatchService.pushTracking). Solo primer plano: si la app se
/// minimiza, el stream del sistema operativo se pausa y el envío se detiene
/// solo hasta volver a foreground.
///
/// Una unidad físicamente solo puede estar en camino a un incidente a la
/// vez, así que este servicio sigue una sola asignación por instancia.
class UnitTrackingService {
  UnitTrackingService._internal();
  static final UnitTrackingService instance = UnitTrackingService._internal();

  final _dispatchService = DispatchService();

  int? _assignmentId;
  StreamSubscription<Position>? _positionSub;
  Timer? _fallbackTimer;
  Position? _lastKnownPosition;
  DateTime? _lastPushAt;

  bool get isTracking => _assignmentId != null;

  Future<void> start(int assignmentId) async {
    if (_assignmentId == assignmentId) return;
    await stop();

    final permission = await LocationService.getCurrentPositionResult();
    if (permission.status != LocationResultStatus.success) {
      // Sin permiso/GPS no hay nada que enviar; el flujo de despacho no
      // debe bloquearse por esto, solo no habrá tracking en vivo.
      return;
    }

    _assignmentId = assignmentId;
    _lastKnownPosition = permission.position;

    _positionSub = Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: TrackingConfig.minDistanceMeters.toInt(),
      ),
    ).listen((position) {
      _lastKnownPosition = position;
      _maybePush();
    });

    // Respaldo: si la unidad queda detenida (semáforo, tráfico) y el
    // stream no emite nada nuevo por movimiento, igual se reenvía la
    // última posición conocida cada `minIntervalSeconds`.
    _fallbackTimer = Timer.periodic(
      const Duration(seconds: TrackingConfig.minIntervalSeconds),
      (_) => _maybePush(force: true),
    );

    // Primer envío inmediato al iniciar el recorrido.
    await _push(_lastKnownPosition!);
  }

  void _maybePush({bool force = false}) {
    final position = _lastKnownPosition;
    if (position == null) return;
    final elapsed = _lastPushAt == null ? null : DateTime.now().difference(_lastPushAt!);
    if (!force && elapsed != null && elapsed.inSeconds < TrackingConfig.minIntervalSeconds) {
      return;
    }
    _push(position);
  }

  Future<void> _push(Position position) async {
    final id = _assignmentId;
    if (id == null) return;
    _lastPushAt = DateTime.now();
    try {
      await _dispatchService.pushTracking(
        id,
        lat: position.latitude,
        lng: position.longitude,
        speed: position.speed >= 0 ? position.speed : null,
        heading: position.heading >= 0 ? position.heading : null,
      );
    } catch (_) {
      // Un fallo de red no debe interrumpir el flujo operativo del
      // despacho; el próximo tick/movimiento reintenta.
    }
  }

  Future<void> stop() async {
    await _positionSub?.cancel();
    _positionSub = null;
    _fallbackTimer?.cancel();
    _fallbackTimer = null;
    _assignmentId = null;
    _lastKnownPosition = null;
    _lastPushAt = null;
  }
}
