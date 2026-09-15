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
  bool _assignmentBaselineLoaded = false;
  bool _unreadBaselineLoaded = false;

  int unreadNotifications = 0;
  int pendingAssignments = 0;

  /// Se dispara cuando aparecen asignaciones nuevas (no en la primera
  /// carga) — quien arranca el provider (`MainShell`) lo usa para mostrar
  /// la pantalla completa de alarma (`IncomingAssignmentScreen`), que es la
  /// que realmente hace sonar/vibrar en loop hasta que se toca la pantalla.
  void Function(int count)? onNewAssignment;

  void start({
    required bool trackAssignments,
    Duration interval = const Duration(seconds: 20),
    void Function(int count)? onNewAssignment,
  }) {
    _trackAssignments = trackAssignments;
    this.onNewAssignment = onNewAssignment;
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
      final previousUnread = unreadNotifications;
      unreadNotifications = data['unread'] as int? ?? 0;
      // Aviso corto (sonido + vibración, una vez) para cualquier
      // notificación nueva — sala de crisis, cambio de estado, etc. — sin
      // importar el rol; no reemplaza la alarma en loop de abajo, que es
      // específica de asignaciones de despacho.
      if (_unreadBaselineLoaded && unreadNotifications > previousUnread) {
        unawaited(_localAlertService.notifyGeneric(
          title: unreadNotifications == 1 ? 'Nueva notificación' : '$unreadNotifications notificaciones sin leer',
          body: 'Tocá para revisarlas en Alertas.',
        ));
      }
      _unreadBaselineLoaded = true;
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
        if (_assignmentBaselineLoaded && pendingAssignments > previous) {
          unawaited(_alertNewAssignment());
        }
        _assignmentBaselineLoaded = true;
      } catch (_) {
        // Sin conexión: se conserva el último valor conocido.
      }
    }
    notifyListeners();
  }

  /// Notificación local de respaldo (útil si la pantalla de alarma no llegó
  /// a mostrarse) + dispara la pantalla completa que hace sonar la sirena
  /// en loop hasta que se toca — ver [IncomingAssignmentScreen].
  Future<void> _alertNewAssignment() async {
    await _localAlertService.notifyNewAssignment(
      title: pendingAssignments == 1 ? 'Nueva asignación pendiente' : '$pendingAssignments asignaciones pendientes',
      body: 'Se te asignó un despacho. Tocá para revisarlo.',
    );
    onNewAssignment?.call(pendingAssignments);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
