import 'dart:async';
import 'dart:math';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/foundation.dart';

/// Location service health monitor with predictive failure detection
class LocationHealthMonitor {
  static Timer? _healthCheckTimer;
  static Timer? _performanceTimer;
  static final List<LocationHealthMetric> _metrics = [];
  static const int _maxMetricsHistory = 100;
  static const Duration _healthCheckInterval = Duration(seconds: 30);
  static const Duration _performanceCheckInterval = Duration(seconds: 10);

  // Health thresholds
  static const double _minAccuracyThreshold = 100.0; // meters
  static const Duration _maxStaleThreshold = Duration(minutes: 2);
  static const int _maxConsecutiveFailures = 3;
  static const Duration _maxResponseTime = Duration(seconds: 5);

  /// Start health monitoring
  static void startMonitoring() {
    debugPrint('🏥 LocationHealthMonitor: Starting health monitoring');

    _healthCheckTimer?.cancel();
    _performanceTimer?.cancel();

    _healthCheckTimer = Timer.periodic(_healthCheckInterval, (_) {
      _performHealthCheck();
    });

    _performanceTimer = Timer.periodic(_performanceCheckInterval, (_) {
      _recordPerformanceMetrics();
    });
  }

  /// Stop health monitoring
  static void stopMonitoring() {
    debugPrint('🛑 LocationHealthMonitor: Stopping health monitoring');
    _healthCheckTimer?.cancel();
    _performanceTimer?.cancel();
    _healthCheckTimer = null;
    _performanceTimer = null;
  }

  /// Record a location update for health tracking
  static void recordLocationUpdate(Position position, Duration responseTime) {
    final metric = LocationHealthMetric(
      timestamp: DateTime.now(),
      accuracy: position.accuracy,
      responseTime: responseTime,
      isSuccessful: true,
    );

    _addMetric(metric);
    _checkForAnomalies(metric);
  }

  /// Record a location error for health tracking
  static void recordLocationError(dynamic error, Duration responseTime) {
    final metric = LocationHealthMetric(
      timestamp: DateTime.now(),
      accuracy: double.infinity,
      responseTime: responseTime,
      isSuccessful: false,
      error: error.toString(),
    );

    _addMetric(metric);
    _checkForAnomalies(metric);
  }

  /// Add metric to history
  static void _addMetric(LocationHealthMetric metric) {
    _metrics.add(metric);

    // Keep only recent metrics
    if (_metrics.length > _maxMetricsHistory) {
      _metrics.removeAt(0);
    }
  }

  /// Check for performance anomalies
  static void _checkForAnomalies(LocationHealthMetric metric) {
    if (_metrics.length < 5) return; // Need some history

    // Check for accuracy degradation
    if (metric.isSuccessful && metric.accuracy > _minAccuracyThreshold) {
      debugPrint('⚠️ Location accuracy degraded: ${metric.accuracy}m');
    }

    // Check for response time issues
    if (metric.responseTime > _maxResponseTime) {
      debugPrint(
        '⚠️ Location response time slow: ${metric.responseTime.inMilliseconds}ms',
      );
    }

    // Check for consecutive failures
    final recentFailures = _getRecentFailures(5);
    if (recentFailures >= _maxConsecutiveFailures) {
      debugPrint('🚨 Multiple consecutive location failures detected');
      _triggerRecovery();
    }
  }

  /// Get recent failure count
  static int _getRecentFailures(int count) {
    final recent = _metrics.length > count
        ? _metrics.sublist(_metrics.length - count)
        : _metrics;
    return recent.where((m) => !m.isSuccessful).length;
  }

  /// Trigger recovery actions
  static void _triggerRecovery() {
    debugPrint('🔧 LocationHealthMonitor: Triggering recovery actions');

    // Clear old metrics to reset state
    _metrics.clear();

    // Could trigger service restart or configuration changes here
    // This would be handled by the calling service
  }

  /// Perform comprehensive health check
  static Future<void> _performHealthCheck() async {
    debugPrint('🏥 LocationHealthMonitor: Performing health check');

    try {
      // Check location permissions
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        debugPrint('⚠️ Health check: Location permission denied');
        return;
      }

      // Check location services
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('⚠️ Health check: Location services disabled');
        return;
      }

      // Check for stale data
      final staleData = _checkForStaleData();
      if (staleData) {
        debugPrint('⚠️ Health check: Stale location data detected');
      }

      // Check performance trends
      final performance = _analyzePerformanceTrends();
      if (performance['trend'] == 'degrading') {
        debugPrint('⚠️ Health check: Performance degrading');
      }

