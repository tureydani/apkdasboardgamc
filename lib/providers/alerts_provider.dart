import 'dart:async';

import 'package:flutter/foundation.dart';

import '../services/dispatch_service.dart';
import '../services/local_alert_service.dart';
import '../services/notification_service.dart';

/// Sondea periódicamente notificaciones sin leer y despachos pendientes
/// (`SOLICITADA`) para que el resto de la app (badge de Alertas, aviso rojo
/// de asignación pendiente) se actualice sin que el usuario tenga que entrar
/// a cada pantalla manualmente. Cuando aparece una asignación pendiente
/// nueva (no la primera carga), dispara un aviso de sonido + vibración para
/// que no pase desapercibida en un ambiente ruidoso (central de emergencias).
class AlertsProvider extends ChangeNotifier {
  final _notificationService = NotificationService();
  final _dispatchService = DispatchService();
  final _localAlertService = LocalAlertService.instance;

  Timer? _timer;
  bool _trackAssignments = false;
  bool _baselineLoaded = false;

  int unreadNotifications = 0;
  int pendingAssignments = 0;

  void start({required bool trackAssignments, Duration interval = const Duration(seconds: 20)}) {
    _trackAssignments = trackAssignments;
    if (trackAssignments) {
      unawaited(_localAlertService.requestPermission());
    }
    _timer?.cancel();
    unawaited(_tick());
    _timer = Timer.periodic(interval, (_) => _tick());
  }

  Future<void> refreshNow() => _tick();

  Future<void> _tick() async {
    try {
      final data = await _notificationService.fetchMine();
      unreadNotifications = data['unread'] as int? ?? 0;
    } catch (_) {
      // Sin conexión: se conserva el último valor conocido.
    }
    if (_trackAssignments) {
      try {
        final result = await _dispatchService.list(status: const ['SOLICITADA']);
        final previous = pendingAssignments;
        pendingAssignments = result.total;
        // Solo alerta si ya teníamos una base cargada (evita disparar el
        // sonido apenas se abre la app y ya había pendientes de antes).
        if (_baselineLoaded && pendingAssignments > previous) {
          unawaited(_alertNewAssignment());
        }
        _baselineLoaded = true;
      } catch (_) {
        // Sin conexión: se conserva el último valor conocido.
      }
    }
    notifyListeners();
  }

  /// Notificación local con sonido + patrón de vibración propio (ver
  /// [LocalAlertService]): más confiable entre equipos que combinar
  /// SystemSound + HapticFeedback, que usábamos antes acá.
  Future<void> _alertNewAssignment() async {
    await _localAlertService.notifyNewAssignment(
      title: pendingAssignments == 1 ? 'Nueva asignación pendiente' : '$pendingAssignments asignaciones pendientes',
      body: 'Se te asignó un despacho. Tocá para revisarlo.',
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
