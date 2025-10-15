import 'dart:async';
import 'package:geolocator/geolocator.dart';
import '../models/trip_model.dart';
import '../models/eta_model.dart';
import 'eta_service.dart';
import 'routing_service.dart';
import 'realtime_location_service.dart';

class RealtimeETAUpdater {
  static Timer? _etaUpdateTimer;
  static bool _isUpdating = false;
  static DateTime? _lastETAUpdate;
  static ETAInfo? _currentETA;
  static Trip? _currentTrip;

  // Throttling configuration
  static const Duration _minETAUpdateInterval = Duration(seconds: 15);
  static const Duration _maxETAUpdateInterval = Duration(minutes: 5);
  static const double _minDistanceForUpdate = 100.0; // 100 meters
  static const int _maxAPIRequestsPerMinute = 10;

  // API request tracking
  static final List<DateTime> _apiRequestTimes = [];
  static int _consecutiveFailures = 0;
  static const int _maxConsecutiveFailures = 3;

  // Callbacks
  static Function(ETAInfo)? _onETAUpdate;
  static Function(String)? _onETAError;
  static Function(ETAInfo)? _onSignificantETAChange;

  /// Start real-time ETA updates for a trip
  static Future<bool> startETAUpdates({
    required Trip trip,
    Function(ETAInfo)? onETAUpdate,
    Function(String)? onETAError,
    Function(ETAInfo)? onSignificantETAChange,
  }) async {
    try {
      if (_isUpdating) {
        print('⚠️ ETA updates already active');
        return true;
      }

      print(
        '🕐 RealtimeETAUpdater: Starting ETA updates for trip ${trip.tripId}',
      );

      // Validate trip has required coordinates
      if (trip.endLatitude == null || trip.endLongitude == null) {
        print('❌ Trip missing destination coordinates');
        _onETAError?.call('Trip missing destination coordinates');
        return false;
      }

      // Set current trip and callbacks
      _currentTrip = trip;
      _onETAUpdate = onETAUpdate;
      _onETAError = onETAError;
      _onSignificantETAChange = onSignificantETAChange;

      // Calculate initial ETA
      await _updateETA();

      // Start periodic ETA updates
      _startPeriodicUpdates();

      print('✅ RealtimeETAUpdater: ETA updates started');
      return true;
    } catch (e) {
      print('❌ RealtimeETAUpdater: Failed to start ETA updates: $e');
      _onETAError?.call('Failed to start ETA updates: $e');
      return false;
    }
  }

  /// Start periodic ETA updates with smart throttling
  static void _startPeriodicUpdates() {
    _etaUpdateTimer?.cancel();

    _etaUpdateTimer = Timer.periodic(_minETAUpdateInterval, (timer) async {
      if (_currentTrip != null && RealtimeLocationService.isTracking) {
        await _updateETA();
      }
    });
  }

  /// Update ETA with throttling and error handling
  static Future<void> _updateETA() async {
    try {
      if (_currentTrip == null) return;

      final currentPosition = RealtimeLocationService.currentPosition;
      if (currentPosition == null) {
        print('⚠️ No current position available for ETA update');
        return;
      }

      // Check throttling conditions
      if (!_shouldUpdateETA(currentPosition)) {
        print('🕐 Throttling ETA update');
        return;
      }

      // Check API rate limits
      if (!_checkAPIRateLimit()) {
        print('🕐 Rate limiting ETA update');
        return;
      }

      print('🕐 RealtimeETAUpdater: Updating ETA...');

      // Calculate ETA using enhanced service
      final etaResult = await ETAService.calculateETA(
        currentLat: currentPosition.latitude,
        currentLng: currentPosition.longitude,
        destinationLat: _currentTrip!.endLatitude!,
        destinationLng: _currentTrip!.endLongitude!,
        trip: _currentTrip!,
        routeName: _currentTrip!.routeName,
        vehicleType: 'School Bus',
      );

      if (etaResult.success) {
        final newETA = etaResult.etaInfo;

        // Check for significant ETA changes
        if (_currentETA != null) {
          final timeDifference = newETA.estimatedArrival.difference(
            _currentETA!.estimatedArrival,
          );
          final significantChange =
              timeDifference.abs().inMinutes >= 5; // 5 minutes threshold

          if (significantChange) {
            print(
              '🕐 Significant ETA change detected: ${timeDifference.inMinutes} minutes',
            );
            _onSignificantETAChange?.call(newETA);
          }
        }

        // Update current ETA
        _currentETA = newETA;
        _lastETAUpdate = DateTime.now();
        _consecutiveFailures = 0;

        // Record API request
        _apiRequestTimes.add(DateTime.now());
        _cleanupOldAPIRequests();

        print(
          '✅ ETA updated: ${newETA.formattedTimeToArrival} (${newETA.formattedDistance})',
        );

        // Notify callback
        _onETAUpdate?.call(newETA);
      } else {
        _handleETAError('ETA calculation failed: ${etaResult.error}');
      }
    } catch (e) {
      _handleETAError('Error updating ETA: $e');
    }
  }

