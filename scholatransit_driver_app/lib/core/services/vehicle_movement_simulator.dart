import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../config/app_config.dart';
import '../providers/trip_provider.dart';
import 'location_service_resolver.dart';
import 'routing_service.dart';

/// When [AppConfig.useSimulatedVehicleMotion] is true, advances along a Mapbox
/// driving route (or straight fallback) and injects GPS so the puck follows roads.
/// Also POSTs to [updateLocationEndpoint] when the backend accepts the trip id.
class VehicleMovementSimulator {
  VehicleMovementSimulator._();

  static ProviderSubscription<TripState>? _subscription;
  static Timer? _timer;
  static String? _lastTripId;
  static int _routeGeneration = 0;

  /// Decoded route vertices [lat, lng], …
  static List<List<double>>? _path;
  /// Cumulative distance in meters at each vertex (same length as _path).
  static List<double>? _cumMeters;
  static double _totalMeters = 0;
  /// Distance traveled from route start along the polyline.
  static double _alongMeters = 0;

  static const double _earthRadiusM = 6371000.0;
  static const double _speedKmh = 28.0;

  static void attach(WidgetRef ref) {
    if (!AppConfig.useSimulatedVehicleMotion) return;
    detach();
    debugPrint(
      '🧪 VehicleMovementSimulator: attached — road-following route while trip is active',
    );
    _subscription = ref.listenManual<TripState>(tripProvider, (prev, next) {
      final active = next.currentTrip?.isActive == true;
      if (active) {
        _syncTimer(ref);
      } else {
        _cancelTimer();
      }
    });
    final now = ref.read(tripProvider);
    if (now.currentTrip?.isActive == true) {
      _syncTimer(ref);
    }
  }

  static void detach() {
    _cancelTimer();
    _subscription?.close();
    _subscription = null;
    _lastTripId = null;
    _path = null;
    _cumMeters = null;
    _totalMeters = 0;
    _alongMeters = 0;
  }

  static void _syncTimer(WidgetRef ref) {
    final trip = ref.read(tripProvider).currentTrip;
    if (trip == null || !trip.isActive) {
      _cancelTimer();
      return;
    }
    if (_lastTripId != trip.tripId) {
      _lastTripId = trip.tripId;
      _alongMeters = 0;
      _path = null;
      _cumMeters = null;
      _totalMeters = 0;
      _routeGeneration++;
      unawaited(_loadRouteForTrip(ref, trip.tripId, _routeGeneration));
    }
    _timer?.cancel();
    _timer = Timer.periodic(
      Duration(seconds: AppConfig.locationUpdateInterval),
      (_) => _tick(ref),
    );
    unawaited(_tick(ref));
  }

  static void _cancelTimer() {
    _timer?.cancel();
    _timer = null;
  }

  static Future<void> _loadRouteForTrip(
    WidgetRef ref,
    String tripIdForGen,
    int gen,
  ) async {
    final trip = ref.read(tripProvider).currentTrip;
    if (trip == null ||
        !trip.isActive ||
        trip.tripId != tripIdForGen ||
        gen != _routeGeneration) {
      return;
    }

    List<List<double>> pts;

    final sLat = trip.startLatitude;
    final sLng = trip.startLongitude;
    final eLat = trip.endLatitude;
    final eLng = trip.endLongitude;

    if (sLat != null && sLng != null && eLat != null && eLng != null) {
      final info = await RoutingService.getRouteInfo(
        startLat: sLat,
        startLng: sLng,
        endLat: eLat,
        endLng: eLng,
      );
      if (info != null && info.coordinates.length >= 2) {
        pts = info.coordinates
            .map((c) => [c['latitude']!, c['longitude']!])
            .toList();
        debugPrint(
          '🧪 SIM route: Mapbox driving polyline, ${pts.length} vertices, '
          '${(info.distance / 1000).toStringAsFixed(2)} km',
        );
      } else {
        pts = [
          [sLat, sLng],
          [eLat, eLng],
        ];
        debugPrint(
          '🧪 SIM route: fallback straight line (no Mapbox route or token)',
        );
      }
    } else {
      pts = [
        [AppConfig.defaultLatitude, AppConfig.defaultLongitude],
        [AppConfig.defaultLatitude + 0.04, AppConfig.defaultLongitude + 0.04],
      ];
      debugPrint('🧪 SIM route: fallback — trip missing start/end');
    }

    if (trip.tripId != tripIdForGen || gen != _routeGeneration) return;

    _setPath(pts);
  }

