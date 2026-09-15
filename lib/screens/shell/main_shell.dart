import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/theme/index.dart';
import '../../core/animations/motion.dart';
import '../../providers/alerts_provider.dart';
import '../../providers/route_view_provider.dart';
import '../../providers/session_provider.dart';
import '../alertas/alertas_screen.dart';
import '../home/home_screen.dart';
import '../mapa/mapa_screen.dart';
import '../mas/mas_screen.dart';
import '../operacion/dispatch_list_screen.dart';
import '../operacion/incoming_assignment_screen.dart';
import '../operacion/operacion_screen.dart';

/// Shell principal con navegación inferior, replicando el árbol de secciones
/// del dashboard web: Inicio, Operación, Mapa, Alertas, Más.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  static const _mapaTabIndex = 2;

  int _index = 0;
  final _alerts = AlertsProvider();
  late final RouteViewProvider _routeView;

  // Evita apilar una segunda `IncomingAssignmentScreen` encima de la
  // primera si el polling detecta otra asignación nueva (u otra ronda del
  // mismo timer) antes de que el operador haya tocado la pantalla de
  // alarma que ya está abierta.
  bool _showingAssignmentAlarm = false;

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
    _alerts.start(
      trackAssignments: user?.role == 'INSTITUTION',
      onNewAssignment: _showAssignmentAlarm,
    );
    // Cualquier pantalla puede pedir "ver ruta" (RouteViewProvider.show);
    // acá se reacciona saltando a la pestaña Mapa, que a su vez salta a su
    // propia subpestaña "Mi ruta" escuchando el mismo provider.
    _routeView = context.read<RouteViewProvider>();
    _routeView.addListener(_onRouteRequested);
  }

  void _showAssignmentAlarm(int count) {
    if (_showingAssignmentAlarm || !mounted) return;
    _showingAssignmentAlarm = true;
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => IncomingAssignmentScreen(count: count), fullscreenDialog: true))
        .then((_) {
      _showingAssignmentAlarm = false;
      _alerts.refreshNow();
    });
  }

  @override
  void dispose() {
    _routeView.removeListener(_onRouteRequested);
    _alerts.dispose();
    super.dispose();
  }

  void _onRouteRequested() {
    if (_routeView.assignmentId != null && _index != _mapaTabIndex) {
      setState(() => _index = _mapaTabIndex);
    }
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
                icon: _dispatchIcon(const Icon(Icons.emergency_outlined), hasPending),
                selectedIcon: _dispatchIcon(const Icon(Icons.emergency), hasPending),
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

  /// Ícono de "Operación" con la insignia de pendientes; si hay al menos
  /// una asignación SOLICITADA, además late suavemente para que el usuario
  /// note que ahí debe tocar (misma idea que la franja roja de arriba).
  Widget _dispatchIcon(Widget icon, bool hasPending) {
    final badged = _badge(icon, hasPending ? _alerts.pendingAssignments : 0);
    if (!hasPending) return badged;
    return badged.pulseGlow(minScale: 1.0, maxScale: 1.15, minOpacity: 0.6, maxOpacity: 1.0, duration: const Duration(milliseconds: 900));
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
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                // Sin cambio de escala (solo opacidad) para no distorsionar
                // una franja de ancho completo — el parpadeo es la señal de
                // "tocá acá", igual que en el ícono de Operación.
                const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 20)
                    .pulseGlow(minScale: 1.0, maxScale: 1.0, minOpacity: 0.5, maxOpacity: 1.0, duration: const Duration(milliseconds: 900)),
                const SizedBox(width: 10),
                // Dos niveles de jerarquía en vez de una sola línea larga:
                // el texto principal (qué pasa) pesa más que la instrucción
                // secundaria (qué hacer), igual que en el resto del rediseño.
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        label,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'Tocar para revisar',
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 11.5),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
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
