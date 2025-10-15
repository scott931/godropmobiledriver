import 'dart:async';
import '../config/app_config.dart';
import '../models/eta_model.dart';
import '../models/trip_model.dart';
import '../models/student_model.dart';
import 'api_service.dart';

class ParentNotificationService {
  static Timer? _notificationTimer;
  static bool _isActive = false;
  static Trip? _currentTrip;
  static List<Student> _studentsOnTrip = [];

  // Notification intervals
  static const Duration _etaUpdateInterval = Duration(minutes: 5);

  // Callbacks
  static Function(String)? _onNotificationSent;
  static Function(String)? _onNotificationError;

  /// Initialize parent notification service
  static Future<void> init() async {
    try {
      print('📱 Parent Notification Service: Initialized successfully');
    } catch (e) {
      print('❌ Parent Notification Service: Failed to initialize: $e');
    }
  }

  /// Start sending notifications to parents for a trip
  static Future<bool> startParentNotifications({
    required Trip trip,
    required List<Student> students,
    Function(String)? onNotificationSent,
    Function(String)? onNotificationError,
  }) async {
    try {
      if (_isActive) {
        print('⚠️ Parent notifications already active');
        return true;
      }

      print(
        '📱 Parent Notification Service: Starting notifications for trip ${trip.tripId}',
      );
      print(
        '📱 Parent Notification Service: Notifying parents of ${students.length} students',
      );

      _currentTrip = trip;
      _studentsOnTrip = students;
      _onNotificationSent = onNotificationSent;
      _onNotificationError = onNotificationError;
      _isActive = true;

      // Send initial notification
      await _sendInitialNotification();

      // Start periodic notifications
      _startPeriodicNotifications();

      print('✅ Parent Notification Service: Started successfully');
      return true;
    } catch (e) {
      print('❌ Parent Notification Service: Failed to start: $e');
      _onNotificationError?.call('Failed to start parent notifications: $e');
      return false;
    }
  }

  /// Stop sending notifications to parents
  static Future<void> stopParentNotifications() async {
    try {
      if (!_isActive) return;

      print('📱 Parent Notification Service: Stopping notifications');

      _notificationTimer?.cancel();
      _notificationTimer = null;
      _isActive = false;
      _currentTrip = null;
      _studentsOnTrip = [];
      _onNotificationSent = null;
      _onNotificationError = null;

      print('✅ Parent Notification Service: Stopped successfully');
    } catch (e) {
      print('❌ Parent Notification Service: Error stopping: $e');
    }
  }

  /// Send ETA update to parents
  static Future<bool> sendETAUpdate({
    required ETAInfo etaInfo,
    required String studentName,
    required String parentPhone,
    required String parentEmail,
  }) async {
    try {
      print(
        '📱 Parent Notification Service: Sending ETA update for $studentName',
      );

      final notificationData = {
        'student_name': studentName,
        'parent_phone': parentPhone,
        'parent_email': parentEmail,
        'trip_id': _currentTrip?.tripId,
        'vehicle_name': _currentTrip?.vehicleName ?? 'School Bus',
        'route_name': _currentTrip?.routeName ?? 'Route',
        'eta_info': {
          'estimated_arrival': etaInfo.estimatedArrival.toIso8601String(),
          'distance_km': (etaInfo.distance / 1000).toStringAsFixed(1),
          'time_to_arrival': etaInfo.formattedTimeToArrival,
          'is_delayed': etaInfo.isDelayed,
          'delay_reason': etaInfo.delayReason,
          'current_speed': etaInfo.currentSpeed?.toStringAsFixed(1),
        },
        'notification_type': 'eta_update',
        'priority': etaInfo.isDelayed ? 'high' : 'normal',
      };

      final response = await ApiService.post<Map<String, dynamic>>(
        AppConfig.parentNotificationEndpoint,
        data: notificationData,
      );

      if (response.success) {
        print('✅ Parent Notification Service: ETA update sent successfully');
        _onNotificationSent?.call('ETA update sent to $studentName\'s parents');
        return true;
      } else {
        print(
          '❌ Parent Notification Service: Failed to send ETA update: ${response.error}',
        );
        _onNotificationError?.call(
          'Failed to send ETA update: ${response.error}',
        );
        return false;
      }
    } catch (e) {
      print('❌ Parent Notification Service: Error sending ETA update: $e');
      _onNotificationError?.call('Error sending ETA update: $e');
      return false;
    }
  }

