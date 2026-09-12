import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/theme/index.dart';
import '../../../core/api_client.dart';
import '../../../core/utils/responsive.dart';
import '../../../providers/session_provider.dart';
import '../../../services/catalog_services.dart';

/// Pantalla bespoke (no usa el motor CRUD genérico) porque el endpoint
/// /api/dashboard/users tiene reglas propias que un formulario genérico no
/// puede expresar limpiamente:
///  - Toda escritura exige `adminPassword` (la contraseña del admin logueado).
///  - `password` solo es obligatorio al crear; en edición vacío = no cambia.
///  - Si el privilegio elegido es tipo INSTITUTION, `FK_institution` pasa a
///    ser obligatorio; si es GAMC, se fuerza a null.
///  - DELETE es baja lógica (status=false), no borrado físico.
class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
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
      final result = await CatalogServices.users.list(query: {
        'pageSize': 200,
        if (_searchCtrl.text.trim().isNotEmpty) 'search': _searchCtrl.text.trim(),
      });
      setState(() => _items = result.items);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openForm({Map<String, dynamic>? item}) async {
    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => _UserFormDialog(initial: item),
    );
    if (saved == true) _load();
  }

  Future<void> _deactivate(Map<String, dynamic> item) async {
    final me = context.read<SessionProvider>().user;
    if (me != null && me.id == item['PK_user'].toString()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No puedes dar de baja tu propia cuenta.')),
      );
      return;
    }
    final passwordCtrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Dar de baja usuario'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('¿Dar de baja a "${item['firstName']} ${item['lastName']}"?'),
            const SizedBox(height: 12),
            TextField(
              controller: passwordCtrl,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Tu contraseña de administrador', border: OutlineInputBorder()),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Dar de baja'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await CatalogServices.users.delete(item['PK_user'], body: {'adminPassword': passwordCtrl.text});
      _load();
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Usuarios'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            child: TextField(
              controller: _searchCtrl,
              onSubmitted: (_) => _load(),
              decoration: InputDecoration(
                hintText: 'Buscar por nombre o correo...',
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
                      final u = _items[i];
                      final active = u['status'] == true;
                      return ListTile(
                        title: Text('${u['firstName'] ?? ''} ${u['lastName'] ?? ''}'),
                        subtitle: Text(
                          '${u['tbprivileges']?['privilege'] ?? ''} · ${u['tbinstitutions']?['name'] ?? 'Central GAMC'}\n${u['email'] ?? ''}',
                        ),
                        isThreeLine: true,
                        leading: CircleAvatar(
                          backgroundColor: active ? AppColors.resolvedGreenContainer : AppColors.surfaceTertiary,
                          child: Icon(Icons.person, color: active ? AppColors.resolvedGreenDark : AppColors.textTertiary),
                        ),
                        onTap: () => _openForm(item: u),
                        trailing: active
                            ? IconButton(
                                icon: const Icon(Icons.person_off_outlined, color: AppColors.error),
                                tooltip: 'Dar de baja',
                                onPressed: () => _deactivate(u),
                              )
                            : const Chip(label: Text('Inactivo'), visualDensity: VisualDensity.compact),
                      );
                    },
                  ),
      ),
      floatingActionButton: FloatingActionButton(onPressed: () => _openForm(), child: const Icon(Icons.add)),
    );
  }
}

class _UserFormDialog extends StatefulWidget {
  final Map<String, dynamic>? initial;
  const _UserFormDialog({this.initial});

  @override
  State<_UserFormDialog> createState() => _UserFormDialogState();
}

