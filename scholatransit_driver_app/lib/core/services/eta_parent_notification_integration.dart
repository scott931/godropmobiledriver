import 'dart:async';
import '../models/eta_model.dart';
import '../models/trip_model.dart';
import '../models/student_model.dart';
import '../providers/parent_notification_provider.dart';
import 'realtime_eta_updater.dart';
import 'realtime_distance_tracker.dart';

class ETAParentNotificationIntegration {
  static bool _isIntegrated = false;
  static Timer? _integrationTimer;
  static ParentNotificationNotifier? _parentNotificationNotifier;

  // Integration settings
  static const Duration _integrationCheckInterval = Duration(minutes: 2);

  /// Initialize ETA-Parent Notification integration
  static Future<void> init(
    ParentNotificationNotifier parentNotificationNotifier,
  ) async {
    try {
      _parentNotificationNotifier = parentNotificationNotifier;
      _isIntegrated = true;

      print('🔗 ETA-Parent Integration: Initialized successfully');
    } catch (e) {
      print('❌ ETA-Parent Integration: Failed to initialize: $e');
    }
  }

  /// Start integrated ETA updates and parent notifications for a trip
  static Future<bool> startIntegratedUpdates({
    required Trip trip,
    required List<Student> students,
  }) async {
    try {
      if (!_isIntegrated || _parentNotificationNotifier == null) {
        print('❌ ETA-Parent Integration: Not initialized');
        return false;
      }

      print(
        '🔗 ETA-Parent Integration: Starting integrated updates for trip ${trip.tripId}',
      );

      // Start parent notifications
      final notificationStarted = await _parentNotificationNotifier!
          .startParentNotifications(trip: trip, students: students);

      if (!notificationStarted) {
        print('❌ ETA-Parent Integration: Failed to start parent notifications');
        return false;
      }

      // Start ETA updates with callbacks
      await RealtimeETAUpdater.startETAUpdates(
        trip: trip,
        onETAUpdate: _onETAUpdate,
        onETAError: _onETAError,
        onSignificantETAChange: _onSignificantETAChange,
      );

      // Start distance tracking with callbacks
      await RealtimeDistanceTracker.startDistanceTracking(
        trip: trip,
        onDistanceUpdate: _onDistanceUpdate,
        onDistanceError: _onDistanceError,
        onProgressUpdate: _onProgressUpdate,
      );

      // Start integration monitoring
      _startIntegrationMonitoring();

      print('✅ ETA-Parent Integration: Started successfully');
      return true;
    } catch (e) {
      print('❌ ETA-Parent Integration: Error starting integrated updates: $e');
      return false;
    }
  }

  /// Stop integrated updates
  static Future<void> stopIntegratedUpdates() async {
    try {
      print('🔗 ETA-Parent Integration: Stopping integrated updates');

      // Stop all services
      RealtimeETAUpdater.stopETAUpdates();
      RealtimeDistanceTracker.stopDistanceTracking();
      await _parentNotificationNotifier?.stopParentNotifications();

      // Stop integration monitoring
      _integrationTimer?.cancel();
      _integrationTimer = null;

      print('✅ ETA-Parent Integration: Stopped successfully');
    } catch (e) {
      print('❌ ETA-Parent Integration: Error stopping integrated updates: $e');
    }
  }

  /// Handle ETA updates
  static Future<void> _onETAUpdate(ETAInfo etaInfo) async {
    try {
      print(
        '🔗 ETA-Parent Integration: ETA updated - ${etaInfo.formattedTimeToArrival}',
      );

      // Send ETA update to parents
      await _parentNotificationNotifier?.sendETAUpdate(etaInfo);
    } catch (e) {
      print('❌ ETA-Parent Integration: Error handling ETA update: $e');
    }
  }

  /// Handle ETA errors
  static void _onETAError(String error) {
    try {
      print('🔗 ETA-Parent Integration: ETA error - $error');

      // Could send error notification to parents if needed
      // _parentNotificationNotifier?.sendErrorNotification(error);
    } catch (e) {
      print('❌ ETA-Parent Integration: Error handling ETA error: $e');
    }
  }

  /// Handle significant ETA changes
  static Future<void> _onSignificantETAChange(ETAInfo etaInfo) async {
    try {
      print(
        '🔗 ETA-Parent Integration: Significant ETA change - ${etaInfo.formattedTimeToArrival}',
      );

      // Send immediate notification for significant changes
      await _parentNotificationNotifier?.sendETAUpdate(etaInfo);
    } catch (e) {
      print(
        '❌ ETA-Parent Integration: Error handling significant ETA change: $e',
      );
    }
  }

