import 'dart:io' show Platform;
import 'package:onesignal_flutter/onesignal_flutter.dart';
import '../config/app_config.dart';
import 'api_service.dart';
import 'notification_service.dart';
import 'navigation_service.dart';

/// Service for handling push notifications using OneSignal
/// This service works without Firebase Cloud Messaging
class PushNotificationService {
  static bool _isInitialized = false;
  static String? _currentDeviceToken;

  /// Initialize OneSignal push notifications
  ///
  /// [oneSignalAppId] - Your OneSignal App ID from OneSignal dashboard
  /// Get it from: https://app.onesignal.com -> Settings -> Keys & IDs
  static Future<void> init({required String oneSignalAppId}) async {
    if (_isInitialized) {
      print('⚠️ PushNotificationService: Already initialized');
      return;
    }

    try {
      // Set OneSignal App ID
      OneSignal.initialize(oneSignalAppId);

      // Request permission for notifications
      OneSignal.Notifications.requestPermission(true);

      // Set up notification handlers
      _setupNotificationHandlers();

      // Get the device token (Player ID in OneSignal)
      _getDeviceToken();

      // Listen for permission changes
      OneSignal.Notifications.addPermissionObserver((state) {
        print('📱 PushNotificationService: Permission state changed: $state');
      });

      _isInitialized = true;
      print(
        '✅ PushNotificationService: Initialized successfully with OneSignal',
      );
    } catch (e) {
      print('❌ PushNotificationService: Initialization failed: $e');
      rethrow;
    }
  }

  /// Set up notification handlers
  static void _setupNotificationHandlers() {
    // Handle notification received (when app is in foreground)
    OneSignal.Notifications.addClickListener((event) {
      print(
        '📱 PushNotificationService: Notification clicked: ${event.notification.notificationId}',
      );
      _handleNotificationTap(event.notification);
    });

    // Handle notification received (when app is in background)
    OneSignal.Notifications.addForegroundWillDisplayListener((event) {
      print(
        '📱 PushNotificationService: Notification received in foreground: ${event.notification.notificationId}',
      );

      // Display the notification
      // You can customize the notification here before displaying
      event.notification.display();
    });

    // Handle notification permission changes
    OneSignal.Notifications.addPermissionObserver((state) {
      print('📱 PushNotificationService: Permission state: $state');
      if (state) {
        // Permission granted, get device token
        _getDeviceToken();
      }
    });
  }

  /// Get the device token (OneSignal Player ID)
  static Future<String?> getDeviceToken() async {
    if (!_isInitialized) {
      print('⚠️ PushNotificationService: Not initialized');
      return null;
    }

    try {
      // Get OneSignal User ID (Player ID)
      final deviceState = OneSignal.User.pushSubscription.id;

      if (deviceState != null) {
        _currentDeviceToken = deviceState;
        print('📱 PushNotificationService: Device token: $deviceState');

        // Register token with backend
        await _registerDeviceTokenWithBackend(deviceState);

        return deviceState;
      }

      return null;
    } catch (e) {
      print('❌ PushNotificationService: Failed to get device token: $e');
      return null;
    }
  }

  /// Get device token (internal method)
  static void _getDeviceToken() async {
    final token = await getDeviceToken();
    if (token != null) {
      _currentDeviceToken = token;
    }
  }

  /// Register device token with backend
  static Future<void> _registerDeviceTokenWithBackend(String token) async {
    try {
      await ApiService.post(
        AppConfig.deviceTokenEndpoint,
        data: {
          'device_token': token,
          'device_type': Platform.isAndroid ? 'android' : 'ios',
          'push_service': 'onesignal', // Indicate we're using OneSignal
        },
      );
      print('✅ PushNotificationService: Device token registered with backend');
    } catch (e) {
      print('❌ PushNotificationService: Failed to register device token: $e');
    }
  }

  /// Handle notification tap
  static void _handleNotificationTap(OSNotification notification) {
    final additionalData = notification.additionalData;

    if (additionalData != null) {
      // Extract chat ID or other data from notification
      final chatId = additionalData['chat_id'] as int?;
      final notificationType = additionalData['type'] as String?;

      print(
        '📱 PushNotificationService: Notification tapped - Type: $notificationType, Chat ID: $chatId',
      );

      // Navigate to notifications screen to view details
      NavigationService.go('/notifications');
      
      // Optional: Handle specific navigation based on notification type
      // if (chatId != null) {
      //   NavigationService.go('/conversations/chat/$chatId');
      // } else if (tripId != null) {
      //   NavigationService.go('/trips/details/$tripId');
      // }
    } else {
      // Navigate to notifications screen even if no additional data
      NavigationService.go('/notifications');
    }
  }

  /// Set user tags (for targeted notifications)
  static Future<void> setUserTags({
    required String userId,
    String? userType,
    Map<String, dynamic>? additionalTags,
  }) async {
    if (!_isInitialized) {
      print('⚠️ PushNotificationService: Not initialized');
      return;
    }

    try {
      final tags = <String, dynamic>{
        'user_id': userId,
        if (userType != null) 'user_type': userType,
        if (additionalTags != null) ...additionalTags,
      };

      await OneSignal.User.addTags(tags);
      print('✅ PushNotificationService: User tags set: $tags');
    } catch (e) {
      print('❌ PushNotificationService: Failed to set user tags: $e');
    }
  }

  /// Subscribe to notification topics
  static Future<void> subscribeToTopic(String topic) async {
    if (!_isInitialized) {
      print('⚠️ PushNotificationService: Not initialized');
      return;
    }

    try {
      await OneSignal.User.addTags({'topic_$topic': 'true'});
      print('✅ PushNotificationService: Subscribed to topic: $topic');
    } catch (e) {
      print('❌ PushNotificationService: Failed to subscribe to topic: $e');
    }
  }

  /// Unsubscribe from notification topics
  static Future<void> unsubscribeFromTopic(String topic) async {
    if (!_isInitialized) {
      print('⚠️ PushNotificationService: Not initialized');
      return;
    }

    try {
      await OneSignal.User.removeTag('topic_$topic');
      print('✅ PushNotificationService: Unsubscribed from topic: $topic');
    } catch (e) {
      print('❌ PushNotificationService: Failed to unsubscribe from topic: $e');
    }
  }

  /// Get current device token
  static String? get currentDeviceToken => _currentDeviceToken;

  /// Check if service is initialized
  static bool get isInitialized => _isInitialized;
}
