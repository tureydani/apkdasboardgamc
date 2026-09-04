import '../core/crud_service.dart';
import '../services/catalog_services.dart';
import '../widgets/crud/crud_config.dart';
import '../widgets/crud/field_spec.dart';

/// Configuraciones declarativas de cada CRUD genérico. Los nombres de
/// campo son EXACTAMENTE los que exigen los schemas zod del backend
/// (src/lib/api/schemas.ts y catalogs.ts), documentados por el mapeo de
/// endpoints realizado sobre el código fuente real.
class CrudConfigs {
  CrudConfigs._();

  /// Forma común a institution-types, resource-types y emergency-types:
  /// { name, code, description?, status? }.
  static CrudConfig _simpleCatalog(String title, CrudService service) => CrudConfig(
        title: title,
        service: service,
        titleBuilder: (i) => i['name']?.toString() ?? '',
        subtitleBuilder: (i) => i['code']?.toString(),
        fields: const [
          FieldSpec(key: 'name', label: 'Nombre', required: true, showInList: true),
          FieldSpec(key: 'code', label: 'Código', required: true, showInList: true),
          FieldSpec(key: 'description', label: 'Descripción', type: FieldType.multilineText),
          FieldSpec(key: 'status', label: 'Activo', type: FieldType.boolean),
        ],
      );

  static final institutionTypes = _simpleCatalog('Tipo de institución', CatalogServices.institutionTypes);
  static final resourceTypes = _simpleCatalog('Tipo de recurso', CatalogServices.resourceTypes);
  static final emergencyTypes = _simpleCatalog('Tipo de emergencia', CatalogServices.emergencyTypes);

  static final institutions = CrudConfig(
    title: 'Institución',
    service: CatalogServices.institutions,
    titleBuilder: (i) => i['name']?.toString() ?? '',
    subtitleBuilder: (i) => i['acronym']?.toString() ?? i['tbinstitutiontypes']?['name']?.toString(),
    fields: [
      FieldSpec(
        key: 'FK_institutionType',
        label: 'Tipo de institución',
        type: FieldType.selectRemote,
        required: true,
        remoteService: CatalogServices.institutionTypes,
        remoteLabelField: 'name',
        remoteValueField: 'PK_institutionType',
      ),
      const FieldSpec(key: 'name', label: 'Nombre', required: true, showInList: true),
      const FieldSpec(key: 'acronym', label: 'Sigla'),
      const FieldSpec(key: 'phoneNumber', label: 'Teléfono'),
      const FieldSpec(key: 'email', label: 'Correo'),
      const FieldSpec(key: 'address', label: 'Dirección', type: FieldType.multilineText),
      const FieldSpec(key: 'latitude', label: 'Latitud', type: FieldType.number),
      const FieldSpec(key: 'longitude', label: 'Longitud', type: FieldType.number),
      const FieldSpec(key: 'status', label: 'Activo', type: FieldType.boolean),
    ],
  );

  static final subinstitutions = CrudConfig(
    title: 'Subinstitución',
    service: CatalogServices.subinstitutions,
    titleBuilder: (i) => i['name']?.toString() ?? '',
    subtitleBuilder: (i) => i['tbinstitutions']?['name']?.toString() ?? i['code']?.toString(),
    fields: [
      FieldSpec(
        key: 'FK_institution',
        label: 'Institución',
        type: FieldType.selectRemote,
        required: true,
        remoteService: CatalogServices.institutions,
        remoteLabelField: 'name',
        remoteValueField: 'PK_institution',
      ),
      const FieldSpec(key: 'name', label: 'Nombre', required: true, showInList: true),
      const FieldSpec(key: 'code', label: 'Código'),
      const FieldSpec(key: 'phoneNumber', label: 'Teléfono'),
      const FieldSpec(key: 'email', label: 'Correo'),
      const FieldSpec(key: 'address', label: 'Dirección', type: FieldType.multilineText),
      const FieldSpec(key: 'latitude', label: 'Latitud', type: FieldType.number),
      const FieldSpec(key: 'longitude', label: 'Longitud', type: FieldType.number),
      const FieldSpec(key: 'status', label: 'Activo', type: FieldType.boolean),
    ],
  );

  static final units = CrudConfig(
    title: 'Unidad',
    service: CatalogServices.units,
    titleBuilder: (i) => '${i['unitCode'] ?? ''} · ${i['unitName'] ?? ''}',
    subtitleBuilder: (i) => '${i['tbinstitutions']?['acronym'] ?? i['tbinstitutions']?['name'] ?? ''} · ${i['status'] ?? ''}',
    fields: [
      FieldSpec(
        key: 'FK_institution',
        label: 'Institución',
        type: FieldType.selectRemote,
        required: true,
        remoteService: CatalogServices.institutions,
        remoteLabelField: 'name',
        remoteValueField: 'PK_institution',
      ),
      FieldSpec(
        key: 'FK_subinstitution',
        label: 'Subinstitución',
        type: FieldType.selectRemote,
        remoteService: CatalogServices.subinstitutions,
        remoteLabelField: 'name',
        remoteValueField: 'PK_subinstitution',
      ),
      FieldSpec(
        key: 'FK_resourceType',
        label: 'Tipo de recurso',
        type: FieldType.selectRemote,
        required: true,
        remoteService: CatalogServices.resourceTypes,
        remoteLabelField: 'name',
        remoteValueField: 'PK_resourceType',
      ),
      const FieldSpec(key: 'unitCode', label: 'Código de unidad', required: true, showInList: true),
      const FieldSpec(key: 'unitName', label: 'Nombre de unidad', required: true, showInList: true),
      const FieldSpec(key: 'phoneNumber', label: 'Teléfono'),
      const FieldSpec(
        key: 'status',
        label: 'Estado',
        type: FieldType.select,
        options: [
          SelectOption('DISPONIBLE', 'Disponible'),
          SelectOption('EN_CAMINO', 'En camino'),
          SelectOption('EN_SITIO', 'En sitio'),
          SelectOption('OCUPADA', 'Ocupada'),
          SelectOption('FUERA_DE_SERVICIO', 'Fuera de servicio'),
        ],
      ),
      const FieldSpec(key: 'isAvailable', label: 'Disponible', type: FieldType.boolean),
      const FieldSpec(key: 'isActive', label: 'Activa', type: FieldType.boolean),
    ],
  );

  static final privileges = CrudConfig(
    title: 'Privilegio',
    service: CatalogServices.privileges,
    requiresAdminPassword: true,
    titleBuilder: (i) => i['privilege']?.toString() ?? '',
    subtitleBuilder: (i) => i['privilegeCode']?.toString(),
    fields: const [
      FieldSpec(key: 'privilege', label: 'Nombre visible', required: true, showInList: true),
      FieldSpec(key: 'privilegeCode', label: 'Código (MAYÚSCULAS_GUION_BAJO)', required: true, showInList: true),
      FieldSpec(
        key: 'privilegeType',
        label: 'Alcance',
        type: FieldType.select,
        required: true,
        options: [
          SelectOption('GAMC', 'GAMC (central)'),
          SelectOption('INSTITUTION', 'Institución'),
        ],
      ),
      FieldSpec(key: 'description', label: 'Descripción', type: FieldType.multilineText),
    ],
  );
}
