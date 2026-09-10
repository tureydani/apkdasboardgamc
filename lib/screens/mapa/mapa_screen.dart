import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../app/theme/index.dart';
import '../../core/services/location_service.dart';
import '../../services/dispatch_service.dart';
import '../../services/emergency_service.dart';
import '../../widgets/crud/generic_crud_screen.dart';
import '../../widgets/map/map_controls.dart';
import '../../config/crud_configs.dart';
import '../operacion/emergencies_list_screen.dart' show priorityColors;
import '../operacion/emergency_detail_screen.dart';
import '../operacion/emergency_form_screen.dart';

const _cochabamba = LatLng(-17.3895, -66.1568);
const _minZoom = 5.0;
const _maxZoom = 19.0;
// Igual que en arconde-gamc (home_page.dart): stack de dos MapControlButton
// (52px cada uno + 8px de separación) anclado abajo a la derecha con
// AppSpacing.md de margen.
const _actionControlsBottom = AppSpacing.md;
const _actionControlsStackHeight = 52 + AppSpacing.sm + 52;
// El FAB "Reportar" se posiciona encima de ese stack, con el mismo margen.
const _reportFabBottom = _actionControlsBottom + _actionControlsStackHeight + AppSpacing.md;

/// Replica el mapa operativo del dashboard: pines de emergencias activas por
/// color de prioridad (GET .../emergencies/map) + pines de unidades
/// (GET .../units/positions). Usa flutter_map + OpenStreetMap, el mismo
/// motor que arconde-gamc (no requiere API key de Google Maps).
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

/// Marcador circular de color sólido con ícono, igual al `AnimatedMarker` de
/// arconde-gamc (lib/features/map/presentation/widgets/map_markers.dart).
class _DotMarker extends StatelessWidget {
  final Color color;
  final IconData icon;
  final VoidCallback? onTap;

  const _DotMarker({required this.color, required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 10, spreadRadius: 2),
          ],
          border: Border.all(color: AppColors.surfacePrimary, width: 2),
        ),
        child: Icon(icon, size: 18, color: AppColors.textOnPrimary),
      ),
    );
  }
}

/// Punto azul pulsante para la ubicación del usuario, igual al
/// `UserLocationMarker` de arconde-gamc
/// (lib/features/map/presentation/widgets/map_markers.dart).
class _UserLocationDot extends StatelessWidget {
  const _UserLocationDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        color: AppColors.primary,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.surfacePrimary, width: 3),
        boxShadow: [
          BoxShadow(color: AppColors.primary.withValues(alpha: 0.4), blurRadius: 8, spreadRadius: 2),
        ],
      ),
      child: const Icon(Icons.navigation, size: 12, color: AppColors.textOnPrimary),
    );
  }
}