  /// Send distance update to parents
  static Future<bool> sendDistanceUpdate({
    required double remainingDistance,
    required double distanceTraveled,
    required String studentName,
    required String parentPhone,
    required String parentEmail,
  }) async {
    try {
      print(
        '📱 Parent Notification Service: Sending distance update for $studentName',
      );

      final notificationData = {
        'student_name': studentName,
        'parent_phone': parentPhone,
        'parent_email': parentEmail,
        'trip_id': _currentTrip?.tripId,
        'vehicle_name': _currentTrip?.vehicleName ?? 'School Bus',
        'route_name': _currentTrip?.routeName ?? 'Route',
        'distance_info': {
          'remaining_distance_km': (remainingDistance / 1000).toStringAsFixed(
            1,
          ),
          'distance_traveled_km': (distanceTraveled / 1000).toStringAsFixed(1),
          'progress_percentage': _calculateProgressPercentage(
            remainingDistance,
            distanceTraveled,
          ),
        },
        'notification_type': 'distance_update',
        'priority': 'normal',
      };

      final response = await ApiService.post<Map<String, dynamic>>(
        AppConfig.parentNotificationEndpoint,
        data: notificationData,
      );

      if (response.success) {
        print(
          '✅ Parent Notification Service: Distance update sent successfully',
        );
        _onNotificationSent?.call(
          'Distance update sent to $studentName\'s parents',
        );
        return true;
      } else {
        print(
          '❌ Parent Notification Service: Failed to send distance update: ${response.error}',
        );
        _onNotificationError?.call(
          'Failed to send distance update: ${response.error}',
        );
        return false;
      }
    } catch (e) {
      print('❌ Parent Notification Service: Error sending distance update: $e');
      _onNotificationError?.call('Error sending distance update: $e');
      return false;
    }
  }

  /// Send arrival notification to parents
  static Future<bool> sendArrivalNotification({
    required String studentName,
    required String parentPhone,
    required String parentEmail,
    required String arrivalLocation,
  }) async {
    try {
      print(
        '📱 Parent Notification Service: Sending arrival notification for $studentName',
      );

      final notificationData = {
        'student_name': studentName,
        'parent_phone': parentPhone,
        'parent_email': parentEmail,
        'trip_id': _currentTrip?.tripId,
        'vehicle_name': _currentTrip?.vehicleName ?? 'School Bus',
        'route_name': _currentTrip?.routeName ?? 'Route',
        'arrival_info': {
          'arrival_time': DateTime.now().toIso8601String(),
          'arrival_location': arrivalLocation,
          'status': 'arrived',
        },
        'notification_type': 'arrival_notification',
        'priority': 'high',
      };

      final response = await ApiService.post<Map<String, dynamic>>(
        AppConfig.parentNotificationEndpoint,
        data: notificationData,
      );

      if (response.success) {
        print(
          '✅ Parent Notification Service: Arrival notification sent successfully',
        );
        _onNotificationSent?.call(
          'Arrival notification sent to $studentName\'s parents',
        );
        return true;
      } else {
        print(
          '❌ Parent Notification Service: Failed to send arrival notification: ${response.error}',
        );
        _onNotificationError?.call(
          'Failed to send arrival notification: ${response.error}',
        );
        return false;
      }
    } catch (e) {
      print(
        '❌ Parent Notification Service: Error sending arrival notification: $e',
      );
      _onNotificationError?.call('Error sending arrival notification: $e');
      return false;
    }
  }

