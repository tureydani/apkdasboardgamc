import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../app/theme/index.dart';
import '../../config/crud_configs.dart';
import '../../core/api_client.dart';
import '../../core/utils/responsive.dart';
import '../../providers/route_view_provider.dart';
import '../../services/emergency_service.dart';
import 'emergencies_list_screen.dart'
    show priorityColors, priorityLabels, emergencyStatusColors, emergencyStatusLabels, emergencyStatusOrder;

const _statusFlow = emergencyStatusOrder;

// Estado de una asignación (`tbemergencyassignments.status`) — mismos
// valores/colores que Operación > Despacho (dispatch_list_screen.dart), para
// que un mismo estado se lea igual en toda la app.
const _assignmentStatusColors = {
  'SOLICITADA': AppColors.moderateOrange,
  'ACEPTADA': AppColors.secondary,
  'EN_CAMINO': AppColors.accent,
  'EN_SITIO': AppColors.primary,
  'FINALIZADA': AppColors.resolvedGreen,
  'RECHAZADA': AppColors.urgentRed,
  'CANCELADA': AppColors.textTertiary,
};
const _assignmentStatusLabels = {
  'SOLICITADA': 'Solicitada',
  'ACEPTADA': 'Aceptada',
  'EN_CAMINO': 'En camino',
  'EN_SITIO': 'En sitio',
  'FINALIZADA': 'Finalizada',
  'RECHAZADA': 'Rechazada',
  'CANCELADA': 'Cancelada',
};
const _openAssignmentStatuses = ['SOLICITADA', 'ACEPTADA', 'EN_CAMINO', 'EN_SITIO'];

// Estado de un requerimiento (`tbemergencyrequirements.status`).
const _requirementStatusColors = {
  'PENDIENTE': AppColors.moderateOrange,
  'SOLICITADO': AppColors.secondary,
  'ASIGNADO': AppColors.secondary,
  'ATENDIDO': AppColors.resolvedGreen,
  'RECHAZADO': AppColors.urgentRed,
};
const _requirementStatusLabels = {
  'PENDIENTE': 'Pendiente',
  'SOLICITADO': 'Solicitado',
  'ASIGNADO': 'Asignado',
  'ATENDIDO': 'Atendido',
  'RECHAZADO': 'Rechazado',
};

const _tabTitles = ['Info', 'Sala / Chat', 'Asignaciones', 'Requerimientos', 'Avances', 'Registros'];

IconData _typeIcon(String? name) {
  final n = (name ?? '').toLowerCase();
  if (n.contains('acciden') || n.contains('choque') || n.contains('tránsito') || n.contains('transito')) return Icons.car_crash;
  if (n.contains('incendio') || n.contains('fuego')) return Icons.local_fire_department;
  if (n.contains('médic') || n.contains('medic') || n.contains('salud')) return Icons.medical_services;
  if (n.contains('rescate')) return Icons.health_and_safety;
  if (n.contains('inunda') || n.contains('agua')) return Icons.water_damage;
  if (n.contains('robo') || n.contains('violenc') || n.contains('seguridad')) return Icons.local_police;
  if (n.contains('derrumbe') || n.contains('estructura') || n.contains('colapso')) return Icons.domain_disabled;
  return Icons.report_problem_outlined;
}

DateTime? _asDate(dynamic raw) => raw is DateTime ? raw : DateTime.tryParse('$raw');

String _timeAgo(dynamic raw) {
  final dt = _asDate(raw);
  if (dt == null) return '';
  final diff = DateTime.now().difference(dt);
  if (diff.inSeconds < 60) return 'hace instantes';
  if (diff.inMinutes < 60) return 'hace ${diff.inMinutes} min';
  if (diff.inHours < 24) return 'hace ${diff.inHours} h';
  if (diff.inDays < 7) return 'hace ${diff.inDays} d';
  return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
}

String _hm(dynamic raw) {
  final dt = _asDate(raw);
  if (dt == null) return '';
  return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
}

String _dmy(dynamic raw) {
  final dt = _asDate(raw);
  if (dt == null) return '';
  return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} · ${_hm(raw)}';
}

/// Expediente completo de una emergencia — GET /api/dashboard/emergencies/[id]
/// trae TODO embebido (reportes, ubicaciones, llamadas, sala/chat,
/// evidencias, análisis IA, requerimientos, asignaciones, historial de
/// estados, avances, destinos). Replica emergency-tabs.tsx del dashboard web.
class EmergencyDetailScreen extends StatefulWidget {
  final int id;
  const EmergencyDetailScreen({super.key, required this.id});

  @override
  State<EmergencyDetailScreen> createState() => _EmergencyDetailScreenState();
}

class _EmergencyDetailScreenState extends State<EmergencyDetailScreen> with SingleTickerProviderStateMixin {
  final _service = EmergencyService();
  late final TabController _tabController = TabController(length: _tabTitles.length, vsync: this);

