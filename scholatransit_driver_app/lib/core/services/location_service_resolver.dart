import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'smart_location_manager.dart';
import 'stream_first_location_service.dart';

/// Location Service Resolver - Prevents conflicts between multiple location services
class LocationServiceResolver {
  static final LocationServiceResolver _instance =
      LocationServiceResolver._internal();
  factory LocationServiceResolver() => _instance;
  LocationServiceResolver._internal();

  static bool _isInitialized = false;
  static bool _isResolving = false;
  static StreamFirstLocationService? _streamFirstService;

  /// Initialize the location service resolver
  /// This ensures only ONE location service is active at a time
  static Future<bool> initialize() async {
    if (_isInitialized) return true;
    if (_isResolving) return false;

    _isResolving = true;
    print('🔧 LocationServiceResolver: Initializing...');

    try {
      // Force stop any existing location services to prevent conflicts
      await _forceStopAllServices();

      // Initialize StreamFirstLocationService as the primary service
      _streamFirstService = StreamFirstLocationService();
      await _streamFirstService!.startTracking();

      _isInitialized = true;
      print(
        '✅ LocationServiceResolver: Initialized with StreamFirstLocationService',
      );
      return true;
    } catch (e) {
      print('❌ LocationServiceResolver: Initialization failed: $e');
      return false;
    } finally {
      _isResolving = false;
    }
  }

  /// Force stop all location services (including old ones)
  static Future<void> _forceStopAllServices() async {
    print(
      '🛑 LocationServiceResolver: Force stopping all location services...',
    );

    try {
      // Stop StreamFirstLocationService
      if (_streamFirstService != null) {
        await _streamFirstService!.stopTracking();
        _streamFirstService!.dispose();
        _streamFirstService = null;
        print('✅ Force stopped StreamFirstLocationService');
      }
    } catch (e) {
      print('⚠️ Error force stopping StreamFirstLocationService: $e');
    }

    try {
      // Stop SmartLocationManager
      await SmartLocationManager.stopTracking();
      await SmartLocationManager.dispose();
      print('✅ Force stopped SmartLocationManager');
    } catch (e) {
      print('⚠️ Error force stopping SmartLocationManager: $e');
    }

    // Wait a bit to ensure cleanup
    await Future.delayed(Duration(milliseconds: 1000));
  }

  /// Stop all location services to prevent conflicts
  static Future<void> _stopAllLocationServices() async {
    print('🛑 LocationServiceResolver: Stopping all location services...');

    try {
      // Stop StreamFirstLocationService
      if (_streamFirstService != null) {
        await _streamFirstService!.stopTracking();
        _streamFirstService = null;
        print('✅ Stopped StreamFirstLocationService');
      }
    } catch (e) {
      print('⚠️ Error stopping StreamFirstLocationService: $e');
    }

    try {
      // Stop SmartLocationManager as backup
      await SmartLocationManager.stopTracking();
      print('✅ Stopped SmartLocationManager');
    } catch (e) {
      print('⚠️ Error stopping SmartLocationManager: $e');
    }

    // Note: We don't stop LocationService or LocationProvider here
    // as they might be used by other parts of the app
    // The key is to ensure ImprovedLocationServiceV2 is the primary service
  }

  /// Start location tracking with conflict resolution
  static Future<bool> startTracking({
    Function(Position)? onLocationUpdate,
    Function(String)? onLocationError,
    Function(String)? onUserGuidance,
  }) async {
    if (!_isInitialized) {
      print(
        '⚠️ LocationServiceResolver: Not initialized, initializing first...',
      );
      final initialized = await initialize();
      if (!initialized) return false;
    }

    print('🔧 LocationServiceResolver: Starting location tracking...');

    // Keep the active GPS stream when already running (avoids dropping map/provider listeners).
    if (_streamFirstService != null && _streamFirstService!.isTracking) {
      if (onLocationUpdate != null) {
        _streamFirstService!.positionStream.listen(onLocationUpdate);
      }
      return true;
    }

    // Stop any existing tracking to prevent conflicts
    await _stopAllLocationServices();

    // Start StreamFirstLocationService
    try {
      _streamFirstService = StreamFirstLocationService();
      await _streamFirstService!.startTracking();

      // Set up callbacks if provided
      if (onLocationUpdate != null) {
        _streamFirstService!.positionStream.listen(onLocationUpdate);
      }

      return true;
    } catch (e) {
      print('❌ Failed to start StreamFirstLocationService: $e');
      return false;
    }
  }

