/// Configuración central de la app: URL base del backend SOS-24 GAMC.
///
/// - Emulador Android -> host usa 10.0.2.2 para llegar a localhost de la PC.
/// - Dispositivo físico en la misma red -> usar la IP LAN de la PC (ej. 192.168.x.x).
/// - Backend desplegado -> usar la URL de Vercel.
class AppConfig {
  AppConfig._();

  /// Cambia esto según dónde corras el backend Next.js.
  static const String baseUrl = String.fromEnvironment(
    'SOS_BASE_URL',
    defaultValue: 'http://10.0.2.2:3000',
  );
}
