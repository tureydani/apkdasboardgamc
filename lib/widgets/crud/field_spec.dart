import '../../core/crud_service.dart';

enum FieldType { text, multilineText, number, boolean, select, selectRemote, password }

class SelectOption {
  final dynamic value;
  final String label;
  const SelectOption(this.value, this.label);
}

/// Describe un campo tanto para la columna de lista como para el formulario
/// de creación/edición, replicando los schemas zod del backend
/// (src/lib/api/schemas.ts y catalogs.ts) campo por campo.
class FieldSpec {
  final String key;
  final String label;
  final FieldType type;
  final bool required;
  final bool showInList;
  final bool editableOnUpdate;
  final List<SelectOption>? options; // FieldType.select
  final CrudService? remoteService; // FieldType.selectRemote
  final String remoteLabelField;
  final String remoteValueField;
  final String? Function(Map<String, dynamic> item)? listFormatter;
  final String? Function(dynamic value)? validator;

  const FieldSpec({
    required this.key,
    required this.label,
    this.type = FieldType.text,
    this.required = false,
    this.showInList = false,
    this.editableOnUpdate = true,
    this.options,
    this.remoteService,
    this.remoteLabelField = 'name',
    this.remoteValueField = 'PK_id',
    this.listFormatter,
    this.validator,
  });
}
