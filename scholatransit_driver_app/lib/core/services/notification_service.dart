import 'dart:io' show Platform;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/timezone.dart' as tz;
import '../config/app_config.dart';
import '../services/api_service.dart';
import 'push_notification_service.dart';
import 'firebase_notification_service.dart';
import 'navigation_service.dart';

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
    
    // Navigate to notifications screen to view details
    NavigationService.go('/notifications');
    
    // Optional: Handle specific navigation based on payload
    // if (response.payload != null) {
    //   if (response.payload!.startsWith('chat_')) {
    //     final chatId = response.payload!.replaceFirst('chat_', '');
    //     NavigationService.go('/conversations/chat/$chatId');
    //   } else if (response.payload!.startsWith('trip_')) {
    //     final tripId = response.payload!.replaceFirst('trip_', '');
    //     NavigationService.go('/trips/details/$tripId');
    //   } else if (response.payload!.startsWith('emergency_')) {
    //     final emergencyId = response.payload!.replaceFirst('emergency_', '');
    //     NavigationService.go('/emergency');
    //   }
    // }
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
    // Try Firebase first, fallback to OneSignal
    try {
      if (FirebaseNotificationService.isInitialized) {
        return await FirebaseNotificationService.getToken();
      }
    } catch (e) {
      print('⚠️ Failed to get FCM token: $e');
    }
    
    // Fallback to OneSignal
    try {
      return await PushNotificationService.getDeviceToken();
    } catch (e) {
      return null;
    }
  }

  static Future<void> subscribeToTopic(String topic) async {
    // Use Firebase if available
    if (FirebaseNotificationService.isInitialized) {
      await FirebaseNotificationService.subscribeToTopic(topic);
    }
    // OneSignal topic subscription can be added here if needed
  }

  static Future<void> unsubscribeFromTopic(String topic) async {
    // Use Firebase if available
    if (FirebaseNotificationService.isInitialized) {
      await FirebaseNotificationService.unsubscribeFromTopic(topic);
    }
    // OneSignal topic unsubscription can be added here if needed
  }

  /// Show notification for a new message
  static Future<void> showMessageNotification({
    required String senderName,
    required String messageContent,
    required int chatId,
    String? chatName,
  }) async {
    try {
      // Truncate message if too long
      final truncatedMessage = messageContent.length > 100
          ? '${messageContent.substring(0, 100)}...'
          : messageContent;

      final title = chatName ?? senderName;
      final body = messageContent.isEmpty
          ? 'New message'
          : truncatedMessage;

      await showLocalNotification(
        title: title,
        body: body,
        payload: 'chat_$chatId', // Payload to navigate to chat when tapped
        id: chatId, // Use chatId as notification ID to avoid duplicates
      );

      print('🔔 Notification shown for message from $senderName in chat $chatId');
    } catch (e) {
      print('❌ Failed to show message notification: $e');
    }
  }
}

// FCM is disabled, no background handler needed
