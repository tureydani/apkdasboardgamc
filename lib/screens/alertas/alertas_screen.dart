import 'package:flutter/material.dart';

import '../../services/notification_service.dart';
import '../../widgets/app_scaffold.dart';
import '../operacion/emergency_detail_screen.dart';

const _typeIcons = {
  'PUSH': Icons.notifications_active_outlined,
  'SYSTEM_ALERT': Icons.warning_amber_rounded,
  'DISPATCH_UPDATE': Icons.local_shipping_outlined,
};

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
      await _service.markRead(n['PK_notification']);
    }
    final emergencyId = n['tbemergencies']?['PK_emergency'] ?? n['FK_emergency'];
    if (emergencyId != null && mounted) {
      await Navigator.of(context).push(MaterialPageRoute(builder: (_) => EmergencyDetailScreen(id: emergencyId)));
    }
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: _unread > 0 ? 'Alertas ($_unread nuevas)' : 'Alertas',
      actions: [
        if (_unread > 0)
          IconButton(
            icon: const Icon(Icons.done_all),
            tooltip: 'Marcar todas leídas',
            onPressed: () async {
              await _service.markAllRead();
              _load();
            },
          ),
      ],
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(child: Text(_error!))
                : _items.isEmpty
                    ? ListView(children: const [SizedBox(height: 80), Center(child: Text('Sin notificaciones'))])
                    : ListView.separated(
                        itemCount: _items.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, i) {
                          final n = _items[i];
                          final read = n['isRead'] == true;
                          return ListTile(
                            leading: Icon(_typeIcons[n['notificationType']] ?? Icons.notifications, color: read ? Colors.grey : Colors.redAccent),
                            title: Text(n['title'] ?? '', style: TextStyle(fontWeight: read ? FontWeight.normal : FontWeight.bold)),
                            subtitle: Text('${n['message'] ?? ''}\n${n['createdAt'] ?? ''}'),
                            isThreeLine: true,
                            onTap: () => _open(n),
                          );
                        },
                      ),
      ),
    );
  }
}
