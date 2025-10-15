import 'dart:async';
import 'package:geolocator/geolocator.dart';
import '../models/trip_model.dart';
import 'location_service_resolver.dart';
import 'routing_service.dart';

class RealtimeDistanceTracker {
  static Timer? _distanceUpdateTimer;
  static bool _isTracking = false;
  static Trip? _currentTrip;
  static double? _totalTripDistance;
  static double? _remainingDistance;
  static double? _distanceTraveled;
  static List<Map<String, double>>? _routeCoordinates;
  static DateTime? _lastDistanceUpdate;

  // Throttling configuration
  static const Duration _minUpdateInterval = Duration(seconds: 5);
  static const double _minDistanceChange = 25.0; // 25 meters minimum change

  // Callbacks
  static Function(double, double, double)?
  _onDistanceUpdate; // remaining, traveled, total
  static Function(String)? _onDistanceError;
  static Function(double)? _onProgressUpdate; // progress percentage

  /// Start real-time distance tracking for a trip
  static Future<bool> startDistanceTracking({
    required Trip trip,
    Function(double, double, double)? onDistanceUpdate,
    Function(String)? onDistanceError,
    Function(double)? onProgressUpdate,
  }) async {
    try {
      if (_isTracking) {
        print('⚠️ Distance tracking already active');
        return true;
      }

      print(
        '📏 RealtimeDistanceTracker: Starting distance tracking for trip ${trip.tripId}',
      );

      // Validate trip has required coordinates
      if (trip.endLatitude == null || trip.endLongitude == null) {
        print('❌ Trip missing destination coordinates');
        _onDistanceError?.call('Trip missing destination coordinates');
        return false;
      }

      // Ensure location service is running
      if (!LocationServiceResolver.getServiceStatus()['is_tracking']) {
        print('⚠️ Location service not running, starting it...');
        final locationStarted = await LocationServiceResolver.startTracking(
          onLocationUpdate: _handleLocationUpdate,
          onLocationError: _handleLocationError,
        );

        if (!locationStarted) {
          print('❌ Failed to start location service for distance tracking');
          _onDistanceError?.call('Failed to start location service');
          return false;
        }
      }

      // Set current trip and callbacks
      _currentTrip = trip;
      _onDistanceUpdate = onDistanceUpdate;
      _onDistanceError = onDistanceError;
      _onProgressUpdate = onProgressUpdate;

      // Get initial route and distance
      await _calculateInitialDistance();

      // Start periodic distance updates
      _startPeriodicUpdates();

      _isTracking = true;
      print('✅ RealtimeDistanceTracker: Distance tracking started');
      return true;
    } catch (e) {
      print('❌ RealtimeDistanceTracker: Failed to start distance tracking: $e');
      _onDistanceError?.call('Failed to start distance tracking: $e');
      return false;
    }
  }

  /// Calculate initial route distance and coordinates
  static Future<void> _calculateInitialDistance() async {
    if (_currentTrip == null) return;

    try {
      final currentPosition =
          await LocationServiceResolver.getCurrentPosition();
      if (currentPosition == null) {
        print('⚠️ No current position available for distance calculation');
        return;
      }

      print('📏 Calculating initial route distance...');

      // Get route information from Mapbox
      final routeInfo = await RoutingService.getRouteInfo(
        startLat: currentPosition.latitude,
        startLng: currentPosition.longitude,
        endLat: _currentTrip!.endLatitude!,
        endLng: _currentTrip!.endLongitude!,
      );

      if (routeInfo != null) {
        _totalTripDistance = routeInfo.distance;
        _routeCoordinates = routeInfo.coordinates;
        _distanceTraveled = 0.0;
        _remainingDistance = _totalTripDistance;

        print(
          '✅ Route distance calculated: ${(_totalTripDistance! / 1000).toStringAsFixed(2)} km',
        );
        print('📊 Route coordinates: ${_routeCoordinates!.length} points');

        // Notify initial distance
        _onDistanceUpdate?.call(
          _remainingDistance!,
          _distanceTraveled!,
          _totalTripDistance!,
        );
        _onProgressUpdate?.call(0.0); // 0% progress initially
      } else {
        print(
          '⚠️ Could not get route information, using straight-line distance',
        );
        await _calculateStraightLineDistance();
      }
    } catch (e) {
      print('❌ Error calculating initial distance: $e');
      await _calculateStraightLineDistance();
    }
  }

