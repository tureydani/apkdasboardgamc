import '../core/api_client.dart';
import '../core/paged_result.dart';

/// Consume /api/dashboard/dispatch/** — máquina de estados
/// SOLICITADA -> ACEPTADA -> EN_CAMINO -> EN_SITIO -> FINALIZADA
/// (o RECHAZADA / CANCELADA). Ver dispatch-service.ts del backend.
class DispatchService {
  final _client = ApiClient.instance;

  Future<PagedResult> list({List<String>? status, String? emergencyCode}) async {
    final data = await _client.get('/api/dashboard/dispatch', query: {
      'pageSize': 200,
      if (status != null && status.isNotEmpty) 'status': status.join(','),
      if (emergencyCode != null && emergencyCode.isNotEmpty) 'emergencyCode': emergencyCode,
    });
    return PagedResult.fromJson(Map<String, dynamic>.from(data));
  }

  Future<Map<String, dynamic>> getById(int id) async {
    final data = await _client.get('/api/dashboard/dispatch/$id');
    return Map<String, dynamic>.from(data);
  }

  Future<void> accept(int id) => _client.post('/api/dashboard/dispatch/$id/accept');
  Future<void> depart(int id) => _client.post('/api/dashboard/dispatch/$id/depart');
  Future<void> arrive(int id) => _client.post('/api/dashboard/dispatch/$id/arrive');
  Future<void> complete(int id) => _client.post('/api/dashboard/dispatch/$id/complete');
  Future<void> cancel(int id) => _client.post('/api/dashboard/dispatch/$id/cancel');

  Future<Map<String, dynamic>> tracking(int id) async {
    final data = await _client.get('/api/dashboard/dispatch/$id/tracking');
    return Map<String, dynamic>.from(data);
  }

  Future<void> pushTracking(int id, {required double lat, required double lng, double? speed, double? heading}) {
    return _client.post('/api/dashboard/dispatch/$id/tracking', body: {
      'latitude': lat,
      'longitude': lng,
      if (speed != null) 'speed': speed,
      if (heading != null) 'heading': heading,
    });
  }

  Future<List<Map<String, dynamic>>> unitPositions() async {
    final data = await _client.get('/api/dashboard/units/positions');
    return (data['items'] as List).map((e) => Map<String, dynamic>.from(e)).toList();
  }
}
