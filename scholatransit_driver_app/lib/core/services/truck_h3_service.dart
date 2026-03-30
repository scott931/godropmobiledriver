import 'package:h3_flutter_plus/h3_flutter_plus.dart';

/// H3 geospatial indexing service for truck/vehicle tracking.
/// Converts GPS coordinates to H3 hexagonal cells for efficient spatial indexing.
class TruckH3Service {
  static H3? _h3;
  static const int routeResolution = 8; // ~0.07 km² - urban tracking

  /// Initialize H3 (call once at app startup).
  static Future<void> initialize() async {
    if (_h3 != null) return;
    try {
      _h3 = const H3Factory().load();
    } catch (_) {
      // Fallback: may fail on web without h3-js script
    }
  }

  /// Convert lat/lng to H3 cell index (BigInt).
  static BigInt? positionToH3(double lat, double lng) {
    if (_h3 == null) return null;
    try {
      return _h3!.latLngToCell(LatLng(lat: lat, lng: lng), routeResolution);
    } catch (_) {
      return null;
    }
  }

  /// Convert lat/lng to H3 index as hex string (for storage/API).
  static String? positionToH3String(double lat, double lng) {
    final cell = positionToH3(lat, lng);
    if (cell == null) return null;
    try {
      return _h3!.h3ToString(cell);
    } catch (_) {
      return cell.toRadixString(16);
    }
  }

  /// Compact a list of route cells for efficient transmission.
  static List<BigInt> compactCells(List<BigInt> cells) {
    if (_h3 == null || cells.isEmpty) return cells;
    try {
      return _h3!.compactCells(cells);
    } catch (_) {
      return cells;
    }
  }

  /// Get k-ring of nearby cells (for proximity/dispatch queries).
  static List<BigInt> getNearbyCells(BigInt cell, int k) {
    if (_h3 == null) return [];
    try {
      return _h3!.gridDisk(cell, k);
    } catch (_) {
      return [];
    }
  }

  /// Get cell boundary as list of LatLng (for GeoJSON polygon).
  static List<LatLng>? cellToBoundary(BigInt cell) {
    if (_h3 == null) return null;
    try {
      return _h3!.cellToBoundary(cell);
    } catch (_) {
      return null;
    }
  }

  /// Check if H3 is initialized and ready.
  static bool get isInitialized => _h3 != null;
}