  /// Calculate straight-line distance as fallback
  static Future<void> _calculateStraightLineDistance() async {
    final currentPosition = await LocationServiceResolver.getCurrentPosition();
    if (currentPosition == null || _currentTrip == null) return;

    _totalTripDistance = Geolocator.distanceBetween(
      currentPosition.latitude,
      currentPosition.longitude,
      _currentTrip!.endLatitude!,
      _currentTrip!.endLongitude!,
    );

    _distanceTraveled = 0.0;
    _remainingDistance = _totalTripDistance;

    print(
      '📏 Using straight-line distance: ${(_totalTripDistance! / 1000).toStringAsFixed(2)} km',
    );

    _onDistanceUpdate?.call(
      _remainingDistance!,
      _distanceTraveled!,
      _totalTripDistance!,
    );
    _onProgressUpdate?.call(0.0);
  }

  /// Start periodic distance updates
  static void _startPeriodicUpdates() {
    _distanceUpdateTimer?.cancel();

    _distanceUpdateTimer = Timer.periodic(_minUpdateInterval, (timer) async {
      if (_currentTrip != null &&
          LocationServiceResolver.getServiceStatus()['is_tracking']) {
        await _updateDistance();
      }
    });

    // Also listen to location updates directly for immediate updates
    _listenToLocationUpdates();
  }

  /// Listen to location updates for immediate distance recalculation
  static void _listenToLocationUpdates() {
    // This will be called whenever location updates
    // We'll trigger distance updates on significant location changes
    print(
      '📏 DistanceTracker: Listening to location updates for immediate distance recalculation',
    );
  }

  /// Handle location updates from the location service
  static void _handleLocationUpdate(Position position) {
    if (!_isTracking || _currentTrip == null) return;

    print(
      '📏 DistanceTracker: Location update received, recalculating distance...',
    );

    // Force immediate distance update on location change
    _updateDistance();
  }

  /// Handle location errors
  static void _handleLocationError(String error) {
    print('❌ DistanceTracker: Location error: $error');
    _onDistanceError?.call('Location error: $error');
  }

  /// Update distance based on current location
  static Future<void> _updateDistance() async {
    try {
      if (_currentTrip == null) return;

      final currentPosition =
          await LocationServiceResolver.getCurrentPosition();
      if (currentPosition == null) {
        print('⚠️ No current position available for distance update');
        return;
      }

      // Check throttling conditions
      if (!_shouldUpdateDistance(currentPosition)) {
        return;
      }

      print('📏 Updating distance calculation...');

      // Calculate remaining distance to destination
      final newRemainingDistance = Geolocator.distanceBetween(
        currentPosition.latitude,
        currentPosition.longitude,
        _currentTrip!.endLatitude!,
        _currentTrip!.endLongitude!,
      );

      // Calculate distance traveled
      final newDistanceTraveled = _totalTripDistance != null
          ? _totalTripDistance! - newRemainingDistance
          : 0.0;

      // Check for significant changes
      if (_remainingDistance != null) {
        final distanceChange = (_remainingDistance! - newRemainingDistance)
            .abs();
        if (distanceChange < _minDistanceChange) {
          print(
            '📏 Throttling distance update (insufficient change: ${distanceChange.toStringAsFixed(1)}m)',
          );
          return;
        }
      }

      // Update distances
      _remainingDistance = newRemainingDistance;
      _distanceTraveled = newDistanceTraveled;
      _lastDistanceUpdate = DateTime.now();

      // Calculate progress percentage
      final progressPercentage =
          _totalTripDistance != null && _totalTripDistance! > 0
          ? (_distanceTraveled! / _totalTripDistance! * 100).clamp(0.0, 100.0)
          : 0.0;

      print('📏 Distance updated:');
      print(
        '  Remaining: ${(_remainingDistance! / 1000).toStringAsFixed(2)} km',
      );
      print('  Traveled: ${(_distanceTraveled! / 1000).toStringAsFixed(2)} km');
      print('  Progress: ${progressPercentage.toStringAsFixed(1)}%');

      // Notify callbacks
      _onDistanceUpdate?.call(
        _remainingDistance!,
        _distanceTraveled!,
        _totalTripDistance ?? 0.0,
      );
      _onProgressUpdate?.call(progressPercentage);
    } catch (e) {
      print('❌ Error updating distance: $e');
      _onDistanceError?.call('Error updating distance: $e');
    }
  }

