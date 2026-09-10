import 'package:flutter/material.dart';

import '../../app/theme/index.dart';
import '../../config/crud_configs.dart';
import '../../core/api_client.dart';
import '../../services/emergency_service.dart';
import 'emergencies_list_screen.dart';

const _statusFlow = [
  'REPORTADA', 'EN_ANALISIS', 'CLASIFICADA', 'ASIGNADA',
  'EN_ATENCION', 'RESUELTA', 'FALSA_ALARMA', 'CANCELADA',
];

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

class _EmergencyDetailScreenState extends State<EmergencyDetailScreen> {
  final _service = EmergencyService();
  Map<String, dynamic>? _data;
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
      final data = await _service.getById(widget.id);
      setState(() => _data = data);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _changeStatus() async {
    final current = _data!['status'];
    final chosen = await showDialog<String>(
      context: context,
      builder: (_) => SimpleDialog(
        title: const Text('Cambiar estado'),
        children: _statusFlow
            .map((s) => RadioListTile<String>(
                  title: Text(s),
                  value: s,
                  groupValue: current,
                  onChanged: (v) => Navigator.pop(context, v),
                ))
            .toList(),
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

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(appBar: AppBar(title: const Text('Cargando...')), body: const Center(child: CircularProgressIndicator()));
    }
    if (_error != null || _data == null) {
      return Scaffold(appBar: AppBar(title: const Text('Error')), body: Center(child: Text(_error ?? 'No encontrada')));
    }
    final e = _data!;
    final color = priorityColors[e['priority']] ?? AppColors.textTertiary;

    return DefaultTabController(
      length: 6,
      child: Scaffold(
        appBar: AppBar(
          title: Text(e['emergencyCode'] ?? ''),
          backgroundColor: color,
          actions: [
            IconButton(icon: const Icon(Icons.sync_alt), tooltip: 'Cambiar estado', onPressed: _changeStatus),
            IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
          ],
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: 'Info'),
              Tab(text: 'Sala/Chat'),
              Tab(text: 'Asignaciones'),
              Tab(text: 'Requerimientos'),
              Tab(text: 'Avances'),
              Tab(text: 'Registros'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _InfoTab(data: e),
            _RoomTab(id: widget.id, service: _service),
            _AssignmentsTab(id: widget.id, service: _service, onChanged: _load),
            _RequirementsTab(id: widget.id, service: _service),
            _ProgressTab(id: widget.id, service: _service),
            _RecordsTab(id: widget.id, service: _service),
          ],
        ),
      ),
    );
  }
}

class _InfoTab extends StatelessWidget {
  final Map<String, dynamic> data;
  const _InfoTab({required this.data});

