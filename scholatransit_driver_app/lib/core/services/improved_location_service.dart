import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:location/location.dart' as location_package;

/// Improved location service with better timeout handling and conflict resolution
class ImprovedLocationService {
  static StreamSubscription<Position>? _positionStream;
  static Position? _currentPosition;
  static bool _isTracking = false;
  static final StreamController<Position> _locationController =
      StreamController<Position>.broadcast();

  // Configuration - Optimized for better reliability
  static const Duration _defaultTimeout = Duration(seconds: 5);
  static const Duration _fallbackTimeout = Duration(seconds: 3);
  static const Duration _lowestTimeout = Duration(seconds: 2);
  static const double _defaultDistanceFilter =
      30.0; // Reduced for more frequent updates
  static const double _fallbackDistanceFilter = 50.0;
  // Callbacks
  static Function(Position)? _onLocationUpdate;
  static Function(String)? _onLocationError;

  static Stream<Position> get locationStream => _locationController.stream;
  static Position? get currentPosition => _currentPosition;
  static bool get isTracking => _isTracking;

  /// Initialize the location service
  static Future<bool> initialize() async {
    try {
      print('📍 ImprovedLocationService: Initializing...');

      // Check permissions
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

      // Configure location package for background mode
      await _configureLocationPackage();

      print('✅ ImprovedLocationService: Initialized successfully');
      return true;
    } catch (e) {
      print('❌ ImprovedLocationService: Initialization failed: $e');
      return false;
    }
  }

  /// Configure location package settings
  static Future<void> _configureLocationPackage() async {
    try {
      final location = location_package.Location();

      // Enable background mode
      await location.enableBackgroundMode(enable: true);

      // Set location settings
      await location.changeSettings(
        accuracy: location_package.LocationAccuracy.high,
        interval: 10000, // 10 seconds
        distanceFilter: _defaultDistanceFilter,
      );

      print('✅ Location package configured');
    } catch (e) {
      print('⚠️ Could not configure location package: $e');
    }
  }

  /// Get current position with progressive fallback
  static Future<Position?> getCurrentPosition() async {
    try {
      print('📍 Getting current position...');

      // Progressive fallback strategy with faster timeouts
      final accuracyLevels = [
        {
          'accuracy': LocationAccuracy
              .medium, // Start with medium for better reliability
          'timeout': Duration(seconds: 3),
          'name': 'medium',
        },
        {
          'accuracy': LocationAccuracy.low,
          'timeout': Duration(seconds: 2),
          'name': 'low',
        },
        {
          'accuracy': LocationAccuracy.lowest,
          'timeout': Duration(seconds: 1),
          'name': 'lowest',
        },
      ];

      for (final level in accuracyLevels) {
        try {
          print('📍 Trying ${level['name']} accuracy...');
          final position = await Geolocator.getCurrentPosition(
            desiredAccuracy: level['accuracy'] as LocationAccuracy,
            timeLimit: level['timeout'] as Duration,
          );
          _currentPosition = position;
          print('✅ Position obtained with ${level['name']} accuracy');
          return position;
        } catch (e) {
          print('❌ ${level['name']} accuracy failed: $e');
          // Continue to next accuracy level
        }
      }

      // Try cached location as last resort
      print('⚠️ All accuracy levels failed, trying cached location...');
      try {
        final position = await Geolocator.getLastKnownPosition();
        if (position != null) {
          _currentPosition = position;
          print('✅ Using cached location');
          return position;
        }
      } catch (e) {
        print('❌ Cached location failed: $e');
      }

      print('❌ All location methods failed');
      return null;
    } catch (e) {
      print('❌ Error getting current position: $e');
      return null;
    }
  }

  /// Start location tracking with optimized settings
  static Future<bool> startTracking({
    Function(Position)? onLocationUpdate,
    Function(String)? onLocationError,
  }) async {
    try {
      if (_isTracking) {
        print('⚠️ Location tracking already active');
        return true;
      }

      print('📍 Starting location tracking...');

      // Set callbacks
      _onLocationUpdate = onLocationUpdate;
      _onLocationError = onLocationError;

      // Get initial position
      final initialPosition = await getCurrentPosition();
      if (initialPosition != null) {
        _onLocationUpdate?.call(initialPosition);
      }

      // Start location stream with optimized settings
      _positionStream = Geolocator.getPositionStream(
        locationSettings: LocationSettings(
          accuracy:
              LocationAccuracy.low, // Use low accuracy for better reliability
          distanceFilter: _defaultDistanceFilter.toInt(),
          timeLimit: Duration(seconds: 4), // Shorter timeout for stream
        ),
      ).listen(_handleLocationUpdate, onError: _handleLocationError);

      _isTracking = true;
      print('✅ Location tracking started');
      return true;
    } catch (e) {
      print('❌ Failed to start location tracking: $e');
      _onLocationError?.call('Failed to start location tracking: $e');
      return false;
    }
  }

  /// Handle location updates
  static void _handleLocationUpdate(Position position) {
    try {
      _currentPosition = position;
      _locationController.add(position);
      _onLocationUpdate?.call(position);

      print(
        '📍 Location update: ${position.latitude}, ${position.longitude} (accuracy: ${position.accuracy}m)',
      );
    } catch (e) {
      print('❌ Error handling location update: $e');
      _onLocationError?.call('Error processing location update: $e');
    }
  }

  /// Handle location errors with recovery
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

      // Stop current tracking completely
      await _positionStream?.cancel();
      _positionStream = null;
      _isTracking = false;

      // Wait longer before restarting to avoid conflicts
      await Future.delayed(Duration(milliseconds: 2000));

      // Try to get a fresh position first
      final freshPosition = await getCurrentPosition();
      if (freshPosition != null) {
        _onLocationUpdate?.call(freshPosition);
      }

      // Restart with lowest accuracy for maximum reliability
      print('🔄 Restarting with lowest accuracy...');
      _positionStream = Geolocator.getPositionStream(
        locationSettings: LocationSettings(
          accuracy: LocationAccuracy.lowest, // Use lowest accuracy for recovery
          distanceFilter: (_fallbackDistanceFilter * 2)
              .toInt(), // Larger distance filter
          timeLimit: Duration(seconds: 2), // Very short timeout
        ),
      ).listen(_handleLocationUpdate, onError: _handleLocationError);

      _isTracking = true;
      print('✅ Location recovery successful');
    } catch (e) {
      print('❌ Location recovery failed: $e');
      // Try one more time with cached location
      try {
        final cachedPosition = await Geolocator.getLastKnownPosition();
        if (cachedPosition != null) {
          _currentPosition = cachedPosition;
          _onLocationUpdate?.call(cachedPosition);
          print('✅ Using cached location as fallback');
        }
      } catch (e2) {
        print('❌ Cached location also failed: $e2');
      }
    }
  }

  /// Stop location tracking
  static Future<void> stopTracking() async {
    try {
      print('📍 Stopping location tracking...');

      await _positionStream?.cancel();
      _positionStream = null;
      _isTracking = false;

      print('✅ Location tracking stopped');
    } catch (e) {
      print('❌ Error stopping location tracking: $e');
    }
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
              'timestamp': _currentPosition!.timestamp,
            }
          : null,
      'stream_active': _positionStream != null,
    };
  }

  /// Dispose of resources
  static Future<void> dispose() async {
    await stopTracking();
    await _locationController.close();
  }
}