class _UserFormDialogState extends State<_UserFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _adminPassword = TextEditingController();
  bool _status = true;
  int? _privilegeId;
  int? _institutionId;
  int? _subinstitutionId;

  List<Map<String, dynamic>> _privileges = [];
  List<Map<String, dynamic>> _institutions = [];
  List<Map<String, dynamic>> _subinstitutions = [];
  bool _loadingOptions = true;
  bool _saving = false;
  String? _error;

  bool get _isEdit => widget.initial != null;

  String? get _selectedPrivilegeType {
    final p = _privileges.where((p) => p['PK_privilege'] == _privilegeId);
    return p.isEmpty ? null : p.first['privilegeType']?.toString();
  }

  @override
  void initState() {
    super.initState();
    final i = widget.initial;
    if (i != null) {
      _firstName.text = i['firstName']?.toString() ?? '';
      _lastName.text = i['lastName']?.toString() ?? '';
      _phone.text = i['phoneNumber']?.toString() ?? '';
      _email.text = i['email']?.toString() ?? '';
      _status = i['status'] == true;
      _privilegeId = i['FK_privilege'] as int?;
      _institutionId = i['FK_institution'] as int?;
      _subinstitutionId = i['FK_subinstitution'] as int?;
    }
    _loadOptions();
  }

  Future<void> _loadOptions() async {
    try {
      final privs = await CatalogServices.privileges.list(query: {'pageSize': 200});
      final insts = await CatalogServices.institutions.list(query: {'pageSize': 200});
      final subs = await CatalogServices.subinstitutions.list(query: {'pageSize': 200});
      setState(() {
        _privileges = privs.items;
        _institutions = insts.items;
        _subinstitutions = subs.items;
      });
    } catch (_) {
      // se maneja con listas vacías; el formulario mostrará "sin opciones"
    } finally {
      if (mounted) setState(() => _loadingOptions = false);
    }
  }

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _phone.dispose();
    _email.dispose();
    _password.dispose();
    _adminPassword.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final isInstitutionScoped = _selectedPrivilegeType == 'INSTITUTION';
    if (isInstitutionScoped && _institutionId == null) {
      setState(() => _error = 'Selecciona la institución para este privilegio.');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    final body = <String, dynamic>{
      'FK_privilege': _privilegeId,
      'FK_institution': isInstitutionScoped ? _institutionId : null,
      'FK_subinstitution': isInstitutionScoped ? _subinstitutionId : null,
      'firstName': _firstName.text.trim(),
      'lastName': _lastName.text.trim(),
      'phoneNumber': _phone.text.trim().isEmpty ? null : _phone.text.trim(),
      'email': _email.text.trim(),
      'status': _status,
      'adminPassword': _adminPassword.text,
    };
    if (_password.text.isNotEmpty || !_isEdit) {
      body['password'] = _password.text;
    }

    try {
      if (_isEdit) {
        await CatalogServices.users.update(widget.initial!['PK_user'], body);
      } else {
        await CatalogServices.users.create(body);
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
    final isInstitutionScoped = _selectedPrivilegeType == 'INSTITUTION';
    return AlertDialog(
      title: Text(_isEdit ? 'Editar usuario' : 'Nuevo usuario'),
      content: SizedBox(
        width: dialogContentWidth(context, 420),
        child: _loadingOptions
            ? const SizedBox(height: 120, child: Center(child: CircularProgressIndicator()))
            : Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextFormField(
                        controller: _firstName,
                        decoration: const InputDecoration(labelText: 'Nombres *', border: OutlineInputBorder()),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _lastName,
                        decoration: const InputDecoration(labelText: 'Apellidos *', border: OutlineInputBorder()),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _email,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(labelText: 'Correo *', border: OutlineInputBorder()),
                        validator: (v) => (v == null || !v.contains('@')) ? 'Correo inválido' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _phone,
                        decoration: const InputDecoration(labelText: 'Teléfono', border: OutlineInputBorder()),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<int>(
                        initialValue: _privilegeId,
                        isExpanded: true,
                        decoration: const InputDecoration(labelText: 'Privilegio *', border: OutlineInputBorder()),
                        items: _privileges
                            .map((p) => DropdownMenuItem(
                                  value: p['PK_privilege'] as int,
                                  child: Text('${p['privilege']} (${p['privilegeType']})', overflow: TextOverflow.ellipsis),
                                ))
                            .toList(),
                        onChanged: (v) => setState(() {
                          _privilegeId = v;
                          if (_selectedPrivilegeType == 'GAMC') {
                            _institutionId = null;
                            _subinstitutionId = null;
                          }
                        }),
                        validator: (v) => v == null ? 'Requerido' : null,
                      ),
                      if (isInstitutionScoped) ...[
                        const SizedBox(height: 12),
                        DropdownButtonFormField<int>(
                          initialValue: _institutions.any((i) => i['PK_institution'] == _institutionId) ? _institutionId : null,
                          isExpanded: true,
                          decoration: const InputDecoration(labelText: 'Institución *', border: OutlineInputBorder()),
                          items: _institutions
                              .map((i) => DropdownMenuItem(value: i['PK_institution'] as int, child: Text(i['name']?.toString() ?? '', overflow: TextOverflow.ellipsis)))
                              .toList(),
                          onChanged: (v) => setState(() => _institutionId = v),
                          validator: (v) => v == null ? 'Requerido para privilegios de institución' : null,
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<int>(
                          initialValue: _subinstitutions.any((s) => s['PK_subinstitution'] == _subinstitutionId) ? _subinstitutionId : null,
                          isExpanded: true,
                          decoration: const InputDecoration(labelText: 'Subinstitución (opcional)', border: OutlineInputBorder()),
                          items: _subinstitutions
                              .where((s) => _institutionId == null || s['FK_institution'] == _institutionId)
                              .map((s) => DropdownMenuItem(value: s['PK_subinstitution'] as int, child: Text(s['name']?.toString() ?? '', overflow: TextOverflow.ellipsis)))
                              .toList(),
                          onChanged: (v) => setState(() => _subinstitutionId = v),
                        ),
                      ],
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _password,
                        obscureText: true,
                        decoration: InputDecoration(
                          labelText: _isEdit ? 'Nueva contraseña (dejar en blanco para no cambiar)' : 'Contraseña *',
                          border: const OutlineInputBorder(),
                        ),
                        validator: (v) {
                          if (!_isEdit && (v == null || v.length < 6)) return 'Mínimo 6 caracteres';
                          if (v != null && v.isNotEmpty && v.length < 6) return 'Mínimo 6 caracteres';
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Expanded(child: Text('Usuario activo')),
                          Switch(value: _status, onChanged: (v) => setState(() => _status = v)),
                        ],
                      ),
                      const Divider(),
                      TextFormField(
                        controller: _adminPassword,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: 'Tu contraseña de administrador *',
                          helperText: 'Requerida por el backend para confirmar cambios en usuarios',
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) => (v == null || v.isEmpty) ? 'Requerida' : null,
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: 8),
                        Text(_error!, style: const TextStyle(color: AppColors.error)),
                      ],
                    ],
                  ),
                ),
              ),
      ),
      actions: [
        TextButton(onPressed: _saving ? null : () => Navigator.pop(context, false), child: const Text('Cancelar')),
        FilledButton(
          onPressed: _saving ? null : _submit,
          child: _saving
              ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Guardar'),
        ),
      ],
    );
  }
}
