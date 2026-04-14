import 'dart:convert';
import 'truck_h3_service.dart';

/// Converts H3 cells to GeoJSON FeatureCollection for Mapbox FillLayer.
class H3MapboxService {
  /// Convert a list of H3 cell indexes to GeoJSON FeatureCollection.
  /// Returns a Map suitable for jsonEncode (GeoJSON format).
  static Map<String, dynamic> cellsToGeoJson(List<BigInt> cells) {
    final features = <Map<String, dynamic>>[];

    for (final cell in cells) {
      final boundary = TruckH3Service.cellToBoundary(cell);
      if (boundary == null || boundary.isEmpty) continue;

      // GeoJSON Polygon: coordinates are [lng, lat] and ring must be closed
      final coords = boundary
          .map((p) => [p.lng, p.lat])
          .toList();
      // Close the ring (first point = last point)
      if (coords.isNotEmpty &&
          (coords.first[0] != coords.last[0] || coords.first[1] != coords.last[1])) {
        coords.add(coords.first);
      }

      features.add({
        'type': 'Feature',
        'geometry': {
          'type': 'Polygon',
          'coordinates': [coords],
        },
        'properties': {},
      });
    }

    return {
      'type': 'FeatureCollection',
      'features': features,
    };
  }

  /// Convert cells to GeoJSON string (for Mapbox GeoJsonSource).
  static String cellsToGeoJsonString(List<BigInt> cells) {
    return jsonEncode(cellsToGeoJson(cells));
  }
}
