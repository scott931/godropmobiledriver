import 'dart:async';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../models/eta_model.dart';
import '../models/trip_model.dart';
import 'notification_service.dart';

class ETANotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static final Map<String, Timer> _scheduledNotifications = {};
  static final Map<String, ETAInfo> _lastETAs = {};

  /// Initialize ETA notification service
  static Future<void> init() async {
    try {
      await NotificationService.init();
      print('✅ ETA Notification Service: Initialized successfully');
    } catch (e) {
      print('❌ ETA Notification Service: Failed to initialize: $e');
    }
  }

  /// Schedule ETA-based notifications for a trip
  static Future<void> scheduleETANotifications({
    required Trip trip,
    required ETAInfo etaInfo,
  }) async {
    try {
      print(
        '🔔 ETA Notification Service: Scheduling notifications for trip ${trip.tripId}',
      );

      // Cancel existing notifications for this trip
      await cancelETANotifications(trip.tripId);

      final now = DateTime.now();
      final arrivalTime = etaInfo.estimatedArrival;

      // Schedule notifications at different intervals
      await _scheduleArrivalNotifications(trip, arrivalTime, now);
      await _scheduleDelayNotifications(trip, etaInfo, now);
      await _scheduleTrafficNotifications(trip, etaInfo, now);

      // Store the ETA info for comparison
      _lastETAs[trip.tripId] = etaInfo;

      print('✅ ETA Notification Service: Notifications scheduled successfully');
    } catch (e) {
      print('❌ ETA Notification Service: Failed to schedule notifications: $e');
    }
  }

  /// Schedule arrival notifications
  static Future<void> _scheduleArrivalNotifications(
    Trip trip,
    DateTime arrivalTime,
    DateTime now,
  ) async {
    // 15 minutes before arrival
    final fifteenMinBefore = arrivalTime.subtract(Duration(minutes: 15));
    if (fifteenMinBefore.isAfter(now)) {
      await _scheduleNotification(
        id: '${trip.id}_15min',
        title: 'Arriving Soon',
        body:
            'You will arrive at ${trip.endLocation ?? 'destination'} in 15 minutes',
        scheduledDate: fifteenMinBefore,
        payload: 'eta_15min_${trip.tripId}',
      );
    }

    // 5 minutes before arrival
    final fiveMinBefore = arrivalTime.subtract(Duration(minutes: 5));
    if (fiveMinBefore.isAfter(now)) {
      await _scheduleNotification(
        id: '${trip.id}_5min',
        title: 'Almost There',
        body:
            'You will arrive at ${trip.endLocation ?? 'destination'} in 5 minutes',
        scheduledDate: fiveMinBefore,
        payload: 'eta_5min_${trip.tripId}',
      );
    }

    // Arrival notification
    if (arrivalTime.isAfter(now)) {
      await _scheduleNotification(
        id: '${trip.id}_arrival',
        title: 'Arrived',
        body: 'You have arrived at ${trip.endLocation ?? 'destination'}',
        scheduledDate: arrivalTime,
        payload: 'eta_arrival_${trip.tripId}',
      );
    }
  }

  /// Schedule delay notifications
  static Future<void> _scheduleDelayNotifications(
    Trip trip,
    ETAInfo etaInfo,
    DateTime now,
  ) async {
    if (!etaInfo.isDelayed) return;

    final scheduledEnd = trip.scheduledEnd;
    final delayMinutes = etaInfo.estimatedArrival
        .difference(scheduledEnd)
        .inMinutes;

    // Immediate delay notification
    await _scheduleNotification(
      id: '${trip.id}_delay',
      title: 'Trip Delayed',
      body: _getDelayMessage(delayMinutes, trip),
      scheduledDate: now.add(Duration(seconds: 5)),
      payload: 'eta_delay_${trip.tripId}',
    );

    // Update delay notification if delay increases
    if (delayMinutes > 15) {
      await _scheduleNotification(
        id: '${trip.id}_delay_update',
        title: 'Delay Update',
        body: 'Trip is now $delayMinutes minutes late',
        scheduledDate: now.add(Duration(minutes: 10)),
        payload: 'eta_delay_update_${trip.tripId}',
      );
    }
  }

  /// Schedule traffic notifications
  static Future<void> _scheduleTrafficNotifications(
    Trip trip,
    ETAInfo etaInfo,
    DateTime now,
  ) async {
    if (etaInfo.trafficMultiplier == null) return;

    final multiplier = etaInfo.trafficMultiplier!;

    // Heavy traffic notification
    if (multiplier > 1.5) {
      await _scheduleNotification(
        id: '${trip.id}_traffic',
        title: 'Heavy Traffic',
        body: 'Heavy traffic detected on your route. ETA may be affected.',
        scheduledDate: now.add(Duration(seconds: 10)),
        payload: 'eta_traffic_${trip.tripId}',
      );
    }

    // Traffic improvement notification
    if (multiplier < 1.0) {
      await _scheduleNotification(
        id: '${trip.id}_traffic_good',
        title: 'Light Traffic',
        body: 'Light traffic conditions. You may arrive ahead of schedule.',
        scheduledDate: now.add(Duration(seconds: 15)),
        payload: 'eta_traffic_good_${trip.tripId}',
      );
    }
  }

  /// Schedule a single notification
  static Future<void> _scheduleNotification({
    required String id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? payload,
  }) async {
    try {
      await NotificationService.scheduleNotification(
        id: id.hashCode,
        title: title,
        body: body,
        scheduledDate: scheduledDate,
        payload: payload,
      );

      print(
        '🔔 ETA Notification Service: Scheduled notification "$title" for ${scheduledDate.toString()}',
      );
    } catch (e) {
      print('❌ ETA Notification Service: Failed to schedule notification: $e');
    }
  }

  /// Get delay message based on delay duration
  static String _getDelayMessage(int delayMinutes, Trip trip) {
    if (delayMinutes <= 5) {
      return 'Minor delay of $delayMinutes minutes due to traffic';
    } else if (delayMinutes <= 15) {
      return 'Moderate delay of $delayMinutes minutes. Traffic conditions are affecting your route';
    } else if (delayMinutes <= 30) {
      return 'Significant delay of $delayMinutes minutes due to heavy traffic';
    } else {
      return 'Major delay of $delayMinutes minutes. Consider alternative routes if available';
    }
  }

  /// Update ETA notifications when ETA changes
  static Future<void> updateETANotifications({
    required Trip trip,
    required ETAInfo newETAInfo,
  }) async {
    try {
      final lastETA = _lastETAs[trip.tripId];
      if (lastETA == null) {
        // First time scheduling for this trip
        await scheduleETANotifications(trip: trip, etaInfo: newETAInfo);
        return;
      }

      // Check if ETA has changed significantly (more than 5 minutes)
      final timeDifference = newETAInfo.estimatedArrival
          .difference(lastETA.estimatedArrival)
          .inMinutes
          .abs();

      if (timeDifference > 5) {
        print(
          '🔄 ETA Notification Service: ETA changed by $timeDifference minutes, updating notifications',
        );

        // Cancel existing notifications
        await cancelETANotifications(trip.tripId);

        // Schedule new notifications
        await scheduleETANotifications(trip: trip, etaInfo: newETAInfo);
      }

      // Check for delay status changes
      if (lastETA.isDelayed != newETAInfo.isDelayed) {
        if (newETAInfo.isDelayed) {
          await _showDelayNotification(trip, newETAInfo);
        } else {
          await _showDelayResolvedNotification(trip);
        }
      }

      // Update stored ETA
      _lastETAs[trip.tripId] = newETAInfo;
    } catch (e) {
      print('❌ ETA Notification Service: Failed to update notifications: $e');
    }
  }

  /// Show immediate delay notification
  static Future<void> _showDelayNotification(Trip trip, ETAInfo etaInfo) async {
    await NotificationService.showLocalNotification(
      title: 'Trip Delayed',
      body: 'Your trip to ${trip.endLocation ?? 'destination'} is running late',
    );
  }

  /// Show delay resolved notification
  static Future<void> _showDelayResolvedNotification(Trip trip) async {
    await NotificationService.showLocalNotification(
      title: 'Back on Schedule',
      body:
          'Your trip to ${trip.endLocation ?? 'destination'} is back on schedule',
    );
  }

  /// Cancel all ETA notifications for a trip
  static Future<void> cancelETANotifications(String tripId) async {
    try {
      final tripIdInt = tripId.hashCode;

      // Cancel all notification IDs for this trip
      await _notifications.cancel(tripIdInt);
      await _notifications.cancel('${tripIdInt}_15min'.hashCode);
      await _notifications.cancel('${tripIdInt}_5min'.hashCode);
      await _notifications.cancel('${tripIdInt}_arrival'.hashCode);
      await _notifications.cancel('${tripIdInt}_delay'.hashCode);
      await _notifications.cancel('${tripIdInt}_delay_update'.hashCode);
      await _notifications.cancel('${tripIdInt}_traffic'.hashCode);
      await _notifications.cancel('${tripIdInt}_traffic_good'.hashCode);

      // Cancel any running timers
      _scheduledNotifications[tripId]?.cancel();
      _scheduledNotifications.remove(tripId);

      // Remove stored ETA
      _lastETAs.remove(tripId);

      print(
        '🔔 ETA Notification Service: Cancelled all notifications for trip $tripId',
      );
    } catch (e) {
      print('❌ ETA Notification Service: Failed to cancel notifications: $e');
    }
  }

  /// Cancel all ETA notifications
  static Future<void> cancelAllETANotifications() async {
    try {
      await _notifications.cancelAll();

      // Cancel all timers
      for (final timer in _scheduledNotifications.values) {
        timer.cancel();
      }
      _scheduledNotifications.clear();
      _lastETAs.clear();

      print('🔔 ETA Notification Service: Cancelled all ETA notifications');
    } catch (e) {
      print(
        '❌ ETA Notification Service: Failed to cancel all notifications: $e',
      );
    }
  }

  /// Get notification statistics
  static Map<String, dynamic> getNotificationStats() {
    return {
      'scheduled_notifications': _scheduledNotifications.length,
      'tracked_trips': _lastETAs.length,
      'active_timers': _scheduledNotifications.values
          .where((timer) => timer.isActive)
          .length,
    };
  }

  /// Check if notifications are enabled
  static Future<bool> areNotificationsEnabled() async {
    try {
      final result = await _notifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.areNotificationsEnabled();
      return result ?? false;
    } catch (e) {
      print(
        '❌ ETA Notification Service: Failed to check notification status: $e',
      );
      return false;
    }
  }

  /// Request notification permissions
  static Future<bool> requestNotificationPermissions() async {
    try {
      final result = await _notifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.requestNotificationsPermission();
      return result ?? false;
    } catch (e) {
      print('❌ ETA Notification Service: Failed to request permissions: $e');
      return false;
    }
  }

  /// Dispose of the service
  static Future<void> dispose() async {
    await cancelAllETANotifications();
  }
}
