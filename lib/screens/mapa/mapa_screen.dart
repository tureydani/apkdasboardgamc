import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../services/dispatch_service.dart';
import '../../services/emergency_service.dart';
import '../../widgets/crud/generic_crud_screen.dart';
import '../../config/crud_configs.dart';
import '../operacion/emergency_detail_screen.dart';

const _cochabamba = LatLng(-17.3895, -66.1568);

/// Replica el mapa operativo del dashboard: pines de emergencias activas por
/// color de prioridad (GET .../emergencies/map) + pines de unidades
/// (GET .../units/positions). "Recursos" no tiene coordenadas propias en el
/// modelo de datos, así que se muestra como catálogo de tipos de recurso.
class MapaScreen extends StatelessWidget {
  const MapaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Mapa'),
          bottom: const TabBar(tabs: [
            Tab(text: 'Emergencias activas'),
            Tab(text: 'Unidades'),
            Tab(text: 'Recursos'),
          ]),
        ),
        body: const TabBarView(
          children: [
            _EmergenciesMapTab(),
            _UnitsMapTab(),
            _ResourcesTab(),
          ],
        ),
      ),
    );
  }
}

class _EmergenciesMapTab extends StatefulWidget {
  const _EmergenciesMapTab();
  @override
  State<_EmergenciesMapTab> createState() => _EmergenciesMapTabState();
}

class _EmergenciesMapTabState extends State<_EmergenciesMapTab> {
  final _service = EmergencyService();
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final items = await _service.map();
      setState(() => _items = items.where((e) => e['latitude'] != null && e['longitude'] != null).toList());
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  double _hueFor(String? priority) {
    switch (priority) {
      case 'CRITICA':
        return BitmapDescriptor.hueRed;
      case 'ALTA':
        return BitmapDescriptor.hueOrange;
      case 'MEDIA':
        return BitmapDescriptor.hueYellow;
      default:
        return BitmapDescriptor.hueAzure;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    return Stack(
      children: [
        GoogleMap(
          initialCameraPosition: const CameraPosition(target: _cochabamba, zoom: 12),
          markers: _items
              .map((e) => Marker(
                    markerId: MarkerId('e${e['PK_emergency']}'),
                    position: LatLng(e['latitude'], e['longitude']),
                    icon: BitmapDescriptor.defaultMarkerWithHue(_hueFor(e['priority'])),
                    infoWindow: InfoWindow(
                      title: e['emergencyCode'],
                      snippet: '${e['priority']} · ${e['status']}',
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => EmergencyDetailScreen(id: e['PK_emergency'])),
                      ),
                    ),
                  ))
              .toSet(),
        ),
        Positioned(
          right: 12,
          bottom: 12,
          child: FloatingActionButton(mini: true, onPressed: _load, child: const Icon(Icons.refresh)),
        ),
      ],
    );
  }
}

class _UnitsMapTab extends StatefulWidget {
  const _UnitsMapTab();
  @override
  State<_UnitsMapTab> createState() => _UnitsMapTabState();
}

class _UnitsMapTabState extends State<_UnitsMapTab> {
  final _service = DispatchService();
  List<Map<String, dynamic>> _units = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final items = await _service.unitPositions();
      setState(() => _units = items.where((u) => u['latitude'] != null && u['longitude'] != null).toList());
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    return Stack(
      children: [
        GoogleMap(
          initialCameraPosition: const CameraPosition(target: _cochabamba, zoom: 12),
          markers: _units
              .map((u) => Marker(
                    markerId: MarkerId('u${u['PK_unit']}'),
                    position: LatLng(u['latitude'], u['longitude']),
                    icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
                    infoWindow: InfoWindow(title: u['unitCode'], snippet: '${u['institution']?['name'] ?? ''} · ${u['status']}'),
                  ))
              .toSet(),
        ),
        Positioned(
          right: 12,
          bottom: 12,
          child: FloatingActionButton(mini: true, onPressed: _load, child: const Icon(Icons.refresh)),
        ),
      ],
    );
  }
}

class _ResourcesTab extends StatelessWidget {
  const _ResourcesTab();
  @override
  Widget build(BuildContext context) {
    return GenericCrudScreen(config: CrudConfigs.resourceTypes);
  }
}