  static void _setPath(List<List<double>> pts) {
    if (pts.length < 2) return;
    _path = pts;
    final cum = <double>[0];
    double t = 0;
    for (var i = 0; i < pts.length - 1; i++) {
      t += _haversineMeters(pts[i][0], pts[i][1], pts[i + 1][0], pts[i + 1][1]);
      cum.add(t);
    }
    _cumMeters = cum;
    _totalMeters = t;
    if (_totalMeters < 1) _totalMeters = 1;
  }

  static double _haversineMeters(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    final p1 = lat1 * math.pi / 180;
    final p2 = lat2 * math.pi / 180;
    final dLat = (lat2 - lat1) * math.pi / 180;
    final dLon = (lon2 - lon1) * math.pi / 180;
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(p1) *
            math.cos(p2) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return _earthRadiusM * c;
  }

  static double _bearingDegrees(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    final phi1 = lat1 * math.pi / 180;
    final phi2 = lat2 * math.pi / 180;
    final dLon = (lon2 - lon1) * math.pi / 180;
    final y = math.sin(dLon) * math.cos(phi2);
    final x = math.cos(phi1) * math.sin(phi2) -
        math.sin(phi1) * math.cos(phi2) * math.cos(dLon);
    final theta = math.atan2(y, x);
    return (theta * 180 / math.pi + 360) % 360;
  }

  /// Position at distance [along] meters from start; heading = movement bearing.
  static List<double>? _interpolateAlong(double along) {
    final path = _path;
    final cum = _cumMeters;
    if (path == null || cum == null || path.length < 2) return null;

    if (along <= 0) {
      final a = path[0];
      final b = path[1];
      return [
        a[0],
        a[1],
        _bearingDegrees(a[0], a[1], b[0], b[1]),
      ];
    }
    if (along >= _totalMeters) {
      final a = path[path.length - 2];
      final b = path[path.length - 1];
      return [b[0], b[1], _bearingDegrees(a[0], a[1], b[0], b[1])];
    }

    int i = 0;
    while (i < cum.length - 1 && cum[i + 1] < along) {
      i++;
    }
    final segStart = cum[i];
    final segEnd = cum[i + 1];
    final segLen = segEnd - segStart;
    final t = segLen > 0 ? (along - segStart) / segLen : 0.0;
    final a = path[i];
    final b = path[i + 1];
    final lat = a[0] + (b[0] - a[0]) * t;
    final lng = a[1] + (b[1] - a[1]) * t;
    final h = _bearingDegrees(a[0], a[1], b[0], b[1]);
    return [lat, lng, h];
  }

  static Future<void> _tick(WidgetRef ref) async {
    final trip = ref.read(tripProvider).currentTrip;
    if (trip == null || !trip.isActive) {
      _cancelTimer();
      return;
    }

    if (_path == null || _cumMeters == null) {
      return;
    }

    final speedMps = _speedKmh / 3.6;
    final stepM = speedMps * AppConfig.locationUpdateInterval;
    _alongMeters += stepM;

    if (_alongMeters >= _totalMeters) {
      _alongMeters = 0;
    }

    final pos = _interpolateAlong(_alongMeters);
    if (pos == null) return;

    final lat = pos[0];
    final lng = pos[1];
    final heading = pos[2];

    final synthetic = Position(
      latitude: lat,
      longitude: lng,
      timestamp: DateTime.now(),
      accuracy: 10,
      altitude: 0,
      altitudeAccuracy: 0,
      heading: heading,
      headingAccuracy: 0,
      speed: speedMps,
      speedAccuracy: 0,
      isMocked: true,
    );
    await LocationServiceResolver.injectSimulatedGps(synthetic);
    debugPrint(
      '🧪 SIM vehicle (road) → ${lat.toStringAsFixed(6)}, ${lng.toStringAsFixed(6)} '
      'along ${_alongMeters.toStringAsFixed(0)}m / ${_totalMeters.toStringAsFixed(0)}m',
    );
    // Same throttled path as real GPS / background posts (interval, 15m, 429 backoff).
    unawaited(
      ref.read(tripProvider.notifier).postLiveLocationIfDue(synthetic),
    );
  }
}