  Map<String, dynamic>? _data;
  List<Map<String, dynamic>> _assignments = [];
  List<Map<String, dynamic>> _locations = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await _service.getById(widget.id);
      List<Map<String, dynamic>> assignments = [];
      List<Map<String, dynamic>> locations = [];
      try {
        assignments = await _service.assignments(widget.id);
      } catch (_) {}
      try {
        locations = await _service.locations(widget.id);
      } catch (_) {}
      setState(() {
        _data = data;
        _assignments = assignments;
        _locations = locations;
        _error = null;
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _changeStatus() async {
    final current = _data!['status'];
    final chosen = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (ctx) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.8),
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(20, 0, 20, 8),
                  child: Align(alignment: Alignment.centerLeft, child: Text('Cambiar estado', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16))),
                ),
                for (final s in _statusFlow)
                  RadioListTile<String>(
                    title: Text(emergencyStatusLabels[s] ?? s),
                    secondary: CircleAvatar(radius: 6, backgroundColor: emergencyStatusColors[s] ?? AppColors.textTertiary),
                    value: s,
                    groupValue: current,
                    onChanged: (v) => Navigator.pop(context, v),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
    if (chosen == null || chosen == current) return;
    try {
      await _service.updateStatus(widget.id, status: chosen);
      _load();
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  /// La asignación con unidad más relevante para mostrar acciones rápidas de
  /// seguimiento: preferimos una todavía en curso; si todas están cerradas,
  /// mostramos igual la más reciente con unidad.
  Map<String, dynamic>? get _trackedAssignment {
    final withUnit = _assignments.where((a) => a['FK_unit'] != null).toList();
    if (withUnit.isEmpty) return null;
    for (final a in withUnit) {
      if (_openAssignmentStatuses.contains(a['status'])) return a;
    }
    return withUnit.first;
  }

  void _openRoute(int assignmentId) {
    context.read<RouteViewProvider>().show(assignmentId);
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  ({double lat, double lng, String? address})? get _primaryLocation {
    if (_locations.isNotEmpty) {
      final l = _locations.first;
      final lat = (l['latitude'] as num?)?.toDouble();
      final lng = (l['longitude'] as num?)?.toDouble();
      if (lat != null && lng != null) return (lat: lat, lng: lng, address: l['address'] as String?);
    }
    return null;
  }

  void _showLocation() {
    final loc = _primaryLocation;
    if (loc == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Esta emergencia no tiene una ubicación registrada.')));
      return;
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _LocationSheet(lat: loc.lat, lng: loc.lng, address: loc.address ?? _data?['address'] as String?),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading && _data == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_error != null && _data == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Emergencia')),
        body: Center(child: Text(_error!)),
      );
    }

    final e = _data!;
    final priority = e['priority'] as String?;
    final priorityColor = priorityColors[priority] ?? AppColors.textTertiary;
    final typeName = e['tbemergencytypes']?['name'] as String?;
    final loc = _primaryLocation;
    final tracked = _trackedAssignment;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(e, priority, priorityColor),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _load,
                child: CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: _SummaryCard(
                        data: e,
                        priorityColor: priorityColor,
                        typeName: typeName,
                        hasLocation: loc != null,
                        onViewMap: _showLocation,
                        canViewRoute: tracked != null,
                        onViewRoute: tracked != null ? () => _openRoute(tracked['PK_assignment'] as int) : null,
                      ),
                    ),
                    SliverPersistentHeader(
                      pinned: true,
                      delegate: _TabBarDelegate(controller: _tabController),
                    ),
                    SliverFillRemaining(
                      hasScrollBody: true,
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _InfoTab(data: e, location: loc, onViewMap: _showLocation, onChangeStatus: _changeStatus),
                          _RoomTab(id: widget.id, service: _service),
                          _AssignmentsTab(
                            id: widget.id,
                            service: _service,
                            onChanged: _load,
                            trackedAssignment: tracked,
                            onOpenRoute: _openRoute,
                          ),
                          _RequirementsTab(id: widget.id, service: _service),
                          _TimelineTab(id: widget.id, service: _service, statusHistory: (e['tbemergencystatushistory'] as List? ?? [])),
                          _RecordsTab(id: widget.id, service: _service),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(Map<String, dynamic> e, String? priority, Color priorityColor) {
    return Container(
      padding: const EdgeInsets.fromLTRB(4, 6, 12, 10),
      decoration: const BoxDecoration(
        color: AppColors.surfacePrimary,
        border: Border(bottom: BorderSide(color: AppColors.borderPrimary, width: 1)),
      ),
      child: Row(
        children: [
          IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.of(context).pop()),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  e['emergencyCode'] ?? '',
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17, color: AppColors.textPrimary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        (e['tbemergencytypes']?['name'] as String?)?.toUpperCase() ?? 'SIN CLASIFICAR',
                        style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppColors.textTertiary, letterSpacing: 0.3),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (priority != null) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(color: priorityColor, borderRadius: BorderRadius.circular(AppSpacing.borderRadiusFull)),
                        child: Text(
                          'PRIORIDAD ${priorityLabels[priority]?.toUpperCase() ?? priority.toUpperCase()}',
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          IconButton(icon: const Icon(Icons.refresh), tooltip: 'Actualizar', onPressed: _load),
          IconButton(icon: const Icon(Icons.place_outlined), tooltip: 'Ver ubicación', onPressed: _showLocation),
        ],
      ),
    );
  }
}

/// Barra de pestañas fijada (sticky) al hacer scroll, con fondo propio para
/// que no se transparente el contenido de abajo.
class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabController controller;
  _TabBarDelegate({required this.controller});

  @override
  double get minExtent => 46;
  @override
  double get maxExtent => 46;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: AppColors.background,
      child: TabBar(
        controller: controller,
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        indicatorSize: TabBarIndicatorSize.label,
        indicatorWeight: 3,
        labelStyle: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700),
        unselectedLabelStyle: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w500),
        tabs: [for (final t in _tabTitles) Tab(text: t)],
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _TabBarDelegate oldDelegate) => oldDelegate.controller != controller;
}

