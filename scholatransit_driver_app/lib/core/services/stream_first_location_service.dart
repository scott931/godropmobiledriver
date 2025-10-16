import 'dart:async';
import 'dart:math';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/foundation.dart';
import 'location_error_handler.dart';

/// Stream-first location service with quality scoring and hysteresis
/// This approach prioritizes responsiveness over strict accuracy
class StreamFirstLocationService {
  StreamSubscription<Position>? _positionStreamSubscription;
  Position? _lastPosition;
  DateTime? _lastSuccessfulUpdate;
  Timer? _upgradeTimer;
  Timer? _healthCheckTimer;

  // Configuration
  static const Duration _warmupTimeout = Duration(seconds: 30);
  static const Duration _upgradeInterval = Duration(seconds: 15);
  static const Duration _healthCheckInterval = Duration(seconds: 30);
  static const Duration _maxStaleAge = Duration(minutes: 2);

  // Quality scoring weights
  static const double _accuracyWeight = 0.4;
  static const double _ageWeight = 0.3;
  static const double _movementWeight = 0.3;

  // Hysteresis thresholds
  static const double _acceptThreshold = 0.3; // Always accept above this
  static const double _upgradeThreshold = 0.7; // Only upgrade above this
  static const double _hysteresisDelta = 0.1; // Prevent oscillation

  final StreamController<Position> _positionController =
      StreamController<Position>.broadcast();

  Stream<Position> get positionStream => _positionController.stream;
  Position? get lastKnownPosition => _lastPosition;
  bool get isTracking => _positionStreamSubscription != null;

  /// Start location tracking with stream-first approach
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

      // Start with relaxed stream settings for immediate response
      // Reduced timeout to prevent the 5-second timeout issue
      await _startPositionStream();

      // Try to get a quick initial position
      await _getInitialPosition();

      // Start periodic upgrade attempts
      _startUpgradeTimer();

