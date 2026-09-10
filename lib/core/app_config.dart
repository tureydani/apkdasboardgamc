/// Configuración central de la app: URL base del backend SOS-24 GAMC.
///
/// - Backend desplegado (Vercel, con Supabase) -> valor por defecto.
/// - Emulador Android contra backend local -> pasar --dart-define=SOS_BASE_URL=http://10.0.2.2:3000
/// - Dispositivo físico en la misma red -> --dart-define=SOS_BASE_URL=http://<IP-LAN-de-tu-PC>:3000
class AppConfig {
  AppConfig._();

  /// Cambia esto según dónde corras el backend Next.js.
  static const String baseUrl = String.fromEnvironment(
    'SOS_BASE_URL',
    defaultValue: 'https://sos-24-gamc-khaki.vercel.app',
  );
}
