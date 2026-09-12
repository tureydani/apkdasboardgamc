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

// Paleta institucional de las tarjetas de estadísticas: fondo pastel bien
// definido + un único color de acento (ícono y número) por tarjeta, para
// que cada estado se reconozca de un vistazo sin saturar la pantalla de
// color. Los estados que requieren acción (críticas, pendientes) usan los
// acentos más fuertes; los informativos (reportadas, resueltas) los más
// suaves.
const _kpiActiveBg = Color(0xFFFFF4E5);
const _kpiActiveAccent = Color(0xFFE67E22);
const _kpiCriticalBg = Color(0xFFFDE8E8);
const _kpiCriticalAccent = Color(0xFFD93025);
const _kpiTodayBg = Color(0xFFE8F4FA);
const _kpiTodayAccent = Color(0xFF1597D3);
const _kpiResolvedBg = Color(0xFFE8F5EE);
const _kpiResolvedAccent = Color(0xFF159A68);
const _kpiPendingBg = Color(0xFFF0E9FA);
const _kpiPendingAccent = Color(0xFF7040B5);
const _kpiUnitsBg = Color(0xFFF5EAF1);
const _kpiUnitsAccent = Color(0xFFB34D87);

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
                              // Sans-serif explícito (no AppTextStyles, que
                              // usa una serif de acento): esta pantalla debe
                              // leerse como un dashboard institucional, no
                              // como una portada editorial.
                              style: const TextStyle(
                                fontSize: 31,
                                fontWeight: FontWeight.w600,
                                height: 1.15,
                                color: AppColors.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              user?.privilegeName ?? '',
                              style: const TextStyle(fontSize: 16, color: AppColors.textSecondary),
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
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
                          elevation: 2,
                          shadowColor: AppColors.primary.withValues(alpha: 0.35),
                          alignment: Alignment.centerLeft,
                        ),
                        icon: const Icon(Icons.map_outlined, size: 28),
                        // Título accionable arriba, código SOS más chico y
                        // secundario debajo: comunica "hay una emergencia
                        // activa y puedo ir hacia ella" de un vistazo.
                        label: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              'Ver ruta a la emergencia',
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              _activeRoute!['tbemergencies']?['emergencyCode'] ?? 'Unidad en camino',
                              style: TextStyle(fontSize: 12, color: AppColors.textOnPrimary.withValues(alpha: 0.8), fontWeight: FontWeight.w400),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 10),
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
                                background: _kpiActiveBg,
                                accent: _kpiActiveAccent,
                                onTap: () => _open(const EmergenciesListScreen(
                                  title: 'Emergencias activas',
                                  statusFilter: _activeStatuses,
                                  allowCreate: true,
                                )),
                              ),
                              _KpiCard(
                                label: 'Emergencias críticas',
                                value: '${stats.criticalActive}',
                                icon: Icons.error_outline,
                                background: _kpiCriticalBg,
                                accent: _kpiCriticalAccent,
                                onTap: () => _open(const EmergenciesListScreen(
                                  title: 'Emergencias críticas',
                                  statusFilter: _activeStatuses,
                                  priorityFilter: 'CRITICA',
                                )),
                              ),
                              _KpiCard(
                                label: 'Reportadas hoy',
                                value: '${stats.reportedToday}',
                                icon: Icons.today_outlined,
                                background: _kpiTodayBg,
                                accent: _kpiTodayAccent,
                                onTap: () => _open(const EmergenciesListScreen(
                                  title: 'Reportadas hoy',
                                  reportedTodayOnly: true,
                                )),
                              ),
                              _KpiCard(
                                label: 'Resueltas',
                                value: '${stats.resolvedTotal}',
                                icon: Icons.check_circle_outline,
                                background: _kpiResolvedBg,
                                accent: _kpiResolvedAccent,
                                onTap: () => _open(const EmergenciesListScreen(
                                  title: 'Emergencias resueltas',
                                  statusFilter: ['RESUELTA'],
                                )),
                              ),
                              _KpiCard(
                                label: 'Asignaciones pendientes',
                                value: '${stats.pendingAssignments}',
                                icon: Icons.assignment_late_outlined,
                                background: _kpiPendingBg,
                                accent: _kpiPendingAccent,
                                onTap: () => _open(const DispatchListScreen(
                                  title: 'Asignaciones pendientes',
                                  statusFilter: ['SOLICITADA'],
                                )),
                              ),
                              _KpiCard(
                                label: 'Unidades disponibles',
                                value: '${stats.unitsAvailable}/${stats.unitsTotal}',
                                icon: Icons.local_shipping_outlined,
                                background: _kpiUnitsBg,
                                accent: _kpiUnitsAccent,
                                onTap: () => _open(const GpsScreen()),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        ConstrainedBox(
                          constraints: const BoxConstraints(minHeight: 56),
                          child: SizedBox(
                            width: double.infinity,
                            child: Card(
                              margin: EdgeInsets.zero,
                              child: ListTile(
                                dense: true,
                                leading: const Icon(Icons.timer_outlined, color: AppColors.textSecondary),
                                title: const Text(
                                  'Tiempo de respuesta promedio',
                                  style: TextStyle(fontSize: 14, color: AppColors.textPrimary),
                                ),
                                trailing: Text(
                                  '${stats.avgResponseMinutes} min',
                                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                                ),
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
  // Fondo pastel bien definido (no el color de acento diluido al vuelo) +
  // un único color de acento fuerte para ícono y número — "fondos suaves +
  // números/íconos fuertes" en vez de tarjetas saturadas de color.
  final Color background;
  final Color accent;
  final VoidCallback onTap;

  const _KpiCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.background,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: background,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
                  child: _KpiCardContent(label: label, value: value, icon: icon, accent: accent),
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
  final Color accent;

  const _KpiCardContent({required this.label, required this.value, required this.icon, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(icon, color: accent, size: 28),
            Icon(Icons.chevron_right, color: accent.withValues(alpha: 0.55), size: 18),
          ],
        ),
        const SizedBox(height: 6),
        // Número: la información prioritaria de la tarjeta — debe
        // reconocerse antes que la etiqueta que lo explica.
        Text(value, style: TextStyle(fontSize: 34, fontWeight: FontWeight.w700, color: accent, height: 1)),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w500, height: 1.2, color: AppColors.textSecondary),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
