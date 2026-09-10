/// Estados posibles de `tbemergencyassignments.status` y qué acciones puede
/// tomar el operador en cada uno. Replica el flujo del backend:
/// SOLICITADA -> ACEPTADA -> EN_CAMINO -> EN_SITIO -> FINALIZADA
/// (o RECHAZADA / CANCELADA en cualquier punto antes de FINALIZADA).
/// Ver `applyAssignmentOp` en dispatch-service.ts del backend.
library;

enum DispatchAction { accept, reject, depart, cancel, arrive, viewRoute, complete }

abstract final class DispatchStatus {
  static const solicitada = 'SOLICITADA';
  static const aceptada = 'ACEPTADA';
  static const enCamino = 'EN_CAMINO';
  static const enSitio = 'EN_SITIO';
  static const finalizada = 'FINALIZADA';
  static const rechazada = 'RECHAZADA';
  static const cancelada = 'CANCELADA';

  static const _finalStates = {finalizada, rechazada, cancelada};

  /// true si el despacho ya no admite ninguna acción (terminó, se rechazó o
  /// se canceló).
  static bool isFinal(String status) => _finalStates.contains(status);

  /// Acciones disponibles para el operador según el estado actual. Lista
  /// vacía si el estado es final o desconocido.
  static List<DispatchAction> actionsFor(String status) {
    switch (status) {
      case solicitada:
        return const [DispatchAction.accept, DispatchAction.reject];
      case aceptada:
        return const [DispatchAction.depart, DispatchAction.cancel];
      case enCamino:
        return const [DispatchAction.arrive, DispatchAction.viewRoute];
      case enSitio:
        return const [DispatchAction.complete];
      default:
        return const [];
    }
  }
}
