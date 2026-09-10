import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../services/dispatch_service.dart';
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

  Timer? _timer;
  bool _trackAssignments = false;
  bool _baselineLoaded = false;

  int unreadNotifications = 0;
  int pendingAssignments = 0;

  void start({required bool trackAssignments, Duration interval = const Duration(seconds: 20)}) {
    _trackAssignments = trackAssignments;
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

  /// Secuencia corta de sonido + vibración fuerte, repetida unas veces,
  /// usando solo APIs nativas de Flutter (sin assets de audio ni permisos
  /// adicionales).
  Future<void> _alertNewAssignment() async {
    for (var i = 0; i < 3; i++) {
      unawaited(SystemSound.play(SystemSoundType.alert));
      unawaited(HapticFeedback.heavyImpact());
      await Future.delayed(const Duration(milliseconds: 350));
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
