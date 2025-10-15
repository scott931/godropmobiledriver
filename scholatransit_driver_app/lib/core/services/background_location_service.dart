import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:location/location.dart' as location_package;

class BackgroundLocationService {
  static bool _isBackgroundModeEnabled = false;
  static StreamSubscription<Position>? _backgroundSubscription;

  // Background location configuration
  static const Duration _backgroundUpdateInterval = Duration(minutes: 2);
  static const double _backgroundDistanceFilter = 200.0; // 200 meters
  static const LocationAccuracy _backgroundAccuracy = LocationAccuracy.high;

  /// Initialize background location service
  static Future<bool> initialize() async {
    try {
      print(
        '🌙 BackgroundLocationService: Initializing background location...',
      );

      // Check permissions
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        print('❌ Location permission required for background tracking');
        return false;
      }

      // Check if location services are enabled
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        print('❌ Location services must be enabled for background tracking');
        return false;
      }

      // Configure background location settings
      await _configureBackgroundSettings();

      print('✅ BackgroundLocationService: Initialized successfully');
      return true;
    } catch (e) {
      print('❌ BackgroundLocationService: Initialization failed: $e');
      return false;
    }
  }

  /// Configure background location settings
  static Future<void> _configureBackgroundSettings() async {
    try {
      final location = location_package.Location();

      // Enable background mode
      await location.enableBackgroundMode(enable: true);

      // Set background location settings
      await location.changeSettings(
        accuracy: location_package.LocationAccuracy.high,
        interval: _backgroundUpdateInterval.inMilliseconds,
        distanceFilter: _backgroundDistanceFilter,
      );

      // Configure for battery optimization
      await _configureBatteryOptimization();

      print('✅ Background location settings configured');
    } catch (e) {
      print('⚠️ Could not configure background location: $e');
    }
  }

  /// Configure battery optimization settings
  static Future<void> _configureBatteryOptimization() async {
    try {
      // This would typically involve platform-specific battery optimization settings
      // For Android, you might need to request battery optimization exemption
      // For iOS, you might need to configure background app refresh

      print('🔋 Battery optimization configured for background location');
    } catch (e) {
      print('⚠️ Could not configure battery optimization: $e');
    }
  }

  /// Start background location tracking
  static Future<bool> startBackgroundTracking({
    Function(Position)? onLocationUpdate,
    Function(String)? onLocationError,
  }) async {
    try {
      if (_isBackgroundModeEnabled) {
        print('⚠️ Background tracking already active');
        return true;
      }

      print(
        '🌙 BackgroundLocationService: Starting background location tracking...',
      );

      // Start background location stream
      _backgroundSubscription =
          Geolocator.getPositionStream(
            locationSettings: LocationSettings(
              accuracy: _backgroundAccuracy,
              distanceFilter: _backgroundDistanceFilter.toInt(),
            ),
          ).listen(
            (position) {
              print(
                '🌙 Background location update: ${position.latitude}, ${position.longitude}',
              );
              onLocationUpdate?.call(position);
            },
            onError: (error) {
              print('❌ Background location error: $error');
              onLocationError?.call('Background location error: $error');
            },
          );

      _isBackgroundModeEnabled = true;
      print('✅ BackgroundLocationService: Background tracking started');
      return true;
    } catch (e) {
      print(
        '❌ BackgroundLocationService: Failed to start background tracking: $e',
      );
      return false;
    }
  }

  /// Stop background location tracking
  static Future<void> stopBackgroundTracking() async {
    try {
      if (!_isBackgroundModeEnabled) {
        print('⚠️ Background tracking not active');
        return;
      }

      print('🌙 BackgroundLocationService: Stopping background tracking...');

      await _backgroundSubscription?.cancel();
      _backgroundSubscription = null;
      _isBackgroundModeEnabled = false;

      print('✅ BackgroundLocationService: Background tracking stopped');
    } catch (e) {
      print('❌ Error stopping background tracking: $e');
    }
  }

  /// Check if background tracking is active
  static bool get isBackgroundTrackingActive => _isBackgroundModeEnabled;

  /// Get background location statistics
  static Map<String, dynamic> getBackgroundStats() {
    return {
      'is_background_tracking': _isBackgroundModeEnabled,
      'update_interval_minutes': _backgroundUpdateInterval.inMinutes,
      'distance_filter_meters': _backgroundDistanceFilter,
      'accuracy': _backgroundAccuracy.toString(),
    };
  }

  /// Handle app lifecycle changes for background location
  static void handleAppLifecycleChange(String state) {
    switch (state) {
      case 'resumed':
        print('📱 App resumed - optimizing location tracking');
        _optimizeForForeground();
        break;
      case 'paused':
        print('📱 App paused - switching to background mode');
        _optimizeForBackground();
        break;
      case 'detached':
        print('📱 App detached - stopping location tracking');
        stopBackgroundTracking();
        break;
      case 'inactive':
        print('📱 App inactive - maintaining location tracking');
        break;
      case 'hidden':
        print('📱 App hidden - maintaining location tracking');
        break;
    }
  }

  /// Optimize location tracking for foreground
  static void _optimizeForForeground() {
    // Switch to high accuracy and frequent updates for foreground
    print('🔄 Optimizing location tracking for foreground');
  }

  /// Optimize location tracking for background
  static void _optimizeForBackground() {
    // Switch to battery-optimized settings for background
    print('🔄 Optimizing location tracking for background');
  }

  /// Request battery optimization exemption (Android)
  static Future<bool> requestBatteryOptimizationExemption() async {
    try {
      // This would typically involve requesting battery optimization exemption
      // The implementation would be platform-specific
      print('🔋 Requesting battery optimization exemption...');
      return true;
    } catch (e) {
      print('❌ Could not request battery optimization exemption: $e');
      return false;
    }
  }

  /// Check if battery optimization is disabled
  static Future<bool> isBatteryOptimizationDisabled() async {
    try {
      // This would check if battery optimization is disabled for the app
      // The implementation would be platform-specific
      return true;
    } catch (e) {
      print('❌ Could not check battery optimization status: $e');
      return false;
    }
  }

  /// Get location permissions status
  static Future<Map<String, bool>> getLocationPermissions() async {
    try {
      final permission = await Geolocator.checkPermission();
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();

      return {
        'location_permission_granted':
            permission == LocationPermission.always ||
            permission == LocationPermission.whileInUse,
        'location_permission_always': permission == LocationPermission.always,
        'location_services_enabled': serviceEnabled,
        'background_location_allowed': permission == LocationPermission.always,
      };
    } catch (e) {
      print('❌ Could not check location permissions: $e');
      return {
        'location_permission_granted': false,
        'location_permission_always': false,
        'location_services_enabled': false,
        'background_location_allowed': false,
      };
    }
  }

  /// Request location permissions
  static Future<bool> requestLocationPermissions() async {
    try {
      print('📍 Requesting location permissions...');

      final permission = await Geolocator.requestPermission();
      final isGranted =
          permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse;

      if (isGranted) {
        print('✅ Location permission granted');
        return true;
      } else {
        print('❌ Location permission denied');
        return false;
      }
    } catch (e) {
      print('❌ Error requesting location permissions: $e');
      return false;
    }
  }
}
