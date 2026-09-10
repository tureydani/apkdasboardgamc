import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../../app/theme/index.dart';
import '../../core/api_client.dart';
import '../../core/services/location_service.dart';
import '../../core/tracking_config.dart';
import '../../services/dispatch_service.dart';
import '../../services/emergency_service.dart';
import '../../services/unit_tracking_service.dart';
import 'dispatch_tracking_screen.dart';

const _statusColors = {
  'SOLICITADA': AppColors.moderateOrange,
  'ACEPTADA': AppColors.secondary,
  'EN_CAMINO': AppColors.accent,
  'EN_SITIO': AppColors.primary,
  'FINALIZADA': AppColors.resolvedGreen,
  'RECHAZADA': AppColors.urgentRed,
  'CANCELADA': AppColors.textTertiary,
};

const _statusLabels = {
  'SOLICITADA': 'Solicitada',
  'ACEPTADA': 'Aceptada',
  'EN_CAMINO': 'En camino',
  'EN_SITIO': 'En sitio',
  'FINALIZADA': 'Finalizada',
  'RECHAZADA': 'Rechazada',
  'CANCELADA': 'Cancelada',
};

/// Lista de asignaciones de despacho (`tbemergencyassignments`), reutilizada
/// para Operación > Despacho (activas, con acciones), Operación > Historial
/// de asignaciones y Más > Seguimiento > Historial (cerradas, solo lectura).
class DispatchListScreen extends StatefulWidget {
  final String title;
  final List<String>? statusFilter;
  final bool showActions;

  const DispatchListScreen({
    super.key,
    required this.title,
    this.statusFilter,
    this.showActions = true,
  });

  @override
  State<DispatchListScreen> createState() => _DispatchListScreenState();
}

class _DispatchListScreenState extends State<DispatchListScreen> {
  final _service = DispatchService();
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;
  String? _error;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await _service.list(status: widget.statusFilter);
      setState(() => _items = result.items);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _act(Future<void> Function() action) async {
    setState(() => _busy = true);
    try {
      await action();
      await _load();
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _depart(int id) => _act(() async {
        await _service.depart(id);
        await UnitTrackingService.instance.start(id);
      });

  Future<void> _cancel(int id) => _act(() async {
        await _service.cancel(id);
        await UnitTrackingService.instance.stop();
      });

  Future<void> _complete(int id) => _act(() async {
        await _service.complete(id);
        await UnitTrackingService.instance.stop();
      });

  /// Antes de confirmar la llegada, calcula la distancia real entre la
  /// posición actual del GPS y la ubicación registrada de la emergencia.
  /// Si está fuera del radio configurado (o no hay GPS disponible), avisa
  /// la distancia pero deja confirmar igual — el GPS urbano puede errar
  /// bastante y bloquear del todo generaría fricción operativa.
  Future<void> _confirmArrival(Map<String, dynamic> item) async {
    final id = item['PK_assignment'] as int;
    final emergencyId = item['tbemergencies']?['PK_emergency'] as int?;

    double? distanceMeters;
    if (emergencyId != null) {
      try {
        final position = await LocationService.getCurrentPosition();
        final emergency = await EmergencyService().getById(emergencyId);
        final locations = emergency['tbemergencylocations'] as List?;
        final lastLocation = (locations != null && locations.isNotEmpty) ? locations.last as Map : null;
        if (position != null && lastLocation != null) {
          distanceMeters = Geolocator.distanceBetween(
            position.latitude,
            position.longitude,
            (lastLocation['latitude'] as num).toDouble(),
            (lastLocation['longitude'] as num).toDouble(),
          );
        }
      } catch (_) {
        // Sin conexión/GPS: se deja avanzar sin distancia calculada.
      }
    }

    final withinRadius = distanceMeters != null && distanceMeters <= TrackingConfig.arrivalRadiusMeters;
    if (withinRadius) {
      await _act(() async {
        await _service.arrive(id);
        await UnitTrackingService.instance.stop();
      });
      return;
    }

    if (!mounted) return;
    final message = distanceMeters != null
        ? 'Estás a ${distanceMeters.round()} m del incidente (radio esperado: ${TrackingConfig.arrivalRadiusMeters.round()} m).'
        : 'No se pudo verificar tu distancia al incidente (sin GPS/conexión).';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Confirmar llegada'),
        content: Text('$message\n¿Confirmar llegada de todas formas?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Confirmar de todas formas')),
        ],
      ),
    );
    if (confirmed == true) {
      await _act(() async {
        await _service.arrive(id);
        await UnitTrackingService.instance.stop();
      });
    }
  }

  List<Widget> _actionsFor(Map<String, dynamic> item) {
    if (!widget.showActions) return [];
    final id = item['PK_assignment'] as int;
    final status = item['status'];
    switch (status) {
      case 'SOLICITADA':
        return [
          TextButton(onPressed: _busy ? null : () => _act(() => _service.accept(id)), child: const Text('Aceptar')),
          TextButton(
            onPressed: _busy ? null : () => _cancel(id),
            child: const Text('Rechazar/Cancelar'),
          ),
        ];
      case 'ACEPTADA':
        return [
          TextButton(onPressed: _busy ? null : () => _depart(id), child: const Text('Salir')),
          TextButton(onPressed: _busy ? null : () => _cancel(id), child: const Text('Cancelar')),
        ];
      case 'EN_CAMINO':
        return [
          TextButton(onPressed: _busy ? null : () => _confirmArrival(item), child: const Text('Llegué')),
          TextButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => DispatchTrackingScreen(assignmentId: id)),
            ),
            child: const Text('Ver ruta'),
          ),
        ];
      case 'EN_SITIO':
        return [
          TextButton(onPressed: _busy ? null : () => _complete(id), child: const Text('Completar')),
        ];
      default:
        return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(child: Text(_error!))
                : _items.isEmpty
                    ? ListView(children: const [SizedBox(height: 80), Center(child: Text('Sin asignaciones'))])
                    : ListView.separated(
                        itemCount: _items.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, i) {
                          final a = _items[i];
                          final color = _statusColors[a['status']] ?? AppColors.textTertiary;
                          final emergency = a['tbemergencies'];
                          final unit = a['tbunits'];
                          return ListTile(
                            leading: CircleAvatar(backgroundColor: color.withValues(alpha: 0.15), child: Icon(Icons.local_shipping, color: color)),
                            title: Text(emergency?['emergencyCode'] ?? 'Asignación #${a['PK_assignment']}'),
                            subtitle: Text(
                              '${a['tbinstitutions']?['acronym'] ?? a['tbinstitutions']?['name'] ?? ''}'
                              '${unit != null ? ' · ${unit['unitCode']}' : ''}\n${_statusLabels[a['status']] ?? a['status']}',
                            ),
                            isThreeLine: true,
                            trailing: Wrap(spacing: 4, children: _actionsFor(a)),
                          );
                        },
                      ),
      ),
    );
  }
}