  /// Send delay notification to parents
  static Future<bool> sendDelayNotification({
    required String studentName,
    required String parentPhone,
    required String parentEmail,
    required String delayReason,
    required int delayMinutes,
  }) async {
    try {
      print(
        '📱 Parent Notification Service: Sending delay notification for $studentName',
      );

      final notificationData = {
        'student_name': studentName,
        'parent_phone': parentPhone,
        'parent_email': parentEmail,
        'trip_id': _currentTrip?.tripId,
        'vehicle_name': _currentTrip?.vehicleName ?? 'School Bus',
        'route_name': _currentTrip?.routeName ?? 'Route',
        'delay_info': {
          'delay_minutes': delayMinutes,
          'delay_reason': delayReason,
          'estimated_new_arrival': DateTime.now()
              .add(Duration(minutes: delayMinutes))
              .toIso8601String(),
          'status': 'delayed',
        },
        'notification_type': 'delay_notification',
        'priority': 'high',
      };

      final response = await ApiService.post<Map<String, dynamic>>(
        AppConfig.parentNotificationEndpoint,
        data: notificationData,
      );

      if (response.success) {
        print(
          '✅ Parent Notification Service: Delay notification sent successfully',
        );
        _onNotificationSent?.call(
          'Delay notification sent to $studentName\'s parents',
        );
        return true;
      } else {
        print(
          '❌ Parent Notification Service: Failed to send delay notification: ${response.error}',
        );
        _onNotificationError?.call(
          'Failed to send delay notification: ${response.error}',
        );
        return false;
      }
    } catch (e) {
      print(
        '❌ Parent Notification Service: Error sending delay notification: $e',
      );
      _onNotificationError?.call('Error sending delay notification: $e');
      return false;
    }
  }

  /// Send initial notification when trip starts
  static Future<void> _sendInitialNotification() async {
    try {
      for (final student in _studentsOnTrip) {
        final notificationData = {
          'student_name': student.fullName,
          'parent_phone': student.parentPhone ?? '',
          'parent_email': student.parentEmail ?? '',
          'trip_id': _currentTrip?.tripId,
          'vehicle_name': _currentTrip?.vehicleName ?? 'School Bus',
          'route_name': _currentTrip?.routeName ?? 'Route',
          'trip_info': {
            'start_time': DateTime.now().toIso8601String(),
            'start_location': _currentTrip?.startLocation ?? 'School',
            'end_location': _currentTrip?.endLocation ?? 'Destination',
            'status': 'started',
          },
          'notification_type': 'trip_started',
          'priority': 'normal',
        };

        await ApiService.post<Map<String, dynamic>>(
          AppConfig.parentNotificationEndpoint,
          data: notificationData,
        );
      }

      print('✅ Parent Notification Service: Initial notifications sent');
    } catch (e) {
      print(
        '❌ Parent Notification Service: Error sending initial notifications: $e',
      );
    }
  }

  /// Start periodic notifications
  static void _startPeriodicNotifications() {
    _notificationTimer = Timer.periodic(_etaUpdateInterval, (timer) async {
      if (!_isActive || _currentTrip == null) {
        timer.cancel();
        return;
      }

      // This would be called by the ETA service when updates are available
      // The actual ETA calculation and notification sending would happen here
      print('📱 Parent Notification Service: Periodic notification check');
    });
  }

  /// Calculate progress percentage
  static double _calculateProgressPercentage(
    double remaining,
    double traveled,
  ) {
    final total = remaining + traveled;
    if (total == 0) return 0.0;
    return (traveled / total) * 100;
  }

  /// Get current notification status
  static bool get isActive => _isActive;
  static Trip? get currentTrip => _currentTrip;
  static List<Student> get studentsOnTrip => _studentsOnTrip;
}
