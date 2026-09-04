import 'package:flutter/material.dart';

import '../../core/api_client.dart';
import 'crud_config.dart';
import 'crud_form_dialog.dart';

/// Pantalla de lista + CRUD reutilizable, alimentada por [CrudConfig].
/// Cubre Instituciones, Tipos de institución, Subinstituciones, Unidades,
/// Tipos de recurso, Tipos de emergencia y Privilegios con un solo widget.
class GenericCrudScreen extends StatefulWidget {
  final CrudConfig config;
  final Map<String, dynamic>? fixedQuery;

  const GenericCrudScreen({super.key, required this.config, this.fixedQuery});

  @override
  State<GenericCrudScreen> createState() => _GenericCrudScreenState();
}

class _GenericCrudScreenState extends State<GenericCrudScreen> {
  final _searchCtrl = TextEditingController();
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;
  String? _error;
  int _total = 0;

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
      final query = <String, dynamic>{
        'pageSize': 200,
        if (_searchCtrl.text.trim().isNotEmpty) 'search': _searchCtrl.text.trim(),
        ...?widget.fixedQuery,
      };
      final result = await widget.config.service.list(query: query);
      setState(() {
        _items = result.items;
        _total = result.total;
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openForm({Map<String, dynamic>? item}) async {
    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => CrudFormDialog(config: widget.config, initial: item),
    );
    if (saved == true) _load();
  }

  Future<void> _confirmDelete(Map<String, dynamic> item) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: Text('¿Eliminar "${widget.config.titleBuilder(item)}"? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      final id = item[widget.config.service.idField];
      await widget.config.service.delete(id);
      _load();
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cfg = widget.config;
    return Scaffold(
      appBar: AppBar(
        title: Text(cfg.title),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            child: TextField(
              controller: _searchCtrl,
              onSubmitted: (_) => _load(),
              decoration: InputDecoration(
                hintText: 'Buscar...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                contentPadding: EdgeInsets.zero,
                isDense: true,
                suffixIcon: IconButton(icon: const Icon(Icons.clear), onPressed: () {
                  _searchCtrl.clear();
                  _load();
                }),
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
                    ? ListView(children: const [SizedBox(height: 80), Center(child: Text('Sin resultados'))])
                    : ListView.separated(
                        itemCount: _items.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, i) {
                          final item = _items[i];
                          return ListTile(
                            title: Text(cfg.titleBuilder(item)),
                            subtitle: cfg.subtitleBuilder != null ? Text(cfg.subtitleBuilder!(item) ?? '') : null,
                            onTap: cfg.canEdit ? () => _openForm(item: item) : null,
                            trailing: cfg.canDelete
                                ? IconButton(
                                    icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                                    onPressed: () => _confirmDelete(item),
                                  )
                                : null,
                          );
                        },
                      ),
      ),
      floatingActionButton: cfg.canCreate
          ? FloatingActionButton(onPressed: () => _openForm(), child: const Icon(Icons.add))
          : null,
      persistentFooterButtons: _total > 0
          ? [Text('$_total registro(s)', style: const TextStyle(fontSize: 12, color: Colors.grey))]
          : null,
    );
  }
}
