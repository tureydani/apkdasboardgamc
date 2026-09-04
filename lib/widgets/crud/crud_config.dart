import '../../core/crud_service.dart';
import 'field_spec.dart';

/// Configuración declarativa de un CRUD, análoga a la que usa el backend
/// en catalogs.ts (crud-factory). Con esto un solo widget genérico puede
/// renderizar Instituciones, Tipos de institución, Subinstituciones,
/// Unidades, Tipos de recurso, Tipos de emergencia y Privilegios.
class CrudConfig {
  final String title;
  final CrudService service;
  final List<FieldSpec> fields;
  final String Function(Map<String, dynamic> item) titleBuilder;
  final String? Function(Map<String, dynamic> item)? subtitleBuilder;
  final bool canCreate;
  final bool canEdit;
  final bool canDelete;

  /// Si es true, el formulario pide la contraseña del administrador y la
  /// envía como `adminPassword` (usuarios y privilegios lo exigen en el
  /// backend real).
  final bool requiresAdminPassword;

  const CrudConfig({
    required this.title,
    required this.service,
    required this.fields,
    required this.titleBuilder,
    this.subtitleBuilder,
    this.canCreate = true,
    this.canEdit = true,
    this.canDelete = true,
    this.requiresAdminPassword = false,
  });
}
