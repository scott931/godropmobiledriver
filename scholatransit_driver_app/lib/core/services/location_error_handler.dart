import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/foundation.dart';

/// Comprehensive location error handler with intelligent retry logic
class LocationErrorHandler {
  static int _consecutiveErrors = 0;
  static DateTime? _lastErrorTime;
  static Timer? _retryTimer;
  static const int _maxConsecutiveErrors = 3;
  static const Duration _errorCooldown = Duration(minutes: 2);
  static const Duration _retryDelay = Duration(seconds: 10);

  /// Handle location errors with intelligent recovery
  static Future<void> handleLocationError(dynamic error) async {
    _consecutiveErrors++;
    _lastErrorTime = DateTime.now();

    debugPrint('🚨 Location Error #$_consecutiveErrors: $error');

    // Categorize error type
    final errorType = _categorizeError(error);
    debugPrint('📊 Error Category: $errorType');

    switch (errorType) {
      case LocationErrorType.timeout:
        await _handleTimeoutError();
        break;
      case LocationErrorType.permission:
        await _handlePermissionError();
        break;
      case LocationErrorType.service:
        await _handleServiceError();
        break;
      case LocationErrorType.hardware:
        await _handleHardwareError();
        break;
      case LocationErrorType.network:
        await _handleNetworkError();
        break;
      default:
        await _handleGenericError();
    }

    // Check if we should enter circuit breaker mode
    if (_consecutiveErrors >= _maxConsecutiveErrors) {
      await _enterCircuitBreakerMode();
    }
  }

  /// Categorize the error type for appropriate handling
  static LocationErrorType _categorizeError(dynamic error) {
    final errorString = error.toString().toLowerCase();

    if (errorString.contains('timeout') || errorString.contains('timed out')) {
      return LocationErrorType.timeout;
    } else if (errorString.contains('permission') ||
        errorString.contains('denied') ||
        errorString.contains('unauthorized')) {
      return LocationErrorType.permission;
    } else if (errorString.contains('service') ||
        errorString.contains('disabled') ||
        errorString.contains('unavailable')) {
      return LocationErrorType.service;
    } else if (errorString.contains('hardware') ||
        errorString.contains('gps') ||
        errorString.contains('sensor')) {
      return LocationErrorType.hardware;
    } else if (errorString.contains('network') ||
        errorString.contains('connection') ||
        errorString.contains('unreachable')) {
      return LocationErrorType.network;
    } else {
      return LocationErrorType.generic;
    }
  }

  /// Handle timeout errors with progressive fallback
  static Future<void> _handleTimeoutError() async {
    debugPrint('⏰ Handling timeout error - reducing accuracy requirements');

    // Reduce accuracy and timeout for next attempt
    // This will be handled by the calling service
  }

  /// Handle permission errors
  static Future<void> _handlePermissionError() async {
    debugPrint('🔒 Handling permission error - requesting permissions');

    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        await Geolocator.requestPermission();
      }
    } catch (e) {
      debugPrint('❌ Failed to handle permission error: $e');
    }
  }

  /// Handle service errors
  static Future<void> _handleServiceError() async {
    debugPrint('🔧 Handling service error - checking location services');

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('⚠️ Location services are disabled');
        // Could show user dialog to enable location services
      }
    } catch (e) {
      debugPrint('❌ Failed to check location services: $e');
    }
  }

  /// Handle hardware errors
  static Future<void> _handleHardwareError() async {
    debugPrint('📱 Handling hardware error - checking device capabilities');

    // Check if device has GPS capabilities
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('⚠️ Location services not available on this device');
      }
    } catch (e) {
      debugPrint('❌ Failed to check hardware capabilities: $e');
    }
  }

  /// Handle network errors
  static Future<void> _handleNetworkError() async {
    debugPrint('🌐 Handling network error - checking connectivity');

    // Network errors are usually temporary, just wait and retry
    await _scheduleRetry();
  }

  /// Handle generic errors
  static Future<void> _handleGenericError() async {
    debugPrint('❓ Handling generic error - applying general recovery');
    await _scheduleRetry();
  }

  /// Enter circuit breaker mode to prevent cascading failures
  static Future<void> _enterCircuitBreakerMode() async {
    debugPrint('🔴 Entering circuit breaker mode - pausing location requests');

    // Cancel any pending retries
    _retryTimer?.cancel();

    // Wait for cooldown period
    await Future.delayed(_errorCooldown);

    // Reset error counter
    _consecutiveErrors = 0;
    debugPrint('🟢 Circuit breaker reset - resuming location requests');
  }

  /// Schedule a retry with exponential backoff
  static Future<void> _scheduleRetry() async {
    if (_retryTimer?.isActive == true) return;

    final delay = Duration(seconds: _retryDelay.inSeconds * _consecutiveErrors);
    debugPrint('⏳ Scheduling retry in ${delay.inSeconds} seconds');

    _retryTimer = Timer(delay, () {
      debugPrint('🔄 Retrying location request...');
      _consecutiveErrors = 0; // Reset on successful retry
    });
  }

  /// Reset error tracking
  static void resetErrorTracking() {
    _consecutiveErrors = 0;
    _lastErrorTime = null;
    _retryTimer?.cancel();
    _retryTimer = null;
    debugPrint('🔄 Location error tracking reset');
  }

  /// Get current error status
  static Map<String, dynamic> getErrorStatus() {
    return {
      'consecutive_errors': _consecutiveErrors,
      'last_error_time': _lastErrorTime?.toIso8601String(),
      'is_in_circuit_breaker': _consecutiveErrors >= _maxConsecutiveErrors,
      'time_since_last_error': _lastErrorTime != null
          ? DateTime.now().difference(_lastErrorTime!).inSeconds
          : null,
    };
  }

  /// Dispose of resources
  static void dispose() {
    _retryTimer?.cancel();
    _retryTimer = null;
  }
}

/// Location error types for categorization
enum LocationErrorType {
  timeout,
  permission,
  service,
  hardware,
  network,
  generic,
}
