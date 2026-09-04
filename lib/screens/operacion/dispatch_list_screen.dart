import 'package:flutter/material.dart';

import '../../core/api_client.dart';
import '../../services/dispatch_service.dart';
import 'dispatch_tracking_screen.dart';

const _statusColors = {
  'SOLICITADA': Colors.orange,
  'ACEPTADA': Colors.blue,
  'EN_CAMINO': Colors.indigo,
  'EN_SITIO': Colors.purple,
  'FINALIZADA': Colors.green,
  'RECHAZADA': Colors.red,
  'CANCELADA': Colors.grey,
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

  List<Widget> _actionsFor(Map<String, dynamic> item) {
    if (!widget.showActions) return [];
    final id = item['PK_assignment'] as int;
    final status = item['status'];
    switch (status) {
      case 'SOLICITADA':
        return [
          TextButton(onPressed: _busy ? null : () => _act(() => _service.accept(id)), child: const Text('Aceptar')),
          TextButton(
            onPressed: _busy ? null : () => _act(() => _service.cancel(id)),
            child: const Text('Rechazar/Cancelar'),
          ),
        ];
      case 'ACEPTADA':
        return [
          TextButton(onPressed: _busy ? null : () => _act(() => _service.depart(id)), child: const Text('Salir')),
          TextButton(onPressed: _busy ? null : () => _act(() => _service.cancel(id)), child: const Text('Cancelar')),
        ];
      case 'EN_CAMINO':
        return [
          TextButton(onPressed: _busy ? null : () => _act(() => _service.arrive(id)), child: const Text('Llegué')),
          TextButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => DispatchTrackingScreen(assignmentId: id)),
            ),
            child: const Text('Ver ruta'),
          ),
        ];
      case 'EN_SITIO':
        return [
          TextButton(onPressed: _busy ? null : () => _act(() => _service.complete(id)), child: const Text('Completar')),
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
                          final color = _statusColors[a['status']] ?? Colors.grey;
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
