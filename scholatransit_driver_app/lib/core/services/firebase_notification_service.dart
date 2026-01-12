import 'dart:io' show Platform;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import '../config/app_config.dart';
import '../services/api_service.dart';
import 'notification_service.dart';
import 'navigation_service.dart';

/// Top-level background message handler
/// Must be a top-level function (not a class method)
/// Must be registered before Firebase.initializeApp()
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('📱 FCM Background Message: ${message.messageId}');
  
  // Initialize Firebase in the background isolate
  // Note: Firebase.initializeApp() is called automatically by firebase_messaging
  
  // Initialize local notifications in background isolate
  final FlutterLocalNotificationsPlugin localNotifications =
      FlutterLocalNotificationsPlugin();
  
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
  
  await localNotifications.initialize(settings);
  
  // Create notification channel for Android
  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    AppConfig.notificationChannelId,
    AppConfig.notificationChannelName,
    description: AppConfig.notificationChannelDescription,
    importance: Importance.high,
    playSound: true,
    enableVibration: true,
    enableLights: true,
  );
  
  await localNotifications
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);
  
  // Extract notification data
  final title = message.notification?.title ?? 
                message.data['title'] ?? 
                message.data['notification']?['title'] ??
                'New Notification';
  
  final body = message.notification?.body ?? 
               message.data['body'] ?? 
               message.data['notification']?['body'] ??
               message.data['message'] ??
               '';
  
  final payload = message.data['payload'] ?? 
                  message.data['chat_id']?.toString() ??
                  message.data['trip_id']?.toString();
  
  // Show notification
  const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
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
  
  await localNotifications.show(
    message.hashCode,
    title,
    body,
    details,
    payload: payload,
  );
  
  print('📱 FCM Background notification shown: $title');
}

/// Separate service for Firebase Cloud Messaging
/// This service handles FCM independently from other notification systems
class FirebaseNotificationService {
  static final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  
  static bool _isInitialized = false;
  static String? _currentToken;