  /// Check if distance should be updated based on throttling rules
  static bool _shouldUpdateDistance(Position currentPosition) {
    // Always update if no previous distance
    if (_remainingDistance == null || _lastDistanceUpdate == null) return true;

    // Check time-based throttling
    final timeSinceLastUpdate = DateTime.now().difference(_lastDistanceUpdate!);
    if (timeSinceLastUpdate < _minUpdateInterval) return false;

    return true;
  }

  /// Stop distance tracking
  static void stopDistanceTracking() {
    try {
      print('📏 RealtimeDistanceTracker: Stopping distance tracking...');

      _distanceUpdateTimer?.cancel();
      _distanceUpdateTimer = null;
      _isTracking = false;
      _currentTrip = null;
      _totalTripDistance = null;
      _remainingDistance = null;
      _distanceTraveled = null;
      _routeCoordinates = null;
      _lastDistanceUpdate = null;

      // Clear callbacks
      _onDistanceUpdate = null;
      _onDistanceError = null;
      _onProgressUpdate = null;

      print('✅ RealtimeDistanceTracker: Distance tracking stopped');
    } catch (e) {
      print('❌ Error stopping distance tracking: $e');
    }
  }

  /// Get current distance information
  static Map<String, dynamic> getDistanceInfo() {
    return {
      'is_tracking': _isTracking,
      'current_trip_id': _currentTrip?.tripId,
      'total_distance_m': _totalTripDistance,
      'remaining_distance_m': _remainingDistance,
      'distance_traveled_m': _distanceTraveled,
      'progress_percentage':
          _totalTripDistance != null && _totalTripDistance! > 0
          ? (_distanceTraveled! / _totalTripDistance! * 100).clamp(0.0, 100.0)
          : 0.0,
      'last_update': _lastDistanceUpdate?.toIso8601String(),
      'route_coordinates_count': _routeCoordinates?.length ?? 0,
    };
  }

  /// Get formatted distance strings
  static Map<String, String> getFormattedDistances() {
    return {
      'total_distance': _totalTripDistance != null
          ? '${(_totalTripDistance! / 1000).toStringAsFixed(2)} km'
          : 'Unknown',
      'remaining_distance': _remainingDistance != null
          ? '${(_remainingDistance! / 1000).toStringAsFixed(2)} km'
          : 'Unknown',
      'distance_traveled': _distanceTraveled != null
          ? '${(_distanceTraveled! / 1000).toStringAsFixed(2)} km'
          : 'Unknown',
      'progress_percentage':
          _totalTripDistance != null && _totalTripDistance! > 0
          ? '${((_distanceTraveled! / _totalTripDistance! * 100).clamp(0.0, 100.0)).toStringAsFixed(1)}%'
          : '0.0%',
    };
  }

  /// Get current trip
  static Trip? get currentTrip => _currentTrip;

  /// Get remaining distance
  static double? get remainingDistance => _remainingDistance;

  /// Get distance traveled
  static double? get distanceTraveled => _distanceTraveled;

  /// Get total trip distance
  static double? get totalTripDistance => _totalTripDistance;

  /// Get progress percentage
  static double get progressPercentage {
    if (_totalTripDistance == null || _totalTripDistance! <= 0) return 0.0;
    return (_distanceTraveled! / _totalTripDistance! * 100).clamp(0.0, 100.0);
  }

  /// Check if tracking is active
  static bool get isTracking => _isTracking;

  /// Get last update time
  static DateTime? get lastUpdateTime => _lastDistanceUpdate;