/// Contenedor visual reutilizado por todas las tarjetas de esta pantalla:
/// bordes redondeados, sombra muy sutil y separación interna consistente.
class _Card extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  const _Card({required this.child, this.padding = const EdgeInsets.all(14), this.margin = const EdgeInsets.fromLTRB(12, 0, 12, 12)});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.surfacePrimary,
        borderRadius: BorderRadius.circular(AppSpacing.borderRadiusLg),
        border: Border.all(color: AppColors.borderPrimary),
        boxShadow: [BoxShadow(color: AppColors.shadowColor, blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: child,
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  final IconData? icon;
  const _SectionLabel(this.text, {this.icon});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          if (icon != null) ...[Icon(icon, size: 15, color: AppColors.textTertiary), const SizedBox(width: 6)],
          Text(text.toUpperCase(), style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.textTertiary, letterSpacing: 0.4)),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final Color color;
  final String label;
  const _StatusPill({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(AppSpacing.borderRadiusFull), border: Border.all(color: color.withValues(alpha: 0.35))),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.circle, size: 8, color: color),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: color)),
        ],
      ),
    );
  }
}

/// Tarjeta superior: resumen del incidente + accesos directos a mapa/ruta.
class _SummaryCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final Color priorityColor;
  final String? typeName;
  final bool hasLocation;
  final VoidCallback onViewMap;
  final bool canViewRoute;
  final VoidCallback? onViewRoute;

  const _SummaryCard({
    required this.data,
    required this.priorityColor,
    required this.typeName,
    required this.hasLocation,
    required this.onViewMap,
    required this.canViewRoute,
    required this.onViewRoute,
  });

  @override
  Widget build(BuildContext context) {
    final priority = data['priority'] as String?;
    return _Card(
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _StatusPill(color: priorityColor, label: 'PRIORIDAD ${priorityLabels[priority]?.toUpperCase() ?? (priority ?? '—')}'),
              const Spacer(),
              Icon(Icons.schedule, size: 14, color: AppColors.textTertiary),
              const SizedBox(width: 4),
              Text(_timeAgo(data['reportedAt']), style: const TextStyle(fontSize: 12, color: AppColors.textTertiary)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(color: AppColors.primaryContainer, borderRadius: BorderRadius.circular(12)),
                child: Icon(_typeIcon(typeName), color: AppColors.primaryDark, size: 21),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text((typeName ?? 'SIN CLASIFICAR').toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
                    const SizedBox(height: 4),
                    Text(
                      (data['description'] as String?)?.trim().isNotEmpty == true ? data['description'] : 'Sin descripción registrada.',
                      style: const TextStyle(fontSize: 13.5, color: AppColors.textSecondary, height: 1.35),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(hasLocation ? Icons.location_on : Icons.location_off_outlined, size: 15, color: hasLocation ? AppColors.resolvedGreen : AppColors.textTertiary),
              const SizedBox(width: 5),
              Text(
                hasLocation ? 'Ubicación disponible' : 'Sin ubicación registrada',
                style: TextStyle(fontSize: 12.5, color: hasLocation ? AppColors.textSecondary : AppColors.textTertiary),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: hasLocation ? onViewMap : null,
                  icon: const Icon(Icons.map_outlined, size: 18),
                  label: const Text('Ver en mapa'),
                  style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 11)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  onPressed: canViewRoute ? onViewRoute : null,
                  icon: const Icon(Icons.alt_route, size: 18),
                  label: const Text('Ver ruta'),
                  style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 11)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Hoja modal con un mapa mínimo centrado en un punto — usada por "Ver
/// ubicación" / "Ver en mapa" para mostrar dónde ocurrió el incidente sin
/// salir de la pantalla de detalle.
class _LocationSheet extends StatelessWidget {
  final double lat;
  final double lng;
  final String? address;
  const _LocationSheet({required this.lat, required this.lng, this.address});

  @override
  Widget build(BuildContext context) {
    final point = LatLng(lat, lng);
    return DraggableScrollableSheet(
      initialChildSize: 0.55,
      minChildSize: 0.35,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) => Container(
        decoration: const BoxDecoration(
          color: AppColors.surfacePrimary,
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.borderRadiusXl)),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            const SizedBox(height: 10),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.borderSecondary, borderRadius: BorderRadius.circular(4))),
            Expanded(
              child: Stack(
                children: [
                  FlutterMap(
                    options: MapOptions(initialCenter: point, initialZoom: 16),
                    children: [
                      TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png', userAgentPackageName: 'com.sosapk.app'),
                      MarkerLayer(markers: [
                        Marker(
                          point: point,
                          width: 44,
                          height: 44,
                          child: const Icon(Icons.location_on, color: AppColors.urgentRed, size: 40),
                        ),
                      ]),
                    ],
                  ),
                  Positioned(
                    left: 12,
                    right: 12,
                    bottom: 12,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: AppColors.surfacePrimary, borderRadius: BorderRadius.circular(AppSpacing.borderRadiusMd), boxShadow: [BoxShadow(color: AppColors.shadowColor, blurRadius: 10)]),
                      child: Row(
                        children: [
                          const Icon(Icons.place, color: AppColors.urgentRed, size: 18),
                          const SizedBox(width: 8),
                          Expanded(child: Text(address ?? '${lat.toStringAsFixed(5)}, ${lng.toStringAsFixed(5)}', style: const TextStyle(fontSize: 13))),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoTab extends StatelessWidget {
  final Map<String, dynamic> data;
  final ({double lat, double lng, String? address})? location;
  final VoidCallback onViewMap;
  final VoidCallback onChangeStatus;
  const _InfoTab({required this.data, required this.location, required this.onViewMap, required this.onChangeStatus});

  @override
  Widget build(BuildContext context) {
    final citizen = data['tbcitizens'];
    final status = data['status'] as String?;
    final statusColor = emergencyStatusColors[status] ?? AppColors.textTertiary;
    final address = location?.address ?? data['address'] as String?;

    return ListView(
      padding: const EdgeInsets.only(top: 12, bottom: 24),
      children: [
        _Card(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _SectionLabel('Estado'),
                    _StatusPill(color: statusColor, label: (emergencyStatusLabels[status] ?? status ?? '—').toUpperCase()),
                  ],
                ),
              ),
              // Acceso directo para revisar/avanzar el caso sin tener que
              // buscarlo en el menú de "⋮" — es la acción que más se repite
              // al atender un reporte, así que va al frente, no escondida.
              OutlinedButton.icon(
                onPressed: onChangeStatus,
                icon: const Icon(Icons.sync_alt, size: 17),
                label: const Text('Cambiar'),
                style: OutlinedButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                ),
              ),
            ],
          ),
        ),
        _Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _SectionLabel('Detalles'),
              _kv('Tipo', data['tbemergencytypes']?['name'] ?? 'Sin clasificar'),
              const SizedBox(height: 10),
              _kv('Prioridad', priorityLabels[data['priority']] ?? data['priority']),
              const SizedBox(height: 10),
              _kv('Reportes recibidos', '${data['reportCount'] ?? 1}'),
              const SizedBox(height: 10),
              const Text('Descripción', style: TextStyle(fontSize: 12, color: AppColors.textTertiary)),
              const SizedBox(height: 3),
              Text((data['description'] as String?)?.trim().isNotEmpty == true ? data['description'] : 'Sin descripción registrada.', style: const TextStyle(fontSize: 14, height: 1.4)),
            ],
          ),
        ),
        _Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _SectionLabel('Ubicación', icon: Icons.place_outlined),
              Row(
                children: [
                  Expanded(child: Text(address ?? 'Sin dirección registrada', style: const TextStyle(fontSize: 14))),
                ],
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: location != null ? onViewMap : null,
                  icon: const Icon(Icons.map_outlined, size: 18),
                  label: const Text('Ver en mapa'),
                ),
              ),
            ],
          ),
        ),
        _Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _SectionLabel('Afectados'),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _affectedTile(Icons.person_outline, 'Personas', data['affectedPersons']),
                  _affectedTile(Icons.pets_outlined, 'Animales', data['affectedAnimals']),
                  _affectedTile(Icons.construction_outlined, 'Atrapados', data['trappedPersons']),
                  _affectedTile(Icons.help_outline, 'Desaparecidos', data['missingPersons']),
                ],
              ),
            ],
          ),
        ),
        _Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _SectionLabel('Ciudadano', icon: Icons.person_outline),
              if (citizen != null)
                Row(
                  children: [
                    CircleAvatar(radius: 18, backgroundColor: AppColors.primaryContainer, child: Text(('${citizen['firstName'] ?? '?'}').characters.first.toUpperCase(), style: const TextStyle(color: AppColors.primaryDark, fontWeight: FontWeight.w700))),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${citizen['firstName'] ?? ''} ${citizen['lastName'] ?? ''}'.trim(), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                          if (citizen['phoneNumber'] != null) Text(citizen['phoneNumber'], style: const TextStyle(fontSize: 12.5, color: AppColors.textTertiary)),
                        ],
                      ),
                    ),
                  ],
                )
              else
                const Text('Reportado por operador institucional', style: TextStyle(fontSize: 13.5, color: AppColors.textTertiary)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _affectedTile(IconData icon, String label, dynamic value) {
    return Container(
      width: 84,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(color: AppColors.surfaceSecondary, borderRadius: BorderRadius.circular(AppSpacing.borderRadiusMd)),
      child: Column(
        children: [
          Icon(icon, size: 18, color: AppColors.accent),
          const SizedBox(height: 4),
          Text('${value ?? 0}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
          Text(label, style: const TextStyle(fontSize: 10.5, color: AppColors.textTertiary), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _kv(String k, dynamic v) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 2, child: Text(k, style: const TextStyle(fontSize: 12.5, color: AppColors.textTertiary))),
          Expanded(flex: 3, child: Text(v?.toString() ?? '-', style: const TextStyle(fontSize: 13.5))),
        ],
      );
}

class _RoomTab extends StatefulWidget {
  final int id;
  final EmergencyService service;
  const _RoomTab({required this.id, required this.service});

  @override
  State<_RoomTab> createState() => _RoomTabState();
}

class _RoomTabState extends State<_RoomTab> {
  List<Map<String, dynamic>> _messages = [];
  Map<String, dynamic>? _room;
  final _msgCtrl = TextEditingController();
  bool _loading = true;
  bool _hasRoom = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _msgCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final room = await widget.service.room(widget.id);
      if (room == null) {
        setState(() {
          _hasRoom = false;
          _loading = false;
        });
        return;
      }
      final msgs = await widget.service.messages(widget.id);
      setState(() {
        _messages = msgs;
        _room = room;
        _hasRoom = true;
      });
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _send() async {
    if (_msgCtrl.text.trim().isEmpty) return;
    final text = _msgCtrl.text.trim();
    _msgCtrl.clear();
    try {
      await widget.service.sendMessage(widget.id, text);
      _load();
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (!_hasRoom) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text('Esta emergencia no tiene sala de crisis.', textAlign: TextAlign.center, style: TextStyle(color: AppColors.textTertiary)),
        ),
      );
    }
    final isOpen = _room?['isOpen'] != false;
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
          color: AppColors.surfaceSecondary,
          child: Row(
            children: [
              const Icon(Icons.forum_outlined, size: 17, color: AppColors.accent),
              const SizedBox(width: 7),
              const Text('Sala del reporte', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
              const Spacer(),
              Icon(Icons.circle, size: 9, color: isOpen ? AppColors.resolvedGreen : AppColors.textTertiary),
              const SizedBox(width: 5),
              Text(isOpen ? 'Sala abierta' : 'Sala cerrada', style: TextStyle(fontSize: 12, color: isOpen ? AppColors.resolvedGreenDark : AppColors.textTertiary, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
        Expanded(
          child: _messages.isEmpty
              ? const Center(child: Text('Aún no hay mensajes en esta sala.', style: TextStyle(color: AppColors.textTertiary)))
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  itemCount: _messages.length,
                  itemBuilder: (context, i) => _buildMessage(_messages[i]),
                ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _msgCtrl,
                    decoration: InputDecoration(
                      hintText: 'Escribir mensaje...',
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppSpacing.borderRadiusFull), borderSide: BorderSide.none),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppSpacing.borderRadiusFull), borderSide: BorderSide.none),
                    ),
                    onSubmitted: (_) => _send(),
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  radius: 21,
                  backgroundColor: AppColors.primary,
                  child: IconButton(icon: const Icon(Icons.send, color: Colors.white, size: 19), onPressed: _send),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMessage(Map<String, dynamic> m) {
    final isSystem = m['senderRole'] == 'SYSTEM';
    if (isSystem) {
      return Center(
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(color: AppColors.resolvedGreenContainer, borderRadius: BorderRadius.circular(AppSpacing.borderRadiusFull)),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle, size: 14, color: AppColors.resolvedGreenDark),
              const SizedBox(width: 6),
              Text(m['message'] ?? '', style: const TextStyle(fontSize: 12, color: AppColors.resolvedGreenDark, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      );
    }

    final isCitizen = m['FK_citizen'] != null;
    final align = isCitizen ? CrossAxisAlignment.start : CrossAxisAlignment.end;
    final bubbleColor = isCitizen ? AppColors.surfaceSecondary : AppColors.primaryContainer;
    final roleLabel = isCitizen ? 'CIUDADANO' : 'OPERADOR';
    final roleColor = isCitizen ? AppColors.textTertiary : AppColors.primaryDark;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Column(
        crossAxisAlignment: align,
        children: [
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.76),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
              decoration: BoxDecoration(
                color: bubbleColor,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(14),
                  topRight: const Radius.circular(14),
                  bottomLeft: Radius.circular(isCitizen ? 2 : 14),
                  bottomRight: Radius.circular(isCitizen ? 14 : 2),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(m['senderName']?.toString() ?? roleLabel, style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: roleColor, letterSpacing: 0.3)),
                  const SizedBox(height: 2),
                  Text(m['message'] ?? '', style: const TextStyle(fontSize: 14, height: 1.3)),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 2, left: 4, right: 4),
            child: Text(_hm(m['createdAt']), style: const TextStyle(fontSize: 10, color: AppColors.textDisabled)),
          ),
        ],
      ),
    );
  }
}

class _AssignmentsTab extends StatefulWidget {
  final int id;
  final EmergencyService service;
  final VoidCallback onChanged;
  final Map<String, dynamic>? trackedAssignment;
  final void Function(int assignmentId) onOpenRoute;
  const _AssignmentsTab({required this.id, required this.service, required this.onChanged, required this.trackedAssignment, required this.onOpenRoute});

  @override
  State<_AssignmentsTab> createState() => _AssignmentsTabState();
}

class _AssignmentsTabState extends State<_AssignmentsTab> {
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
      final items = await widget.service.assignments(widget.id);
      setState(() => _items = items);
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _newAssignment() async {
    final institutions = await CrudConfigs.institutions.service.list(query: {'pageSize': 200});
    if (!mounted) return;
    int? institutionId;
    int? unitId;
    List<Map<String, dynamic>> units = [];

    await showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Asignar unidad'),
          content: SizedBox(
            width: dialogContentWidth(context, 380),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<int>(
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Institución *', border: OutlineInputBorder()),
                  items: institutions.items
                      .map((i) => DropdownMenuItem(value: i['PK_institution'] as int, child: Text(i['name']?.toString() ?? '', overflow: TextOverflow.ellipsis)))
                      .toList(),
                  onChanged: (v) async {
                    final u = await CrudConfigs.units.service.list(query: {'FK_institution': v, 'pageSize': 200});
                    // `unitId` se resetea junto con la institución: la unidad
                    // elegida antes casi nunca pertenece a la nueva lista, y
                    // sin esto el dropdown de abajo queda con un valor
                    // seleccionado que ya no está entre sus `items` — eso
                    // dispara el assert de Flutter ("exactly one item with
                    // value") y revienta el diálogo. La `key` fuerza además
                    // que ese dropdown arranque de cero (sin selección
                    // visual) cada vez que cambia la institución.
                    setDialogState(() {
                      institutionId = v;
                      unitId = null;
                      units = u.items;
                    });
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  key: ValueKey(institutionId),
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Unidad (opcional)', border: OutlineInputBorder()),
                  items: units.map((u) => DropdownMenuItem(value: u['PK_unit'] as int, child: Text('${u['unitCode']} · ${u['unitName']}', overflow: TextOverflow.ellipsis))).toList(),
                  onChanged: (v) => setDialogState(() => unitId = v),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancelar')),
            FilledButton(
              onPressed: () async {
                if (institutionId == null) return;
                try {
                  await widget.service.createAssignment(widget.id, institution: institutionId!, unit: unitId);
                  if (dialogContext.mounted) Navigator.pop(dialogContext);
                  _load();
                  widget.onChanged();
                } on ApiException catch (e) {
                  if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
                }
              },
              child: const Text('Asignar'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    final tracked = widget.trackedAssignment;

    return Stack(
      children: [
        ListView(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 90),
          children: [
            if (tracked != null) _trackingCard(tracked),
            _Card(
              margin: EdgeInsets.zero,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _SectionLabel('Asignación de recursos'),
                  if (_items.isEmpty) ...[
                    _StatusPill(color: AppColors.moderateOrange, label: 'PENDIENTE DE ASIGNACIÓN'),
                    const SizedBox(height: 12),
                    _kv('Unidad', '— Sin asignar —'),
                    const SizedBox(height: 8),
                    _kv('Institución', '— Sin asignar —'),
                  ] else
                    Column(children: [for (final a in _items) _assignmentTile(a)]),
                ],
              ),
            ),
          ],
        ),
        Positioned(
          left: 12,
          right: 12,
          bottom: 12,
          child: FilledButton.icon(
            onPressed: _newAssignment,
            icon: const Icon(Icons.add),
            label: const Text('Asignar unidad'),
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
          ),
        ),
      ],
    );
  }

  Widget _trackingCard(Map<String, dynamic> a) {
    final unit = a['tbunits'];
    final color = _assignmentStatusColors[a['status']] ?? AppColors.primary;
    return _Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionLabel('Seguimiento en tiempo real', icon: Icons.gps_fixed),
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
                child: Icon(Icons.local_shipping, color: color, size: 19),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(unit != null ? '${unit['unitCode']} · ${unit['unitName']}' : 'Unidad asignada', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
                    const SizedBox(height: 3),
                    _StatusPill(color: color, label: _assignmentStatusLabels[a['status']] ?? a['status'] ?? ''),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => widget.onOpenRoute(a['PK_assignment'] as int),
              icon: const Icon(Icons.alt_route, size: 18),
              label: const Text('Ver seguimiento'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _assignmentTile(Map<String, dynamic> a) {
    final unit = a['tbunits'];
    final color = _assignmentStatusColors[a['status']] ?? AppColors.textTertiary;
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: AppColors.surfaceSecondary, borderRadius: BorderRadius.circular(AppSpacing.borderRadiusMd)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(a['tbinstitutions']?['name'] ?? 'Institución', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5))),
              _StatusPill(color: color, label: _assignmentStatusLabels[a['status']] ?? a['status'] ?? ''),
            ],
          ),
          const SizedBox(height: 6),
          Text(unit != null ? '${unit['unitCode']} · ${unit['unitName']}' : 'Sin unidad asignada', style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary)),
          if (unit != null) ...[
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () => widget.onOpenRoute(a['PK_assignment'] as int),
              icon: const Icon(Icons.alt_route, size: 16),
              label: const Text('Ver ruta'),
              style: OutlinedButton.styleFrom(visualDensity: VisualDensity.compact, padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _kv(String k, dynamic v) => Row(
        children: [
          Expanded(flex: 2, child: Text(k, style: const TextStyle(fontSize: 12.5, color: AppColors.textTertiary))),
          Expanded(flex: 3, child: Text(v?.toString() ?? '-', style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600))),
        ],
      );
}

class _RequirementsTab extends StatefulWidget {
  final int id;
  final EmergencyService service;
  const _RequirementsTab({required this.id, required this.service});

  @override
  State<_RequirementsTab> createState() => _RequirementsTabState();
}

class _RequirementsTabState extends State<_RequirementsTab> {
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
      final items = await widget.service.requirements(widget.id);
      setState(() => _items = items);
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _newRequirement() async {
    final types = await CrudConfigs.resourceTypes.service.list(query: {'pageSize': 200});
    if (!mounted) return;
    int? typeId;
    final qtyCtrl = TextEditingController(text: '1');
    await showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Solicitar apoyo adicional'),
        content: SizedBox(
          width: dialogContentWidth(dialogContext, 340),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<int>(
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Tipo de recurso *', border: OutlineInputBorder()),
                items: types.items
                    .map((t) => DropdownMenuItem(value: t['PK_resourceType'] as int, child: Text(t['name']?.toString() ?? '', overflow: TextOverflow.ellipsis)))
                    .toList(),
                onChanged: (v) => typeId = v,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: qtyCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Cantidad', border: OutlineInputBorder()),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () async {
              if (typeId == null) return;
              await widget.service.createRequirement(widget.id, resourceType: typeId!, quantity: int.tryParse(qtyCtrl.text) ?? 1);
              if (dialogContext.mounted) Navigator.pop(dialogContext);
              _load();
            },
            child: const Text('Solicitar'),
          ),
        ],
      ),
    );
  }

  Future<void> _cycleStatus(Map<String, dynamic> r) async {
    const order = ['PENDIENTE', 'ASIGNADO', 'ATENDIDO'];
    final next = order[(order.indexOf(r['status']) + 1) % order.length];
    await widget.service.updateRequirementStatus(widget.id, r['PK_requirement'], next);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    return Stack(
      children: [
        ListView(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 90),
          children: [
            const Padding(
              padding: EdgeInsets.only(left: 2, bottom: 10),
              child: Text('¿Se requiere apoyo adicional?', style: TextStyle(fontSize: 13, color: AppColors.textTertiary)),
            ),
            if (_items.isEmpty)
              const Padding(padding: EdgeInsets.only(top: 30), child: Center(child: Text('Sin requerimientos registrados', style: TextStyle(color: AppColors.textTertiary))))
            else
              for (final r in _items) _requirementCard(r),
          ],
        ),
        Positioned(
          left: 12,
          right: 12,
          bottom: 12,
          child: FilledButton.icon(
            onPressed: _newRequirement,
            icon: const Icon(Icons.add),
            label: const Text('Solicitar unidad'),
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
          ),
        ),
      ],
    );
  }

  Widget _requirementCard(Map<String, dynamic> r) {
    final color = _requirementStatusColors[r['status']] ?? AppColors.textTertiary;
    return _Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text('${r['tbresourcetypes']?['name'] ?? 'Recurso'} × ${r['quantity'] ?? 1}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5))),
              _StatusPill(color: color, label: _requirementStatusLabels[r['status']] ?? r['status'] ?? ''),
            ],
          ),
          const SizedBox(height: 6),
          Text(_dmy(r['createdAt']), style: const TextStyle(fontSize: 11.5, color: AppColors.textTertiary)),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(onPressed: () => _cycleStatus(r), child: const Text('Avanzar estado')),
          ),
        ],
      ),
    );
  }
}

