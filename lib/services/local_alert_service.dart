import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:vibration/vibration.dart';

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
///
/// Para "nueva asignación" además hay una alarma en loop (ver
/// [startAssignmentAlarm]/[stopAssignmentAlarm]): una notificación normal
/// solo suena una vez, así que para que realmente "no se pueda ignorar"
/// (mismo criterio que apps de despacho tipo taxi/delivery) se reproduce un
/// tono de sirena propio en bucle + vibración continua mientras la pantalla
/// de alerta esté abierta, hasta que el operador la toca.
class LocalAlertService {
  LocalAlertService._internal();
  static final LocalAlertService instance = LocalAlertService._internal();

  static const _channelId = 'dispatch_alerts';
  static const _channelName = 'Asignaciones de despacho';
  static const _channelDescription = 'Aviso al asignarse un nuevo despacho';

  static const _generalChannelId = 'general_alerts';
  static const _generalChannelName = 'Notificaciones';
  static const _generalChannelDescription = 'Aviso general de notificaciones nuevas';

  static final _vibrationPattern = Int64List.fromList([0, 500, 200, 500, 200, 500]);
  static final _generalVibrationPattern = Int64List.fromList([0, 250, 150, 250]);

  // Patrón de vibración en bucle para la alarma de asignación: pausa corta,
  // vibra fuerte, pausa, repite — `repeat: 1` hace que el paquete vuelva al
  // índice 1 (el primer "vibra") en vez de al índice 0 (la pausa inicial),
  // así el loop no arranca con un silencio cada vez.
  static const _alarmVibrationPattern = [0, 700, 300, 700, 300];

  final _plugin = FlutterLocalNotificationsPlugin();
  final _alarmPlayer = AudioPlayer(playerId: 'assignment-alarm');
  bool _ready = false;
  int _notificationId = 0;
  bool _alarmPlaying = false;

  Future<void> ensureReady() async {
    if (_ready) return;
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidInit);
    await _plugin.initialize(settings: initSettings);
    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.createNotificationChannel(AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: _channelDescription,
      importance: Importance.max,
      enableVibration: true,
      vibrationPattern: _vibrationPattern,
      playSound: true,
    ));
    // Canal aparte (menos intrusivo) para notificaciones generales — no
    // comparte el sonido/patrón "de alarma" del despacho, para que un
    // mensaje de sala de crisis no se confunda con una asignación nueva.
    await androidPlugin?.createNotificationChannel(AndroidNotificationChannel(
      _generalChannelId,
      _generalChannelName,
      description: _generalChannelDescription,
      importance: Importance.high,
      enableVibration: true,
      vibrationPattern: _generalVibrationPattern,
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

  /// Aviso corto (una vez) para una notificación general nueva (sala de
  /// crisis, cambio de estado, etc.) — suena y vibra, pero sin el loop de
  /// [startAssignmentAlarm]: no amerita interrumpir hasta que se toque la
  /// pantalla, solo hacerse notar.
  Future<void> notifyGeneric({required String title, required String body}) async {
    await ensureReady();
    _notificationId++;
    await _plugin.show(
      id: _notificationId,
      title: title,
      body: body,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          _generalChannelId,
          _generalChannelName,
          channelDescription: _generalChannelDescription,
          importance: Importance.high,
          priority: Priority.high,
          enableVibration: true,
          vibrationPattern: _generalVibrationPattern,
          playSound: true,
        ),
      ),
    );
  }

  /// Arranca la sirena en loop + vibración continua para "nueva asignación"
  /// — pensada para sonar mientras el operador tiene la app abierta y no ha
  /// tocado la pantalla de alerta todavía (ver `IncomingAssignmentScreen`).
  /// Idempotente: si ya está sonando, no la reinicia (evita el "clic" de
  /// cortar y volver a arrancar el loop si algo la llama dos veces).
  Future<void> startAssignmentAlarm() async {
    if (_alarmPlaying) return;
    _alarmPlaying = true;
    try {
      await _alarmPlayer.setReleaseMode(ReleaseMode.loop);
      await _alarmPlayer.setVolume(1.0);
      await _alarmPlayer.play(AssetSource('sounds/siren_alarm.wav'));
    } catch (_) {
      // Sin salida de audio disponible (emulador sin audio, etc.): la
      // vibración de abajo sigue siendo el aviso principal.
    }
    try {
      if (await Vibration.hasVibrator()) {
        // `repeat: 1` vuelve al índice 1 del patrón (el primer "vibra", no
        // la pausa inicial en 0) al terminar cada ciclo -> loop continuo
        // sin arrancar cada vuelta con un silencio.
        await Vibration.vibrate(pattern: _alarmVibrationPattern, repeat: 1);
      }
    } catch (_) {
      // Sin vibrador (tablet/desktop): el sonido sigue sonando igual.
    }
  }

  /// Corta la sirena + vibración — se llama al tocar la pantalla de alerta
  /// de asignación (o al salir de ella de cualquier forma).
  Future<void> stopAssignmentAlarm() async {
    if (!_alarmPlaying) return;
    _alarmPlaying = false;
    await _alarmPlayer.stop();
    Vibration.cancel();
  }
}
