import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:location/location.dart' as location_package;

class RealtimeLocationService {
  static StreamSubscription<Position>? _locationSubscription;
  static Position? _currentPosition;
  static DateTime? _lastLocationUpdate;
  static bool _isTracking = false;
  static final List<Position> _locationHistory = [];
  static const int _maxHistorySize = 50;

  // Throttling configuration
  static const Duration _minUpdateInterval = Duration(seconds: 10);
  static const double _minDistanceMeters = 50.0; // 50 meters minimum distance

  // Background location configuration
  static const double _backgroundDistanceFilter =
      100.0; // 100 meters for background

  // Callbacks
  static Function(Position)? _onLocationUpdate;
  static Function(String)? _onLocationError;
  static Function(Position)? _onSignificantLocationChange;

  /// Initialize the location service with proper permissions
  static Future<bool> initialize() async {
    try {
      print('📍 RealtimeLocationService: Initializing location service...');

      // Check location permissions
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        final requestPermission = await Geolocator.requestPermission();
        if (requestPermission == LocationPermission.denied) {
          print('❌ Location permission denied');
          return false;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        print('❌ Location permission permanently denied');
        return false;
      }

      // Check if location services are enabled
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        print('❌ Location services are disabled');
        return false;
      }

      // Configure location settings
      await _configureLocationSettings();

      print('✅ RealtimeLocationService: Initialized successfully');
      return true;
    } catch (e) {
      print('❌ RealtimeLocationService: Initialization failed: $e');
      return false;
    }
  }

  /// Configure location settings for optimal performance
  static Future<void> _configureLocationSettings() async {
    try {
      // Configure location package for background mode
      final location = location_package.Location();

      // Enable background mode
      await location.enableBackgroundMode(enable: true);

      // Set location settings
      await location.changeSettings(
        accuracy: location_package.LocationAccuracy.high,
        interval: _minUpdateInterval.inMilliseconds,
        distanceFilter: _minDistanceMeters,
      );

      print('✅ Location settings configured for background mode');
    } catch (e) {
      print('⚠️ Could not configure background location: $e');
    }
  }

  /// Start real-time location tracking
  static Future<bool> startTracking({
    Function(Position)? onLocationUpdate,
    Function(String)? onLocationError,
    Function(Position)? onSignificantLocationChange,
  }) async {
    try {
      if (_isTracking) {
        print('⚠️ Location tracking already active');
        return true;
      }

      print('📍 RealtimeLocationService: Starting location tracking...');

      // Set callbacks
      _onLocationUpdate = onLocationUpdate;
      _onLocationError = onLocationError;
      _onSignificantLocationChange = onSignificantLocationChange;

      // Get initial position with progressive fallback
      Position? initialPosition;
      try {
        initialPosition = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 8),
        );
        print('✅ Initial position obtained with high accuracy');
      } catch (e) {
        print('⚠️ High accuracy failed, trying medium accuracy: $e');
        try {
          initialPosition = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.medium,
            timeLimit: Duration(seconds: 6),
          );
          print('✅ Initial position obtained with medium accuracy');
        } catch (e2) {
          print('⚠️ Medium accuracy failed, trying low accuracy: $e2');
          try {
            initialPosition = await Geolocator.getCurrentPosition(
              desiredAccuracy: LocationAccuracy.low,
              timeLimit: Duration(seconds: 4),
            );
            print('✅ Initial position obtained with low accuracy');
          } catch (e3) {
            print('❌ All accuracy levels failed for initial position: $e3');
            // Try cached location as last resort
            initialPosition = await Geolocator.getLastKnownPosition();
            if (initialPosition != null) {
              print('✅ Using cached location for initial position');
            } else {
              print('❌ No cached location available');
              throw Exception('Could not obtain initial position');
            }
          }
        }
      }

      _currentPosition = initialPosition;
      _lastLocationUpdate = DateTime.now();
      _addToHistory(initialPosition);

      // Start location stream with optimized settings
      _locationSubscription = Geolocator.getPositionStream(
        locationSettings: LocationSettings(
          accuracy: LocationAccuracy
              .medium, // Use medium accuracy for better reliability
          distanceFilter: _minDistanceMeters.toInt(),
          timeLimit: Duration(seconds: 10), // Add timeout to prevent hanging
        ),
      ).listen(_handleLocationUpdate, onError: _handleLocationError);

      _isTracking = true;
      print('✅ RealtimeLocationService: Location tracking started');
      return true;
    } catch (e) {
      print('❌ RealtimeLocationService: Failed to start tracking: $e');
      _onLocationError?.call('Failed to start location tracking: $e');
      return false;
    }
  }

  /// Handle location updates with throttling
  static void _handleLocationUpdate(Position position) {
    try {
      final now = DateTime.now();

      // Check if enough time has passed since last update
      if (_lastLocationUpdate != null) {
        final timeSinceLastUpdate = now.difference(_lastLocationUpdate!);
        if (timeSinceLastUpdate < _minUpdateInterval) {
          print('📍 Throttling location update (too frequent)');
          return;
        }
      }

      // Check if significant distance change
      if (_currentPosition != null) {
        final distance = Geolocator.distanceBetween(
          _currentPosition!.latitude,
          _currentPosition!.longitude,
          position.latitude,
          position.longitude,
        );

        if (distance < _minDistanceMeters) {
          print(
            '📍 Throttling location update (insufficient distance: ${distance.toStringAsFixed(1)}m)',
          );
          return;
        }

        // Check for significant location change
        if (distance > _backgroundDistanceFilter) {
          print(
            '📍 Significant location change detected: ${distance.toStringAsFixed(1)}m',
          );
          _onSignificantLocationChange?.call(position);
        }
      }

      // Update current position
      _currentPosition = position;
      _lastLocationUpdate = now;
      _addToHistory(position);

      print(
        '📍 Location updated: ${position.latitude}, ${position.longitude} (accuracy: ${position.accuracy}m)',
      );

      // Notify callback
      _onLocationUpdate?.call(position);
    } catch (e) {
      print('❌ Error handling location update: $e');
      _onLocationError?.call('Error processing location update: $e');
    }
  }

  /// Handle location errors with recovery strategies
  static void _handleLocationError(dynamic error) {
    print('❌ Location error: $error');
    _onLocationError?.call('Location error: $error');

    // Try to recover from timeout errors
    if (error.toString().contains('TimeoutException')) {
      print('🔄 Attempting to recover from timeout error...');
      _attemptLocationRecovery();
    }
  }

  /// Attempt to recover from location errors
  static void _attemptLocationRecovery() async {
    try {
      print('🔄 Attempting location recovery...');

      // Stop current tracking
      await _locationSubscription?.cancel();
      _locationSubscription = null;
      _isTracking = false;

      // Wait a moment before restarting
      await Future.delayed(Duration(milliseconds: 1000));

      // Try to restart with lower accuracy
      print('🔄 Restarting with lower accuracy...');
      _locationSubscription = Geolocator.getPositionStream(
        locationSettings: LocationSettings(
          accuracy: LocationAccuracy.low, // Use lower accuracy for recovery
          distanceFilter: (_minDistanceMeters * 2)
              .toInt(), // Increase distance filter
          timeLimit: Duration(seconds: 8), // Shorter timeout
        ),
      ).listen(_handleLocationUpdate, onError: _handleLocationError);

      _isTracking = true;
      print('✅ Location recovery successful');
    } catch (e) {
      print('❌ Location recovery failed: $e');
    }
  }

  /// Add position to history with size limit
  static void _addToHistory(Position position) {
    _locationHistory.add(position);
    if (_locationHistory.length > _maxHistorySize) {
      _locationHistory.removeAt(0);
    }
  }

  /// Stop location tracking
  static Future<void> stopTracking() async {
    try {
      if (!_isTracking) {
        print('⚠️ Location tracking not active');
        return;
      }

      print('📍 RealtimeLocationService: Stopping location tracking...');

      await _locationSubscription?.cancel();
      _locationSubscription = null;
      _isTracking = false;

      // Clear callbacks
      _onLocationUpdate = null;
      _onLocationError = null;
      _onSignificantLocationChange = null;

      print('✅ RealtimeLocationService: Location tracking stopped');
    } catch (e) {
      print('❌ Error stopping location tracking: $e');
    }
  }

  /// Get current position
  static Position? get currentPosition => _currentPosition;

  /// Get location history
  static List<Position> get locationHistory =>
      List.unmodifiable(_locationHistory);

  /// Check if tracking is active
  static bool get isTracking => _isTracking;

  /// Get last update time
  static DateTime? get lastUpdateTime => _lastLocationUpdate;

  /// Calculate current speed from recent positions
  static double? getCurrentSpeed() {
    if (_locationHistory.length < 2) return null;

    try {
      final recent = _locationHistory.length >= 2
          ? _locationHistory.sublist(_locationHistory.length - 2)
          : _locationHistory;
      final distance = Geolocator.distanceBetween(
        recent[0].latitude,
        recent[0].longitude,
        recent[1].latitude,
        recent[1].longitude,
      );

      final timeDiff = recent[1].timestamp.difference(recent[0].timestamp);
      if (timeDiff.inSeconds == 0) return null;

      final speedMs = distance / timeDiff.inSeconds;
      final speedKmh = speedMs * 3.6;

      // Filter unrealistic speeds
      if (speedKmh > 200 || speedKmh < 0) return null;

      return speedKmh;
    } catch (e) {
      print('❌ Error calculating speed: $e');
      return null;
    }
  }

  /// Get distance traveled
  static double getDistanceTraveled() {
    if (_locationHistory.length < 2) return 0.0;

    double totalDistance = 0.0;
    for (int i = 1; i < _locationHistory.length; i++) {
      final distance = Geolocator.distanceBetween(
        _locationHistory[i - 1].latitude,
        _locationHistory[i - 1].longitude,
        _locationHistory[i].latitude,
        _locationHistory[i].longitude,
      );
      totalDistance += distance;
    }

    return totalDistance;
  }

  /// Clear location history
  static void clearHistory() {
    _locationHistory.clear();
    print('📍 Location history cleared');
  }

  /// Get location statistics
  static Map<String, dynamic> getLocationStats() {
    return {
      'is_tracking': _isTracking,
      'current_position': _currentPosition != null
          ? {
              'latitude': _currentPosition!.latitude,
              'longitude': _currentPosition!.longitude,
              'accuracy': _currentPosition!.accuracy,
              'timestamp': _currentPosition!.timestamp.toIso8601String(),
            }
          : null,
      'last_update': _lastLocationUpdate?.toIso8601String(),
      'history_size': _locationHistory.length,
      'current_speed_kmh': getCurrentSpeed(),
      'distance_traveled_m': getDistanceTraveled(),
      'tracking_duration': _lastLocationUpdate != null
          ? DateTime.now().difference(_lastLocationUpdate!).inMinutes
          : 0,
    };
  }
}
