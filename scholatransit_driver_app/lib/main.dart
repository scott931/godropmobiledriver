import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'core/config/app_config.dart';
import 'core/services/storage_service.dart';
import 'core/services/api_service.dart';
import 'core/services/location_health_monitor.dart';
import 'core/services/simple_communication_log_service.dart';
import 'core/services/background_message_service.dart';
import 'core/services/notification_service.dart';
import 'core/services/push_notification_service.dart';
import 'core/services/firebase_notification_service.dart';
import 'core/services/navigation_service.dart';
import 'core/widgets/system_back_button_handler.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // CRITICAL: Register background handler FIRST (before Firebase init)
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  // Initialize Hive for local storage
  await Hive.initFlutter();

  // Initialize Firebase
  await Firebase.initializeApp();

  // Initialize services
  await _initializeServices();

  // Request permissions
  await _requestPermissions();

  runApp(const ProviderScope(child: GoDropApp()));
}

Future<void> _initializeServices() async {
  // Initialize persistent storage (SharedPreferences + Hive box)
  await StorageService.init();

  // Initialize API client (Dio, interceptors)
  await ApiService.init();

  // Initialize communication log service
  await SimpleCommunicationLogService.init();

  // Initialize location health monitoring
  LocationHealthMonitor.startMonitoring();

  // Initialize notification service (local notifications)
  await NotificationService.init();

  // Initialize Firebase Cloud Messaging
  try {
    await FirebaseNotificationService.init();
    print('✅ Firebase Cloud Messaging initialized');
  } catch (e) {
    print('⚠️ Failed to initialize Firebase Cloud Messaging: $e');
    // Continue without FCM - other notification systems will still work
  }

  // Initialize push notification service (OneSignal) - optional, can coexist with FCM
  // Replace 'YOUR_ONESIGNAL_APP_ID' with your actual OneSignal App ID
  try {
    await PushNotificationService.init(
      oneSignalAppId: AppConfig.oneSignalAppId,
    );
  } catch (e) {
    print('⚠️ Failed to initialize OneSignal push notifications: $e');
    // Continue without OneSignal - Firebase and local notifications will still work
  }

  // Start background message checking service
  // This will check for new messages even when app is in background
  BackgroundMessageService.startBackgroundChecking();
}

Future<void> _requestPermissions() async {
  // Request location permission
  await Permission.locationWhenInUse.request();

  // Request notification permission
  await Permission.notification.request();

  // Request camera permission (for QR scanning)
  await Permission.camera.request();

  // Request contact permission (for parent contact selection)
  await Permission.contacts.request();
}

class GoDropApp extends ConsumerWidget {
  const GoDropApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ScreenUtilInit(
      designSize: const Size(375, 812), // iPhone X design size
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        final router = ref.watch(appRouterProvider);
        // Store router reference for navigation service
        NavigationService.setRouter(router);
        
        return MaterialApp.router(
          title: 'ScholaTransit Driver',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: ThemeMode.system,
          routerConfig: router,
          builder: (context, child) {
            return SystemBackButtonHandler(
              child: MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  textScaler: TextScaler.linear(1.0), // Disable text scaling
                ),
                child: child!,
              ),
            );
          },
        );
      },
    );
  }
}
