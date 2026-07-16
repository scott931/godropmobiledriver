import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'core/config/app_config.dart';
import 'core/providers/auth_provider.dart';
import 'core/providers/trip_provider.dart';
import 'core/services/storage_service.dart';
import 'core/services/api_service.dart';
import 'core/services/location_health_monitor.dart';
import 'core/services/simple_communication_log_service.dart';
import 'core/services/background_message_service.dart';
import 'core/services/notification_service.dart';
import 'core/services/push_notification_service.dart';
import 'core/services/firebase_notification_service.dart';
import 'core/services/navigation_service.dart';
import 'core/services/truck_h3_service.dart';
import 'core/services/vehicle_movement_simulator.dart';
import 'core/services/background_location_service.dart';
import 'core/services/location_service_resolver.dart';
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

  // Initialize H3 geospatial indexing when enabled (additive - no impact if disabled)
  if (AppConfig.enableH3Tracking) {
    await TruckH3Service.initialize();
  }

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

  // Prepare background location capabilities (best effort).
  await BackgroundLocationService.initialize();
}

Future<void> _requestPermissions() async {
  // Request location permission
  await Permission.locationWhenInUse.request();
  await Permission.locationAlways.request();

  // Request notification permission
  await Permission.notification.request();

  // Request camera permission (for QR scanning)
  await Permission.camera.request();
}

class GoDropApp extends ConsumerStatefulWidget {
  const GoDropApp({super.key});

  @override
  ConsumerState<GoDropApp> createState() => _GoDropAppState();
}

class _GoDropAppState extends ConsumerState<GoDropApp>
    with WidgetsBindingObserver {
  Timer? _statusCheckTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _startStatusCheckIfAuthenticated();
    _registerSuspensionCallback();
    if (AppConfig.useSimulatedVehicleMotion) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        VehicleMovementSimulator.attach(ref);
      });
    }
  }

  void _registerSuspensionCallback() {
    ApiService.setSuspensionCallback((message) {
      if (!mounted) return;
      ref.read(authProvider.notifier).logout(suspensionError: message);
    });
  }

  @override
  void dispose() {
    VehicleMovementSimulator.detach();
    _statusCheckTimer?.cancel();
    _statusCheckTimer = null;
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _startStatusCheckIfAuthenticated() {
    _statusCheckTimer?.cancel();
    final authState = ref.read(authProvider);
    if (authState.isAuthenticated && authState.driver != null) {
      // One-time background check on start - no periodic timer to avoid app refresh
      // Suspension is also detected by API interceptor on 401/403
      ref.read(authProvider.notifier).refreshDriverProfileInBackground();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    BackgroundLocationService.handleAppLifecycleChange(state.name);
    if (state == AppLifecycleState.resumed) {
      _startStatusCheckIfAuthenticated();
      final tripState = ref.read(tripProvider);
      if (tripState.currentTrip != null) {
        unawaited(BackgroundLocationService.stopBackgroundTracking());
        ref.read(tripProvider.notifier).resumeForegroundLiveLocation();
      }
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached ||
        state == AppLifecycleState.hidden) {
      _statusCheckTimer?.cancel();
      _statusCheckTimer = null;
      final tripState = ref.read(tripProvider);
      if (tripState.currentTrip != null) {
        ref.read(tripProvider.notifier).pauseForegroundLiveLocation();
        unawaited(
          BackgroundLocationService.startBackgroundTracking(
            onLocationUpdate: (Position position) {
              final activeTrip = ref.read(tripProvider).currentTrip;
              if (activeTrip?.isActive == true) {
                unawaited(
                  ref.read(tripProvider.notifier).postLiveLocationIfDue(
                    position,
                  ),
                );
              }
              unawaited(LocationServiceResolver.injectSimulatedGps(position));
            },
            onLocationError:
                (error) => print('❌ Background location lifecycle error: $error'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AuthState>(authProvider, (previous, next) {
      if (!next.isAuthenticated) {
        _statusCheckTimer?.cancel();
        _statusCheckTimer = null;
        // Redirect to login only when transitioning from authenticated (suspension/logout)
        if (previous?.isAuthenticated == true) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!context.mounted) return;
            ref.read(appRouterProvider).go('/login');
          });
        }
      } else if (next.isAuthenticated &&
          next.driver != null &&
          previous?.isAuthenticated != true) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          if (AppConfig.seedTestActiveTrip) {
            unawaited(
              ref.read(tripProvider.notifier).seedTestActiveTripIfEnabled(),
            );
          } else {
            unawaited(ref.read(tripProvider.notifier).clearMockTestData());
          }
        });
      }
    });
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
