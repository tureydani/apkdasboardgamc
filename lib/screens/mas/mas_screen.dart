import 'package:flutter/material.dart';

import 'package:provider/provider.dart';

import '../../app/theme/index.dart';
import '../../config/crud_configs.dart';
import '../../providers/session_provider.dart';
import '../../providers/theme_provider.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/crud/generic_crud_screen.dart';
import 'administracion/users_screen.dart';
import 'catalogos/estados_screen.dart';
import 'citizens_screen.dart';
import 'perfil_screen.dart';
import 'seguimiento/gps_screen.dart';
import 'seguimiento/tracking_historial_screen.dart';

class MasScreen extends StatelessWidget {
  const MasScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<SessionProvider>().user;
    final themeProvider = context.watch<ThemeProvider>();

    return AppScaffold(
      body: SafeArea(
        child: ListView(
          children: [
            Card(
              margin: const EdgeInsets.fromLTRB(12, 12, 12, 4),
              child: ListTile(
                leading: const CircleAvatar(
                  backgroundColor: AppColors.primaryContainer,
                  child: Icon(Icons.person, color: AppColors.primary),
                ),
                title: Text(user?.fullName ?? 'Mi perfil', style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text(user?.privilegeName ?? 'Ver información de la cuenta'),
                trailing: const Icon(Icons.chevron_right, size: 18),
                onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PerfilScreen())),
              ),
            ),
            Card(
              margin: const EdgeInsets.fromLTRB(12, 4, 12, 4),
              child: SwitchListTile(
                secondary: const Icon(Icons.dark_mode_outlined),
                title: const Text('Modo oscuro', style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text('Fondo navy en vez de blanco'),
                value: themeProvider.isDark,
                onChanged: themeProvider.setDark,
              ),
            ),
            _Section(
              title: 'Instituciones',
              icon: Icons.apartment,
              items: [
                _Item('Instituciones', () => GenericCrudScreen(config: CrudConfigs.institutions)),
                _Item('Personal', () => const UsersScreen()),
              ],
            ),
            _Section(
              title: 'Unidades y recursos',
              icon: Icons.local_shipping,
              items: [
                _Item('Unidades', () => GenericCrudScreen(config: CrudConfigs.units)),
                _Item('Vehículos', () => GenericCrudScreen(config: CrudConfigs.units)),
                _Item('Recursos', () => GenericCrudScreen(config: CrudConfigs.resourceTypes)),
                _Item('Equipamiento', () => GenericCrudScreen(config: CrudConfigs.resourceTypes)),
              ],
            ),
            _Section(
              title: 'Seguimiento',
              icon: Icons.gps_fixed,
              items: [
                _Item('GPS', () => const GpsScreen()),
                _Item(
                  'Estado de unidades',
                  () => GenericCrudScreen(config: CrudConfigs.units),
                ),
                _Item('Historial', () => const TrackingHistorialScreen()),
              ],
            ),
            _Section(
              title: 'Administración',
              icon: Icons.admin_panel_settings,
              items: [
                _Item('Usuarios', () => const UsersScreen()),
                _Item('Roles', () => GenericCrudScreen(config: CrudConfigs.privileges)),
                _Item('Permisos', () => GenericCrudScreen(config: CrudConfigs.privileges)),
                _Item('Ciudadanos', () => const CitizensScreen()),
              ],
            ),
            _Section(
              title: 'Catálogos',
              icon: Icons.category,
              items: [
                _Item('Tipos de emergencia', () => GenericCrudScreen(config: CrudConfigs.emergencyTypes)),
                _Item('Estados', () => const EstadosScreen()),
                _Item('Categorías (tipos de institución)', () => GenericCrudScreen(config: CrudConfigs.institutionTypes)),
                _Item('Otros catálogos (subinstituciones)', () => GenericCrudScreen(config: CrudConfigs.subinstitutions)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Item {
  final String label;
  final Widget Function() builder;
  _Item(this.label, this.builder);
}

class _Section extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<_Item> items;

  const _Section({required this.title, required this.icon, required this.items});

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      leading: Icon(icon),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      children: items
          .map((item) => ListTile(
                contentPadding: const EdgeInsets.only(left: 32, right: 16),
                title: Text(item.label),
                trailing: const Icon(Icons.chevron_right, size: 18),
                onTap: () {
                  Navigator.of(context).push(MaterialPageRoute(builder: (_) => item.builder()));
                },
              ))
          .toList(),
    );
  }
}
