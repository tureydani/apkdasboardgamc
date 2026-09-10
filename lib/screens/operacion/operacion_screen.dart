import 'package:flutter/material.dart';

import '../../app/theme/index.dart';
import 'dispatch_list_screen.dart';
import 'emergencies_list_screen.dart';

class OperacionScreen extends StatelessWidget {
  const OperacionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final items = [
      _MenuItem(
        'Emergencias',
        'Todas las emergencias activas',
        Icons.emergency,
        AppColors.urgentRed,
        () => const EmergenciesListScreen(title: 'Emergencias', allowCreate: true),
      ),
      _MenuItem(
        'Incidentes',
        'Recién reportadas, en análisis/clasificación',
        Icons.report_gmailerrorred,
        AppColors.moderateOrange,
        () => const EmergenciesListScreen(
          title: 'Incidentes',
          statusFilter: ['REPORTADA', 'EN_ANALISIS', 'CLASIFICADA'],
        ),
      ),
      _MenuItem(
        'Despacho',
        'Aceptar, salir, llegar y completar asignaciones',
        Icons.local_shipping_outlined,
        AppColors.accent,
        () => const DispatchListScreen(
          title: 'Despacho',
          statusFilter: ['SOLICITADA', 'ACEPTADA', 'EN_CAMINO', 'EN_SITIO'],
        ),
      ),
      _MenuItem(
        'Asignación de unidades',
        'Emergencias clasificadas listas para asignar',
        Icons.assignment_ind_outlined,
        AppColors.secondary,
        () => const EmergenciesListScreen(
          title: 'Asignación de unidades',
          statusFilter: ['CLASIFICADA', 'ASIGNADA'],
        ),
      ),
      _MenuItem(
        'Historial',
        'Resueltas, falsas alarmas y canceladas',
        Icons.history,
        AppColors.textTertiary,
        () => const EmergenciesListScreen(
          title: 'Historial de emergencias',
          statusFilter: ['RESUELTA', 'FALSA_ALARMA', 'CANCELADA'],
        ),
      ),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Operación')),
      body: ListView.separated(
        padding: const EdgeInsets.all(12),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, i) {
          final item = items[i];
          return Card(
            child: ListTile(
              leading: CircleAvatar(backgroundColor: item.color.withValues(alpha: 0.15), child: Icon(item.icon, color: item.color)),
              title: Text(item.title, style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text(item.subtitle),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => item.builder())),
            ),
          );
        },
      ),
    );
  }
}

class _MenuItem {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final Widget Function() builder;
  _MenuItem(this.title, this.subtitle, this.icon, this.color, this.builder);
}
