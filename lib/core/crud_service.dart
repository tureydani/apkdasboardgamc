import 'api_client.dart';
import 'paged_result.dart';

/// Cliente REST genérico para los recursos que en el backend usan
/// crud-factory (institution-types, resource-types, emergency-types,
/// institutions, subinstitutions, units, privileges, users, ...).
///
/// Todas siguen el mismo contrato:
///   GET    {basePath}                -> lista paginada
///   POST   {basePath}                -> crear
///   GET    {basePath}/{id}           -> obtener uno
///   PUT    {basePath}/{id}           -> actualizar
///   DELETE {basePath}/{id}           -> eliminar
class CrudService {
  final String basePath;
  final String idField;

  CrudService(this.basePath, {this.idField = 'PK_id'});

  final _client = ApiClient.instance;

  Future<PagedResult> list({Map<String, dynamic>? query}) async {
    final data = await _client.get(basePath, query: query);
    return PagedResult.fromJson(Map<String, dynamic>.from(data));
  }

  Future<Map<String, dynamic>> getById(dynamic id) async {
    final data = await _client.get('$basePath/$id');
    return Map<String, dynamic>.from(data);
  }

  Future<Map<String, dynamic>> create(Map<String, dynamic> body) async {
    final data = await _client.post(basePath, body: body);
    return Map<String, dynamic>.from(data);
  }

  Future<Map<String, dynamic>> update(dynamic id, Map<String, dynamic> body) async {
    final data = await _client.put('$basePath/$id', body: body);
    return Map<String, dynamic>.from(data);
  }

  Future<void> delete(dynamic id, {Map<String, dynamic>? body}) async {
    await _client.delete('$basePath/$id', body: body);
  }
}
