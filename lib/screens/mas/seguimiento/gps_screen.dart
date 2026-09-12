import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../app/theme/index.dart';
import '../../../core/services/gps_preference_service.dart';
import '../../../services/dispatch_service.dart';
import '../../../services/unit_tracking_service.dart';

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
  bool _sharingEnabled = true;
  bool _loadingPreference = true;

  static const _cochabamba = LatLng(-17.3895, -66.1568);

  @override
  void initState() {
    super.initState();
    _load();
    _loadPreference();
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

  Future<void> _loadPreference() async {
    final enabled = await GpsPreferenceService.isSharingEnabled();
    if (!mounted) return;
    setState(() {
      _sharingEnabled = enabled;
      _loadingPreference = false;
    });
  }

  Future<void> _toggleSharing(bool value) async {
    if (!value && UnitTrackingService.instance.isTracking) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Desactivar GPS'),
          content: const Text(
            'Tenés un despacho en camino ahora mismo. Si desactivás el GPS, la central deja de ver tu ubicación en vivo hasta que lo reactives. ¿Continuar?',
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              style: FilledButton.styleFrom(backgroundColor: AppColors.urgentRed),
              child: const Text('Desactivar'),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
      await UnitTrackingService.instance.stop();
    }
    await GpsPreferenceService.setSharingEnabled(value);
    if (mounted) setState(() => _sharingEnabled = value);
  }

  Widget _buildSharingToggle() {
    final isTracking = _sharingEnabled && UnitTrackingService.instance.isTracking;
    return Container(
      color: AppColors.surfaceSecondary,
      child: SwitchListTile(
        value: _sharingEnabled,
        onChanged: _loadingPreference ? null : _toggleSharing,
        title: const Text('Compartir mi ubicación'),
        subtitle: Text(
          !_sharingEnabled
              ? 'Desactivado: la central no verá tu recorrido mientras estés en camino.'
              : isTracking
                  ? 'Enviando ubicación en vivo (despacho en camino).'
                  : 'Se envía automáticamente mientras estés EN_CAMINO en un despacho.',
          style: const TextStyle(fontSize: 12),
        ),
        secondary: Icon(
          _sharingEnabled ? Icons.gps_fixed : Icons.gps_off,
          color: _sharingEnabled ? AppColors.secondary : AppColors.textTertiary,
        ),
        activeThumbColor: AppColors.secondary,
      ),
    );
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
                    _buildSharingToggle(),
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
