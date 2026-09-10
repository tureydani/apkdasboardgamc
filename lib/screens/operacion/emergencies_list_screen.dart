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

/// Lista de emergencias (`tbemergencies`, isMainEmergency=true), reutilizada
/// para Operación > Emergencias, Incidentes (recién reportadas) e Historial
/// (cerradas).
class EmergenciesListScreen extends StatefulWidget {
  final String title;
  final List<String>? statusFilter;
  final bool allowCreate;

  const EmergenciesListScreen({
    super.key,
    required this.title,
    this.statusFilter,
    this.allowCreate = false,
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
      final result = await _service.list(
        status: widget.statusFilter,
        search: _searchCtrl.text.trim().isEmpty ? null : _searchCtrl.text.trim(),
      );
      setState(() => _items = result.items);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
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
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? ListView(children: [const SizedBox(height: 80), Center(child: Text(_error!))])
                : _items.isEmpty
                    ? ListView(children: const [SizedBox(height: 80), Center(child: Text('Sin emergencias'))])
                    : ListView.separated(
                        itemCount: _items.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, i) {
                          final e = _items[i];
                          final color = priorityColors[e['priority']] ?? AppColors.textTertiary;
                          return ListTile(
                            leading: CircleAvatar(backgroundColor: color.withValues(alpha: 0.15), child: Icon(Icons.emergency, color: color)),
                            title: Text(e['emergencyCode'] ?? ''),
                            subtitle: Text(
                              '${e['tbemergencytypes']?['name'] ?? 'Sin clasificar'} · ${e['status']}\n${e['description'] ?? ''}',
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
                        },
                      ),
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
}
