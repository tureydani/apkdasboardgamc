import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/session_provider.dart';
import '../../services/dashboard_service.dart';
import '../../widgets/app_scaffold.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _service = DashboardService();
  late Future<DashboardStats> _future;

  @override
  void initState() {
    super.initState();
    _future = _service.fetchStats();
  }

  Future<void> _reload() async {
    setState(() => _future = _service.fetchStats());
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<SessionProvider>().user;

    return AppScaffold(
      title: 'Inicio',
      body: RefreshIndicator(
        onRefresh: _reload,
        child: FutureBuilder<DashboardStats>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return ListView(
                children: [
                  const SizedBox(height: 80),
                  Icon(Icons.cloud_off, size: 48, color: Colors.grey.shade400),
                  const SizedBox(height: 12),
                  Center(child: Text('${snapshot.error}')),
                ],
              );
            }
            final stats = snapshot.data!;
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  user != null ? 'Hola, ${user.fullName}' : 'Hola',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                Text(
                  user?.privilegeName ?? '',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
                const SizedBox(height: 20),
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.5,
                  children: [
                    _KpiCard(
                      label: 'Emergencias activas',
                      value: '${stats.activeEmergencies}',
                      icon: Icons.warning_amber_rounded,
                      color: Colors.orange,
                    ),
                    _KpiCard(
                      label: 'Críticas',
                      value: '${stats.criticalActive}',
                      icon: Icons.priority_high,
                      color: Colors.red,
                    ),
                    _KpiCard(
                      label: 'Reportadas hoy',
                      value: '${stats.reportedToday}',
                      icon: Icons.today,
                      color: Colors.blue,
                    ),
                    _KpiCard(
                      label: 'Resueltas',
                      value: '${stats.resolvedTotal}',
                      icon: Icons.check_circle_outline,
                      color: Colors.green,
                    ),
                    _KpiCard(
                      label: 'Asignaciones pendientes',
                      value: '${stats.pendingAssignments}',
                      icon: Icons.pending_actions,
                      color: Colors.purple,
                    ),
                    _KpiCard(
                      label: 'Unidades disponibles',
                      value: '${stats.unitsAvailable}/${stats.unitsTotal}',
                      icon: Icons.local_shipping_outlined,
                      color: Colors.teal,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.timer_outlined),
                    title: const Text('Tiempo de respuesta promedio'),
                    trailing: Text('${stats.avgResponseMinutes} min'),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _KpiCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _KpiCard({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: color.withValues(alpha: 0.08),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color),
            const Spacer(),
            Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
            Text(label, style: const TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
