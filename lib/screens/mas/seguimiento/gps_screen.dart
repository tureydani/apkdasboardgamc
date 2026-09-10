import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../app/theme/index.dart';
import '../../../services/dispatch_service.dart';

/// GET /api/dashboard/units/positions — última posición GPS conocida de
/// cada unidad activa. Usa flutter_map + OpenStreetMap (sin API key), el
/// mismo motor que arconde-gamc.
class GpsScreen extends StatefulWidget {
  const GpsScreen({super.key});

  @override
  State<GpsScreen> createState() => _GpsScreenState();
}

class _GpsScreenState extends State<GpsScreen> {
  final _service = DispatchService();
  List<Map<String, dynamic>> _units = [];
  bool _loading = true;
  String? _error;

  static const _cochabamba = LatLng(-17.3895, -66.1568);

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
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('GPS de unidades'), actions: [
        IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
      ]),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : Column(
                  children: [
                    SizedBox(
                      height: 300,
                      child: FlutterMap(
                        options: const MapOptions(initialCenter: _cochabamba, initialZoom: 12, minZoom: 5, maxZoom: 19),
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
                                      width: 36,
                                      height: 36,
                                      child: Container(
                                        padding: const EdgeInsets.all(5),
                                        decoration: BoxDecoration(
                                          color: AppColors.secondary,
                                          shape: BoxShape.circle,
                                          border: Border.all(color: AppColors.surfacePrimary, width: 2),
                                          boxShadow: [
                                            BoxShadow(color: AppColors.secondary.withValues(alpha: 0.4), blurRadius: 8, spreadRadius: 2),
                                          ],
                                        ),
                                        child: const Icon(Icons.local_shipping, size: 16, color: AppColors.textOnPrimary),
                                      ),
                                    ))
                                .toList(),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView.separated(
                        itemCount: _units.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, i) {
                          final u = _units[i];
                          return ListTile(
                            leading: const Icon(Icons.local_shipping_outlined),
                            title: Text('${u['unitCode']} · ${u['unitName']}'),
                            subtitle: Text('${u['institution'] ?? ''} · ${u['status']}'),
                            trailing: Text(u['lastSeenAt']?.toString().split('T').first ?? ''),
                          );
                        },
                      ),
                    ),
                  ],
                ),
    );
  }
}
