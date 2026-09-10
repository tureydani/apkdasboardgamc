import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/theme/index.dart';
import '../../models/session_user.dart';
import '../../providers/session_provider.dart';
import '../../services/catalog_services.dart';
import '../../widgets/app_scaffold.dart';
import '../auth/login_screen.dart';

const _privilegeColors = {
  'CENTRAL_ADMIN': AppColors.urgentRed,
  'CENTRAL_OPERATOR': AppColors.primary,
  'DISPATCHER': AppColors.accent,
  'INSTITUTION_ADMIN': AppColors.secondaryDark,
  'INSTITUTION_OPERATOR': AppColors.moderateOrange,
};

/// Muestra toda la información de la sesión activa (institucional o
/// ciudadano): son los mismos campos que devuelve GET /api/auth/session,
/// resolviendo además el nombre de la institución/subinstitución por id.
class PerfilScreen extends StatefulWidget {
  const PerfilScreen({super.key});

  @override
  State<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen> {
  String? _institutionName;
  String? _subinstitutionName;
  bool _loadingRelations = false;

  @override
  void initState() {
    super.initState();
    _loadRelations();
  }

  Future<void> _loadRelations() async {
    final user = context.read<SessionProvider>().user;
    if (user == null) return;
    setState(() => _loadingRelations = true);
    try {
      if (user.institutionId != null) {
        final institution = await CatalogServices.institutions.getById(user.institutionId);
        _institutionName = institution['name'] as String?;
      }
      if (user.subinstitutionId != null) {
        final subinstitution = await CatalogServices.subinstitutions.getById(user.subinstitutionId);
        _subinstitutionName = subinstitution['name'] as String?;
      }
    } catch (_) {
      // Sin conexión o sin permiso: se muestra igual el resto del perfil.
    } finally {
      if (mounted) setState(() => _loadingRelations = false);
    }
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Cerrar sesión'),
        content: const Text('¿Seguro que quieres cerrar sesión?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Cerrar sesión')),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await context.read<SessionProvider>().logout();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<SessionProvider>().user;

    return AppScaffold(
      title: 'Perfil',
      body: user == null
          ? const Center(child: Text('No hay una sesión activa.'))
          : RefreshIndicator(
              onRefresh: _loadRelations,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _ProfileHeader(user: user),
                  const SizedBox(height: 20),
                  _InfoSection(
                    title: 'Contacto',
                    icon: Icons.contact_mail_outlined,
                    rows: [
                      if (user.email != null) _InfoRow(Icons.email_outlined, 'Correo', user.email!),
                      if (user.phoneNumber != null) _InfoRow(Icons.phone_outlined, 'Teléfono', user.phoneNumber!),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _InfoSection(
                    title: 'Cuenta',
                    icon: Icons.badge_outlined,
                    rows: [
                      _InfoRow(Icons.tag, 'ID de usuario', user.id),
                      _InfoRow(Icons.category_outlined, 'Tipo de cuenta', user.role == 'CITIZEN' ? 'Ciudadano' : 'Institucional'),
                      if (user.privilegeName != null) _InfoRow(Icons.verified_user_outlined, 'Rol', user.privilegeName!),
                      if (user.privilegeCode != null) _InfoRow(Icons.key_outlined, 'Código de privilegio', user.privilegeCode!),
                    ],
                  ),
                  if (user.institutionId != null || user.subinstitutionId != null) ...[
                    const SizedBox(height: 12),
                    _InfoSection(
                      title: 'Institución',
                      icon: Icons.apartment_outlined,
                      rows: [
                        if (user.institutionId != null)
                          _InfoRow(
                            Icons.apartment,
                            'Institución',
                            _institutionName ?? (_loadingRelations ? 'Cargando...' : '#${user.institutionId}'),
                          ),
                        if (user.subinstitutionId != null)
                          _InfoRow(
                            Icons.account_tree_outlined,
                            'Subinstitución',
                            _subinstitutionName ?? (_loadingRelations ? 'Cargando...' : '#${user.subinstitutionId}'),
                          ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 24),
                  OutlinedButton.icon(
                    onPressed: _logout,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.urgentRed,
                      side: const BorderSide(color: AppColors.urgentRed),
                      minimumSize: const Size.fromHeight(48),
                    ),
                    icon: const Icon(Icons.logout),
                    label: const Text('Cerrar sesión'),
                  ),
                ],
              ),
            ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  final SessionUser user;
  const _ProfileHeader({required this.user});

  String get _initials {
    final f = user.firstName.trim();
    final l = user.lastName.trim();
    final a = f.isNotEmpty ? f[0] : '';
    final b = l.isNotEmpty ? l[0] : '';
    final initials = '$a$b'.toUpperCase();
    return initials.isNotEmpty ? initials : '?';
  }

  @override
  Widget build(BuildContext context) {
    final color = _privilegeColors[user.privilegeCode] ?? AppColors.primary;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 32,
              backgroundColor: color.withValues(alpha: 0.15),
              child: Text(_initials, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 22)),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(user.fullName, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      if (user.privilegeName != null)
                        Chip(
                          label: Text(user.privilegeName!, style: const TextStyle(fontSize: 11, color: Colors.white)),
                          backgroundColor: color,
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        )
                      else
                        Chip(
                          label: Text(user.role == 'CITIZEN' ? 'Ciudadano' : 'Institucional', style: const TextStyle(fontSize: 11, color: Colors.white)),
                          backgroundColor: color,
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<_InfoRow> rows;

  const _InfoSection({required this.title, required this.icon, required this.rows});

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) return const SizedBox.shrink();
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Row(
              children: [
                Icon(icon, size: 18, color: AppColors.textSecondary),
                const SizedBox(width: 8),
                Text(title, style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
              ],
            ),
          ),
          const Divider(height: 1),
          ...rows,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow(this.icon, this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      leading: Icon(icon, size: 20, color: AppColors.textTertiary),
      title: Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textTertiary)),
      subtitle: Text(value, style: const TextStyle(fontSize: 14)),
    );
  }
}
