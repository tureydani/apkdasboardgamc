import 'package:latlong2/latlong.dart';

/// A single polygon ring set: an outer boundary plus optional holes,
/// mirroring GeoJSON's `Polygon` coordinate structure.
class GeoPolygonShape {
  final List<LatLng> exterior;
  final List<List<LatLng>> holes;

  const GeoPolygonShape({required this.exterior, this.holes = const []});
}

/// Parsed geometry for a search result: either one or more polygons
/// (`Polygon`/`MultiPolygon`) or one or more lines
/// (`LineString`/`MultiLineString`). A result with a bare point geometry
/// (or no geometry at all) parses to `null` — callers fall back to
/// center + bounding box in that case.
class GeoZoneGeometry {
  final List<GeoPolygonShape> polygons;
  final List<List<LatLng>> lines;

  const GeoZoneGeometry({this.polygons = const [], this.lines = const []});

  bool get isArea => polygons.isNotEmpty;
  bool get isLine => lines.isNotEmpty && polygons.isEmpty;
}

/// Convierte el objeto `geojson` crudo que devuelve Nominatim
/// (`polygon_geojson=1`) a [GeoZoneGeometry], listo para
/// `PolygonLayer`/`PolylineLayer` de flutter_map.
class GeoJsonParser {
  GeoJsonParser._();

  static GeoZoneGeometry? parse(Map<String, dynamic>? geojson) {
    if (geojson == null) return null;
    final type = geojson['type'] as String?;
    final coordinates = geojson['coordinates'];
    if (type == null || coordinates is! List) return null;

    switch (type) {
      case 'Polygon':
        final shape = _parsePolygon(coordinates);
        return shape == null ? null : GeoZoneGeometry(polygons: [shape]);

      case 'MultiPolygon':
        final shapes = coordinates
            .whereType<List>()
            .map(_parsePolygon)
            .whereType<GeoPolygonShape>()
            .toList();
        return shapes.isEmpty ? null : GeoZoneGeometry(polygons: shapes);

      case 'LineString':
        final line = _parseRing(coordinates);
        return line.isEmpty ? null : GeoZoneGeometry(lines: [line]);

      case 'MultiLineString':
        final lines = coordinates
            .whereType<List>()
            .map(_parseRing)
            .where((line) => line.isNotEmpty)
            .toList();
        return lines.isEmpty ? null : GeoZoneGeometry(lines: lines);

      default:
        // Point / MultiPoint / GeometryCollection: no hay forma que dibujar.
        return null;
    }
  }

  static GeoPolygonShape? _parsePolygon(List rings) {
    if (rings.isEmpty) return null;
    final exterior = _parseRing(rings.first as List);
    if (exterior.isEmpty) return null;
    final holes = rings
        .skip(1)
        .whereType<List>()
        .map(_parseRing)
        .where((ring) => ring.isNotEmpty)
        .toList();
    return GeoPolygonShape(exterior: exterior, holes: holes);
  }

  static List<LatLng> _parseRing(List ring) {
    return ring
        .whereType<List>()
        .where((point) => point.length >= 2)
        .map((point) => LatLng((point[1] as num).toDouble(), (point[0] as num).toDouble()))
        .toList();
  }
}

/// Test de punto-en-polígono (ray casting), respetando huecos.
bool isPointInZone(LatLng point, GeoZoneGeometry geometry) {
  for (final polygon in geometry.polygons) {
    if (_isPointInShape(point, polygon)) return true;
  }
  return false;
}

bool _isPointInShape(LatLng point, GeoPolygonShape shape) {
  if (!_isPointInRing(point, shape.exterior)) return false;
  for (final hole in shape.holes) {
    if (_isPointInRing(point, hole)) return false;
  }
  return true;
}

bool _isPointInRing(LatLng point, List<LatLng> ring) {
  var inside = false;
  for (var i = 0, j = ring.length - 1; i < ring.length; j = i++) {
    final pi = ring[i];
    final pj = ring[j];
    final crossesLatitude = (pi.latitude > point.latitude) != (pj.latitude > point.latitude);
    if (!crossesLatitude) continue;

    final intersectionLongitude = (pj.longitude - pi.longitude) *
            (point.latitude - pi.latitude) /
            (pj.latitude - pi.latitude) +
        pi.longitude;
    if (point.longitude < intersectionLongitude) inside = !inside;
  }
  return inside;
}