  /// Initialize Firebase Cloud Messaging
  /// This should be called after Firebase.initializeApp()
  static Future<void> init() async {
    if (_isInitialized) {
      print('⚠️ FirebaseNotificationService: Already initialized');
      return;
    }

    try {
      // Request notification permissions
      final NotificationSettings settings = 
          await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        print('✅ FirebaseNotificationService: User granted permission');
      } else if (settings.authorizationStatus == 
                 AuthorizationStatus.provisional) {
        print('⚠️ FirebaseNotificationService: User granted provisional permission');
      } else {
        print('❌ FirebaseNotificationService: User declined permission');
        return;
      }

      // Initialize local notifications for foreground display
      await _initializeLocalNotifications();

      // Set up message handlers
      _setupMessageHandlers();

      // Get and register FCM token
      await _getAndRegisterToken();

      // Listen for token refresh
      _firebaseMessaging.onTokenRefresh.listen((newToken) {
        print('📱 FCM Token refreshed: $newToken');
        _currentToken = newToken;
        _registerTokenWithBackend(newToken);
      });

      _isInitialized = true;
      print('✅ FirebaseNotificationService: Initialized successfully');
    } catch (e) {
      print('❌ FirebaseNotificationService: Initialization failed: $e');
      rethrow;
    }
  }

  /// Initialize local notifications for displaying FCM messages in foreground
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

    // Create notification channel for Android
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      AppConfig.notificationChannelId,
      AppConfig.notificationChannelName,
      description: AppConfig.notificationChannelDescription,
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
      enableLights: true,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  /// Set up Firebase message handlers
  static void _setupMessageHandlers() {
    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('📱 FCM Foreground Message: ${message.messageId}');
      _handleForegroundMessage(message);
    });

    // Handle notification tap when app is opened from terminated state
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('📱 FCM Notification opened app: ${message.messageId}');
      _handleNotificationTap(message);
    });

    // Check if app was opened from a terminated state
    FirebaseMessaging.instance.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        print('📱 FCM App opened from terminated state: ${message.messageId}');
        _handleNotificationTap(message);
      }
    });
  }

  /// Handle foreground messages (app is open)
  static Future<void> _handleForegroundMessage(RemoteMessage message) async {
    // Extract notification data with fallback
    final title = message.notification?.title ?? 
                  message.data['title'] ?? 
                  message.data['notification']?['title'] ??
                  'New Notification';
    
    final body = message.notification?.body ?? 
                 message.data['body'] ?? 
                 message.data['notification']?['body'] ??
                 message.data['message'] ??
                 '';
    
    final payload = message.data['payload'] ?? 
                    message.data['chat_id']?.toString() ??
                    message.data['trip_id']?.toString();

    // Show local notification
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
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

    await _localNotifications.show(
      message.hashCode,
      title,
      body,
      details,
      payload: payload,
    );

    print('📱 FCM Foreground notification shown: $title');
  }

  /// Handle notification tap
  static void _handleNotificationTap(RemoteMessage message) {
    final data = message.data;
    final chatId = data['chat_id'];
    final tripId = data['trip_id'];
    final payload = data['payload'];

    print('📱 FCM Notification tapped - Chat ID: $chatId, Trip ID: $tripId');

    // Navigate to notifications screen to view details
    // User can then tap on the specific notification to see more details
    NavigationService.go('/notifications');
    
    // Optional: Handle specific navigation based on notification type
    // This can be extended to navigate to specific screens if needed
    // if (chatId != null) {
    //   NavigationService.go('/conversations/chat/$chatId');
    // } else if (tripId != null) {
    //   NavigationService.go('/trips/details/$tripId');
    // }
  }

  /// Handle local notification tap
  static void _onNotificationTapped(NotificationResponse response) {
    print('📱 Local notification tapped: ${response.payload}');
    
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
    //   }
    // }
  }

  /// Get FCM token and register with backend
  static Future<void> _getAndRegisterToken() async {
    try {
      final token = await _firebaseMessaging.getToken();
      if (token != null) {
        _currentToken = token;
        print('📱 FCM Token: $token');
        await _registerTokenWithBackend(token);
      } else {
        print('⚠️ FCM Token is null');
      }
    } catch (e) {
      print('❌ Failed to get FCM token: $e');
    }
  }

  /// Register FCM token with backend
  static Future<void> _registerTokenWithBackend(String token) async {
    try {
      await ApiService.post(
        AppConfig.deviceTokenEndpoint,
        data: {
          'device_token': token,
          'device_type': Platform.isAndroid ? 'android' : 'ios',
          'push_service': 'fcm', // Indicate we're using Firebase
        },
      );
      print('✅ FCM Token registered with backend');
    } catch (e) {
      print('❌ Failed to register FCM token: $e');
    }
  }

  /// Get current FCM token
  static Future<String?> getToken() async {
    if (!_isInitialized) {
      print('⚠️ FirebaseNotificationService: Not initialized');
      return null;
    }
    return _currentToken ?? await _firebaseMessaging.getToken();
  }

  /// Delete FCM token (e.g., on logout)
  static Future<void> deleteToken() async {
    try {
      await _firebaseMessaging.deleteToken();
      _currentToken = null;
      print('✅ FCM Token deleted');
    } catch (e) {
      print('❌ Failed to delete FCM token: $e');
    }
  }

  /// Subscribe to a topic
  static Future<void> subscribeToTopic(String topic) async {
    try {
      await _firebaseMessaging.subscribeToTopic(topic);
      print('✅ Subscribed to topic: $topic');
    } catch (e) {
      print('❌ Failed to subscribe to topic: $e');
    }
  }

  /// Unsubscribe from a topic
  static Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _firebaseMessaging.unsubscribeFromTopic(topic);
      print('✅ Unsubscribed from topic: $topic');
    } catch (e) {
      print('❌ Failed to unsubscribe from topic: $e');
    }
  }

  /// Check if service is initialized
  static bool get isInitialized => _isInitialized;
}