  /// Handle distance updates
  static Future<void> _onDistanceUpdate(
    double remainingDistance,
    double distanceTraveled,
    double totalDistance,
  ) async {
    try {
      print(
        '🔗 ETA-Parent Integration: Distance updated - Remaining: ${(remainingDistance / 1000).toStringAsFixed(1)}km, Traveled: ${(distanceTraveled / 1000).toStringAsFixed(1)}km',
      );

      // Send distance update to parents
      await _parentNotificationNotifier?.sendDistanceUpdate(
        remainingDistance: remainingDistance,
        distanceTraveled: distanceTraveled,
      );
    } catch (e) {
      print('❌ ETA-Parent Integration: Error handling distance update: $e');
    }
  }

  /// Handle distance errors
  static void _onDistanceError(String error) {
    try {
      print('🔗 ETA-Parent Integration: Distance error - $error');

      // Could send error notification to parents if needed
    } catch (e) {
      print('❌ ETA-Parent Integration: Error handling distance error: $e');
    }
  }

  /// Handle progress updates
  static void _onProgressUpdate(double progressPercentage) {
    try {
      print(
        '🔗 ETA-Parent Integration: Progress updated - ${progressPercentage.toStringAsFixed(1)}%',
      );

      // Could send progress update to parents if needed
    } catch (e) {
      print('❌ ETA-Parent Integration: Error handling progress update: $e');
    }
  }

  /// Start integration monitoring
  static void _startIntegrationMonitoring() {
    _integrationTimer = Timer.periodic(_integrationCheckInterval, (
      timer,
    ) async {
      try {
        // Check if all services are still active
        final isETAActive = RealtimeETAUpdater.isUpdating;
        final isDistanceActive = RealtimeDistanceTracker.isTracking;
        final isNotificationActive =
            _parentNotificationNotifier?.isActive ?? false;

        if (!isETAActive || !isDistanceActive || !isNotificationActive) {
          print(
            '⚠️ ETA-Parent Integration: One or more services are not active',
          );
          print('   ETA Active: $isETAActive');
          print('   Distance Active: $isDistanceActive');
          print('   Notification Active: $isNotificationActive');
        }

        // Perform periodic checks and maintenance
        await _performPeriodicChecks();
      } catch (e) {
        print('❌ ETA-Parent Integration: Error in monitoring: $e');
      }
    });
  }

  /// Perform periodic checks
  static Future<void> _performPeriodicChecks() async {
    try {
      // Check if we need to send any periodic notifications
      final currentTrip = _parentNotificationNotifier?.currentTrip;
      final students = _parentNotificationNotifier?.studentsOnTrip ?? [];

      if (currentTrip != null && students.isNotEmpty) {
        // Could implement periodic status updates here
        print('🔗 ETA-Parent Integration: Performing periodic checks');
      }
    } catch (e) {
      print('❌ ETA-Parent Integration: Error in periodic checks: $e');
    }
  }

  /// Send manual ETA update
  static Future<void> sendManualETAUpdate(ETAInfo etaInfo) async {
    try {
      print('🔗 ETA-Parent Integration: Sending manual ETA update');
      _parentNotificationNotifier?.sendETAUpdate(etaInfo);
    } catch (e) {
      print('❌ ETA-Parent Integration: Error sending manual ETA update: $e');
    }
  }

  /// Send manual distance update
  static Future<void> sendManualDistanceUpdate({
    required double remainingDistance,
    required double distanceTraveled,
  }) async {
    try {
      print('🔗 ETA-Parent Integration: Sending manual distance update');
      _parentNotificationNotifier?.sendDistanceUpdate(
        remainingDistance: remainingDistance,
        distanceTraveled: distanceTraveled,
      );
    } catch (e) {
      print(
        '❌ ETA-Parent Integration: Error sending manual distance update: $e',
      );
    }
  }

  /// Send arrival notification
  static Future<void> sendArrivalNotification(String arrivalLocation) async {
    try {
      print('🔗 ETA-Parent Integration: Sending arrival notification');
      _parentNotificationNotifier?.sendArrivalNotification(arrivalLocation);
    } catch (e) {
      print('❌ ETA-Parent Integration: Error sending arrival notification: $e');
    }
  }

  /// Send delay notification
  static Future<void> sendDelayNotification({
    required String delayReason,
    required int delayMinutes,
  }) async {
    try {
      print('🔗 ETA-Parent Integration: Sending delay notification');
      _parentNotificationNotifier?.sendDelayNotification(
        delayReason: delayReason,
        delayMinutes: delayMinutes,
      );
    } catch (e) {
      print('❌ ETA-Parent Integration: Error sending delay notification: $e');
    }
  }

  /// Get integration status
  static bool get isIntegrated => _isIntegrated;
  static bool get isActive => _integrationTimer != null;
}
