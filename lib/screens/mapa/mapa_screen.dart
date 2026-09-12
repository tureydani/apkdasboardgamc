import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../app/theme/index.dart';
import '../../core/animations/motion.dart';
import '../../core/services/location_service.dart';
import '../../core/services/nominatim_service.dart';
import '../../core/services/routing_service.dart';
import '../../core/tracking_config.dart';
import '../../core/utils/geojson_parser.dart';
import '../../providers/route_view_provider.dart';
import '../../services/dispatch_service.dart';
import '../../services/emergency_service.dart';
import '../../widgets/crud/generic_crud_screen.dart';
import '../../widgets/map/map_controls.dart';
import '../../widgets/map/map_zone_search.dart';
import '../../config/crud_configs.dart';
import '../operacion/emergencies_list_screen.dart' show priorityColors;
import '../operacion/emergency_detail_screen.dart';
import '../operacion/emergency_form_screen.dart';

const _cochabamba = LatLng(-17.3895, -66.1568);
const _minZoom = 5.0;
const _maxZoom = 19.0;
// Alto aproximado del campo de búsqueda de sectores (TextField ~56 + margen
// AppSpacing.md arriba/abajo) — los controles de zoom se posicionan debajo
// para no superponerse, tanto si está el campo vacío como el chip de zona
// activa (ambos ocupan prácticamente la misma altura).
const _zoneSearchBarHeight = 56.0 + AppSpacing.md * 2;
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
class MapaScreen extends StatefulWidget {
  const MapaScreen({super.key});

  @override
  State<MapaScreen> createState() => _MapaScreenState();
}

class _MapaScreenState extends State<MapaScreen> with SingleTickerProviderStateMixin {
  static const _miRutaTabIndex = 3;

