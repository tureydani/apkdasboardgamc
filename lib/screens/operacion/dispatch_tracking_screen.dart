import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../app/theme/index.dart';
import '../../core/services/routing_service.dart';
import '../../core/tracking_config.dart';
import '../../services/dispatch_service.dart';
import '../../services/emergency_service.dart';

/// GET /api/dashboard/dispatch/[id]/tracking — puntos GPS reportados por la
/// unidad mientras está EN_CAMINO (tbassignmenttracking), más la ruta
/// proyectada (OSRM) y el ETA hacia la ubicación de la emergencia.
class DispatchTrackingScreen extends StatefulWidget {
  final int assignmentId;
  const DispatchTrackingScreen({super.key, required this.assignmentId});

  @override
  State<DispatchTrackingScreen> createState() => _DispatchTrackingScreenState();
}

class _DispatchTrackingScreenState extends State<DispatchTrackingScreen> {
  // Colores vivos y muy distinguibles entre sí sobre las tiles claras de
  // OpenStreetMap: azul brillante para el recorrido ya hecho, naranja
  // intenso para la ruta proyectada, rojo para el destino.
  static const _traveledColor = Color(0xFF1E88FF);
  static const _projectedColor = Color(0xFFFF6D00);

  final _dispatchService = DispatchService();
  final _emergencyService = EmergencyService();
  List<Map<String, dynamic>> _points = [];
  LatLng? _destination;
  RouteResult? _route;
  bool _loading = true;
  bool _loadingRoute = false;
  String? _error;
  Timer? _pollTimer;
  int _pollTicks = 0;

  static const _ticksPerRouteRecalc = TrackingConfig.routeRecalcSeconds ~/ TrackingConfig.pollIntervalSeconds;

  @override
  void initState() {
    super.initState();
    _load();
    // Refresca sola la última posición mientras la unidad sigue en camino,
    // sin necesidad de que el usuario toque el botón de refresh.
    _pollTimer = Timer.periodic(
      const Duration(seconds: TrackingConfig.pollIntervalSeconds),
      (_) => _poll(),
    );
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      await _loadDestination();
      final data = await _dispatchService.tracking(widget.assignmentId);
      setState(() => _points = (data['points'] as List).map((e) => Map<String, dynamic>.from(e)).toList());
      await _recalcRoute();
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// La ubicación de la emergencia no cambia durante el despacho — se
  /// obtiene una sola vez (reutiliza EmergencyService.getById, ya existe).
  Future<void> _loadDestination() async {
    final assignment = await _dispatchService.getById(widget.assignmentId);
    final emergencyId = assignment['tbemergencies']?['PK_emergency'] as int?;
    if (emergencyId == null) return;
    final emergency = await _emergencyService.getById(emergencyId);
    final locations = emergency['tbemergencylocations'] as List?;
    if (locations == null || locations.isEmpty) return;
    final last = locations.last as Map;
    _destination = LatLng((last['latitude'] as num).toDouble(), (last['longitude'] as num).toDouble());
  }

  /// Igual que `_load` pero sin mostrar el spinner de pantalla completa,
  /// para que el refresco automático no interrumpa la vista del mapa.
  Future<void> _poll() async {
    try {
      final data = await _dispatchService.tracking(widget.assignmentId);
      if (!mounted) return;
      setState(() => _points = (data['points'] as List).map((e) => Map<String, dynamic>.from(e)).toList());
      _pollTicks++;
      if (_pollTicks % _ticksPerRouteRecalc == 0) {
        await _recalcRoute();
      }
    } catch (_) {
      // Un fallo puntual de red no debe interrumpir la vista actual.
    }
  }

  /// Ruta real por calles (OSRM) desde la última posición conocida de la
  /// unidad hasta la emergencia — mismo servicio que ya usa arconde-gamc
  /// para el ciudadano (RoutingService).
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
    return Scaffold(
      appBar: AppBar(title: const Text('Ruta de la unidad'), actions: [
        IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
      ]),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : _points.isEmpty
                  ? const Center(child: Text('Aún no hay puntos GPS reportados.'))
                  : Column(
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
                        SizedBox(
                          height: 260,
                          child: FlutterMap(
                            options: MapOptions(
                              initialCenter: LatLng(_points.last['latitude'], _points.last['longitude']),
                              initialZoom: 14,
                              minZoom: 5,
                              maxZoom: 19,
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
                        Expanded(
                          child: ListView.separated(
                            itemCount: _points.length,
                            separatorBuilder: (_, __) => const Divider(height: 1),
                            itemBuilder: (context, i) {
                              final p = _points[_points.length - 1 - i];
                              return ListTile(
                                dense: true,
                                leading: const Icon(Icons.location_on_outlined),
                                title: Text('${p['latitude']}, ${p['longitude']}'),
                                subtitle: Text('${p['createdAt']}${p['speed'] != null ? ' · ${p['speed']} km/h' : ''}'),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
    );
  }
}
