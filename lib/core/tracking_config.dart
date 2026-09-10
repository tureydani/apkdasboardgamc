/// Umbrales del envío de GPS en tiempo real, centralizados aquí para no
/// dispersar "números mágicos" por las pantallas de despacho.
class TrackingConfig {
  TrackingConfig._();

  /// No reenviar la posición más seguido que esto, aunque el GPS reporte
  /// movimiento continuo.
  static const minIntervalSeconds = 15;

  /// distanceFilter del stream de GPS: cuántos metros debe moverse la
  /// unidad para que el sistema operativo emita una nueva posición.
  static const minDistanceMeters = 25.0;

  /// Radio dentro del cual se permite confirmar "Marcar llegada" sin avisos.
  static const arrivalRadiusMeters = 100.0;

  /// Cada cuánto refresca "Ver ruta" la última posición conocida.
  static const pollIntervalSeconds = 8;

  /// Cada cuánto recalcula la ruta proyectada (OSRM) y el ETA. Más
  /// espaciado que el polling de posición para no saturar el servidor
  /// público de OSRM con una unidad en movimiento constante.
  static const routeRecalcSeconds = 30;
}
