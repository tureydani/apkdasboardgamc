import 'package:flutter/material.dart';

import '../../app/theme/index.dart';
import '../../core/animations/motion.dart';
import '../../services/notification_service.dart';
import '../../widgets/app_scaffold.dart';
import '../operacion/emergency_detail_screen.dart';

const _typeIcons = {
  'PUSH': Icons.notifications_active_outlined,
  'SYSTEM_ALERT': Icons.warning_amber_rounded,
  'DISPATCH_UPDATE': Icons.local_shipping_outlined,
};

const _typeColors = {
  'PUSH': AppColors.secondary,
  'SYSTEM_ALERT': AppColors.urgentRed,
  'DISPATCH_UPDATE': AppColors.accent,
};

/// "Hace X min/h/días", igual que `Formatters.formatRelativeTime` de
/// arconde-gamc pero sin depender de `intl` (sosapk no lo trae).
String _formatRelativeTime(String? iso) {
  if (iso == null) return '';
  final dateTime = DateTime.tryParse(iso);
  if (dateTime == null) return iso;
  final difference = DateTime.now().difference(dateTime);

  if (difference.inSeconds < 60) return 'Ahora mismo';
  if (difference.inMinutes < 60) return 'Hace ${difference.inMinutes} min';
  if (difference.inHours < 24) return 'Hace ${difference.inHours} h';
  if (difference.inDays < 7) return 'Hace ${difference.inDays} d';
  final local = dateTime.toLocal();
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(local.day)}/${two(local.month)}/${local.year}';
}

class AlertasScreen extends StatefulWidget {
  const AlertasScreen({super.key});

  @override
  State<AlertasScreen> createState() => _AlertasScreenState();
}

class _AlertasScreenState extends State<AlertasScreen> {
  final _service = NotificationService();
  List<Map<String, dynamic>> _items = [];
  int _unread = 0;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await _service.fetchMine();
      setState(() {
        _items = (data['items'] as List).map((e) => Map<String, dynamic>.from(e)).toList();
        _unread = data['unread'] ?? 0;
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _open(Map<String, dynamic> n) async {
    if (n['isRead'] != true) {
      await _markRead(n);
    }
    final emergencyId = n['tbemergencies']?['PK_emergency'] ?? n['FK_emergency'];
    if (emergencyId != null && mounted) {
      await Navigator.of(context).push(MaterialPageRoute(builder: (_) => EmergencyDetailScreen(id: emergencyId)));
      _load();
    }
  }

  /// Marca como leída en el momento (sin esperar un `_load()` completo) para
  /// que el deslizar o tocar se sienta inmediato, y solo entonces avisa al
  /// backend.
  Future<void> _markRead(Map<String, dynamic> n) async {
    if (n['isRead'] == true) return;
    setState(() {
      n['isRead'] = true;
      if (_unread > 0) _unread--;
    });
    try {
      await _service.markRead(n['PK_notification']);
    } catch (_) {
      // Sin conexión: queda visualmente leída, el próximo refresh corrige
      // el estado real si el PATCH no llegó a aplicarse.
    }
  }

  Future<void> _markAllRead() async {
    setState(() {
      for (final n in _items) {
        n['isRead'] = true;
      }
      _unread = 0;
    });
    try {
      await _service.markAllRead();
    } catch (_) {
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
                  ? _buildError()
                  : _items.isEmpty
                      ? _buildEmpty()
                      : Column(
                          children: [
                            if (_unread > 0) _buildUnreadBanner(),
                            Expanded(
                              child: ListView.separated(
                                itemCount: _items.length,
                                separatorBuilder: (_, __) => const Divider(height: 1),
                                itemBuilder: (context, i) => _NotificationTile(
                                  notification: _items[i],
                                  onTap: () => _open(_items[i]),
                                  onMarkRead: () => _markRead(_items[i]),
                                ),
                              ),
                            ),
                          ],
                        ),
        ),
      ),
    );
  }

  Widget _buildUnreadBanner() {
    return Container(
      width: double.infinity,
      color: AppColors.secondaryContainer,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              _unread == 1 ? '1 notificación sin leer' : '$_unread notificaciones sin leer',
              style: const TextStyle(color: AppColors.secondaryDark, fontWeight: FontWeight.w600, fontSize: 12),
            ),
          ),
          TextButton.icon(
            onPressed: _markAllRead,
            icon: const Icon(Icons.done_all, size: 16),
            label: const Text('Marcar todas'),
            style: TextButton.styleFrom(foregroundColor: AppColors.secondaryDark, visualDensity: VisualDensity.compact),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return ListView(
      children: [
        const SizedBox(height: 100),
        Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.notifications_off_outlined, size: 48, color: AppColors.textDisabled),
                const SizedBox(height: 12),
                const Text('Sin notificaciones', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                const Text(
                  'Acá vas a ver las alertas de emergencias y despachos.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildError() {
    return ListView(
      children: [
        const SizedBox(height: 100),
        Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.cloud_off, size: 48, color: AppColors.textDisabled),
                const SizedBox(height: 12),
                Text(_error!, textAlign: TextAlign.center),
                const SizedBox(height: 12),
                FilledButton.icon(onPressed: _load, icon: const Icon(Icons.refresh), label: const Text('Reintentar')),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final Map<String, dynamic> notification;
  final VoidCallback onTap;
  final VoidCallback onMarkRead;

  const _NotificationTile({required this.notification, required this.onTap, required this.onMarkRead});

  @override
  Widget build(BuildContext context) {
    final n = notification;
    final read = n['isRead'] == true;
    final type = n['notificationType'] as String?;
    final color = _typeColors[type] ?? AppColors.textTertiary;

    return Dismissible(
      key: ValueKey(n['PK_notification']),
      direction: read ? DismissDirection.none : DismissDirection.endToStart,
      confirmDismiss: (_) async {
        onMarkRead();
        return false; // Solo marca como leída; no hay borrado en el backend.
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        color: AppColors.secondaryContainer,
        child: const Icon(Icons.done, color: AppColors.secondaryDark),
      ),
      child: Material(
        color: read ? Colors.transparent : AppColors.primaryContainer.withValues(alpha: 0.35),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: color.withValues(alpha: 0.15),
            child: Icon(_typeIcons[type] ?? Icons.notifications, color: color),
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  n['title'] ?? '',
                  style: TextStyle(fontWeight: read ? FontWeight.normal : FontWeight.bold),
                ),
              ),
              if (!read)
                Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.only(left: 6),
                  decoration: const BoxDecoration(color: AppColors.urgentRed, shape: BoxShape.circle),
                ).pulseGlow(minScale: 1.0, maxScale: 1.6, duration: const Duration(milliseconds: 1200)),
            ],
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  n['message'] ?? '',
                  style: const TextStyle(color: AppColors.textSecondary),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  _formatRelativeTime(n['createdAt'] as String?),
                  style: const TextStyle(color: AppColors.textTertiary, fontSize: 11),
                ),
              ],
            ),
          ),
          isThreeLine: true,
          onTap: onTap,
        ),
      ),
    );
  }
}
