import 'dart:typed_data';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Aviso local (sonido + vibración) para eventos que necesitan sacar al
/// operador de lo que esté haciendo, como una nueva asignación de despacho.
///
/// `SystemSound.play` + `HapticFeedback` (usados antes acá) resultaron poco
/// confiables en Android: el sonido respeta el volumen de medios/silencioso
/// y a menudo no suena, y el haptic feedback respeta el interruptor de
/// "vibración táctil" del sistema en vez de vibrar de verdad. Una
/// notificación local usa el canal de notificaciones (sonido + patrón de
/// vibración propio, banner con prioridad alta) y sí se nota de forma
/// consistente entre equipos.
class LocalAlertService {
  LocalAlertService._internal();
  static final LocalAlertService instance = LocalAlertService._internal();

  static const _channelId = 'dispatch_alerts';
  static const _channelName = 'Asignaciones de despacho';
  static const _channelDescription = 'Aviso al asignarse un nuevo despacho';

  static final _vibrationPattern = Int64List.fromList([0, 500, 200, 500, 200, 500]);

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _ready = false;
  int _notificationId = 0;

  Future<void> ensureReady() async {
    if (_ready) return;
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidInit);
    await _plugin.initialize(settings: initSettings);
    await _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(AndroidNotificationChannel(
          _channelId,
          _channelName,
          description: _channelDescription,
          importance: Importance.max,
          enableVibration: true,
          vibrationPattern: _vibrationPattern,
          playSound: true,
        ));
    _ready = true;
  }

  /// Pide el permiso de notificaciones (obligatorio desde Android 13). Se
  /// llama al iniciar el seguimiento de asignaciones; si el usuario lo
  /// niega, el aviso simplemente no se mostrará (sin romper el resto de la
  /// app).
  Future<void> requestPermission() async {
    await ensureReady();
    await _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  /// Dispara el aviso de "nuevo despacho asignado".
  Future<void> notifyNewAssignment({required String title, required String body}) async {
    await ensureReady();
    _notificationId++;
    await _plugin.show(
      id: _notificationId,
      title: title,
      body: body,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDescription,
          importance: Importance.max,
          priority: Priority.high,
          enableVibration: true,
          vibrationPattern: _vibrationPattern,
          playSound: true,
          category: AndroidNotificationCategory.alarm,
          fullScreenIntent: false,
        ),
      ),
    );
  }
}
