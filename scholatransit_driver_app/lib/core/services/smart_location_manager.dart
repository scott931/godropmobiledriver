import 'dart:async';
import 'package:geolocator/geolocator.dart';

/// Smart Location Manager with circuit breaker pattern and intelligent retry logic
class SmartLocationManager {
  static final SmartLocationManager _instance =
      SmartLocationManager._internal();
  factory SmartLocationManager() => _instance;
  SmartLocationManager._internal();

  // Circuit breaker pattern
  bool _isCircuitOpen = false;
  DateTime? _lastFailure;
  int _consecutiveFailures = 0;
  static const Duration _circuitTimeout = Duration(minutes: 5);
  static const int _maxConsecutiveFailures = 3;

  // Retry logic
  int _currentRetries = 0;
  static const Duration _baseRetryDelay = Duration(seconds: 5);

  // Location quality tracking
  Position? _lastValidPosition;
  DateTime? _lastPositionUpdate;
  static const Duration _maxStaleLocation = Duration(minutes: 2);
  static const double _minAccuracy = 100.0; // meters
  static const double _minMovement = 5.0; // meters

  // Service management
  StreamSubscription<Position>? _locationSubscription;
  bool _isTracking = false;
  Timer? _healthCheckTimer;
  Timer? _retryTimer;

  // Callbacks
  Function(Position)? _onLocationUpdate;
  Function(String)? _onLocationError;
  Function(String)? _onUserGuidance;

  /// Initialize the smart location manager
  static Future<bool> initialize() async {
    try {
      print('🧠 SmartLocationManager: Initializing...');

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

      print('✅ SmartLocationManager: Initialized successfully');
      return true;
    } catch (e) {
      print('❌ SmartLocationManager: Initialization failed: $e');
      return false;
    }
  }

  /// Start location tracking with smart retry logic
  static Future<bool> startTracking({
    Function(Position)? onLocationUpdate,
    Function(String)? onLocationError,
    Function(String)? onUserGuidance,
  }) async {
    final manager = SmartLocationManager();

    try {
      print('🧠 SmartLocationManager: Starting location tracking...');

      // Check circuit breaker
      if (!manager._shouldAttemptLocation()) {
        print('🔒 Circuit breaker is open - location attempts blocked');
        onUserGuidance?.call(
          'Location services temporarily unavailable. Please check your GPS settings.',
        );
        return false;
      }

      // Set callbacks
      manager._onLocationUpdate = onLocationUpdate;
      manager._onLocationError = onLocationError;
      manager._onUserGuidance = onUserGuidance;

      // Try to get initial position with smart retry
      final initialPosition = await manager._getLocationWithSmartRetry();
      if (initialPosition != null) {
        manager._recordSuccess();
        onLocationUpdate?.call(initialPosition);
      }

      // Start location stream with optimized settings
      manager._locationSubscription =
          Geolocator.getPositionStream(
            locationSettings: LocationSettings(
              accuracy: LocationAccuracy
                  .low, // Start with low accuracy for reliability
              distanceFilter: 30, // 30 meters
              timeLimit: Duration(seconds: 8), // Reasonable timeout
            ),
          ).listen(
            manager._handleLocationUpdate,
            onError: manager._handleLocationError,
          );

      manager._isTracking = true;
      manager._startHealthCheck();

      print('✅ SmartLocationManager: Location tracking started');
      return true;
    } catch (e) {
      print('❌ SmartLocationManager: Failed to start tracking: $e');
      manager._recordFailure();
      return false;
    }
  }

  /// Get location with smart retry logic
  Future<Position?> _getLocationWithSmartRetry() async {
    final accuracyLevels = [
      {
        'accuracy': LocationAccuracy.low,
        'timeout': Duration(seconds: 5),
        'name': 'low',
      },
      {
        'accuracy': LocationAccuracy.lowest,
        'timeout': Duration(seconds: 3),
        'name': 'lowest',
      },
    ];

    for (final level in accuracyLevels) {
      try {
        print('🧠 Trying ${level['name']} accuracy location...');
        final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: level['accuracy'] as LocationAccuracy,
          timeLimit: level['timeout'] as Duration,
        );

        if (_isLocationQualityAcceptable(position)) {
          print('✅ Location obtained with ${level['name']} accuracy');
          return position;
        } else {
          print('⚠️ Location quality not acceptable, trying next level...');
        }
      } catch (e) {
        print('❌ ${level['name']} accuracy failed: $e');
        // Continue to next accuracy level
      }
    }