  /// Check if ETA should be updated based on throttling rules
  static bool _shouldUpdateETA(Position currentPosition) {
    // Always update if no previous ETA
    if (_currentETA == null || _lastETAUpdate == null) return true;

    // Check time-based throttling
    final timeSinceLastUpdate = DateTime.now().difference(_lastETAUpdate!);
    if (timeSinceLastUpdate < _minETAUpdateInterval) return false;

    // Check distance-based throttling
    if (_currentETA!.distance > 0) {
      final distanceToDestination = Geolocator.distanceBetween(
        currentPosition.latitude,
        currentPosition.longitude,
        _currentTrip!.endLatitude!,
        _currentTrip!.endLongitude!,
      );

      // Update more frequently as we get closer
      final distanceThreshold = _getDistanceThreshold(distanceToDestination);
      if (distanceToDestination < distanceThreshold) return true;
    }

    // Force update if too much time has passed
    if (timeSinceLastUpdate > _maxETAUpdateInterval) return true;

    return false;
  }

  /// Get distance threshold based on proximity to destination
  static double _getDistanceThreshold(double distanceToDestination) {
    if (distanceToDestination < 1000) return 50; // 50m when < 1km
    if (distanceToDestination < 5000) return 100; // 100m when < 5km
    return _minDistanceForUpdate; // 100m for longer distances
  }

  /// Check API rate limits
  static bool _checkAPIRateLimit() {
    final now = DateTime.now();
    final oneMinuteAgo = now.subtract(Duration(minutes: 1));

    // Remove requests older than 1 minute
    _apiRequestTimes.removeWhere((time) => time.isBefore(oneMinuteAgo));

    // Check if we're within rate limit
    return _apiRequestTimes.length < _maxAPIRequestsPerMinute;
  }

  /// Clean up old API request times
  static void _cleanupOldAPIRequests() {
    final now = DateTime.now();
    final oneMinuteAgo = now.subtract(Duration(minutes: 1));
    _apiRequestTimes.removeWhere((time) => time.isBefore(oneMinuteAgo));
  }

  /// Handle ETA errors with exponential backoff
  static void _handleETAError(String error) {
    _consecutiveFailures++;
    print('❌ ETA update failed (attempt $_consecutiveFailures): $error');

    if (_consecutiveFailures >= _maxConsecutiveFailures) {
      print('❌ Too many consecutive ETA failures, stopping updates');
      stopETAUpdates();
    }

    _onETAError?.call(error);
  }

  /// Stop ETA updates
  static void stopETAUpdates() {
    try {
      print('🕐 RealtimeETAUpdater: Stopping ETA updates...');

      _etaUpdateTimer?.cancel();
      _etaUpdateTimer = null;
      _isUpdating = false;
      _currentTrip = null;
      _currentETA = null;
      _lastETAUpdate = null;
      _consecutiveFailures = 0;

      // Clear callbacks
      _onETAUpdate = null;
      _onETAError = null;
      _onSignificantETAChange = null;

      print('✅ RealtimeETAUpdater: ETA updates stopped');
    } catch (e) {
      print('❌ Error stopping ETA updates: $e');
    }
  }

  /// Get current ETA
  static ETAInfo? get currentETA => _currentETA;

  /// Get current trip
  static Trip? get currentTrip => _currentTrip;

  /// Check if ETA updates are active
  static bool get isUpdating => _isUpdating;

  /// Get last ETA update time
  static DateTime? get lastUpdateTime => _lastETAUpdate;

  /// Force immediate ETA update
  static Future<void> forceETAUpdate() async {
    if (_currentTrip != null && RealtimeLocationService.isTracking) {
      print('🕐 Forcing immediate ETA update...');
      await _updateETA();
    }
  }

  /// Get ETA update statistics
  static Map<String, dynamic> getETAStats() {
    return {
      'is_updating': _isUpdating,
      'current_trip_id': _currentTrip?.tripId,
      'last_update': _lastETAUpdate?.toIso8601String(),
      'consecutive_failures': _consecutiveFailures,
      'api_requests_last_minute': _apiRequestTimes.length,
      'current_eta': _currentETA != null
          ? {
              'estimated_arrival': _currentETA!.estimatedArrival
                  .toIso8601String(),
              'time_to_arrival': _currentETA!.formattedTimeToArrival,
              'distance': _currentETA!.formattedDistance,
              'is_delayed': _currentETA!.isDelayed,
              'arrival_duration': _currentETA!.formattedArrivalDuration,
            }
          : null,
    };
  }

  /// Get route information using Mapbox Directions API
  static Future<Map<String, dynamic>?> getRouteInfo() async {
    if (_currentTrip == null) return null;

    final currentPosition = RealtimeLocationService.currentPosition;
    if (currentPosition == null) return null;

    try {
      final routeInfo = await RoutingService.getRouteInfo(
        startLat: currentPosition.latitude,
        startLng: currentPosition.longitude,
        endLat: _currentTrip!.endLatitude!,
        endLng: _currentTrip!.endLongitude!,
      );

      if (routeInfo != null) {
        return {
          'distance_km': routeInfo.distance / 1000,
          'duration_minutes': routeInfo.duration / 60,
          'coordinates_count': routeInfo.coordinates.length,
          'route_geometry': routeInfo.coordinates,
        };
      }
    } catch (e) {
      print('❌ Error getting route info: $e');
    }

    return null;
  }
}