  @override
  Widget build(BuildContext context) {
    final citizen = data['tbcitizens'];
    final history = (data['tbemergencystatushistory'] as List? ?? []);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _kv('Estado', data['status']),
        _kv('Prioridad', data['priority']),
        _kv('Tipo', data['tbemergencytypes']?['name']),
        _kv('Descripción', data['description']),
        _kv('Dirección', data['address']),
        _kv('Reportes recibidos', data['reportCount']),
        _kv('Ciudadano', citizen != null ? '${citizen['firstName']} ${citizen['lastName']} · ${citizen['phoneNumber']}' : 'Reportado por operador'),
        _kv('Afectados', 'Personas: ${data['affectedPersons'] ?? 0} · Animales: ${data['affectedAnimals'] ?? 0} · Atrapados: ${data['trappedPersons'] ?? 0} · Desaparecidos: ${data['missingPersons'] ?? 0}'),
        _kv('Creada', data['createdAt']),
        const Divider(height: 32),
        const Text('Historial de estados', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ...history.map((h) => ListTile(
              dense: true,
              leading: const Icon(Icons.history),
              title: Text('${h['previousStatus'] ?? '—'} → ${h['newStatus']}'),
              subtitle: Text('${h['createdAt']} · ${h['tbusers']?['firstName'] ?? ''} ${h['tbusers']?['lastName'] ?? ''}'),
            )),
      ],
    );
  }

  Widget _kv(String k, dynamic v) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(width: 130, child: Text(k, style: const TextStyle(color: AppColors.textTertiary))),
            Expanded(child: Text(v?.toString() ?? '-')),
          ],
        ),
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
  final _msgCtrl = TextEditingController();
  bool _loading = true;
  bool _hasRoom = true;

  @override
  void initState() {
    super.initState();
    _load();
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
    if (!_hasRoom) return const Center(child: Text('Esta emergencia no tiene sala de crisis.'));
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            reverse: false,
            padding: const EdgeInsets.all(12),
            itemCount: _messages.length,
            itemBuilder: (context, i) {
              final m = _messages[i];
              final isSystem = m['senderRole'] == 'SYSTEM';
              return Align(
                alignment: isSystem ? Alignment.center : Alignment.centerLeft,
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSystem ? AppColors.surfaceTertiary : AppColors.accentContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${m['senderName'] ?? m['senderRole']}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.accent)),
                      Text(m['message'] ?? ''),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _msgCtrl,
                    decoration: const InputDecoration(hintText: 'Escribe un mensaje...', border: OutlineInputBorder(), isDense: true),
                    onSubmitted: (_) => _send(),
                  ),
                ),
                IconButton(icon: const Icon(Icons.send), onPressed: _send),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _AssignmentsTab extends StatefulWidget {
  final int id;
  final EmergencyService service;
  final VoidCallback onChanged;
  const _AssignmentsTab({required this.id, required this.service, required this.onChanged});

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
          title: const Text('Nueva asignación'),
          content: SizedBox(
            width: 380,
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
                    institutionId = v;
                    final u = await CrudConfigs.units.service.list(query: {'FK_institution': v, 'pageSize': 200});
                    setDialogState(() => units = u.items);
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Unidad (opcional)', border: OutlineInputBorder()),
                  items: units.map((u) => DropdownMenuItem(value: u['PK_unit'] as int, child: Text('${u['unitCode']} · ${u['unitName']}', overflow: TextOverflow.ellipsis))).toList(),
                  onChanged: (v) => unitId = v,
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
    return Scaffold(
      body: _items.isEmpty
          ? const Center(child: Text('Sin asignaciones'))
          : ListView.separated(
              itemCount: _items.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, i) {
                final a = _items[i];
                return ListTile(
                  leading: const Icon(Icons.local_shipping_outlined),
                  title: Text(a['tbinstitutions']?['name'] ?? ''),
                  subtitle: Text('${a['tbunits']?['unitCode'] ?? 'Sin unidad'} · ${a['status']}'),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.small(onPressed: _newAssignment, child: const Icon(Icons.add)),
    );
  }
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
        title: const Text('Nuevo requerimiento'),
        content: SizedBox(
          width: 340,
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
            child: const Text('Agregar'),
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
    return Scaffold(
      body: _items.isEmpty
          ? const Center(child: Text('Sin requerimientos'))
          : ListView.separated(
              itemCount: _items.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, i) {
                final r = _items[i];
                return ListTile(
                  leading: const Icon(Icons.inventory_2_outlined),
                  title: Text('${r['tbresourcetypes']?['name'] ?? ''} × ${r['quantity']}'),
                  subtitle: Text(r['status'] ?? ''),
                  trailing: TextButton(onPressed: () => _cycleStatus(r), child: const Text('Avanzar')),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.small(onPressed: _newRequirement, child: const Icon(Icons.add)),
    );
  }
}

class _ProgressTab extends StatefulWidget {
  final int id;
  final EmergencyService service;
  const _ProgressTab({required this.id, required this.service});

  @override
  State<_ProgressTab> createState() => _ProgressTabState();
}

class _ProgressTabState extends State<_ProgressTab> {
  List<Map<String, dynamic>> _items = [];
  final _textCtrl = TextEditingController();
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final items = await widget.service.progressReports(widget.id);
      setState(() => _items = items);
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

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    return Column(
      children: [
        Expanded(
          child: _items.isEmpty
              ? const Center(child: Text('Sin avances registrados'))
              : ListView.separated(
                  itemCount: _items.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final p = _items[i];
                    return ListTile(
                      leading: const Icon(Icons.notes),
                      title: Text(p['reportText'] ?? ''),
                      subtitle: Text('${p['tbinstitutions']?['acronym'] ?? ''} · ${p['tbusers']?['firstName'] ?? ''} · ${p['createdAt']}'),
                    );
                  },
                ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _textCtrl,
                    decoration: const InputDecoration(hintText: 'Nuevo avance...', border: OutlineInputBorder(), isDense: true),
                  ),
                ),
                IconButton(icon: const Icon(Icons.send), onPressed: _add),
              ],
            ),
          ),
        ),
      ],
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
      padding: const EdgeInsets.all(12),
      children: [
        _section('Llamadas', _calls, (c) => '${c['callType']} · ${c['status']}', (c) => c['transcription']),
        _section('Evidencias', _evidences, (v) => v['fileType'], (v) => v['fileUrl']),
        _section('Ubicaciones', _locations, (l) => '${l['latitude']}, ${l['longitude']}', (l) => l['address']),
        _section('Destinos', _destinations, (d) => d['destinationName'], (d) => d['tbinstitutions']?['name']),
        _section('Reportes vinculados', _reports, (r) => r['reportChannel'], (r) => '${r['tbcitizens']?['firstName'] ?? 'Anónimo'} · ${r['description'] ?? ''}'),
      ],
    );
  }

  Widget _section(
    String title,
    List<Map<String, dynamic>> items,
    String? Function(Map<String, dynamic>) titleOf,
    String? Function(Map<String, dynamic>) subtitleOf,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        title: Text('$title (${items.length})'),
        children: items.isEmpty
            ? [const Padding(padding: EdgeInsets.all(12), child: Text('Sin registros'))]
            : items
                .map((it) => ListTile(dense: true, title: Text(titleOf(it) ?? ''), subtitle: Text(subtitleOf(it) ?? '')))
                .toList(),
      ),
    );
  }
}
