import 'package:flutter_test/flutter_test.dart';
import 'package:sosapk/services/dashboard_service.dart';

void main() {
  group('DashboardStats.fromJson', () {
    test('parsea todos los KPIs devueltos por /api/dashboard/stats', () {
      final stats = DashboardStats.fromJson({
        'activeEmergencies': 5,
        'criticalActive': 2,
        'reportedToday': 3,
        'resolvedTotal': 40,
        'pendingAssignments': 1,
        'unitsAvailable': 4,
        'unitsTotal': 6,
        'avgResponseMinutes': 12,
      });

      expect(stats.activeEmergencies, 5);
      expect(stats.criticalActive, 2);
      expect(stats.reportedToday, 3);
      expect(stats.resolvedTotal, 40);
      expect(stats.pendingAssignments, 1);
      expect(stats.unitsAvailable, 4);
      expect(stats.unitsTotal, 6);
      expect(stats.avgResponseMinutes, 12);
    });

    test('usa 0 por defecto cuando faltan campos (ej. sin casos resueltos aún)', () {
      final stats = DashboardStats.fromJson({});

      expect(stats.activeEmergencies, 0);
      expect(stats.criticalActive, 0);
      expect(stats.reportedToday, 0);
      expect(stats.resolvedTotal, 0);
      expect(stats.pendingAssignments, 0);
      expect(stats.unitsAvailable, 0);
      expect(stats.unitsTotal, 0);
      expect(stats.avgResponseMinutes, 0);
    });

    test('avgResponseMinutes puede venir null desde el backend (sin casos resueltos)', () {
      final stats = DashboardStats.fromJson({'avgResponseMinutes': null});
      expect(stats.avgResponseMinutes, 0);
    });
  });
}
