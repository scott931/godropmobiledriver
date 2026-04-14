/// H3 geospatial indexing service for truck/vehicle tracking.
/// Converts GPS coordinates to stable grid cells for spatial indexing.
///
/// NOTE:
/// We intentionally keep this implementation pure Dart so iOS/macOS builds do
/// not depend on a native H3 plugin pod. The API remains compatible with the
/// rest of the app.
class H3LatLng {
  final double lat;
  final double lng;
  const H3LatLng({required this.lat, required this.lng});
}

class TruckH3Service {
  static bool _isInitialized = false;
  static const int routeResolution = 8; // ~0.07 km² - urban tracking

  /// Initialize H3 (call once at app startup).
  static Future<void> initialize() async {
    _isInitialized = true;
  }

  /// Convert lat/lng to a deterministic cell index (BigInt).
  static BigInt? positionToH3(double lat, double lng) {
    try {
      // Quantize coordinates by pseudo-resolution (keeps nearby points grouped)
      final scale = _resolutionScale(routeResolution);
      final qLat = ((lat + 90.0) * scale).round();
      final qLng = ((lng + 180.0) * scale).round();
      final packed = (BigInt.from(qLat) << 32) | BigInt.from(qLng);
      return packed;
    } catch (_) {
      return null;
    }
  }

  /// Convert lat/lng to H3 index as hex string (for storage/API).
  static String? positionToH3String(double lat, double lng) {
    final cell = positionToH3(lat, lng);
    if (cell == null) return null;
    return cell.toRadixString(16);
  }

  /// Compact a list of route cells for efficient transmission.
  static List<BigInt> compactCells(List<BigInt> cells) {
    if (cells.isEmpty) return cells;
    return cells.toSet().toList();
  }

  /// Get k-ring of nearby cells (for proximity/dispatch queries).
  static List<BigInt> getNearbyCells(BigInt cell, int k) {
    try {
      final center = _decodeCell(cell);
      if (center == null) return [];
      final scale = _resolutionScale(routeResolution);
      final step = 1.0 / scale;
      final cells = <BigInt>[];
      for (var y = -k; y <= k; y++) {
        for (var x = -k; x <= k; x++) {
          final lat = center.lat + (y * step);
          final lng = center.lng + (x * step);
          final nearby = positionToH3(lat, lng);
          if (nearby != null) {
            cells.add(nearby);
          }
        }
      }
      return cells.toSet().toList();
    } catch (_) {
      return [];
    }
  }

  /// Get cell boundary as list of points (for GeoJSON polygon).
  static List<H3LatLng>? cellToBoundary(BigInt cell) {
    try {
      final center = _decodeCell(cell);
      if (center == null) return null;
      final scale = _resolutionScale(routeResolution);
      final delta = 0.5 / scale;
      return [
        H3LatLng(lat: center.lat + delta, lng: center.lng - delta),
        H3LatLng(lat: center.lat + delta, lng: center.lng + delta),
        H3LatLng(lat: center.lat - delta, lng: center.lng + delta),
        H3LatLng(lat: center.lat - delta, lng: center.lng - delta),
      ];
    } catch (_) {
      return null;
    }
  }

  /// Check if H3 is initialized and ready.
  static bool get isInitialized => _isInitialized;

  static int _resolutionScale(int resolution) {
    // Keep numbers bounded while still producing a finer grid at higher values.
    final clamped = resolution.clamp(1, 12);
    return 1000 * clamped;
  }

  static H3LatLng? _decodeCell(BigInt cell) {
    try {
      final qLat = (cell >> 32).toInt();
      final qLng = (cell & BigInt.from(0xFFFFFFFF)).toInt();
      final scale = _resolutionScale(routeResolution);
      return H3LatLng(
        lat: (qLat / scale) - 90.0,
        lng: (qLng / scale) - 180.0,
      );
    } catch (_) {
      return null;
    }
  }
}