/// Mismo flujo que `_onLocateMePressed` de arconde-gamc
/// (lib/features/home/presentation/widgets/map_view.dart): pide el permiso
/// de ubicación solo al presionar el botón, y explica cada estado posible
/// (GPS apagado, permiso denegado, denegado para siempre) por SnackBar.
mixin _LocateMeMixin<T extends StatefulWidget> on State<T> {
  bool locating = false;

  MapController get mapController;
  void onLocated(LatLng point) {}

  Future<void> locateMe() async {
    if (locating) return;
    setState(() => locating = true);
    final result = await LocationService.getCurrentPositionResult();
    if (!mounted) return;
    setState(() => locating = false);

    switch (result.status) {
      case LocationResultStatus.success:
        final point = LatLng(result.position!.latitude, result.position!.longitude);
        onLocated(point);
        mapController.move(point, 16.0);
        break;
      case LocationResultStatus.serviceDisabled:
        _showMessage('Activa el GPS de tu dispositivo para ver tu ubicación.');
        break;
      case LocationResultStatus.permissionDenied:
        _showMessage('Necesitamos permiso de ubicación para mostrarte en el mapa.');
        break;
      case LocationResultStatus.permissionDeniedForever:
        _showMessage('El permiso de ubicación está bloqueado. Actívalo desde los ajustes del sistema.');
        break;
      case LocationResultStatus.error:
        _showMessage('No se pudo obtener tu ubicación. Intenta nuevamente.');
        break;
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

class _EmergenciesMapTab extends StatefulWidget {
  const _EmergenciesMapTab();
  @override
  State<_EmergenciesMapTab> createState() => _EmergenciesMapTabState();
}

class _EmergenciesMapTabState extends State<_EmergenciesMapTab> with _LocateMeMixin {
  final _service = EmergencyService();
  final _mapController = MapController();
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;
  String? _error;
  LatLng? _userLocation;

  @override
  MapController get mapController => _mapController;

  @override
  void onLocated(LatLng point) => setState(() => _userLocation = point);

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
      final items = await _service.map();
      setState(() => _items = items.where((e) => e['latitude'] != null && e['longitude'] != null).toList());
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _onZoomIn() {
    final camera = _mapController.camera;
    _mapController.move(camera.center, (camera.zoom + 1).clamp(_minZoom, _maxZoom));
  }

  void _onZoomOut() {
    final camera = _mapController.camera;
    _mapController.move(camera.center, (camera.zoom - 1).clamp(_minZoom, _maxZoom));
  }

  void _showDetail(Map<String, dynamic> e) {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: (priorityColors[e['priority']] ?? AppColors.textTertiary).withValues(alpha: 0.15),
            child: Icon(Icons.emergency, color: priorityColors[e['priority']] ?? AppColors.textTertiary),
          ),
          title: Text(e['emergencyCode'] ?? ''),
          subtitle: Text('${e['priority'] ?? ''} · ${e['status'] ?? ''}'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            Navigator.of(context).pop();
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => EmergencyDetailScreen(id: e['PK_emergency'])),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(child: Text(_error!, style: const TextStyle(color: AppColors.error)));
    }
    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: const MapOptions(initialCenter: _cochabamba, initialZoom: 12, minZoom: _minZoom, maxZoom: _maxZoom),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'bo.gob.cochabamba.gamc.sosapk',
              maxZoom: 19,
            ),
            MarkerLayer(
              markers: _items
                  .map((e) => Marker(
                        point: LatLng(e['latitude'], e['longitude']),
                        width: 40,
                        height: 40,
                        child: _DotMarker(
                          color: priorityColors[e['priority']] ?? AppColors.textTertiary,
                          icon: Icons.emergency,
                          onTap: () => _showDetail(e),
                        ),
                      ))
                  .toList(),
            ),
            if (_userLocation != null)
              MarkerLayer(markers: [
                Marker(point: _userLocation!, width: 28, height: 28, child: const _UserLocationDot()),
              ]),
          ],
        ),
        // Zoom: arriba a la derecha, igual que en arconde-gamc.
        Positioned(
          top: 12,
          right: 12,
          child: SafeArea(
            child: MapZoomControls(onZoomIn: _onZoomIn, onZoomOut: _onZoomOut),
          ),
        ),
        // Actualizar + mi ubicación: abajo a la derecha, igual que en
        // arconde-gamc (fullscreen/locate-me), encima del FAB "Reportar".
        Positioned(
          right: 12,
          bottom: _actionControlsBottom,
          child: MapActionControls(
            onRefresh: _load,
            onLocateMe: locateMe,
            isLocating: locating,
          ),
        ),
        Positioned(
          right: 12,
          bottom: _reportFabBottom,
          child: FloatingActionButton.extended(
            heroTag: 'report-emergency',
            onPressed: () async {
              final created = await Navigator.of(context).push<bool>(
                MaterialPageRoute(builder: (_) => const EmergencyFormScreen()),
              );
              if (created == true) _load();
            },
            backgroundColor: AppColors.secondary,
            foregroundColor: AppColors.textOnPrimary,
            elevation: AppSpacing.elevationMd,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Reportar'),
            extendedPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.borderRadiusXl)),
          ).animate().fadeIn(delay: 300.ms, duration: 400.ms).slideY(begin: 0.5, end: 0),
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

class _UnitsMapTabState extends State<_UnitsMapTab> with _LocateMeMixin {
  final _service = DispatchService();
  final _mapController = MapController();
  List<Map<String, dynamic>> _units = [];
  bool _loading = true;
  String? _error;
  LatLng? _userLocation;

  @override
  MapController get mapController => _mapController;

  @override
  void onLocated(LatLng point) => setState(() => _userLocation = point);

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
      final items = await _service.unitPositions();
      setState(() => _units = items.where((u) => u['latitude'] != null && u['longitude'] != null).toList());
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _onZoomIn() {
    final camera = _mapController.camera;
    _mapController.move(camera.center, (camera.zoom + 1).clamp(_minZoom, _maxZoom));
  }

  void _onZoomOut() {
    final camera = _mapController.camera;
    _mapController.move(camera.center, (camera.zoom - 1).clamp(_minZoom, _maxZoom));
  }

  void _showDetail(Map<String, dynamic> u) {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: ListTile(
          leading: const CircleAvatar(
            backgroundColor: AppColors.secondaryContainer,
            child: Icon(Icons.local_shipping, color: AppColors.secondaryDark),
          ),
          title: Text(u['unitCode'] ?? ''),
          subtitle: Text('${u['institution']?['name'] ?? ''} · ${u['status'] ?? ''}'),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(child: Text(_error!, style: const TextStyle(color: AppColors.error)));
    }
    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: const MapOptions(initialCenter: _cochabamba, initialZoom: 12, minZoom: _minZoom, maxZoom: _maxZoom),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'bo.gob.cochabamba.gamc.sosapk',
              maxZoom: 19,
            ),
            MarkerLayer(
              markers: _units
                  .map((u) => Marker(
                        point: LatLng(u['latitude'], u['longitude']),
                        width: 40,
                        height: 40,
                        child: _DotMarker(
                          color: AppColors.secondary,
                          icon: Icons.local_shipping,
                          onTap: () => _showDetail(u),
                        ),
                      ))
                  .toList(),
            ),
            if (_userLocation != null)
              MarkerLayer(markers: [
                Marker(point: _userLocation!, width: 28, height: 28, child: const _UserLocationDot()),
              ]),
          ],
        ),
        Positioned(
          top: 12,
          right: 12,
          child: SafeArea(
            child: MapZoomControls(onZoomIn: _onZoomIn, onZoomOut: _onZoomOut),
          ),
        ),
        Positioned(
          right: 12,
          bottom: _actionControlsBottom,
          child: MapActionControls(
            onRefresh: _load,
            onLocateMe: locateMe,
            isLocating: locating,
          ),
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
