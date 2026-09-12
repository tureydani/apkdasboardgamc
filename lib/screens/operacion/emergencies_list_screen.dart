import 'package:flutter/material.dart';

import '../../app/theme/index.dart';
import '../../services/emergency_service.dart';
import 'emergency_detail_screen.dart';
import 'emergency_form_screen.dart';

const priorityColors = {
  'CRITICA': AppColors.urgentRedDark,
  'ALTA': AppColors.urgentRed,
  'MEDIA': AppColors.moderateOrange,
  'BAJA': AppColors.textTertiary,
};

const _priorityOrder = ['CRITICA', 'ALTA', 'MEDIA', 'BAJA'];
const _priorityLabels = {
  'CRITICA': 'Crítica',
  'ALTA': 'Alta',
  'MEDIA': 'Media',
  'BAJA': 'Baja',
};

// Mismo flujo operativo que `_statusFlow` en emergency_detail_screen.dart:
// REPORTADA -> EN_ANALISIS -> CLASIFICADA -> ASIGNADA -> EN_ATENCION ->
// RESUELTA (o FALSA_ALARMA / CANCELADA en cualquier punto antes de cerrar).
const _statusOrder = [
  'REPORTADA',
  'EN_ANALISIS',
  'CLASIFICADA',
  'ASIGNADA',
  'EN_ATENCION',
  'RESUELTA',
  'FALSA_ALARMA',
  'CANCELADA',
];
const _statusLabels = {
  'REPORTADA': 'Reportada',
  'EN_ANALISIS': 'En análisis',
  'CLASIFICADA': 'Clasificada',
  'ASIGNADA': 'Asignada',
  'EN_ATENCION': 'En atención',
  'RESUELTA': 'Resuelta',
  'FALSA_ALARMA': 'Falsa alarma',
  'CANCELADA': 'Cancelada',
};
const _statusColors = {
  'REPORTADA': AppColors.moderateOrange,
  'EN_ANALISIS': AppColors.secondary,
  'CLASIFICADA': AppColors.accent,
  'ASIGNADA': AppColors.primary,
  'EN_ATENCION': AppColors.urgentRed,
  'RESUELTA': AppColors.resolvedGreen,
  'FALSA_ALARMA': AppColors.textTertiary,
  'CANCELADA': AppColors.textDisabled,
};

/// Lista de emergencias (`tbemergencies`, isMainEmergency=true), reutilizada
/// para Operación > Emergencias, Incidentes (recién reportadas), Asignación
/// de unidades e Historial (cerradas).
///
/// Además de la búsqueda por texto, permite filtrar por estado (agrupando
/// la vista "Todas" en secciones por estado, para que se entienda de un
/// vistazo cuántas hay en cada punto del flujo) y por prioridad — ambos
/// acotados a los estados que el botón de Operación que abrió esta pantalla
/// ya delimitó (p. ej. "Incidentes" solo deja elegir entre sus 3 estados).
class EmergenciesListScreen extends StatefulWidget {
  final String title;
  final List<String>? statusFilter;
  final bool allowCreate;
  final bool activeOnly;
  final String? priorityFilter;
  final bool reportedTodayOnly;

  const EmergenciesListScreen({
    super.key,
    required this.title,
    this.statusFilter,
    this.allowCreate = false,
    this.activeOnly = false,
    this.priorityFilter,
    this.reportedTodayOnly = false,
  });

  @override
  State<EmergenciesListScreen> createState() => _EmergenciesListScreenState();
}

class _EmergenciesListScreenState extends State<EmergenciesListScreen> {
  final _service = EmergencyService();
  final _searchCtrl = TextEditingController();
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;
  String? _error;

  /// Estados que este botón de Operación habilita ver, en orden de flujo.
  late final List<String> _statusScope = (widget.statusFilter ?? _statusOrder)
      .where(_statusOrder.contains)
      .toList()
    ..sort((a, b) => _statusOrder.indexOf(a).compareTo(_statusOrder.indexOf(b)));

  /// null = "Todas" (dentro del alcance de arriba) → vista agrupada por
  /// estado. Un valor puntual → lista plana filtrada a ese estado.
  String? _selectedStatus;
  String? _selectedPriority;

