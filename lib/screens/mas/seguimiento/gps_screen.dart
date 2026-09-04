import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../services/dispatch_service.dart';

/// GET /api/dashboard/units/positions — última posición GPS conocida de
/// cada unidad activa.
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
                      child: GoogleMap(
                        initialCameraPosition: const CameraPosition(target: _cochabamba, zoom: 12),
                        markers: _units
                            .map((u) => Marker(
                                  markerId: MarkerId('u${u['PK_unit']}'),
                                  position: LatLng(u['latitude'], u['longitude']),
                                  infoWindow: InfoWindow(title: u['unitCode'], snippet: u['unitName']),
                                  icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
                                ))
                            .toSet(),
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
                            subtitle: Text('${u['institution']?['name'] ?? ''} · ${u['status']}'),
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
