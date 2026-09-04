import '../core/api_client.dart';
import '../core/paged_result.dart';

/// Consume /api/dashboard/emergencies y todos sus sub-recursos
/// (assignments, calls, destinations, evidences, locations, messages,
/// progress-reports, reports, requirements, room). Ver mapeo de endpoints
/// extraído directamente del código fuente del backend.
class EmergencyService {
  final _client = ApiClient.instance;

  Future<PagedResult> list({
    List<String>? status,
    String? priority,
    int? emergencyType,
    String? search,
    bool? active,
  }) async {
    final data = await _client.get('/api/dashboard/emergencies', query: {
      'pageSize': 100,
      if (status != null && status.isNotEmpty) 'status': status.join(','),
      if (priority != null) 'priority': priority,
      if (emergencyType != null) 'FK_emergencyType': emergencyType,
      if (search != null && search.isNotEmpty) 'search': search,
      if (active == true) 'active': 'true',
    });
    return PagedResult.fromJson(Map<String, dynamic>.from(data));
  }

  Future<Map<String, dynamic>> getById(int id) async {
    final data = await _client.get('/api/dashboard/emergencies/$id');
    return Map<String, dynamic>.from(data);
  }

  Future<Map<String, dynamic>> create(Map<String, dynamic> body) async {
    final data = await _client.post('/api/dashboard/emergencies', body: body);
    return Map<String, dynamic>.from(data);
  }

  Future<Map<String, dynamic>> updateStatus(int id, {required String status, String? statusReason}) async {
    final data = await _client.patch('/api/dashboard/emergencies/$id', body: {
      'status': status,
      if (statusReason != null) 'statusReason': statusReason,
    });
    return Map<String, dynamic>.from(data);
  }

  Future<Map<String, dynamic>> updateClassification(
    int id, {
    int? emergencyType,
    String? priority,
    String? description,
  }) async {
    final data = await _client.patch('/api/dashboard/emergencies/$id', body: {
      if (emergencyType != null) 'FK_emergencyType': emergencyType,
      if (priority != null) 'priority': priority,
      if (description != null) 'description': description,
    });
    return Map<String, dynamic>.from(data);
  }

  Future<List<Map<String, dynamic>>> map() async {
    final data = await _client.get('/api/dashboard/emergencies/map');
    return (data['items'] as List).map((e) => Map<String, dynamic>.from(e)).toList();
  }

  // ---- assignments ----
  Future<List<Map<String, dynamic>>> assignments(int id) async {
    final data = await _client.get('/api/dashboard/emergencies/$id/assignments');
    return (data as List).map((e) => Map<String, dynamic>.from(e)).toList();
  }

  Future<void> createAssignment(int id, {required int institution, int? subinstitution, int? unit}) {
    return _client.post('/api/dashboard/emergencies/$id/assignments', body: {
      'FK_institution': institution,
      if (subinstitution != null) 'FK_subinstitution': subinstitution,
      if (unit != null) 'FK_unit': unit,
    });
  }

  // ---- room / messages ----
  Future<Map<String, dynamic>?> room(int id) async {
    try {
      final data = await _client.get('/api/dashboard/emergencies/$id/room');
      return Map<String, dynamic>.from(data);
    } on ApiException catch (e) {
      if (e.statusCode == 404) return null;
      rethrow;
    }
  }

  Future<void> setRoomOpen(int id, bool isOpen) {
    return _client.patch('/api/dashboard/emergencies/$id/room', body: {'isOpen': isOpen});
  }

  Future<List<Map<String, dynamic>>> messages(int id) async {
    final data = await _client.get('/api/dashboard/emergencies/$id/messages');
    return (data as List).map((e) => Map<String, dynamic>.from(e)).toList();
  }

  Future<void> sendMessage(int id, String message) {
    return _client.post('/api/dashboard/emergencies/$id/messages', body: {'message': message, 'messageType': 'TEXT'});
  }

  // ---- requirements ----
  Future<List<Map<String, dynamic>>> requirements(int id) async {
    final data = await _client.get('/api/dashboard/emergencies/$id/requirements');
    return (data as List).map((e) => Map<String, dynamic>.from(e)).toList();
  }

  Future<void> createRequirement(int id, {required int resourceType, int quantity = 1}) {
    return _client.post('/api/dashboard/emergencies/$id/requirements', body: {
      'FK_resourceType': resourceType,
      'quantity': quantity,
    });
  }

  Future<void> updateRequirementStatus(int id, int requirementId, String status) {
    return _client.patch('/api/dashboard/emergencies/$id/requirements', body: {
      'PK_requirement': requirementId,
      'status': status,
    });
  }

  // ---- progress reports ----
  Future<List<Map<String, dynamic>>> progressReports(int id) async {
    final data = await _client.get('/api/dashboard/emergencies/$id/progress-reports');
    return (data as List).map((e) => Map<String, dynamic>.from(e)).toList();
  }

  Future<void> addProgressReport(int id, String text) {
    return _client.post('/api/dashboard/emergencies/$id/progress-reports', body: {'reportText': text});
  }

  // ---- calls ----
  Future<List<Map<String, dynamic>>> calls(int id) async {
    final data = await _client.get('/api/dashboard/emergencies/$id/calls');
    return (data as List).map((e) => Map<String, dynamic>.from(e)).toList();
  }

  // ---- evidences ----
  Future<List<Map<String, dynamic>>> evidences(int id) async {
    final data = await _client.get('/api/dashboard/emergencies/$id/evidences');
    return (data as List).map((e) => Map<String, dynamic>.from(e)).toList();
  }

  Future<void> addEvidence(int id, {required String fileType, required String fileUrl, String? description}) {
    return _client.post('/api/dashboard/emergencies/$id/evidences', body: {
      'fileType': fileType,
      'fileUrl': fileUrl,
      if (description != null) 'description': description,
    });
  }

  // ---- locations ----
  Future<List<Map<String, dynamic>>> locations(int id) async {
    final data = await _client.get('/api/dashboard/emergencies/$id/locations');
    return (data as List).map((e) => Map<String, dynamic>.from(e)).toList();
  }

  // ---- destinations ----
  Future<List<Map<String, dynamic>>> destinations(int id) async {
    final data = await _client.get('/api/dashboard/emergencies/$id/destinations');
    return (data as List).map((e) => Map<String, dynamic>.from(e)).toList();
  }

  Future<void> addDestination(int id, {required String name, int? institution}) {
    return _client.post('/api/dashboard/emergencies/$id/destinations', body: {
      'destinationName': name,
      if (institution != null) 'FK_institution': institution,
    });
  }

  // ---- reports (reportes ciudadanos vinculados) ----
  Future<List<Map<String, dynamic>>> reports(int id) async {
    final data = await _client.get('/api/dashboard/emergencies/$id/reports');
    return (data as List).map((e) => Map<String, dynamic>.from(e)).toList();
  }
}
