import '../core/crud_service.dart';

/// Instancias únicas de CrudService por recurso — mismos basePath e
/// idField que usa el backend (ver `crud-factory` + `catalogs.ts`).
class CatalogServices {
  CatalogServices._();

  static final institutionTypes = CrudService('/api/dashboard/institution-types', idField: 'PK_institutionType');
  static final resourceTypes = CrudService('/api/dashboard/resource-types', idField: 'PK_resourceType');
  static final emergencyTypes = CrudService('/api/dashboard/emergency-types', idField: 'PK_emergencyType');
  static final institutions = CrudService('/api/dashboard/institutions', idField: 'PK_institution');
  static final subinstitutions = CrudService('/api/dashboard/subinstitutions', idField: 'PK_subinstitution');
  static final units = CrudService('/api/dashboard/units', idField: 'PK_unit');
  static final privileges = CrudService('/api/dashboard/privileges', idField: 'PK_privilege');
  static final users = CrudService('/api/dashboard/users', idField: 'PK_user');
}
