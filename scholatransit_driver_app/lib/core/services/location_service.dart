import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:permission_handler/permission_handler.dart';
import '../config/app_config.dart';

class LocationService {
  static StreamSubscription<Position>? _positionStream;
  static Position? _currentPosition;
  static final StreamController<Position> _locationController =
      StreamController<Position>.broadcast();

  static Stream<Position> get locationStream => _locationController.stream;
  static Position? get currentPosition => _currentPosition;

  static Future<void> init() async {
    await _requestLocationPermission();
    await _checkLocationSettings();
  }

  static Future<bool> _requestLocationPermission() async {
    final status = await Permission.locationWhenInUse.request();
    return status.isGranted;
  }

  static Future<bool> _checkLocationSettings() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return false;
    }

    final permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      final newPermission = await Geolocator.requestPermission();
      return newPermission == LocationPermission.whileInUse ||
          newPermission == LocationPermission.always;
    }

    return permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always;
  }

  static Future<Position?> getCurrentPosition() async {
    try {
      final hasPermission = await _checkLocationSettings();
      if (!hasPermission) {
        print('❌ Location permission not granted');
        return null;
      }

      // Progressive fallback strategy with optimized timeouts
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
          print('📍 Trying ${level['name']} accuracy location...');
          final position = await Geolocator.getCurrentPosition(
            desiredAccuracy: level['accuracy'] as LocationAccuracy,
            timeLimit: level['timeout'] as Duration,
          );
          _currentPosition = position;
          print('✅ Location obtained with ${level['name']} accuracy');
          return position;
        } catch (e) {
          print('❌ ${level['name']} accuracy failed: $e');
          // Continue to next accuracy level
        }
      }

      // If all accuracy levels fail, try with cached location
      print('⚠️ All accuracy levels failed, trying cached location...');
      try {
        final position = await Geolocator.getLastKnownPosition();
        if (position != null) {
          _currentPosition = position;
          print('✅ Using cached location');
          return position;
        }
      } catch (e) {
        print('❌ Cached location also failed: $e');
      }

      print('❌ All location methods failed');
      return null;
    } catch (e) {
      print('❌ Error getting current position: $e');
      return null;
    }
  }

  static Future<void> startLocationTracking() async {
    try {
      final hasPermission = await _checkLocationSettings();
      if (!hasPermission) {
        print('❌ Location permission not granted');
        return;
      }

      print('📍 Starting location tracking with optimized settings...');

      _positionStream =
          Geolocator.getPositionStream(
            locationSettings: LocationSettings(
              accuracy: LocationAccuracy
                  .low, // Use low accuracy for better reliability
              distanceFilter: AppConfig.locationAccuracyThreshold.toInt(),
              timeLimit: Duration(
                seconds: 4,
              ), // Shorter timeout for better responsiveness
            ),
          ).listen(
            (Position position) {
              _currentPosition = position;
              _locationController.add(position);
              print(
                '📍 Location update: ${position.latitude}, ${position.longitude} (accuracy: ${position.accuracy}m)',
              );
            },
            onError: (error) {
              print('❌ Location tracking error: $error');
              // Try to restart with lower accuracy if medium accuracy fails
              _restartLocationTrackingWithLowerAccuracy();
            },
          );

      print('✅ Location tracking started successfully');
    } catch (e) {
      print('❌ Error starting location tracking: $e');
    }
  }

  static Future<void> stopLocationTracking() async {
    await _positionStream?.cancel();
    _positionStream = null;
  }

  static Future<String?> getAddressFromCoordinates(
    double latitude,
    double longitude,
  ) async {
    try {
      final placemarks = await placemarkFromCoordinates(latitude, longitude);
      if (placemarks.isNotEmpty) {
        final placemark = placemarks.first;
        return '${placemark.street}, ${placemark.locality}, ${placemark.administrativeArea}';
      }
      return null;
    } catch (e) {
      print('Error getting address: $e');
      return null;
    }
  }

  static Future<Map<String, double>?> getCoordinatesFromAddress(
    String address,
  ) async {
    try {
      final locations = await locationFromAddress(address);
      if (locations.isNotEmpty) {
        final location = locations.first;
        return {'latitude': location.latitude, 'longitude': location.longitude};
      }
      return null;
    } catch (e) {
      print('Error getting coordinates: $e');
      return null;
    }
  }

  static double calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2);
  }

  static double calculateBearing(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    return Geolocator.bearingBetween(lat1, lon1, lat2, lon2);
  }

  static bool isLocationAccurate(Position position) {
    return position.accuracy <= AppConfig.locationAccuracyThreshold;
  }

  static Future<void> _restartLocationTrackingWithLowerAccuracy() async {
    try {
      print('🔄 Restarting location tracking with lower accuracy...');
      await stopLocationTracking();

      // Wait a moment before restarting to avoid conflicts
      await Future.delayed(Duration(milliseconds: 500));

      _positionStream =
          Geolocator.getPositionStream(
            locationSettings: LocationSettings(
              accuracy: LocationAccuracy.low, // Use low accuracy as fallback
              distanceFilter:
                  AppConfig.locationAccuracyThreshold.toInt() *
                  2, // Increase distance filter
              timeLimit: Duration(seconds: 10), // Shorter timeout for fallback
            ),
          ).listen(
            (Position position) {
              _currentPosition = position;
              _locationController.add(position);
              print(
                '📍 Fallback location update: ${position.latitude}, ${position.longitude} (accuracy: ${position.accuracy}m)',
              );
            },
            onError: (error) {
              print('❌ Location tracking error (low accuracy): $error');
              // Try one more time with lowest accuracy
              _restartLocationTrackingWithLowestAccuracy();
            },
          );

      print('✅ Location tracking restarted with lower accuracy');
    } catch (e) {
      print('❌ Error restarting location tracking: $e');
    }
  }

  static Future<void> _restartLocationTrackingWithLowestAccuracy() async {
    try {
      print('🔄 Restarting location tracking with lowest accuracy...');
      await stopLocationTracking();

      // Wait a moment before restarting
      await Future.delayed(Duration(milliseconds: 1000));

      _positionStream =
          Geolocator.getPositionStream(
            locationSettings: LocationSettings(
              accuracy: LocationAccuracy
                  .lowest, // Use lowest accuracy as final fallback
              distanceFilter:
                  AppConfig.locationAccuracyThreshold.toInt() *
                  3, // Even larger distance filter
              timeLimit: Duration(seconds: 8), // Even shorter timeout
            ),
          ).listen(
            (Position position) {
              _currentPosition = position;
              _locationController.add(position);
              print(
                '📍 Lowest accuracy location update: ${position.latitude}, ${position.longitude} (accuracy: ${position.accuracy}m)',
              );
            },
            onError: (error) {
              print('❌ Location tracking error (lowest accuracy): $error');
              print('❌ All location tracking methods have failed');
            },
          );

      print('✅ Location tracking restarted with lowest accuracy');
    } catch (e) {
      print('❌ Error restarting location tracking with lowest accuracy: $e');
    }
  }

  static Future<void> dispose() async {
    await stopLocationTracking();
    await _locationController.close();
  }
}
