import 'package:dio/dio.dart';
import 'package:latlong2/latlong.dart';

/// Resultado de una ruta calculada por OSRM: los puntos a dibujar y las
/// métricas (distancia/tiempo) para mostrar un ETA.
class RouteResult {
  final List<LatLng> points;
  final double distanceMeters;
  final double durationSeconds;

  const RouteResult({
    required this.points,
    required this.distanceMeters,
    required this.durationSeconds,
  });
}

/// Calcula rutas siguiendo calles reales usando el servidor público de OSRM
/// (Open Source Routing Machine), el mismo que ya usa arconde-gamc para el
/// ciudadano (lib/core/services/routing_service.dart) — misma API, mismo
/// motor de mapas (OpenStreetMap), sin necesidad de llave alguna.
class RoutingService {
  static final Dio _dio = Dio();

  static Future<RouteResult?> fetchRoute(LatLng origin, LatLng destination) async {
    try {
      final url = 'https://router.project-osrm.org/route/v1/driving/'
          '${origin.longitude},${origin.latitude};'
          '${destination.longitude},${destination.latitude}'
          '?overview=full&geometries=geojson';
      final response = await _dio.get(url);
      final routes = response.data['routes'] as List<dynamic>?;
      if (routes == null || routes.isEmpty) return null;
      final route = routes.first as Map<String, dynamic>;
      final geometry = route['geometry'] as Map<String, dynamic>;
      final coordinates = geometry['coordinates'] as List<dynamic>;
      final points = coordinates
          .map((c) => LatLng((c[1] as num).toDouble(), (c[0] as num).toDouble()))
          .toList();
      return RouteResult(
        points: points,
        distanceMeters: (route['distance'] as num).toDouble(),
        durationSeconds: (route['duration'] as num).toDouble(),
      );
    } catch (_) {
      return null;
    }
  }
}
