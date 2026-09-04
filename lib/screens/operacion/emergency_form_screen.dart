import 'package:flutter/material.dart';

import '../../config/crud_configs.dart';
import '../../services/emergency_service.dart';

/// Replica el diálogo "Registrar emergencia" de emergencies/page.tsx del
/// dashboard web: description, latitude/longitude (con default sobre
/// Cochabamba), FK_emergencyType y priority opcionales.
class EmergencyFormScreen extends StatefulWidget {
  const EmergencyFormScreen({super.key});

  @override
  State<EmergencyFormScreen> createState() => _EmergencyFormScreenState();
}

class _EmergencyFormScreenState extends State<EmergencyFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _description = TextEditingController();
  final _address = TextEditingController();
  final _lat = TextEditingController(text: '-17.3895');
  final _lng = TextEditingController(text: '-66.1568');
  final _affectedPersons = TextEditingController();
  String _priority = 'MEDIA';
  int? _emergencyTypeId;
  List<Map<String, dynamic>> _types = [];
  bool _loadingTypes = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadTypes();
  }

  Future<void> _loadTypes() async {
    try {
      final page = await CrudConfigs.emergencyTypes.service.list(query: {'pageSize': 200});
      setState(() => _types = page.items);
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loadingTypes = false);
    }
  }

  @override
  void dispose() {
    _description.dispose();
    _address.dispose();
    _lat.dispose();
    _lng.dispose();
    _affectedPersons.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await EmergencyService().create({
        'description': _description.text.trim().isEmpty ? null : _description.text.trim(),
        'FK_emergencyType': _emergencyTypeId,
        'priority': _priority,
        'latitude': double.parse(_lat.text.trim()),
        'longitude': double.parse(_lng.text.trim()),
        'address': _address.text.trim().isEmpty ? null : _address.text.trim(),
        'affectedPersons': _affectedPersons.text.trim().isEmpty ? null : int.tryParse(_affectedPersons.text.trim()),
      });
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Registrar emergencia')),
      body: _loadingTypes
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  TextFormField(
                    controller: _description,
                    maxLines: 3,
                    decoration: const InputDecoration(labelText: 'Descripción', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<int>(
                    initialValue: _emergencyTypeId,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Tipo de emergencia', border: OutlineInputBorder()),
                    items: _types
                        .map((t) => DropdownMenuItem(value: t['PK_emergencyType'] as int, child: Text(t['name']?.toString() ?? '', overflow: TextOverflow.ellipsis)))
                        .toList(),
                    onChanged: (v) => setState(() => _emergencyTypeId = v),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: _priority,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Prioridad', border: OutlineInputBorder()),
                    items: const [
                      DropdownMenuItem(value: 'BAJA', child: Text('Baja')),
                      DropdownMenuItem(value: 'MEDIA', child: Text('Media')),
                      DropdownMenuItem(value: 'ALTA', child: Text('Alta')),
                      DropdownMenuItem(value: 'CRITICA', child: Text('Crítica')),
                    ],
                    onChanged: (v) => setState(() => _priority = v!),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _lat,
                          keyboardType: const TextInputType.numberWithOptions(signed: true, decimal: true),
                          decoration: const InputDecoration(labelText: 'Latitud *', border: OutlineInputBorder()),
                          validator: (v) => (v == null || double.tryParse(v) == null) ? 'Inválida' : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _lng,
                          keyboardType: const TextInputType.numberWithOptions(signed: true, decimal: true),
                          decoration: const InputDecoration(labelText: 'Longitud *', border: OutlineInputBorder()),
                          validator: (v) => (v == null || double.tryParse(v) == null) ? 'Inválida' : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _address,
                    decoration: const InputDecoration(labelText: 'Dirección', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _affectedPersons,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Personas afectadas', border: OutlineInputBorder()),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(_error!, style: const TextStyle(color: Colors.red)),
                  ],
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: _saving ? null : _submit,
                    child: _saving
                        ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text('Registrar emergencia'),
                  ),
                ],
              ),
            ),
    );
  }
}
