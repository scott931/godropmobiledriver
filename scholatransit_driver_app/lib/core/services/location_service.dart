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
        throw Exception('Location permission not granted');
      }

      // Try with high accuracy first
      try {
        final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        );
        _currentPosition = position;
        return position;
      } catch (e) {
        print('High accuracy location failed, trying medium accuracy: $e');

        // Fallback to medium accuracy
        try {
          final position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.medium,
            timeLimit: Duration(seconds: 10),
          );
          _currentPosition = position;
          return position;
        } catch (e2) {
          print('Medium accuracy location failed, trying low accuracy: $e2');

          // Final fallback to low accuracy
          final position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.low,
            timeLimit: Duration(seconds: 5),
          );
          _currentPosition = position;
          return position;
        }
      }
    } catch (e) {
      print('Error getting current position: $e');
      return null;
    }
  }

  static Future<void> startLocationTracking() async {
    try {
      final hasPermission = await _checkLocationSettings();
      if (!hasPermission) {
        throw Exception('Location permission not granted');
      }

      _positionStream =
          Geolocator.getPositionStream(
            locationSettings: LocationSettings(
              accuracy: LocationAccuracy.medium, // Use medium accuracy for better reliability
              distanceFilter: AppConfig.locationAccuracyThreshold.toInt(),
              timeLimit: Duration(seconds: 20), // Reduced timeout for stream
            ),
          ).listen(
            (Position position) {
              _currentPosition = position;
              _locationController.add(position);
            },
            onError: (error) {
              print('Location tracking error: $error');
              // Try to restart with lower accuracy if high accuracy fails
              _restartLocationTrackingWithLowerAccuracy();
            },
          );
    } catch (e) {
      print('Error starting location tracking: $e');
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
      await stopLocationTracking();

      _positionStream =
          Geolocator.getPositionStream(
            locationSettings: LocationSettings(
              accuracy: LocationAccuracy.low, // Use low accuracy as fallback
              distanceFilter: AppConfig.locationAccuracyThreshold.toInt() * 2, // Increase distance filter
              timeLimit: Duration(seconds: 15),
            ),
          ).listen(
            (Position position) {
              _currentPosition = position;
              _locationController.add(position);
            },
            onError: (error) {
              print('Location tracking error (low accuracy): $error');
            },
          );
    } catch (e) {
      print('Error restarting location tracking: $e');
    }
  }

  static Future<void> dispose() async {
    await stopLocationTracking();
    await _locationController.close();
  }
}


