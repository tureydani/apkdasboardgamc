import '../core/api_client.dart';

/// GET/PATCH /api/dashboard/notifications/me
class NotificationService {
  final _client = ApiClient.instance;

  Future<Map<String, dynamic>> fetchMine() async {
    final data = await _client.get('/api/dashboard/notifications/me');
    return Map<String, dynamic>.from(data);
  }

  Future<void> markAllRead() {
    return _client.patch('/api/dashboard/notifications/me', body: {'all': true});
  }

  Future<void> markRead(int id) {
    return _client.patch('/api/dashboard/notifications/me', body: {'PK_notification': id});
  }
}
