import 'dart:async';
import 'dart:math';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/foundation.dart';

class ImprovedLocationServiceV2 {
  StreamSubscription<Position>? _positionStreamSubscription;
  Position? _lastPosition;
  DateTime? _lastSuccessfulUpdate;
  int _consecutiveFailures = 0;
  int _retryCount = 0;
  bool _isCircuitOpen = false;
  Timer? _retryTimer;
  Timer? _healthCheckTimer;

  // Configuration
  static const int maxConsecutiveFailures = 3;
  static const int maxRetryCount = 5;
  static const Duration circuitBreakerResetDuration = Duration(minutes: 2);
  static const Duration healthCheckInterval = Duration(seconds: 30);

  // Adaptive timeouts
  Duration get _bestAccuracyTimeout => Duration(seconds: 8 + (_retryCount * 2));
  Duration get _lowAccuracyTimeout => Duration(seconds: 10 + (_retryCount * 2));
  Duration get _lowestAccuracyTimeout => Duration(seconds: 6 + (_retryCount));

  // Context-aware quality thresholds
  bool _isLikelyIndoors = false;

  final StreamController<Position> _positionController =
      StreamController<Position>.broadcast();

  Stream<Position> get positionStream => _positionController.stream;
  Position? get lastKnownPosition => _lastPosition;
  bool get isTracking => _positionStreamSubscription != null;

  /// Start location tracking with improved error handling
  Future<void> startTracking() async {
    if (isTracking) {
      debugPrint('📍 Already tracking location');
      return;
    }

    try {
      // Check permissions
      final permission = await _checkPermissions();
      if (!permission) {
        throw Exception('Location permissions not granted');
      }

      // Start health monitoring
      _startHealthCheck();

      // Attempt to get initial position
      await _getInitialPosition();

      // Start continuous tracking
      await _startPositionStream();

      debugPrint('✅ Location tracking started successfully');
    } catch (e) {
      debugPrint('❌ Failed to start tracking: $e');
      await _handleError(e);
    }
  }

  /// Stop location tracking and cleanup
  Future<void> stopTracking() async {
    debugPrint('🛑 Stopping location tracking');

    _retryTimer?.cancel();
    _retryTimer = null;

    _healthCheckTimer?.cancel();
    _healthCheckTimer = null;

    await _positionStreamSubscription?.cancel();
    _positionStreamSubscription = null;

    // Small delay to ensure cleanup
    await Future.delayed(Duration(milliseconds: 500));

    _consecutiveFailures = 0;
    _retryCount = 0;
    _isCircuitOpen = false;

    debugPrint('✅ Location tracking stopped');
  }

  /// Get initial position with fallback strategies
  Future<void> _getInitialPosition() async {
    debugPrint('🎯 Getting initial position...');

    try {
      // Try best accuracy first
      final position = await _tryGetPosition(LocationAccuracy.best);
      if (position != null) {
        _updatePosition(position);
        return;
      }
    } catch (e) {
      debugPrint('⚠️ Best accuracy failed: $e');
    }

    // Try degraded accuracy levels
    final accuracyLevels = [
      LocationAccuracy.high,
      LocationAccuracy.medium,
      LocationAccuracy.low,
      LocationAccuracy.lowest,
    ];

    for (final accuracy in accuracyLevels) {
      try {
        final position = await _tryGetPosition(accuracy);
        if (position != null) {
          _updatePosition(position);
          return;
        }
      } catch (e) {
        debugPrint('⚠️ ${accuracy.name} accuracy failed: $e');
      }
    }

    // Last resort: try cached location
    await _tryGetCachedPosition();

    // If still no position, try to get any available position with relaxed criteria
    if (_lastPosition == null) {
      debugPrint(
        '🆘 Emergency fallback: trying to get any available position...',
      );
      try {
        final emergencyPosition = await Geolocator.getLastKnownPosition();
        if (emergencyPosition != null) {
          debugPrint(
            '🆘 Using emergency position: ${emergencyPosition.accuracy}m accuracy',
          );
          _updatePositionDirectly(emergencyPosition);
          _isLikelyIndoors = emergencyPosition.accuracy > 80;
        }
      } catch (e) {
        debugPrint('❌ Emergency fallback failed: $e');
      }
    }
  }

  /// Try to get position at specific accuracy level
  Future<Position?> _tryGetPosition(
    LocationAccuracy accuracy, {
    Duration? timeout,
  }) async {
    final actualTimeout = timeout ?? _getTimeoutForAccuracy(accuracy);

    debugPrint(
      '🧠 Trying ${accuracy.name} accuracy (timeout: ${actualTimeout.inSeconds}s)...',
    );

    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: accuracy,
        timeLimit: actualTimeout,
      );

      final isAcceptable = _isLocationQualityAcceptable(position);

      debugPrint('🧠 Location quality check:');
      debugPrint('   Accuracy: ${accuracy.name}');
      debugPrint('   Precision: ${position.accuracy.toStringAsFixed(1)}m');
      debugPrint('   Age: ${_getPositionAge(position)}');
      debugPrint('   Acceptable: $isAcceptable');

