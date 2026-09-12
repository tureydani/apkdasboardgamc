import 'package:dio/dio.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../utils/geojson_parser.dart';

/// Clasificación amplia de un resultado de Nominatim, derivada de su
/// geometría (con el `class` de OSM como respaldo si no hay geometría) —
/// se usa para decidir cómo dibujarlo y si filtra emergencias o no.
enum GeoResultKind { area, street, place }

class GeoSearchResult {
  final String osmType;
  final int osmId;
  final String displayName;
  final String primaryLabel;
  final String secondaryLabel;
  final LatLng center;
  final LatLngBounds bounds;
  final GeoZoneGeometry? geometry;
  final String category;
  final String type;

  const GeoSearchResult({
    required this.osmType,
    required this.osmId,
    required this.displayName,
    required this.primaryLabel,
    required this.secondaryLabel,
    required this.center,
    required this.bounds,
    required this.geometry,
    required this.category,
    required this.type,
  });

  GeoResultKind get kind {
    if (geometry != null && geometry!.isArea) return GeoResultKind.area;
    if (geometry != null && geometry!.isLine) return GeoResultKind.street;
    if (category == 'highway') return GeoResultKind.street;
    if (category == 'boundary' || category == 'place') return GeoResultKind.area;
    return GeoResultKind.place;
  }

  String get key => '$osmType/$osmId';
}

class NominatimException implements Exception {
  final String message;
  NominatimException(this.message);

  @override
  String toString() => message;
}

/// Cliente de geocodificación para Nominatim/OpenStreetMap, usado por el
/// buscador de sectores del mapa. Va separado de [ApiClient] porque apunta
/// a otro host y no necesita cookies de sesión.
class NominatimService {
  NominatimService._();

  static final Dio _dio = Dio(
    BaseOptions(
      baseUrl: 'https://nominatim.openstreetmap.org',
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {'User-Agent': 'SosApp/1.0 (bo.gob.cochabamba.gamc.sosapk)'},
    ),
  );

  // Bounding box aproximado alrededor de Cochabamba, Bolivia, para sesgar
  // (no restringir — `bounded=0`) los resultados hacia la zona de la app.
  static const _cochabambaViewbox = '-67.0,-16.7,-65.3,-18.0';

  static Future<List<GeoSearchResult>> search(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return [];

    try {
      final response = await _dio.get<List<dynamic>>(
        '/search',
        queryParameters: {
          'q': trimmed,
          'format': 'jsonv2',
          'polygon_geojson': 1,
          'addressdetails': 1,
          'limit': 8,
          'countrycodes': 'bo',
          'viewbox': _cochabambaViewbox,
          'bounded': 0,
        },
      );

      final data = response.data ?? const [];
      final results = <GeoSearchResult>[];
      final seenKeys = <String>{};

      for (final item in data) {
        if (item is! Map<String, dynamic>) continue;
        final result = _parseResult(item);
        if (result == null) continue;
        if (!seenKeys.add(result.key)) continue;
        results.add(result);
      }
      return results;
    } on DioException {
      throw NominatimException('No se pudo realizar la búsqueda. Intenta nuevamente.');
    } catch (_) {
      throw NominatimException('No se pudo realizar la búsqueda. Intenta nuevamente.');
    }
  }

  static GeoSearchResult? _parseResult(Map<String, dynamic> item) {
    final lat = double.tryParse(item['lat']?.toString() ?? '');
    final lon = double.tryParse(item['lon']?.toString() ?? '');
    final boundingBox = item['boundingbox'];
    final displayName = item['display_name'] as String?;
    if (lat == null || lon == null || displayName == null || displayName.isEmpty) {
      return null;
    }
    if (boundingBox is! List || boundingBox.length < 4) return null;

    final south = double.tryParse(boundingBox[0].toString());
    final north = double.tryParse(boundingBox[1].toString());
    final west = double.tryParse(boundingBox[2].toString());
    final east = double.tryParse(boundingBox[3].toString());
    if (south == null || north == null || west == null || east == null) return null;

    final geojson = item['geojson'];
    final geometry = GeoJsonParser.parse(geojson is Map<String, dynamic> ? geojson : null);

    final parts = displayName.split(',').map((p) => p.trim()).where((p) => p.isNotEmpty).toList();
    final primary = parts.isNotEmpty ? parts.first : displayName;
    final secondary = parts.length > 1 ? parts.skip(1).take(2).join(', ') : '';

    return GeoSearchResult(
      osmType: item['osm_type']?.toString() ?? '',
      osmId: int.tryParse(item['osm_id']?.toString() ?? '') ?? 0,
      displayName: displayName,
      primaryLabel: primary,
      secondaryLabel: secondary,
      center: LatLng(lat, lon),
      bounds: LatLngBounds(LatLng(south, west), LatLng(north, east)),
      geometry: geometry,
      category: item['class']?.toString() ?? '',
      type: item['type']?.toString() ?? '',
    );
  }
}