    // Try cached location as last resort
    print('⚠️ All accuracy levels failed, trying cached location...');
    try {
      final cachedPosition = await Geolocator.getLastKnownPosition();
      if (cachedPosition != null &&
          _isLocationQualityAcceptable(cachedPosition)) {
        print('✅ Using cached location');
        return cachedPosition;
      }
    } catch (e) {
      print('❌ Cached location failed: $e');
    }

    return null;
  }

  /// Check if location quality is acceptable
  bool _isLocationQualityAcceptable(Position position) {
    // Check if location is recent
    final isRecent =
        DateTime.now().difference(position.timestamp) < _maxStaleLocation;

    // Check accuracy
    final hasGoodAccuracy = position.accuracy < _minAccuracy;

    // Check if position has moved significantly from last position
    bool hasMoved = true;
    if (_lastValidPosition != null) {
      final distance = Geolocator.distanceBetween(
        _lastValidPosition!.latitude,
        _lastValidPosition!.longitude,
        position.latitude,
        position.longitude,
      );
      hasMoved = distance > _minMovement;
    }

    final isAcceptable = isRecent && hasGoodAccuracy && hasMoved;

    print('🧠 Location quality check:');
    print(
      '  Recent: $isRecent (${DateTime.now().difference(position.timestamp).inMinutes}m old)',
    );
    print('  Accurate: $hasGoodAccuracy (${position.accuracy}m)');
    print('  Moved: $hasMoved');
    print('  Acceptable: $isAcceptable');

    return isAcceptable;
  }

  /// Handle location updates
  void _handleLocationUpdate(Position position) {
    try {
      if (_isLocationQualityAcceptable(position)) {
        _recordSuccess();
        _lastValidPosition = position;
        _lastPositionUpdate = DateTime.now();
        _onLocationUpdate?.call(position);

        print(
          '🧠 Location update: ${position.latitude}, ${position.longitude} (accuracy: ${position.accuracy}m)',
        );
      } else {
        print('⚠️ Location quality not acceptable, ignoring update');
      }
    } catch (e) {
      print('❌ Error handling location update: $e');
      _handleLocationError('Error processing location update: $e');
    }
  }

  /// Handle location errors with intelligent recovery
  void _handleLocationError(dynamic error) {
    print('❌ Location error: $error');
    _recordFailure();
    _onLocationError?.call('Location error: $error');

    if (error.toString().contains('TimeoutException')) {
      _handleTimeoutError();
    } else {
      _handleOtherError(error);
    }
  }

  /// Handle timeout errors specifically
  void _handleTimeoutError() {
    print('⏰ Handling timeout error...');

    if (_consecutiveFailures >= _maxConsecutiveFailures) {
      _openCircuit();
      _onUserGuidance?.call(
        'Location services are having trouble. Please:\n'
        '• Check that GPS is enabled\n'
        '• Move to an area with better signal\n'
        '• Wait a moment and try again',
      );
    } else {
      _scheduleDelayedRetry();
    }
  }

  /// Handle other types of errors
  void _handleOtherError(dynamic error) {
    print('🔧 Handling other error: $error');
    _onUserGuidance?.call(
      'Location services unavailable. Please check your device settings.',
    );
  }

  /// Check if location attempts should be made (circuit breaker)
  bool _shouldAttemptLocation() {
    if (!_isCircuitOpen) return true;

    if (_lastFailure != null &&
        DateTime.now().difference(_lastFailure!) > _circuitTimeout) {
      print('🔓 Circuit breaker timeout reached, allowing location attempts');
      _isCircuitOpen = false;
      _consecutiveFailures = 0;
      return true;
    }

    return false;
  }

  /// Record successful location update
  void _recordSuccess() {
    _isCircuitOpen = false;
    _consecutiveFailures = 0;
    _currentRetries = 0;
    _lastFailure = null;
  }

  /// Record location failure
  void _recordFailure() {
    _consecutiveFailures++;
    _lastFailure = DateTime.now();

    if (_consecutiveFailures >= _maxConsecutiveFailures) {
      _openCircuit();
    }
  }

  /// Open circuit breaker
  void _openCircuit() {
    _isCircuitOpen = true;
    print('🔒 Circuit breaker opened due to consecutive failures');
  }

  /// Schedule delayed retry with exponential backoff
  void _scheduleDelayedRetry() {
    if (_retryTimer?.isActive == true) return;

    final delay = Duration(
      seconds: _baseRetryDelay.inSeconds * (_currentRetries + 1),
    );
    print('⏰ Scheduling retry in ${delay.inSeconds} seconds...');

    _retryTimer = Timer(delay, () {
      if (_shouldAttemptLocation()) {
        _attemptRecovery();
      }
    });
  }

  /// Attempt to recover from location issues
  void _attemptRecovery() async {
    try {
      print('🔄 Attempting location recovery...');

      if (!_shouldAttemptLocation()) {
        print('🔒 Circuit breaker still open, skipping recovery');
        return;
      }

      // Stop current tracking
      await _locationSubscription?.cancel();
      _locationSubscription = null;
      _isTracking = false;

      // Wait before restarting
      await Future.delayed(Duration(seconds: 2));

      // Try to restart with different settings
      _locationSubscription = Geolocator.getPositionStream(
        locationSettings: LocationSettings(
          accuracy: LocationAccuracy.lowest, // Use lowest accuracy for recovery
          distanceFilter: 100, // Larger distance filter
          timeLimit: Duration(seconds: 5), // Shorter timeout
        ),
      ).listen(_handleLocationUpdate, onError: _handleLocationError);

      _isTracking = true;
      _currentRetries++;

      print('✅ Location recovery attempted');
    } catch (e) {
      print('❌ Location recovery failed: $e');
      _recordFailure();
    }
  }

  /// Start health check timer
  void _startHealthCheck() {
    _healthCheckTimer = Timer.periodic(Duration(seconds: 30), (timer) {
      _performHealthCheck();
    });
  }

  /// Perform health check
  void _performHealthCheck() {
    try {
      final isTracking = _isTracking;
      final hasRecentPosition =
          _lastPositionUpdate != null &&
          DateTime.now().difference(_lastPositionUpdate!) <
              Duration(minutes: 1);

      print(
        '🧠 Health check - Tracking: $isTracking, Recent position: $hasRecentPosition',
      );

      if (isTracking && !hasRecentPosition) {
        print('⚠️ Tracking but no recent position - potential issue');
        _consecutiveFailures++;

        if (_consecutiveFailures >= _maxConsecutiveFailures) {
          _openCircuit();
        }
      }
    } catch (e) {
      print('❌ Health check error: $e');
    }
  }

  /// Stop location tracking
  static Future<void> stopTracking() async {
    final manager = SmartLocationManager();

    try {
      print('🧠 SmartLocationManager: Stopping location tracking...');

      await manager._locationSubscription?.cancel();
      manager._locationSubscription = null;
      manager._isTracking = false;

      manager._healthCheckTimer?.cancel();
      manager._healthCheckTimer = null;

      manager._retryTimer?.cancel();
      manager._retryTimer = null;

      print('✅ SmartLocationManager: Location tracking stopped');
    } catch (e) {
      print('❌ SmartLocationManager: Error stopping tracking: $e');
    }
  }

  /// Get current position with fallback
  static Future<Position?> getCurrentPosition() async {
    final manager = SmartLocationManager();

    try {
      // Try to get position from active service
      if (manager._isTracking && manager._lastValidPosition != null) {
        return manager._lastValidPosition;
      }

      // Fallback to direct position request
      return await manager._getLocationWithSmartRetry();
    } catch (e) {
      print('❌ SmartLocationManager: Error getting current position: $e');
      return null;
    }
  }

  /// Get service status
  static Map<String, dynamic> getServiceStatus() {
    final manager = SmartLocationManager();

    return {
      'is_tracking': manager._isTracking,
      'circuit_open': manager._isCircuitOpen,
      'consecutive_failures': manager._consecutiveFailures,
      'current_retries': manager._currentRetries,
      'has_recent_position':
          manager._lastPositionUpdate != null &&
          DateTime.now().difference(manager._lastPositionUpdate!) <
              Duration(minutes: 1),
      'last_position_age': manager._lastPositionUpdate != null
          ? DateTime.now().difference(manager._lastPositionUpdate!).inMinutes
          : null,
    };
  }

  /// Dispose of resources
  static Future<void> dispose() async {
    final manager = SmartLocationManager();

    try {
      print('🧠 SmartLocationManager: Disposing...');

      await stopTracking();

      manager._onLocationUpdate = null;
      manager._onLocationError = null;
      manager._onUserGuidance = null;

      print('✅ SmartLocationManager: Disposed');
    } catch (e) {
      print('❌ SmartLocationManager: Error disposing: $e');
    }
  }
}
