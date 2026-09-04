import '../core/api_client.dart';

class DashboardStats {
  final int activeEmergencies;
  final int criticalActive;
  final int reportedToday;
  final int resolvedTotal;
  final int pendingAssignments;
  final int unitsAvailable;
  final int unitsTotal;
  final num avgResponseMinutes;

  DashboardStats({
    required this.activeEmergencies,
    required this.criticalActive,
    required this.reportedToday,
    required this.resolvedTotal,
    required this.pendingAssignments,
    required this.unitsAvailable,
    required this.unitsTotal,
    required this.avgResponseMinutes,
  });

  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    return DashboardStats(
      activeEmergencies: json['activeEmergencies'] ?? 0,
      criticalActive: json['criticalActive'] ?? 0,
      reportedToday: json['reportedToday'] ?? 0,
      resolvedTotal: json['resolvedTotal'] ?? 0,
      pendingAssignments: json['pendingAssignments'] ?? 0,
      unitsAvailable: json['unitsAvailable'] ?? 0,
      unitsTotal: json['unitsTotal'] ?? 0,
      avgResponseMinutes: json['avgResponseMinutes'] ?? 0,
    );
  }
}

/// Consume GET /api/dashboard/stats (mismo endpoint que usa la página
/// principal del dashboard web).
class DashboardService {
  final _client = ApiClient.instance;

  Future<DashboardStats> fetchStats() async {
    await _client.ensureReady();
    final res = await _client.dio.get('/api/dashboard/stats');
    final data = res.data;
    if (data is! Map || data['ok'] != true) {
      throw Exception('No se pudieron cargar las estadísticas.');
    }
    return DashboardStats.fromJson(Map<String, dynamic>.from(data['data']['kpis']));
  }
}
