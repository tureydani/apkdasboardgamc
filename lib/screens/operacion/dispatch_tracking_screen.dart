import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../services/dispatch_service.dart';

/// GET /api/dashboard/dispatch/[id]/tracking — puntos GPS reportados por la
/// unidad mientras está EN_CAMINO (tbassignmenttracking).
class DispatchTrackingScreen extends StatefulWidget {
  final int assignmentId;
  const DispatchTrackingScreen({super.key, required this.assignmentId});

  @override
  State<DispatchTrackingScreen> createState() => _DispatchTrackingScreenState();
}

class _DispatchTrackingScreenState extends State<DispatchTrackingScreen> {
  final _service = DispatchService();
  List<Map<String, dynamic>> _points = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await _service.tracking(widget.assignmentId);
      setState(() => _points = (data['points'] as List).map((e) => Map<String, dynamic>.from(e)).toList());
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
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
                        SizedBox(
                          height: 260,
                          child: GoogleMap(
                            initialCameraPosition: CameraPosition(
                              target: LatLng(_points.last['latitude'], _points.last['longitude']),
                              zoom: 14,
                            ),
                            polylines: {
                              Polyline(
                                polylineId: const PolylineId('route'),
                                color: Colors.indigo,
                                width: 4,
                                points: _points.map((p) => LatLng(p['latitude'], p['longitude'])).toList(),
                              ),
                            },
                            markers: {
                              Marker(
                                markerId: const MarkerId('current'),
                                position: LatLng(_points.last['latitude'], _points.last['longitude']),
                              ),
                            },
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
