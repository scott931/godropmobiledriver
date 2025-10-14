import 'dart:io' show Platform;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/timezone.dart' as tz;
import '../config/app_config.dart';
import '../services/api_service.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    await _initializeLocalNotifications();
    await _requestNotificationPermission();
  }

  static Future<void> _initializeLocalNotifications() async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      settings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );
  }

  // Firebase Messaging removed. Local notifications only

  static Future<void> _requestNotificationPermission() async {
    final status = await Permission.notification.request();
    if (!status.isGranted) {
      print('Notification permission not granted');
    }
  }

  static Future<void> registerDeviceToken(String token) async {
    try {
      await ApiService.post(
        AppConfig.deviceTokenEndpoint,
        data: {
          'device_token': token,
          'device_type': Platform.isAndroid ? 'android' : 'ios',
        },
      );
    } catch (_) {}
  }

  static void _onNotificationTapped(NotificationResponse response) {
    print('Notification tapped: ${response.payload}');
    // Handle notification tap
  }

  // No-op handlers since FCM is removed

  static Future<void> showLocalNotification({
    required String title,
    required String body,
    String? payload,
    int id = 0,
  }) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          AppConfig.notificationChannelId,
          AppConfig.notificationChannelName,
          channelDescription: AppConfig.notificationChannelDescription,
          importance: Importance.high,
          priority: Priority.high,
          showWhen: true,
          enableVibration: true,
          playSound: true,
        );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(id, title, body, details, payload: payload);
  }

  static Future<void> showTripNotification({
    required String title,
    required String body,
    String? tripId,
  }) async {
    await showLocalNotification(
      title: title,
      body: body,
      payload: tripId,
      id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
    );
  }

  static Future<void> showEmergencyNotification({
    required String title,
    required String body,
    String? emergencyId,
  }) async {
    try {
      print('🔔 DEBUG: Showing emergency notification: $title');
      await showLocalNotification(
        title: title,
        body: body,
        payload: emergencyId,
        id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
      );
      print('🔔 DEBUG: Emergency notification shown successfully');
    } catch (e) {
      print('🔔 DEBUG: Failed to show emergency notification: $e');
      rethrow;
    }
  }

  static Future<void> showStudentStatusNotification({
    required String studentName,
    required String status,
    String? tripId,
  }) async {
    await showLocalNotification(
      title: 'Student Status Update',
      body: '$studentName: $status',
      payload: tripId,
      id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
    );
  }

  static Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? payload,
  }) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          AppConfig.notificationChannelId,
          AppConfig.notificationChannelName,
          channelDescription: AppConfig.notificationChannelDescription,
          importance: Importance.high,
          priority: Priority.high,
        );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledDate, tz.local),
      details,
      payload: payload,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  static Future<void> cancelNotification(int id) async {
    await _localNotifications.cancel(id);
  }

  static Future<void> cancelAllNotifications() async {
    await _localNotifications.cancelAll();
  }

  static Future<String?> getFCMToken() async {
    // FCM is disabled, return null
    return null;
  }

  static Future<void> subscribeToTopic(String topic) async {
    // FCM is disabled, no-op
  }

  static Future<void> unsubscribeFromTopic(String topic) async {
    // FCM is disabled, no-op
  }
}

// FCM is disabled, no background handler needed
