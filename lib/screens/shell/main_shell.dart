import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/theme/index.dart';
import '../../providers/alerts_provider.dart';
import '../../providers/session_provider.dart';
import '../alertas/alertas_screen.dart';
import '../home/home_screen.dart';
import '../mapa/mapa_screen.dart';
import '../mas/mas_screen.dart';
import '../operacion/dispatch_list_screen.dart';
import '../operacion/operacion_screen.dart';

/// Shell principal con navegación inferior, replicando el árbol de secciones
/// del dashboard web: Inicio, Operación, Mapa, Alertas, Más.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;
  final _alerts = AlertsProvider();

  final _pages = const [
    HomeScreen(),
    OperacionScreen(),
    MapaScreen(),
    AlertasScreen(),
    MasScreen(),
  ];

  @override
  void initState() {
    super.initState();
    final user = context.read<SessionProvider>().user;
    _alerts.start(trackAssignments: user?.role == 'INSTITUTION');
  }

  @override
  void dispose() {
    _alerts.dispose();
    super.dispose();
  }

  void _selectTab(int i) {
    setState(() => _index = i);
    _alerts.refreshNow();
  }

  void _goToPendingDispatch() {
    setState(() => _index = 1);
    Navigator.of(context)
        .push(MaterialPageRoute(
          builder: (_) => const DispatchListScreen(
            title: 'Asignaciones pendientes',
            statusFilter: ['SOLICITADA'],
          ),
        ))
        .then((_) => _alerts.refreshNow());
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _alerts,
      builder: (context, _) {
        final hasPending = _alerts.pendingAssignments > 0;
        return Scaffold(
          body: Column(
            children: [
              if (hasPending) _PendingAssignmentBanner(count: _alerts.pendingAssignments, onTap: _goToPendingDispatch),
              Expanded(child: IndexedStack(index: _index, children: _pages)),
            ],
          ),
          bottomNavigationBar: NavigationBar(
            selectedIndex: _index,
            onDestinationSelected: _selectTab,
            destinations: [
              const NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Inicio'),
              NavigationDestination(
                icon: _badge(const Icon(Icons.emergency_outlined), hasPending ? _alerts.pendingAssignments : 0),
                selectedIcon: _badge(const Icon(Icons.emergency), hasPending ? _alerts.pendingAssignments : 0),
                label: 'Operación',
              ),
              const NavigationDestination(icon: Icon(Icons.map_outlined), selectedIcon: Icon(Icons.map), label: 'Mapa'),
              NavigationDestination(
                icon: _badge(const Icon(Icons.notifications_outlined), _alerts.unreadNotifications),
                selectedIcon: _badge(const Icon(Icons.notifications), _alerts.unreadNotifications),
                label: 'Alertas',
              ),
              const NavigationDestination(icon: Icon(Icons.menu), selectedIcon: Icon(Icons.menu_open), label: 'Más'),
            ],
          ),
        );
      },
    );
  }

  Widget _badge(Widget icon, int count) {
    if (count <= 0) return icon;
    return Badge(
      label: Text(count > 99 ? '99+' : '$count'),
      backgroundColor: AppColors.urgentRed,
      child: icon,
    );
  }
}

/// Franja roja persistente, visible en cualquier pestaña, mientras haya al
/// menos un despacho SOLICITADA para la institución del usuario.
class _PendingAssignmentBanner extends StatelessWidget {
  final int count;
  final VoidCallback onTap;

  const _PendingAssignmentBanner({required this.count, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final label = count == 1 ? '1 asignación pendiente' : '$count asignaciones pendientes';
    return Material(
      color: AppColors.urgentRed,
      child: InkWell(
        onTap: onTap,
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '$label · Tocar para revisar',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Icon(Icons.chevron_right, color: Colors.white, size: 18),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