  late final TabController _tabController;
  late final RouteViewProvider _routeView;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    // Cuando alguna pantalla pide "ver ruta" (RouteViewProvider.show), esta
    // pestaña salta directo a "Mi ruta" para mostrarla, sin que el usuario
    // tenga que navegar manualmente.
    _routeView = context.read<RouteViewProvider>();
    _routeView.addListener(_onRouteRequested);
  }

  @override
  void dispose() {
    _routeView.removeListener(_onRouteRequested);
    _tabController.dispose();
    super.dispose();
  }

  void _onRouteRequested() {
    if (_routeView.assignmentId != null) {
      _tabController.animateTo(_miRutaTabIndex);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // toolbarHeight: 0 colapsa la franja vacía que un AppBar reserva
      // arriba (para title/leading/actions) cuando no tiene ninguno de
      // esos — el TabBar sigue respetando el status bar por su cuenta, así
      // que el mapa gana esa franja completa sin perder navegación.
      appBar: AppBar(
        toolbarHeight: 0,
        // Etiquetas cortas a propósito: con 4 pestañas fijas (no scrollable)
        // un texto largo como "Emergencias activas" se corta o envuelve en
        // un teléfono angosto (~360dp / 4 ≈ 90dp por pestaña).
        bottom: TabBar(controller: _tabController, tabs: const [
          Tab(text: 'Activas'),
          Tab(text: 'Unidades'),
          Tab(text: 'Recursos'),
          Tab(text: 'Mi ruta'),
        ]),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _EmergenciesMapTab(),
          _UnitsMapTab(),
          _ResourcesTab(),
          _MyRouteTab(),
        ],
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
  // Igual que `AnimatedMarker` de arconde-gamc (map_markers.dart): las
  // emergencias críticas "laten" en el mapa para que salten a la vista sin
  // tener que leer el color del pin.
  final bool pulse;

  const _DotMarker({required this.color, required this.icon, this.onTap, this.pulse = false});

  @override
  Widget build(BuildContext context) {
    final marker = Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(color: color.withValues(alpha: pulse ? 0.6 : 0.5), blurRadius: pulse ? 16 : 10, spreadRadius: pulse ? 4 : 2),
        ],
        border: Border.all(color: AppColors.surfacePrimary, width: 2),
      ),
      child: Icon(icon, size: 18, color: AppColors.textOnPrimary),
    );
    final animated = pulse
        ? marker.pulseGlow(minScale: 1.0, maxScale: 1.15, minOpacity: 0.4, maxOpacity: 1.0, duration: const Duration(milliseconds: 1500))
        : marker;
    return GestureDetector(onTap: onTap, child: animated);
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
  GeoSearchResult? _selectedZone;

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

  /// Emergencias visibles: todas, o solo las que caen dentro de la
  /// geometría real del sector elegido (punto-en-polígono, no coincidencia
  /// de nombre).
  List<Map<String, dynamic>> get _visibleItems {
    final geometry = _selectedZone?.geometry;
    if (geometry == null || !geometry.isArea) return _items;
    return _items.where((e) {
      final point = LatLng(e['latitude'], e['longitude']);
      return isPointInZone(point, geometry);
    }).toList();
  }

  void _onZoneSelected(GeoSearchResult zone) {
    setState(() => _selectedZone = zone);
    _mapController.fitCamera(
      CameraFit.bounds(bounds: zone.bounds, padding: const EdgeInsets.all(48), maxZoom: _maxZoom),
    );
  }

  void _onZoneCleared() => setState(() => _selectedZone = null);

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
    final visibleItems = _visibleItems;
    final zoneGeometry = _selectedZone?.geometry;
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
            if (zoneGeometry != null && zoneGeometry.isArea)
              PolygonLayer(
                polygons: zoneGeometry.polygons
                    .map((shape) => Polygon(
                          points: shape.exterior,
                          holePointsList: shape.holes.isEmpty ? null : shape.holes,
                          color: AppColors.secondary.withValues(alpha: 0.12),
                          borderColor: AppColors.secondary,
                          borderStrokeWidth: 2.5,
                        ))
                    .toList(),
              ),
            if (zoneGeometry != null && zoneGeometry.isLine)
              PolylineLayer(
                polylines: zoneGeometry.lines
                    .map((points) => Polyline(
                          points: points,
                          color: AppColors.secondary,
                          strokeWidth: 4,
                          borderColor: AppColors.surfacePrimary,
                          borderStrokeWidth: 1.5,
                        ))
                    .toList(),
              ),
            MarkerLayer(
              markers: visibleItems
                  .map((e) => Marker(
                        point: LatLng(e['latitude'], e['longitude']),
                        width: 40,
                        height: 40,
                        child: _DotMarker(
                          color: priorityColors[e['priority']] ?? AppColors.textTertiary,
                          icon: Icons.emergency,
                          onTap: () => _showDetail(e),
                          pulse: e['priority'] == 'CRITICA',
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
        // Buscador de sectores: arriba, ancho completo, igual que en
        // arconde-gamc — filtra las emergencias visibles cuando el
        // resultado elegido es un área (barrio/zona/distrito).
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: SafeArea(
            bottom: false,
            child: MapZoneSearchField(
              selectedZone: _selectedZone,
              filteredCount: _selectedZone == null ? null : visibleItems.length,
              onZoneSelected: _onZoneSelected,
              onZoneCleared: _onZoneCleared,
            ),
          ),
        ),
        // Zoom: arriba a la derecha, debajo del buscador.
        Positioned(
          top: _zoneSearchBarHeight,
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
          subtitle: Text('${u['institution'] ?? ''} · ${u['status'] ?? ''}'),
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

/// Subpestaña "Mi ruta": la unidad en camino (GET
/// /api/dashboard/dispatch/[id]/tracking) más la ruta proyectada por calles
/// (OSRM), directo en el mapa principal en vez de una pantalla aparte —
/// reemplaza al antiguo DispatchTrackingScreen. Escucha RouteViewProvider
/// para saber qué asignación mostrar, sin acoplarse a quién la pidió.
class _MyRouteTab extends StatefulWidget {
  const _MyRouteTab();
  @override
  State<_MyRouteTab> createState() => _MyRouteTabState();
}

class _MyRouteTabState extends State<_MyRouteTab> {
  static const _traveledColor = Color(0xFF1E88FF);
  static const _projectedColor = Color(0xFFFF6D00);
  static const _ticksPerRouteRecalc = TrackingConfig.routeRecalcSeconds ~/ TrackingConfig.pollIntervalSeconds;

  final _dispatchService = DispatchService();
  final _emergencyService = EmergencyService();
  late final RouteViewProvider _routeView;

  int? _assignmentId;
  List<Map<String, dynamic>> _points = [];
  LatLng? _destination;
  RouteResult? _route;
  bool _loading = false;
  bool _loadingRoute = false;
  String? _error;
  Timer? _pollTimer;
  int _pollTicks = 0;

  @override
  void initState() {
    super.initState();
    _routeView = context.read<RouteViewProvider>();
    _routeView.addListener(_onRouteChanged);
    _onRouteChanged();
  }

  @override
  void dispose() {
    _routeView.removeListener(_onRouteChanged);
    _pollTimer?.cancel();
    super.dispose();
  }

  void _onRouteChanged() {
    final id = _routeView.assignmentId;
    if (id == _assignmentId) return;
    _pollTimer?.cancel();
    setState(() {
      _assignmentId = id;
      _points = [];
      _destination = null;
      _route = null;
      _error = null;
    });
    if (id != null) {
      _load(id);
      _pollTimer = Timer.periodic(
        const Duration(seconds: TrackingConfig.pollIntervalSeconds),
        (_) => _poll(id),
      );
    }
  }

  Future<void> _load(int id) async {
    setState(() => _loading = true);
    try {
      await _loadDestination(id);
      final data = await _dispatchService.tracking(id);
      if (!mounted) return;
      setState(() => _points = (data['points'] as List).map((e) => Map<String, dynamic>.from(e)).toList());
      await _recalcRoute();
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadDestination(int id) async {
    final assignment = await _dispatchService.getById(id);
    final emergencyId = assignment['tbemergencies']?['PK_emergency'] as int?;
    if (emergencyId == null) return;
    final emergency = await _emergencyService.getById(emergencyId);
    final locations = emergency['tbemergencylocations'] as List?;
    if (locations == null || locations.isEmpty) return;
    final last = locations.last as Map;
    if (!mounted) return;
    setState(() => _destination = LatLng((last['latitude'] as num).toDouble(), (last['longitude'] as num).toDouble()));
  }

  Future<void> _poll(int id) async {
    if (_assignmentId != id) return;
    try {
      final data = await _dispatchService.tracking(id);
      if (!mounted || _assignmentId != id) return;
      setState(() => _points = (data['points'] as List).map((e) => Map<String, dynamic>.from(e)).toList());
      _pollTicks++;
      if (_pollTicks % _ticksPerRouteRecalc == 0) {
        await _recalcRoute();
      }
    } catch (_) {
      // Un fallo puntual de red no debe interrumpir la vista actual.
    }
  }

  Future<void> _recalcRoute() async {
    if (_destination == null || _points.isEmpty || _loadingRoute) return;
    final last = _points.last;
    final origin = LatLng((last['latitude'] as num).toDouble(), (last['longitude'] as num).toDouble());
    _loadingRoute = true;
    final route = await RoutingService.fetchRoute(origin, _destination!);
    _loadingRoute = false;
    if (!mounted) return;
    setState(() => _route = route);
  }

  String _formatEta(double seconds) {
    final minutes = (seconds / 60).round();
    if (minutes < 1) return 'menos de 1 min';
    if (minutes < 60) return '$minutes min';
    final hours = minutes ~/ 60;
    final rest = minutes % 60;
    return '${hours}h ${rest}min';
  }

  String _formatDistance(double meters) {
    if (meters < 1000) return '${meters.round()} m';
    return '${(meters / 1000).toStringAsFixed(1)} km';
  }

  @override
  Widget build(BuildContext context) {
    if (_assignmentId == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.route_outlined, size: 48, color: AppColors.textDisabled),
              const SizedBox(height: 12),
              const Text('Sin ruta activa', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text(
                'Cuando una unidad salga en camino (Operación > Despacho), su ruta aparece acá.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      );
    }
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) return Center(child: Text(_error!, style: const TextStyle(color: AppColors.error)));
    if (_points.isEmpty) return const Center(child: Text('Aún no hay puntos GPS reportados.'));

    return Stack(
      children: [
        Column(
          children: [
            if (_route != null)
              Container(
                width: double.infinity,
                color: AppColors.secondaryContainer,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(
                  children: [
                    const Icon(Icons.timer_outlined, size: 18, color: AppColors.secondaryDark),
                    const SizedBox(width: 8),
                    Text(
                      'ETA ${_formatEta(_route!.durationSeconds)} · ${_formatDistance(_route!.distanceMeters)}',
                      style: const TextStyle(color: AppColors.secondaryDark, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            Expanded(
              child: FlutterMap(
                options: MapOptions(
                  initialCenter: LatLng(_points.last['latitude'], _points.last['longitude']),
                  initialZoom: 14,
                  minZoom: _minZoom,
                  maxZoom: _maxZoom,
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'bo.gob.cochabamba.gamc.sosapk',
                    maxZoom: 19,
                  ),
                  // Camino ya recorrido (breadcrumb histórico) — azul vivo.
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: _points.map((p) => LatLng(p['latitude'], p['longitude'])).toList(),
                        color: _traveledColor,
                        strokeWidth: 6,
                        borderColor: AppColors.surfacePrimary,
                        borderStrokeWidth: 1.5,
                      ),
                    ],
                  ),
                  // Ruta proyectada (OSRM) hacia el destino — naranja vivo.
                  if (_route != null)
                    PolylineLayer(
                      polylines: [
                        Polyline(
                          points: _route!.points,
                          color: _projectedColor,
                          strokeWidth: 6,
                          borderColor: AppColors.surfacePrimary,
                          borderStrokeWidth: 1.5,
                          pattern: const StrokePattern.dotted(spacingFactor: 2.2),
                        ),
                      ],
                    ),
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: LatLng(_points.last['latitude'], _points.last['longitude']),
                        width: 40,
                        height: 40,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: _traveledColor,
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.surfacePrimary, width: 3),
                            boxShadow: [
                              BoxShadow(color: _traveledColor.withValues(alpha: 0.55), blurRadius: 10, spreadRadius: 3),
                            ],
                          ),
                          child: const Icon(Icons.local_shipping, size: 18, color: Colors.white),
                        ),
                      ),
                      if (_destination != null)
                        Marker(
                          point: _destination!,
                          width: 42,
                          height: 42,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: AppColors.urgentRed,
                              shape: BoxShape.circle,
                              border: Border.all(color: AppColors.surfacePrimary, width: 3),
                              boxShadow: [
                                BoxShadow(color: AppColors.urgentRed.withValues(alpha: 0.6), blurRadius: 12, spreadRadius: 3),
                              ],
                            ),
                            child: const Icon(Icons.emergency, size: 18, color: Colors.white),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        Positioned(
          right: 12,
          bottom: _actionControlsBottom,
          child: FloatingActionButton.small(
            heroTag: 'close-my-route',
            tooltip: 'Cerrar ruta',
            onPressed: _routeView.clear,
            child: const Icon(Icons.close),
          ),
        ),
      ],
    );
  }
}