      debugPrint('✅ Stream-first location tracking started');
    } catch (e) {
      debugPrint('❌ Failed to start tracking: $e');
      await _handleError(e);
    }
  }

  /// Stop location tracking
  Future<void> stopTracking() async {
    debugPrint('🛑 Stopping location tracking');

    _upgradeTimer?.cancel();
    _upgradeTimer = null;

    _healthCheckTimer?.cancel();
    _healthCheckTimer = null;

    await _positionStreamSubscription?.cancel();
    _positionStreamSubscription = null;

    // Small delay to ensure cleanup
    await Future.delayed(Duration(milliseconds: 500));

    debugPrint('✅ Location tracking stopped');
  }

  /// Start position stream with relaxed settings for immediate response
  Future<void> _startPositionStream() async {
    if (_positionStreamSubscription != null) {
      await _positionStreamSubscription!.cancel();
      await Future.delayed(Duration(milliseconds: 500));
    }

    final settings = LocationSettings(
      accuracy: LocationAccuracy.low, // Start with low for immediate response
      distanceFilter: 10, // Update every 10 meters
      timeLimit: _warmupTimeout,
    );

    debugPrint('📡 Starting position stream (warmup mode)');

    _positionStreamSubscription =
        Geolocator.getPositionStream(locationSettings: settings).listen(
          _handlePositionUpdate,
          onError: (error) async {
            await LocationErrorHandler.handleLocationError(error);
            _handleStreamError(error);
          },
          cancelOnError: false,
        );
  }

  /// Get initial position with quick fallback
  Future<void> _getInitialPosition() async {
    debugPrint('🎯 Getting initial position...');

    try {
      // Try quick position with relaxed settings
      // Reduced timeout to prevent the 5-second timeout issue
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.low,
        timeLimit: Duration(seconds: 3), // Reduced from 8 to 3 seconds
      );

      _updatePosition(position);
      return;
    } catch (e) {
      debugPrint('⚠️ Quick position failed: $e');
    }

    // Fallback to cached location
    await _tryGetCachedPosition();
  }

  /// Try to get cached location
  Future<void> _tryGetCachedPosition() async {
    debugPrint('💾 Trying cached location...');

    try {
      final position = await Geolocator.getLastKnownPosition();

      if (position != null) {
        final age = DateTime.now().difference(position.timestamp);
        debugPrint(
          '💾 Cached location: ${age.inMinutes}m old, ${position.accuracy}m accuracy',
        );

        // Accept any recent cached location
        if (age < _maxStaleAge) {
          debugPrint('✅ Using cached location');
          _updatePosition(position);
        } else {
          debugPrint('⚠️ Cached location too old');
        }
      } else {
        debugPrint('❌ No cached location available');
      }
    } catch (e) {
      debugPrint('❌ Failed to get cached location: $e');
    }
  }

  /// Handle position updates with quality scoring
  void _handlePositionUpdate(Position position) {
    final score = _calculateQualityScore(position);
    final shouldAccept = _shouldAcceptPosition(position, score);

    debugPrint('🧠 Position quality score: ${score.toStringAsFixed(2)}');
    debugPrint('   Accuracy: ${position.accuracy}m');
    debugPrint('   Age: ${_getPositionAge(position)}');
    debugPrint('   Should accept: $shouldAccept');

    if (shouldAccept) {
      _updatePosition(position);
      // Reset error tracking on successful position update
      LocationErrorHandler.resetErrorTracking();
    } else {
      debugPrint('⚠️ Position rejected by quality score');
    }
  }

  /// Calculate quality score (0.0 to 1.0)
  double _calculateQualityScore(Position position) {
    final age = DateTime.now().difference(position.timestamp);
    final ageScore = max(
      0.0,
      1.0 - (age.inSeconds / 60.0),
    ); // 1.0 for 0s, 0.0 for 60s+

    final accuracyScore = max(
      0.0,
      1.0 - (position.accuracy / 200.0),
    ); // 1.0 for 0m, 0.0 for 200m+

    double movementScore = 1.0;
    if (_lastPosition != null) {
      final distance = Geolocator.distanceBetween(
        _lastPosition!.latitude,
        _lastPosition!.longitude,
        position.latitude,
        position.longitude,
      );
      movementScore = min(1.0, distance / 50.0); // 1.0 for 50m+ movement
    }

    final score =
        (ageScore * _ageWeight) +
        (accuracyScore * _accuracyWeight) +
        (movementScore * _movementWeight);

    return score.clamp(0.0, 1.0);
  }

  /// Determine if position should be accepted (with hysteresis)
  bool _shouldAcceptPosition(Position position, double score) {
    // Always accept if score is above accept threshold
    if (score >= _acceptThreshold) {
      return true;
    }

    // Hysteresis: only accept if significantly better than last
    if (_lastPosition != null) {
      final lastScore = _calculateQualityScore(_lastPosition!);
      if (score > lastScore + _hysteresisDelta) {
        return true;
      }
    }

    // Accept if we have no position and it's recent
    if (_lastPosition == null && score > 0.1) {
      return true;
    }

    return false;
  }

  /// Start periodic upgrade attempts
  void _startUpgradeTimer() {
    _upgradeTimer?.cancel();

    _upgradeTimer = Timer.periodic(_upgradeInterval, (timer) async {
      if (!isTracking) return;

      debugPrint('🔄 Attempting position upgrade...');

      try {
        final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 5),
        );

        final score = _calculateQualityScore(position);
        if (score > _upgradeThreshold) {
          debugPrint('✅ Position upgraded: ${position.accuracy}m accuracy');
          _updatePosition(position);

          // Tighten stream settings after successful upgrade
          await _tightenStreamSettings();
        }
      } catch (e) {
        debugPrint('⚠️ Position upgrade failed: $e');
      }
    });
  }

  /// Tighten stream settings after successful upgrade
  Future<void> _tightenStreamSettings() async {
    if (_positionStreamSubscription == null) return;

    debugPrint('🔧 Tightening stream settings...');

    await _positionStreamSubscription!.cancel();
    await Future.delayed(Duration(milliseconds: 500));

    final settings = LocationSettings(
      accuracy: LocationAccuracy.medium, // Upgraded from low
      distanceFilter: 5, // More sensitive
      timeLimit: Duration(seconds: 20),
    );

    _positionStreamSubscription =
        Geolocator.getPositionStream(locationSettings: settings).listen(
          _handlePositionUpdate,
          onError: _handleStreamError,
          cancelOnError: false,
        );
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

  /// Handle stream errors
  void _handleStreamError(dynamic error) {
    debugPrint('❌ Position stream error: $error');
    // Don't call _handleError here to avoid breaking the stream
  }

  /// Handle errors
  Future<void> _handleError(dynamic error) async {
    debugPrint('⚠️ Location error: $error');
    // Try to get cached location as fallback
    await _tryGetCachedPosition();
  }

  /// Start health check timer
  void _startHealthCheck() {
    _healthCheckTimer?.cancel();

    _healthCheckTimer = Timer.periodic(_healthCheckInterval, (timer) {
      final hasRecentPosition =
          _lastSuccessfulUpdate != null &&
          DateTime.now().difference(_lastSuccessfulUpdate!) <
              Duration(minutes: 1);

      debugPrint('🏥 Health check:');
      debugPrint('   Tracking: $isTracking');
      debugPrint('   Recent position: $hasRecentPosition');

      if (isTracking && !hasRecentPosition) {
        debugPrint('⚠️ No recent position - trying cached location');
        _tryGetCachedPosition();
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
    _updatePosition(position);
  }

  /// Get service status
  Map<String, dynamic> getServiceStatus() {
    return {
      'is_tracking': isTracking,
      'has_position': _lastPosition != null,
      'last_position_age': _lastSuccessfulUpdate != null
          ? DateTime.now().difference(_lastSuccessfulUpdate!).inSeconds
          : null,
      'service_type': 'StreamFirstLocationService',
    };
  }

  /// Cleanup resources
  void dispose() {
    stopTracking();
    _positionController.close();
  }
}
