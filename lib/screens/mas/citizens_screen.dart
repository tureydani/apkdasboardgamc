import 'package:flutter/material.dart';

import '../../core/api_client.dart';

/// GET/PATCH /api/dashboard/citizens — sin POST/DELETE: los ciudadanos se
/// registran desde la PWA. Aquí solo se listan y se activan/desactivan.
class CitizensScreen extends StatefulWidget {
  const CitizensScreen({super.key});

  @override
  State<CitizensScreen> createState() => _CitizensScreenState();
}

class _CitizensScreenState extends State<CitizensScreen> {
  final _client = ApiClient.instance;
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
      final data = await _client.get('/api/dashboard/citizens', query: {
        'pageSize': 200,
        if (_searchCtrl.text.trim().isNotEmpty) 'search': _searchCtrl.text.trim(),
      });
      setState(() => _items = (data['items'] as List).map((e) => Map<String, dynamic>.from(e)).toList());
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _toggleStatus(Map<String, dynamic> item) async {
    final newStatus = !(item['status'] == true);
    try {
      await _client.patch('/api/dashboard/citizens', body: {
        'PK_citizen': item['PK_citizen'],
        'status': newStatus,
      });
      _load();
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ciudadanos'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            child: TextField(
              controller: _searchCtrl,
              onSubmitted: (_) => _load(),
              decoration: InputDecoration(
                hintText: 'Buscar por nombre, teléfono o CI...',
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
                ? Center(child: Text(_error!))
                : ListView.separated(
                    itemCount: _items.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, i) {
                      final c = _items[i];
                      final active = c['status'] == true;
                      final emergencies = c['_count']?['tbemergencies'] ?? 0;
                      return ListTile(
                        title: Text('${c['firstName'] ?? ''} ${c['lastName'] ?? ''}'),
                        subtitle: Text('${c['phoneNumber'] ?? ''} · CI ${c['CI'] ?? '-'} · $emergencies emergencia(s)'),
                        trailing: Switch(
                          value: active,
                          onChanged: (_) => _toggleStatus(c),
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}
