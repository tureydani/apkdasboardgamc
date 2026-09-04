import '../../operacion/dispatch_list_screen.dart';

/// Historial de asignaciones cerradas (FINALIZADA/RECHAZADA/CANCELADA),
/// solo lectura.
class TrackingHistorialScreen extends DispatchListScreen {
  const TrackingHistorialScreen({super.key})
      : super(
          title: 'Historial de despacho',
          statusFilter: const ['FINALIZADA', 'RECHAZADA', 'CANCELADA'],
          showActions: false,
        );
}