      if (isAcceptable) {
        return position;
      } else {
        debugPrint('! Location quality not acceptable for ${accuracy.name}');
        return null;
      }
    } on TimeoutException catch (e) {
      debugPrint('⏰ ${accuracy.name} timeout: $e');
      return null;
    } catch (e) {
      debugPrint('❌ ${accuracy.name} error: $e');
      return null;
    }
  }

  /// Try to get cached/last known position
  Future<void> _tryGetCachedPosition() async {
    debugPrint('💾 Trying cached location...');

    try {
      final position = await Geolocator.getLastKnownPosition();

      if (position != null) {
        final age = DateTime.now().difference(position.timestamp);
        final isRecent = age.inMinutes < 5;

        debugPrint('💾 Cached location found:');
        debugPrint('   Age: ${age.inMinutes}m ${age.inSeconds % 60}s');
        debugPrint('   Accuracy: ${position.accuracy.toStringAsFixed(1)}m');

        // Accept cached location if it's recent or we're having issues
        if (isRecent || _consecutiveFailures > 0) {
          debugPrint(
            '✅ Using cached location (recent: $isRecent, failures: $_consecutiveFailures)',
          );
          // Force accept cached location without quality check
          _updatePositionDirectly(position);
          _isLikelyIndoors = position.accuracy > 80; // Adjust context awareness
        } else {
          debugPrint('⚠️ Cached location too old, not using');
        }
      } else {
        debugPrint('❌ No cached location available');
      }
    } catch (e) {
      debugPrint('❌ Failed to get cached location: $e');
    }
  }

  /// Start continuous position stream
  Future<void> _startPositionStream() async {
    if (_positionStreamSubscription != null) {
      await _positionStreamSubscription!.cancel();
      await Future.delayed(Duration(milliseconds: 500));
    }

    final settings = LocationSettings(
      accuracy: _isLikelyIndoors ? LocationAccuracy.low : LocationAccuracy.high,
      distanceFilter: 10, // Update every 10 meters
      timeLimit: Duration(seconds: 30),
    );

    debugPrint(
      '📡 Starting position stream (accuracy: ${settings.accuracy.name})',
    );

    _positionStreamSubscription =
        Geolocator.getPositionStream(locationSettings: settings).listen(
          _handlePositionUpdate,
          onError: _handleStreamError,
          cancelOnError: false,
        );
  }

  /// Handle position updates from stream
  void _handlePositionUpdate(Position position) {
    if (_isLocationQualityAcceptable(position)) {
      _updatePosition(position);
      _consecutiveFailures = 0;
      _retryCount = 0;

      if (_isCircuitOpen) {
        debugPrint('✅ Circuit breaker closed - location recovered');
        _isCircuitOpen = false;
      }
    } else {
      debugPrint('⚠️ Received low quality position, skipping update');
    }
  }

  /// Handle stream errors
  void _handleStreamError(dynamic error) {
    debugPrint('❌ Position stream error: $error');
    _handleError(error);
  }

  /// Update current position
  void _updatePosition(Position position) {
    _lastPosition = position;
    _lastSuccessfulUpdate = DateTime.now();
    _positionController.add(position);

    debugPrint(
      '📍 Position updated: ${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)} (±${position.accuracy.toStringAsFixed(1)}m)',
    );
  }

  /// Update position directly without quality check (for cached locations)
  void _updatePositionDirectly(Position position) {
    _lastPosition = position;
    _lastSuccessfulUpdate = DateTime.now();
    _positionController.add(position);
    _consecutiveFailures = 0;
    _retryCount = 0;
    _isCircuitOpen = false;

    debugPrint(
      '📍 Position updated directly: ${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)} (±${position.accuracy.toStringAsFixed(1)}m)',
    );
  }

  /// Check if location quality is acceptable
  bool _isLocationQualityAcceptable(Position position) {
    // Adaptive threshold based on context
    final accuracyThreshold = _isLikelyIndoors
        ? 150.0
        : 100.0; // Increased outdoor threshold
    final ageThreshold = _isLikelyIndoors
        ? Duration(minutes: 2)
        : Duration(minutes: 1);

    final age = DateTime.now().difference(position.timestamp);
    final isRecent = age < ageThreshold;
    final isAccurate = position.accuracy <= accuracyThreshold;

    debugPrint('🧠 Quality check details:');
    debugPrint(
      '   Accuracy: ${position.accuracy}m (threshold: ${accuracyThreshold}m)',
    );
    debugPrint(
      '   Age: ${age.inSeconds}s (threshold: ${ageThreshold.inSeconds}s)',
    );
    debugPrint('   Is recent: $isRecent');
    debugPrint('   Is accurate: $isAccurate');
    debugPrint('   Is likely indoors: $_isLikelyIndoors');
    debugPrint('   Consecutive failures: $_consecutiveFailures');

    // In desperation mode, accept any recent position
    if (_consecutiveFailures > 1 && isRecent) {
      debugPrint('✅ Accepting location in desperation mode');
      return true;
    }

    // Special case: if we have a 100m accuracy location and no better options, accept it
    if (isRecent && position.accuracy <= 100.0 && _consecutiveFailures > 0) {
      debugPrint('✅ Accepting 100m accuracy location as fallback');
      return true;
    }

    // Special case: if we have exactly 100m accuracy and it's recent, accept it
    if (isRecent && position.accuracy == 100.0) {
      debugPrint('✅ Accepting 100m accuracy location (exact match)');
      return true;
    }

    // Accept if recent and either accurate OR we're likely indoors
    final acceptable = isRecent && (isAccurate || _isLikelyIndoors);
    debugPrint('   Final decision: $acceptable');

    return acceptable;
  }

  /// Get timeout duration for accuracy level
  Duration _getTimeoutForAccuracy(LocationAccuracy accuracy) {
    switch (accuracy) {
      case LocationAccuracy.best:
      case LocationAccuracy.bestForNavigation:
        return _bestAccuracyTimeout;
      case LocationAccuracy.high:
      case LocationAccuracy.medium:
        return _lowAccuracyTimeout;
      case LocationAccuracy.low:
      case LocationAccuracy.lowest:
        return _lowestAccuracyTimeout;
      default:
        return Duration(seconds: 10);
    }
  }

  /// Handle errors with exponential backoff
  Future<void> _handleError(dynamic error) async {
    _consecutiveFailures++;

    debugPrint('⚠️ Error handled (consecutive: $_consecutiveFailures): $error');

    if (_consecutiveFailures >= maxConsecutiveFailures) {
      _openCircuitBreaker();
    }

    if (_retryCount < maxRetryCount && !_isCircuitOpen) {
      _scheduleRetry();
    } else {
      debugPrint(
        '❌ Max retries reached or circuit open, falling back to cached location',
      );
      await _tryGetCachedPosition();
    }
  }

  /// Schedule retry with exponential backoff
  void _scheduleRetry() {
    _retryTimer?.cancel();

    // Exponential backoff: 10s, 20s, 40s, 60s (max)
    final delaySeconds = min(10 * pow(2, _retryCount), 60).toInt();
    _retryCount++;

    debugPrint('⏰ Scheduling retry #$_retryCount in ${delaySeconds}s...');

    _retryTimer = Timer(Duration(seconds: delaySeconds), () async {
      debugPrint('🔄 Retry attempt #$_retryCount');
      await _getInitialPosition();

      // Restart stream if needed
      if (_positionStreamSubscription == null) {
        await _startPositionStream();
      }
    });
  }

  /// Open circuit breaker
  void _openCircuitBreaker() {
    if (_isCircuitOpen) return;

    _isCircuitOpen = true;
    debugPrint('🔒 Circuit breaker opened due to consecutive failures');

    // Auto-reset after duration
    Timer(circuitBreakerResetDuration, () {
      if (_isCircuitOpen) {
        debugPrint('🔓 Circuit breaker reset, attempting recovery...');
        _isCircuitOpen = false;
        _consecutiveFailures = 0;
        _retryCount = 0;
        _getInitialPosition();
      }
    });
  }

  /// Start periodic health checks
  void _startHealthCheck() {
    _healthCheckTimer?.cancel();

    _healthCheckTimer = Timer.periodic(healthCheckInterval, (timer) {
      final hasRecentPosition =
          _lastSuccessfulUpdate != null &&
          DateTime.now().difference(_lastSuccessfulUpdate!) <
              Duration(minutes: 2);

      debugPrint('🏥 Health check:');
      debugPrint('   Tracking: $isTracking');
      debugPrint('   Recent position: $hasRecentPosition');
      debugPrint('   Consecutive failures: $_consecutiveFailures');
      debugPrint('   Circuit open: $_isCircuitOpen');

      if (isTracking && !hasRecentPosition && !_isCircuitOpen) {
        debugPrint('⚠️ Tracking but no recent position - triggering recovery');
        _getInitialPosition();
      }
    });
  }

  /// Check and request permissions
  Future<bool> _checkPermissions() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      debugPrint('❌ Location services disabled');
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        debugPrint('❌ Location permissions denied');
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      debugPrint('❌ Location permissions permanently denied');
      return false;
    }

    return true;
  }

  /// Get human-readable position age
  String _getPositionAge(Position position) {
    final age = DateTime.now().difference(position.timestamp);
    if (age.inMinutes > 0) {
      return '${age.inMinutes}m ${age.inSeconds % 60}s old';
    }
    return '${age.inSeconds}s old';
  }

  /// Force accept a location (for emergency situations)
  void forceAcceptLocation(Position position) {
    debugPrint('🆘 Force accepting location: ${position.accuracy}m accuracy');
    _updatePositionDirectly(position);
  }

  /// Cleanup resources
  void dispose() {
    stopTracking();
    _positionController.close();
  }
}