  /// Force immediate distance update
  static Future<void> forceDistanceUpdate() async {
    if (_currentTrip != null &&
        LocationServiceResolver.getServiceStatus()['is_tracking']) {
      print('📏 Forcing immediate distance update...');
      await _updateDistance();
    } else {
      print(
        '⚠️ Cannot force distance update - trip: ${_currentTrip != null}, location tracking: ${LocationServiceResolver.getServiceStatus()['is_tracking']}',
      );
    }
  }

  /// Get current tracking status for debugging
  static Future<Map<String, dynamic>> getTrackingStatus() async {
    return {
      'distance_tracking_active': _isTracking,
      'current_trip_id': _currentTrip?.tripId,
      'location_tracking_active':
          LocationServiceResolver.getServiceStatus()['is_tracking'],
      'current_position_available':
          await LocationServiceResolver.getCurrentPosition() != null,
      'last_distance_update': _lastDistanceUpdate?.toIso8601String(),
      'remaining_distance_m': _remainingDistance,
      'distance_traveled_m': _distanceTraveled,
      'total_trip_distance_m': _totalTripDistance,
    };
  }

  /// Get route coordinates for map display
  static List<Map<String, double>>? get routeCoordinates => _routeCoordinates;

  /// Get remaining route coordinates based on current progress
  static Future<List<Map<String, double>>?>
  getRemainingRouteCoordinates() async {
    if (_routeCoordinates == null || _routeCoordinates!.isEmpty) return null;

    final currentPosition = await LocationServiceResolver.getCurrentPosition();
    if (currentPosition == null) return _routeCoordinates;

    // Find the closest point on the route to current position
    double minDistance = double.infinity;
    int closestIndex = 0;

    for (int i = 0; i < _routeCoordinates!.length; i++) {
      final point = _routeCoordinates![i];
      final distance = Geolocator.distanceBetween(
        currentPosition.latitude,
        currentPosition.longitude,
        point['latitude']!,
        point['longitude']!,
      );

      if (distance < minDistance) {
        minDistance = distance;
        closestIndex = i;
      }
    }

    // Return route coordinates from closest point to end
    return _routeCoordinates!.skip(closestIndex).toList();
  }

  /// Get current position along the route (0.0 to 1.0)
  static Future<double> getCurrentRouteProgress() async {
    if (_routeCoordinates == null || _routeCoordinates!.isEmpty) return 0.0;

    final currentPosition = await LocationServiceResolver.getCurrentPosition();
    if (currentPosition == null) return 0.0;

    // Find the closest point on the route
    double minDistance = double.infinity;
    int closestIndex = 0;

    for (int i = 0; i < _routeCoordinates!.length; i++) {
      final point = _routeCoordinates![i];
      final distance = Geolocator.distanceBetween(
        currentPosition.latitude,
        currentPosition.longitude,
        point['latitude']!,
        point['longitude']!,
      );

      if (distance < minDistance) {
        minDistance = distance;
        closestIndex = i;
      }
    }

    // Return progress as a percentage of route completion
    return (closestIndex / (_routeCoordinates!.length - 1)).clamp(0.0, 1.0);
  }

  /// Calculate distance to next waypoint (if route has multiple points)
  static Future<double?> getDistanceToNextWaypoint() async {
    if (_routeCoordinates == null || _routeCoordinates!.isEmpty) return null;

    final currentPosition = await LocationServiceResolver.getCurrentPosition();
    if (currentPosition == null) return null;

    // Find the closest point on the route
    double minDistance = double.infinity;
    int closestIndex = 0;

    for (int i = 0; i < _routeCoordinates!.length; i++) {
      final point = _routeCoordinates![i];
      final distance = Geolocator.distanceBetween(
        currentPosition.latitude,
        currentPosition.longitude,
        point['latitude']!,
        point['longitude']!,
      );

      if (distance < minDistance) {
        minDistance = distance;
        closestIndex = i;
      }
    }

    // Calculate distance to next waypoint
    if (closestIndex < _routeCoordinates!.length - 1) {
      final nextPoint = _routeCoordinates![closestIndex + 1];
      return Geolocator.distanceBetween(
        currentPosition.latitude,
        currentPosition.longitude,
        nextPoint['latitude']!,
        nextPoint['longitude']!,
      );
    }

    return null;
  }
}
