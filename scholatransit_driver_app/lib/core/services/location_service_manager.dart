import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'improved_location_service.dart';

/// Location Service Manager to prevent conflicts between multiple location services
class LocationServiceManager {
  static bool _isInitialized = false;
  static String? _activeService;
  static Timer? _healthCheckTimer;
  static int _timeoutCount = 0;
  static const int _maxTimeoutCount = 3;

  /// Initialize the location service manager
  static Future<bool> initialize() async {
    try {
      print('🔧 LocationServiceManager: Initializing...');

      if (_isInitialized) {
        print('⚠️ LocationServiceManager already initialized');
        return true;
      }

      // Initialize the improved location service
      final initialized = await ImprovedLocationService.initialize();
      if (!initialized) {
        print('❌ Failed to initialize location service');
        return false;
      }

      _isInitialized = true;
      _activeService = 'ImprovedLocationService';

      // Start health check timer
      _startHealthCheck();

      print('✅ LocationServiceManager: Initialized successfully');
      return true;
    } catch (e) {
      print('❌ LocationServiceManager: Initialization failed: $e');
      return false;
    }
  }

  /// Start location tracking with conflict prevention
  static Future<bool> startTracking({
    Function(Position)? onLocationUpdate,
    Function(String)? onLocationError,
  }) async {
    try {
      print('🔧 LocationServiceManager: Starting location tracking...');

      // Check if already tracking
      if (ImprovedLocationService.isTracking) {
        print('⚠️ Location tracking already active');
        return true;
      }

      // Start tracking with the improved service
      final started = await ImprovedLocationService.startTracking(
        onLocationUpdate: (position) {
          _timeoutCount = 0; // Reset timeout count on successful update
          onLocationUpdate?.call(position);
        },
        onLocationError: (error) {
          _handleLocationError(error);
          onLocationError?.call(error);
        },
      );

      if (started) {
        print('✅ LocationServiceManager: Tracking started successfully');
        return true;
      } else {
        print('❌ LocationServiceManager: Failed to start tracking');
        return false;
      }
    } catch (e) {
      print('❌ LocationServiceManager: Error starting tracking: $e');
      return false;
    }
  }

  /// Stop location tracking
  static Future<void> stopTracking() async {
    try {
      print('🔧 LocationServiceManager: Stopping location tracking...');

      await ImprovedLocationService.stopTracking();
      _activeService = null;

      // Stop health check timer
      _healthCheckTimer?.cancel();
      _healthCheckTimer = null;

      print('✅ LocationServiceManager: Tracking stopped');
    } catch (e) {
      print('❌ LocationServiceManager: Error stopping tracking: $e');
    }
  }

  /// Handle location errors with intelligent recovery
  static void _handleLocationError(String error) {
    print('🔧 LocationServiceManager: Handling location error: $error');

    if (error.contains('TimeoutException')) {
      _timeoutCount++;
      print(
        '🔧 LocationServiceManager: Timeout count: $_timeoutCount/$_maxTimeoutCount',
      );

      if (_timeoutCount >= _maxTimeoutCount) {
        print(
          '🔧 LocationServiceManager: Too many timeouts, attempting recovery...',
        );
        _attemptRecovery();
      }
    }
  }

  /// Attempt to recover from location issues
  static void _attemptRecovery() async {
    try {
      print('🔧 LocationServiceManager: Attempting recovery...');

      // Stop current tracking
      await stopTracking();

      // Wait before restarting
      await Future.delayed(Duration(seconds: 3));

      // Reset timeout count
      _timeoutCount = 0;

      // Try to restart
      final restarted = await startTracking();
      if (restarted) {
        print('✅ LocationServiceManager: Recovery successful');
      } else {
        print('❌ LocationServiceManager: Recovery failed');
      }
    } catch (e) {
      print('❌ LocationServiceManager: Recovery error: $e');
    }
  }

  /// Start health check timer
  static void _startHealthCheck() {
    _healthCheckTimer = Timer.periodic(Duration(seconds: 30), (timer) {
      _performHealthCheck();
    });
  }

  /// Perform health check on location service
  static void _performHealthCheck() {
    try {
      final isTracking = ImprovedLocationService.isTracking;
      final hasPosition = ImprovedLocationService.currentPosition != null;

      print(
        '🔧 LocationServiceManager: Health check - Tracking: $isTracking, Position: $hasPosition',
      );

      if (isTracking && !hasPosition) {
        print(
          '⚠️ LocationServiceManager: Tracking but no position - potential issue',
        );
        _timeoutCount++;

        if (_timeoutCount >= _maxTimeoutCount) {
          print('🔧 LocationServiceManager: Health check triggered recovery');
          _attemptRecovery();
        }
      }
    } catch (e) {
      print('❌ LocationServiceManager: Health check error: $e');
    }
  }

  /// Get current position with fallback
  static Future<Position?> getCurrentPosition() async {
    try {
      // Try to get position from active service
      if (ImprovedLocationService.isTracking) {
        final position = ImprovedLocationService.currentPosition;
        if (position != null) {
          return position;
        }
      }

      // Fallback to direct position request
      return await ImprovedLocationService.getCurrentPosition();
    } catch (e) {
      print('❌ LocationServiceManager: Error getting current position: $e');
      return null;
    }
  }

  /// Get service status
  static Map<String, dynamic> getServiceStatus() {
    return {
      'is_initialized': _isInitialized,
      'active_service': _activeService,
      'is_tracking': ImprovedLocationService.isTracking,
      'has_position': ImprovedLocationService.currentPosition != null,
      'timeout_count': _timeoutCount,
      'max_timeout_count': _maxTimeoutCount,
    };
  }

  /// Dispose of resources
  static Future<void> dispose() async {
    try {
      print('🔧 LocationServiceManager: Disposing...');

      await stopTracking();
      await ImprovedLocationService.dispose();

      _isInitialized = false;
      _activeService = null;
      _timeoutCount = 0;

      print('✅ LocationServiceManager: Disposed');
    } catch (e) {
      print('❌ LocationServiceManager: Error disposing: $e');
    }
  }
}