      debugPrint('✅ Health check: All systems normal');
    } catch (e) {
      debugPrint('❌ Health check failed: $e');
    }
  }

  /// Check for stale location data
  static bool _checkForStaleData() {
    if (_metrics.isEmpty) return true;

    final lastUpdate = _metrics.last.timestamp;
    final age = DateTime.now().difference(lastUpdate);

    return age > _maxStaleThreshold;
  }

  /// Analyze performance trends
  static Map<String, dynamic> _analyzePerformanceTrends() {
    if (_metrics.length < 10) {
      return {'trend': 'insufficient_data', 'confidence': 0.0};
    }

    final recent = _metrics.length > 10
        ? _metrics.sublist(_metrics.length - 10)
        : _metrics;
    final older = _metrics.length > 20
        ? _metrics.sublist(_metrics.length - 20, _metrics.length - 10)
        : <LocationHealthMetric>[];

    if (older.isEmpty) {
      return {'trend': 'insufficient_data', 'confidence': 0.0};
    }

    // Calculate average accuracy
    final recentAccuracy =
        recent
            .where((m) => m.isSuccessful)
            .map((m) => m.accuracy)
            .fold(0.0, (a, b) => a + b) /
        recent.where((m) => m.isSuccessful).length;

    final olderAccuracy =
        older
            .where((m) => m.isSuccessful)
            .map((m) => m.accuracy)
            .fold(0.0, (a, b) => a + b) /
        older.where((m) => m.isSuccessful).length;

    // Calculate success rate
    final recentSuccessRate =
        recent.where((m) => m.isSuccessful).length / recent.length;
    final olderSuccessRate =
        older.where((m) => m.isSuccessful).length / older.length;

    String trend = 'stable';
    double confidence = 0.5;

    if (recentAccuracy > olderAccuracy * 1.5) {
      trend = 'degrading';
      confidence = 0.8;
    } else if (recentAccuracy < olderAccuracy * 0.7) {
      trend = 'improving';
      confidence = 0.8;
    }

    if (recentSuccessRate < olderSuccessRate * 0.8) {
      trend = 'degrading';
      confidence = max(confidence, 0.9);
    }

    return {
      'trend': trend,
      'confidence': confidence,
      'recent_accuracy': recentAccuracy,
      'older_accuracy': olderAccuracy,
      'recent_success_rate': recentSuccessRate,
      'older_success_rate': olderSuccessRate,
    };
  }

  /// Record performance metrics
  static void _recordPerformanceMetrics() {
    // This could record system-level metrics like memory usage, CPU, etc.
    // For now, we'll just ensure the monitoring is active
    if (_metrics.isNotEmpty) {
      final lastMetric = _metrics.last;
      final age = DateTime.now().difference(lastMetric.timestamp);

      if (age > Duration(minutes: 1)) {
        debugPrint('⚠️ No location updates in ${age.inSeconds} seconds');
      }
    }
  }

  /// Get current health status
  static Map<String, dynamic> getHealthStatus() {
    final performance = _analyzePerformanceTrends();
    final staleData = _checkForStaleData();
    final recentFailures = _getRecentFailures(5);

    return {
      'is_healthy': !staleData && recentFailures < _maxConsecutiveFailures,
      'performance_trend': performance['trend'],
      'confidence': performance['confidence'],
      'has_stale_data': staleData,
      'recent_failures': recentFailures,
      'total_metrics': _metrics.length,
      'last_update': _metrics.isNotEmpty
          ? _metrics.last.timestamp.toIso8601String()
          : null,
    };
  }

  /// Get detailed metrics for debugging
  static List<Map<String, dynamic>> getDetailedMetrics() {
    return _metrics.map((m) => m.toMap()).toList();
  }

  /// Clear all metrics
  static void clearMetrics() {
    _metrics.clear();
    debugPrint('🧹 LocationHealthMonitor: Cleared all metrics');
  }

  /// Dispose of resources
  static void dispose() {
    stopMonitoring();
    clearMetrics();
  }
}

/// Location health metric data class
class LocationHealthMetric {
  final DateTime timestamp;
  final double accuracy;
  final Duration responseTime;
  final bool isSuccessful;
  final String? error;

  LocationHealthMetric({
    required this.timestamp,
    required this.accuracy,
    required this.responseTime,
    required this.isSuccessful,
    this.error,
  });

  Map<String, dynamic> toMap() {
    return {
      'timestamp': timestamp.toIso8601String(),
      'accuracy': accuracy,
      'response_time_ms': responseTime.inMilliseconds,
      'is_successful': isSuccessful,
      'error': error,
    };
  }
}