  /// Stop location tracking
  static Future<void> stopTracking() async {
    print('🔧 LocationServiceResolver: Stopping location tracking...');
    await _stopAllLocationServices();
  }

  /// Get current position with conflict resolution
  static Future<Position?> getCurrentPosition() async {
    if (!_isInitialized) {
      print(
        '⚠️ LocationServiceResolver: Not initialized, initializing first...',
      );
      final initialized = await initialize();
      if (!initialized) return null;
    }

    if (_streamFirstService != null) {
      return await _streamFirstService!.getFreshPosition();
    }

    // Fallback to SmartLocationManager
    return await SmartLocationManager.getCurrentPosition();
  }

  /// Get service status
  static Map<String, dynamic> getServiceStatus() {
    if (!_isInitialized) {
      return {
        'is_initialized': false,
        'is_tracking': false,
        'has_position': false,
        'error': 'LocationServiceResolver not initialized',
      };
    }

    if (_streamFirstService != null) {
      return {
        'is_initialized': true,
        'is_tracking': _streamFirstService!.isTracking,
        'has_position': _streamFirstService!.lastKnownPosition != null,
        'service_type': 'StreamFirstLocationService',
        'last_position': _streamFirstService!.lastKnownPosition,
      };
    }

    // Fallback to SmartLocationManager status
    final status = SmartLocationManager.getServiceStatus();
    status['is_initialized'] = true;
    status['service_type'] = 'SmartLocationManager';
    return status;
  }

  /// Listen to GPS fixes without restarting the underlying stream.
  /// Use when `getServiceStatus()['is_tracking']` is already true (e.g. after `initialize`)
  /// so the map still receives emulator / `adb emu geo fix` updates.
  static StreamSubscription<Position>? subscribeToPositionUpdates(
    void Function(Position position) onData,
  ) {
    if (_streamFirstService == null || !_streamFirstService!.isTracking) {
      print(
        '⚠️ LocationServiceResolver.subscribeToPositionUpdates: stream not ready',
      );
      return null;
    }
    return _streamFirstService!.positionStream.listen(onData);
  }

  /// Force accept a location (for emergency situations)
  static void forceAcceptLocation(Position position) {
    if (_streamFirstService != null) {
      _streamFirstService!.forceAcceptLocation(position);
    }
  }

  /// Pushes a fix into the shared position stream so MapScreen moves the puck
  /// without real GPS. Starts tracking if needed (requires location permission).
  static Future<void> injectSimulatedGps(Position position) async {
    if (!_isInitialized || _streamFirstService == null) {
      final ok = await initialize();
      if (!ok || _streamFirstService == null) {
        print(
          '⚠️ LocationServiceResolver.injectSimulatedGps: could not start stream',
        );
        return;
      }
    }
    _streamFirstService!.forceAcceptLocation(position);
  }

  /// Force restart location service (for debugging)
  static Future<void> forceRestart() async {
    print('🔄 LocationServiceResolver: Force restarting...');
    _isInitialized = false;
    await _forceStopAllServices();
    await initialize();
  }

  /// Dispose of resources
  static Future<void> dispose() async {
    print('🔧 LocationServiceResolver: Disposing...');
    await _stopAllLocationServices();

    if (_streamFirstService != null) {
      _streamFirstService!.dispose();
      _streamFirstService = null;
    }

    await SmartLocationManager.dispose();
    _isInitialized = false;
  }

  /// Check for location service conflicts
  static Future<Map<String, dynamic>> checkConflicts() async {
    print('🔍 LocationServiceResolver: Checking for conflicts...');

    final conflicts = <String>[];
    final recommendations = <String>[];

    // Check if primary service is running
    final status = getServiceStatus();
    if (status['is_tracking'] == true) {
      print('✅ ${status['service_type']} is running');
    } else {
      conflicts.add('${status['service_type']} not running');
      recommendations.add('Start location service for tracking');
    }

    // Check location permissions
    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        conflicts.add('Location permission denied');
        recommendations.add('Request location permission');
      } else if (permission == LocationPermission.deniedForever) {
        conflicts.add('Location permission permanently denied');
        recommendations.add('Enable location permission in device settings');
      }
    } catch (e) {
      conflicts.add('Error checking location permission: $e');
    }

    // Check if location services are enabled
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        conflicts.add('Location services disabled');
        recommendations.add('Enable location services in device settings');
      }
    } catch (e) {
      conflicts.add('Error checking location services: $e');
    }

    return {
      'conflicts': conflicts,
      'recommendations': recommendations,
      'has_conflicts': conflicts.isNotEmpty,
      'service_status': status,
    };
  }
}
