import 'package:flutter/material.dart';

import 'crud_config.dart';
import 'field_spec.dart';

/// Formulario genérico de creación/edición construido a partir de
/// List&lt;FieldSpec&gt;. Devuelve el body listo para enviar a la API (con
/// `adminPassword` incluido si el config lo exige).
class CrudFormDialog extends StatefulWidget {
  final CrudConfig config;
  final Map<String, dynamic>? initial; // null = creación

  const CrudFormDialog({super.key, required this.config, this.initial});

  @override
  State<CrudFormDialog> createState() => _CrudFormDialogState();
}

class _CrudFormDialogState extends State<CrudFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final Map<String, dynamic> _values = {};
  final Map<String, TextEditingController> _controllers = {};
  final Map<String, List<SelectOption>> _remoteOptions = {};
  bool _loadingOptions = true;
  bool _saving = false;
  String? _error;
  final _adminPasswordCtrl = TextEditingController();

  bool get _isEdit => widget.initial != null;

  @override
  void initState() {
    super.initState();
    for (final f in widget.config.fields) {
      final raw = widget.initial?[f.key];
      if (f.type == FieldType.boolean) {
        _values[f.key] = raw ?? true;
      } else if (f.type == FieldType.select || f.type == FieldType.selectRemote) {
        _values[f.key] = raw;
      } else {
        _controllers[f.key] = TextEditingController(text: raw == null ? '' : raw.toString());
      }
    }
    _loadRemoteOptions();
  }

  Future<void> _loadRemoteOptions() async {
    for (final f in widget.config.fields) {
      if (f.type == FieldType.selectRemote && f.remoteService != null) {
        try {
          final page = await f.remoteService!.list(query: {'pageSize': 200});
          _remoteOptions[f.key] = page.items
              .map((e) => SelectOption(e[f.remoteValueField], e[f.remoteLabelField]?.toString() ?? '#${e[f.remoteValueField]}'))
              .toList();
        } catch (_) {
          _remoteOptions[f.key] = [];
        }
      }
    }
    if (mounted) setState(() => _loadingOptions = false);
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    _adminPasswordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });

    final body = <String, dynamic>{};
    for (final f in widget.config.fields) {
      if (_isEdit && !f.editableOnUpdate) continue;
      switch (f.type) {
        case FieldType.boolean:
          body[f.key] = _values[f.key] ?? true;
          break;
        case FieldType.select:
        case FieldType.selectRemote:
          body[f.key] = _values[f.key];
          break;
        case FieldType.number:
          final text = _controllers[f.key]!.text.trim();
          body[f.key] = text.isEmpty ? null : num.tryParse(text);
          break;
        case FieldType.password:
          final text = _controllers[f.key]!.text;
          if (text.isNotEmpty) body[f.key] = text;
          break;
        case FieldType.text:
        case FieldType.multilineText:
          final text = _controllers[f.key]!.text.trim();
          body[f.key] = text.isEmpty ? null : text;
          break;
      }
    }
    if (widget.config.requiresAdminPassword) {
      body['adminPassword'] = _adminPasswordCtrl.text;
    }

    try {
      if (_isEdit) {
        final id = widget.initial![widget.config.service.idField];
        await widget.config.service.update(id, body);
      } else {
        await widget.config.service.create(body);
      }
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_isEdit ? 'Editar ${widget.config.title}' : 'Nuevo/a ${widget.config.title}'),
      content: SizedBox(
        width: 420,
        child: _loadingOptions
            ? const SizedBox(height: 120, child: Center(child: CircularProgressIndicator()))
            : Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (final f in widget.config.fields) ...[
                        _buildField(f),
                        const SizedBox(height: 12),
                      ],
                      if (widget.config.requiresAdminPassword) ...[
                        TextFormField(
                          controller: _adminPasswordCtrl,
                          obscureText: true,
                          decoration: const InputDecoration(
                            labelText: 'Tu contraseña de administrador *',
                            border: OutlineInputBorder(),
                          ),
                          validator: (v) => (v == null || v.isEmpty) ? 'Requerida para confirmar' : null,
                        ),
                        const SizedBox(height: 12),
                      ],
                      if (_error != null)
                        Text(_error!, style: const TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ),
      ),
      actions: [
        TextButton(onPressed: _saving ? null : () => Navigator.of(context).pop(false), child: const Text('Cancelar')),
        FilledButton(
          onPressed: _saving ? null : _submit,
          child: _saving
              ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Guardar'),
        ),
      ],
    );
  }

  Widget _buildField(FieldSpec f) {
    if (_isEdit && !f.editableOnUpdate) {
      final display = widget.initial?[f.key]?.toString() ?? '';
      return TextFormField(
        initialValue: display,
        enabled: false,
        decoration: InputDecoration(labelText: f.label, border: const OutlineInputBorder()),
      );
    }

    switch (f.type) {
      case FieldType.boolean:
        return Row(
          children: [
            Expanded(child: Text(f.label)),
            Switch(
              value: _values[f.key] == true,
              onChanged: (v) => setState(() => _values[f.key] = v),
            ),
          ],
        );
      case FieldType.select:
        return DropdownButtonFormField<dynamic>(
          initialValue: _values[f.key],
          isExpanded: true,
          decoration: InputDecoration(labelText: f.required ? '${f.label} *' : f.label, border: const OutlineInputBorder()),
          items: f.options!
              .map((o) => DropdownMenuItem(value: o.value, child: Text(o.label, overflow: TextOverflow.ellipsis)))
              .toList(),
          onChanged: (v) => setState(() => _values[f.key] = v),
          validator: (v) => (f.required && v == null) ? 'Requerido' : null,
        );
      case FieldType.selectRemote:
        final opts = _remoteOptions[f.key] ?? [];
        return DropdownButtonFormField<dynamic>(
          initialValue: opts.any((o) => o.value == _values[f.key]) ? _values[f.key] : null,
          isExpanded: true,
          decoration: InputDecoration(labelText: f.required ? '${f.label} *' : f.label, border: const OutlineInputBorder()),
          items: opts.map((o) => DropdownMenuItem(value: o.value, child: Text(o.label, overflow: TextOverflow.ellipsis))).toList(),
          onChanged: (v) => setState(() => _values[f.key] = v),
          validator: (v) => (f.required && v == null) ? 'Requerido' : null,
        );
      case FieldType.number:
        return TextFormField(
          controller: _controllers[f.key],
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(labelText: f.required ? '${f.label} *' : f.label, border: const OutlineInputBorder()),
          validator: (v) {
            if (f.required && (v == null || v.trim().isEmpty)) return 'Requerido';
            if (v != null && v.trim().isNotEmpty && num.tryParse(v.trim()) == null) return 'Debe ser numérico';
            return f.validator?.call(v);
          },
        );
      case FieldType.password:
        return TextFormField(
          controller: _controllers[f.key],
          obscureText: true,
          decoration: InputDecoration(
            labelText: (f.required && !_isEdit) ? '${f.label} *' : '${f.label}${_isEdit ? ' (dejar en blanco para no cambiar)' : ''}',
            border: const OutlineInputBorder(),
          ),
          validator: (v) {
            if (!_isEdit && f.required && (v == null || v.isEmpty)) return 'Requerido';
            if (v != null && v.isNotEmpty && v.length < 6) return 'Mínimo 6 caracteres';
            return null;
          },
        );
      case FieldType.multilineText:
        return TextFormField(
          controller: _controllers[f.key],
          maxLines: 3,
          decoration: InputDecoration(labelText: f.required ? '${f.label} *' : f.label, border: const OutlineInputBorder()),
          validator: (v) => (f.required && (v == null || v.trim().isEmpty)) ? 'Requerido' : f.validator?.call(v),
        );
      case FieldType.text:
        return TextFormField(
          controller: _controllers[f.key],
          decoration: InputDecoration(labelText: f.required ? '${f.label} *' : f.label, border: const OutlineInputBorder()),
          validator: (v) => (f.required && (v == null || v.trim().isEmpty)) ? 'Requerido' : f.validator?.call(v),
        );
    }
  }
}
