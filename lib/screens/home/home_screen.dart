import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/theme/index.dart';
import '../../providers/route_view_provider.dart';
import '../../providers/session_provider.dart';
import '../../services/dashboard_service.dart';
import '../../services/dispatch_service.dart';
import '../../widgets/app_scaffold.dart';
import '../mas/seguimiento/gps_screen.dart';
import '../operacion/dispatch_list_screen.dart';
import '../operacion/emergencies_list_screen.dart';

/// Mismos estados "activos" que usa el backend en /api/dashboard/stats para
/// calcular activeEmergencies/criticalActive, así el filtro del recuadro
/// coincide exactamente con el número mostrado.
const _activeStatuses = ['REPORTADA', 'EN_ANALISIS', 'CLASIFICADA', 'ASIGNADA', 'EN_ATENCION'];

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _service = DashboardService();
  final _dispatchService = DispatchService();
  late Future<DashboardStats> _future;
  Map<String, dynamic>? _activeRoute;

  @override
  void initState() {
    super.initState();
    _future = _service.fetchStats();
    _loadActiveRoute();
  }

  Future<void> _reload() async {
    setState(() {
      _future = _service.fetchStats();
    });
    await _future;
    await _loadActiveRoute();
  }

  /// Asignación EN_CAMINO (si la hay) para mostrar el botón "Ver ruta" —
  /// solo aplica a usuarios institucionales, el backend ya filtra por
  /// institución/sesión igual que el resto de listados de despacho.
  Future<void> _loadActiveRoute() async {
    final user = context.read<SessionProvider>().user;
    if (user?.role != 'INSTITUTION') return;
    try {
      final result = await _dispatchService.list(status: const ['EN_CAMINO']);
      if (!mounted) return;
      setState(() => _activeRoute = result.items.isNotEmpty ? result.items.first : null);
    } catch (_) {
      // Sin conexión: se conserva el último valor conocido.
    }
  }

  void _open(Widget screen) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen)).then((_) => _reload());
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<SessionProvider>().user;

    return AppScaffold(
      body: SafeArea(
        child: FutureBuilder<DashboardStats>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.cloud_off, size: 48, color: AppColors.textDisabled),
                      const SizedBox(height: 12),
                      Text('${snapshot.error}', textAlign: TextAlign.center),
                      const SizedBox(height: 12),
                      FilledButton.icon(onPressed: _reload, icon: const Icon(Icons.refresh), label: const Text('Reintentar')),
                    ],
                  ),
                ),
              );
            }
            final stats = snapshot.data!;
            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user != null ? 'Hola, ${user.fullName}' : 'Hola',
                              style: Theme.of(context).textTheme.titleLarge,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              user?.privilegeName ?? '',
                              style: AppTextStyles.bodyMediumSecondary,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.refresh),
                        tooltip: 'Actualizar',
                        onPressed: _reload,
                        visualDensity: VisualDensity.compact,
                      ),
                    ],
                  ),
                  if (_activeRoute != null) ...[
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () => context.read<RouteViewProvider>().show(_activeRoute!['PK_assignment'] as int),
                        icon: const Icon(Icons.map_outlined),
                        label: Text(
                          'Ver ruta · ${_activeRoute!['tbemergencies']?['emergencyCode'] ?? 'Unidad en camino'}',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Expanded(
                    child: Column(
                      children: [
                        Expanded(
                          child: _KpiGrid(
                            cards: [
                              _KpiCard(
                                label: 'Emergencias activas',
                                value: '${stats.activeEmergencies}',
                                icon: Icons.warning_amber_rounded,
                                color: AppColors.moderateOrange,
                                onTap: () => _open(const EmergenciesListScreen(
                                  title: 'Emergencias activas',
                                  statusFilter: _activeStatuses,
                                  allowCreate: true,
                                )),
                              ),
                              _KpiCard(
                                label: 'Críticas',
                                value: '${stats.criticalActive}',
                                icon: Icons.priority_high,
                                color: AppColors.urgentRed,
                                onTap: () => _open(const EmergenciesListScreen(
                                  title: 'Emergencias críticas',
                                  statusFilter: _activeStatuses,
                                  priorityFilter: 'CRITICA',
                                )),
                              ),
                              _KpiCard(
                                label: 'Reportadas hoy',
                                value: '${stats.reportedToday}',
                                icon: Icons.today,
                                color: AppColors.secondary,
                                onTap: () => _open(const EmergenciesListScreen(
                                  title: 'Reportadas hoy',
                                  reportedTodayOnly: true,
                                )),
                              ),
                              _KpiCard(
                                label: 'Resueltas',
                                value: '${stats.resolvedTotal}',
                                icon: Icons.check_circle_outline,
                                color: AppColors.resolvedGreen,
                                onTap: () => _open(const EmergenciesListScreen(
                                  title: 'Emergencias resueltas',
                                  statusFilter: ['RESUELTA'],
                                )),
                              ),
                              _KpiCard(
                                label: 'Asignaciones pendientes',
                                value: '${stats.pendingAssignments}',
                                icon: Icons.pending_actions,
                                color: AppColors.accent,
                                onTap: () => _open(const DispatchListScreen(
                                  title: 'Asignaciones pendientes',
                                  statusFilter: ['SOLICITADA'],
                                )),
                              ),
                              _KpiCard(
                                label: 'Unidades disponibles',
                                value: '${stats.unitsAvailable}/${stats.unitsTotal}',
                                icon: Icons.local_shipping_outlined,
                                color: AppColors.accentSoft,
                                onTap: () => _open(const GpsScreen()),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        ConstrainedBox(
                          constraints: const BoxConstraints(minHeight: 56),
                          child: SizedBox(
                            width: double.infinity,
                            child: Card(
                              margin: EdgeInsets.zero,
                              child: ListTile(
                                dense: true,
                                leading: const Icon(Icons.timer_outlined),
                                title: const Text('Tiempo de respuesta promedio'),
                                trailing: Text('${stats.avgResponseMinutes} min'),
                                onTap: () => _open(const EmergenciesListScreen(
                                  title: 'Emergencias resueltas',
                                  statusFilter: ['RESUELTA'],
                                )),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Cuadrícula que reparte el alto disponible entre las filas sin dejar que
/// el contenido se desborde ni active scroll: cada celda mide exactamente
/// lo que le corresponde del espacio real de la pantalla. El número de
/// columnas se deriva del ancho disponible (2 en un teléfono, 3+ en una
/// pantalla ancha/tablet) en vez de quedar fijo.
class _KpiGrid extends StatelessWidget {
  final List<_KpiCard> cards;
  static const _spacing = 12.0;
  // Alto mínimo que necesita una tarjeta para mostrar ícono + valor + etiqueta
  // de 2 líneas sin recortarse (con margen para texto de sistema ampliado).
  static const _minCellHeight = 96.0;
  // Ancho mínimo cómodo por tarjeta antes de sumar una columna más.
  static const _minCellWidth = 160.0;

  const _KpiGrid({required this.cards});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxColumns = ((constraints.maxWidth + _spacing) / (_minCellWidth + _spacing)).floor();
        final crossAxisCount = maxColumns.clamp(2, cards.length);
        final rows = (cards.length / crossAxisCount).ceil();
        final cellWidth = (constraints.maxWidth - _spacing * (crossAxisCount - 1)) / crossAxisCount;
        final evenCellHeight = (constraints.maxHeight - _spacing * (rows - 1)) / rows;
        final cellHeight = evenCellHeight < _minCellHeight ? _minCellHeight : evenCellHeight;

        final grid = Column(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(rows, (row) {
            return Padding(
              padding: EdgeInsets.only(bottom: row == rows - 1 ? 0 : _spacing),
              child: SizedBox(
                height: cellHeight,
                child: Row(
                  children: List.generate(crossAxisCount, (col) {
                    final index = row * crossAxisCount + col;
                    final child = index < cards.length
                        ? SizedBox(width: cellWidth, child: cards[index])
                        : SizedBox(width: cellWidth);
                    return Padding(
                      padding: EdgeInsets.only(right: col == crossAxisCount - 1 ? 0 : _spacing),
                      child: child,
                    );
                  }),
                ),
              ),
            );
          }),
        );

        // Caso normal: la cuadrícula entra exacta en el espacio disponible,
        // sin scroll. Si la pantalla es demasiado baja (texto de accesibilidad
        // grande, ventana chica) para respetar el alto mínimo, se cede a un
        // scroll de respaldo antes que desbordar el layout.
        final totalHeight = cellHeight * rows + _spacing * (rows - 1);
        if (totalHeight <= constraints.maxHeight + 0.5) return grid;
        return SingleChildScrollView(child: grid);
      },
    );
  }
}

class _KpiCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _KpiCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: color.withValues(alpha: 0.08),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          // FittedBox mide el contenido a un ancho fijo (para que el texto
          // siga ajustando línea normalmente) y lo encoge como bloque si no
          // entra en el alto real disponible, en vez de desbordar.
          child: LayoutBuilder(
            builder: (context, constraints) {
              return FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: SizedBox(
                  width: constraints.maxWidth,
                  child: _KpiCardContent(label: label, value: value, icon: icon, color: color),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _KpiCardContent extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _KpiCardContent({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(icon, color: color, size: 20),
            Icon(Icons.chevron_right, color: color.withValues(alpha: 0.6), size: 18),
          ],
        ),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(fontSize: 11, height: 1.15),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