/// Combina el historial de estados (`tbemergencystatushistory`) y los
/// avances de campo (`/progress-reports`) en una sola línea de tiempo,
/// ordenada cronológicamente — así "Avances" muestra de un vistazo todo lo
/// que pasó con el caso, sin fabricar eventos que el backend no registra.
class _TimelineTab extends StatefulWidget {
  final int id;
  final EmergencyService service;
  final List statusHistory;
  const _TimelineTab({required this.id, required this.service, required this.statusHistory});

  @override
  State<_TimelineTab> createState() => _TimelineTabState();
}

class _TimelineTabState extends State<_TimelineTab> {
  List<Map<String, dynamic>> _progress = [];
  final _textCtrl = TextEditingController();
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _textCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final items = await widget.service.progressReports(widget.id);
      setState(() => _progress = items);
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _add() async {
    if (_textCtrl.text.trim().isEmpty) return;
    await widget.service.addProgressReport(widget.id, _textCtrl.text.trim());
    _textCtrl.clear();
    _load();
  }

  List<Map<String, dynamic>> get _events {
    final events = <Map<String, dynamic>>[
      for (final h in widget.statusHistory)
        {
          'kind': 'status',
          'createdAt': h['createdAt'],
          'status': h['newStatus'],
          'previousStatus': h['previousStatus'],
          'user': h['tbusers'] != null ? '${h['tbusers']['firstName'] ?? ''} ${h['tbusers']['lastName'] ?? ''}'.trim() : null,
        },
      for (final p in _progress)
        {
          'kind': 'progress',
          'createdAt': p['createdAt'],
          'text': p['reportText'],
          'user': p['tbusers'] != null ? '${p['tbusers']['firstName'] ?? ''} ${p['tbusers']['lastName'] ?? ''}'.trim() : null,
          'institution': p['tbinstitutions']?['acronym'] ?? p['tbinstitutions']?['name'],
        },
    ];
    events.sort((a, b) {
      final da = _asDate(a['createdAt']) ?? DateTime(0);
      final db = _asDate(b['createdAt']) ?? DateTime(0);
      return da.compareTo(db);
    });
    return events;
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    final events = _events;
    return Column(
      children: [
        Expanded(
          child: events.isEmpty
              ? const Center(child: Text('Sin avances registrados', style: TextStyle(color: AppColors.textTertiary)))
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  itemCount: events.length,
                  itemBuilder: (context, i) => _timelineNode(events[i], isLast: i == events.length - 1, isCurrent: i == events.length - 1),
                ),
        ),
        const Divider(height: 1),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _textCtrl,
                    decoration: InputDecoration(
                      hintText: 'Registrar nuevo avance...',
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppSpacing.borderRadiusFull), borderSide: BorderSide.none),
                      filled: true,
                    ),
                    onSubmitted: (_) => _add(),
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(radius: 21, backgroundColor: AppColors.primary, child: IconButton(icon: const Icon(Icons.send, color: Colors.white, size: 19), onPressed: _add)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _timelineNode(Map<String, dynamic> ev, {required bool isLast, required bool isCurrent}) {
    final isStatus = ev['kind'] == 'status';
    final color = isStatus ? (emergencyStatusColors[ev['status']] ?? AppColors.textTertiary) : AppColors.accent;
    final title = isStatus ? (emergencyStatusLabels[ev['status']] ?? ev['status'] ?? '') : 'Avance registrado';
    final subtitle = isStatus ? null : ev['text'] as String?;
    final who = [ev['institution'], ev['user']].where((s) => s != null && (s as String).isNotEmpty).join(' · ');

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isCurrent ? color : Colors.transparent,
                  border: Border.all(color: color, width: 2.5),
                ),
              ),
              if (!isLast) Expanded(child: Container(width: 2, color: AppColors.borderPrimary)),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(isStatus ? Icons.flag : Icons.notes, size: 14, color: color),
                      const SizedBox(width: 6),
                      Text(title.toString().toUpperCase(), style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5, color: color)),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(_dmy(ev['createdAt']), style: const TextStyle(fontSize: 11.5, color: AppColors.textTertiary)),
                  if (subtitle != null && subtitle.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(subtitle, style: const TextStyle(fontSize: 13.5, height: 1.3)),
                  ],
                  if (who.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(who, style: const TextStyle(fontSize: 11.5, color: AppColors.textTertiary, fontStyle: FontStyle.italic)),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RecordsTab extends StatefulWidget {
  final int id;
  final EmergencyService service;
  const _RecordsTab({required this.id, required this.service});

  @override
  State<_RecordsTab> createState() => _RecordsTabState();
}

class _RecordsTabState extends State<_RecordsTab> {
  List<Map<String, dynamic>> _calls = [];
  List<Map<String, dynamic>> _evidences = [];
  List<Map<String, dynamic>> _locations = [];
  List<Map<String, dynamic>> _destinations = [];
  List<Map<String, dynamic>> _reports = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final results = await Future.wait([
        widget.service.calls(widget.id),
        widget.service.evidences(widget.id),
        widget.service.locations(widget.id),
        widget.service.destinations(widget.id),
        widget.service.reports(widget.id),
      ]);
      setState(() {
        _calls = results[0];
        _evidences = results[1];
        _locations = results[2];
        _destinations = results[3];
        _reports = results[4];
      });
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
      children: [
        _section('Llamadas', Icons.call_outlined, _calls, (c) => '${c['callType']} · ${c['status']}', (c) => c['transcription']),
        _section('Evidencias', Icons.attachment_outlined, _evidences, (v) => v['fileType'], (v) => v['fileUrl']),
        _section('Ubicaciones', Icons.place_outlined, _locations, (l) => '${l['latitude']}, ${l['longitude']}', (l) => l['address']),
        _section('Destinos', Icons.flag_outlined, _destinations, (d) => d['destinationName'], (d) => d['tbinstitutions']?['name']),
        _section('Reportes vinculados', Icons.report_gmailerrorred_outlined, _reports, (r) => r['reportChannel'], (r) => '${r['tbcitizens']?['firstName'] ?? 'Anónimo'} · ${r['description'] ?? ''}'),
      ],
    );
  }

  Widget _section(
    String title,
    IconData icon,
    List<Map<String, dynamic>> items,
    String? Function(Map<String, dynamic>) titleOf,
    String? Function(Map<String, dynamic>) subtitleOf,
  ) {
    return _Card(
      margin: const EdgeInsets.only(bottom: 10),
      padding: EdgeInsets.zero,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          leading: Icon(icon, size: 19, color: AppColors.accent),
          title: Text('$title (${items.length})', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
          childrenPadding: const EdgeInsets.only(bottom: 8),
          children: items.isEmpty
              ? [const Padding(padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8), child: Align(alignment: Alignment.centerLeft, child: Text('Sin registros', style: TextStyle(color: AppColors.textTertiary))))]
              : items
                  .map((it) => ListTile(dense: true, title: Text(titleOf(it) ?? ''), subtitle: Text(subtitleOf(it) ?? '')))
                  .toList(),
        ),
      ),
    );
  }
}