  @override
  void initState() {
    super.initState();
    _selectedPriority = widget.priorityFilter;
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      // La prioridad NO se manda al servidor: `widget.priorityFilter` solo
      // fija la selección inicial del chip, que el usuario puede ampliar a
      // "Toda prioridad" sin perder datos ya traídos (ver _visibleItems).
      final result = await _service.list(
        status: widget.statusFilter,
        active: widget.activeOnly ? true : null,
        search: _searchCtrl.text.trim().isEmpty ? null : _searchCtrl.text.trim(),
      );
      var items = result.items;
      if (widget.reportedTodayOnly) {
        final startOfDay = DateTime.now();
        final today = DateTime(startOfDay.year, startOfDay.month, startOfDay.day);
        items = items.where((e) {
          final reportedAt = DateTime.tryParse('${e['reportedAt']}');
          return reportedAt != null && !reportedAt.isBefore(today);
        }).toList();
      }
      setState(() => _items = items);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// Filtro de estado/prioridad aplicado en el cliente sobre lo ya
  /// descargado — instantáneo, sin ida y vuelta al servidor, ya que
  /// `widget.statusFilter`/`widget.priorityFilter` acotan de entrada lo que
  /// se pide al backend.
  List<Map<String, dynamic>> get _visibleItems {
    return _items.where((e) {
      if (_selectedStatus != null && e['status'] != _selectedStatus) return false;
      if (_selectedPriority != null && e['priority'] != _selectedPriority) return false;
      return true;
    }).toList();
  }

  /// Agrupa por estado (en orden de flujo), omitiendo estados sin resultados.
  List<MapEntry<String, List<Map<String, dynamic>>>> get _groupedByStatus {
    final visible = _visibleItems;
    return _statusScope
        .map((s) => MapEntry(s, visible.where((e) => e['status'] == s).toList()))
        .where((entry) => entry.value.isNotEmpty)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
            child: TextField(
              controller: _searchCtrl,
              onSubmitted: (_) => _load(),
              decoration: InputDecoration(
                hintText: 'Buscar por código o descripción...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                isDense: true,
              ),
            ),
          ),
          if (_statusScope.length > 1) _buildStatusFilterRow(),
          _buildPriorityFilterRow(),
          const Divider(height: 1),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _load,
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? ListView(children: [const SizedBox(height: 80), Center(child: Text(_error!))])
                      : _visibleItems.isEmpty
                          ? ListView(children: const [SizedBox(height: 80), Center(child: Text('Sin emergencias'))])
                          : _selectedStatus == null
                              ? _buildGroupedList()
                              : _buildFlatList(_visibleItems),
            ),
          ),
        ],
      ),
      floatingActionButton: widget.allowCreate
          ? FloatingActionButton.extended(
              icon: const Icon(Icons.add),
              label: const Text('Registrar'),
              onPressed: () async {
                final created = await Navigator.of(context).push<bool>(
                  MaterialPageRoute(builder: (_) => const EmergencyFormScreen()),
                );
                if (created == true) _load();
              },
            )
          : null,
    );
  }

  Widget _buildStatusFilterRow() {
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        children: [
          _filterChip(
            label: 'Todas',
            selected: _selectedStatus == null,
            color: AppColors.textSecondary,
            onSelected: () => setState(() => _selectedStatus = null),
          ),
          for (final status in _statusScope)
            _filterChip(
              label: _statusLabels[status] ?? status,
              selected: _selectedStatus == status,
              color: _statusColors[status] ?? AppColors.textTertiary,
              onSelected: () => setState(() => _selectedStatus = status),
            ),
        ],
      ),
    );
  }

  Widget _buildPriorityFilterRow() {
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 4),
        children: [
          _filterChip(
            label: 'Toda prioridad',
            selected: _selectedPriority == null,
            color: AppColors.textSecondary,
            onSelected: () => setState(() => _selectedPriority = null),
          ),
          for (final priority in _priorityOrder)
            _filterChip(
              label: _priorityLabels[priority] ?? priority,
              selected: _selectedPriority == priority,
              color: priorityColors[priority] ?? AppColors.textTertiary,
              onSelected: () => setState(() => _selectedPriority = priority),
            ),
        ],
      ),
    );
  }

  Widget _filterChip({required String label, required bool selected, required Color color, required VoidCallback onSelected}) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label, style: TextStyle(fontSize: 12, color: selected ? Colors.white : color)),
        selected: selected,
        onSelected: (_) => onSelected(),
        backgroundColor: color.withValues(alpha: 0.1),
        selectedColor: color,
        checkmarkColor: Colors.white,
        visualDensity: VisualDensity.compact,
        side: BorderSide(color: color.withValues(alpha: 0.4)),
      ),
    );
  }

  /// Vista "Todas": una sección por estado (en orden de flujo), con
  /// encabezado de color + cantidad, para que se entienda de un vistazo
  /// cómo se reparten las emergencias entre sus distintos estados.
  Widget _buildGroupedList() {
    final groups = _groupedByStatus;
    return ListView.builder(
      itemCount: groups.length,
      itemBuilder: (context, i) {
        final status = groups[i].key;
        final items = groups[i].value;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatusHeader(status, items.length),
            ...items.map(_buildTile),
            const Divider(height: 1),
          ],
        );
      },
    );
  }

  Widget _buildFlatList(List<Map<String, dynamic>> items) {
    return ListView.separated(
      itemCount: items.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, i) => _buildTile(items[i]),
    );
  }

  Widget _buildStatusHeader(String status, int count) {
    final color = _statusColors[status] ?? AppColors.textTertiary;
    return Container(
      width: double.infinity,
      color: color.withValues(alpha: 0.1),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Text(
            '${_statusLabels[status] ?? status} · $count',
            style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildTile(Map<String, dynamic> e) {
    final color = priorityColors[e['priority']] ?? AppColors.textTertiary;
    return ListTile(
      leading: CircleAvatar(backgroundColor: color.withValues(alpha: 0.15), child: Icon(Icons.emergency, color: color)),
      title: Text(e['emergencyCode'] ?? ''),
      subtitle: Text(
        '${e['tbemergencytypes']?['name'] ?? 'Sin clasificar'}\n${e['description'] ?? ''}',
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      isThreeLine: true,
      trailing: Chip(
        label: Text(e['priority'] ?? '', style: const TextStyle(fontSize: 11, color: Colors.white)),
        backgroundColor: color,
        visualDensity: VisualDensity.compact,
      ),
      onTap: () async {
        await Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => EmergencyDetailScreen(id: e['PK_emergency'])),
        );
        _load();
      },
    );
  }
}
