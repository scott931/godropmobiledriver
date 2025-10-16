import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:permission_handler/permission_handler.dart';

import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'core/services/storage_service.dart';
import 'core/services/api_service.dart';
import 'core/services/location_health_monitor.dart';
import 'core/widgets/system_back_button_handler.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive for local storage
  await Hive.initFlutter();

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

  // Initialize location health monitoring
  LocationHealthMonitor.startMonitoring();
}

Future<void> _requestPermissions() async {
  // Request location permission
  await Permission.locationWhenInUse.request();

  // Request notification permission
  await Permission.notification.request();

  // Request camera permission (for QR scanning)
  await Permission.camera.request();
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
        return MaterialApp.router(
          title: 'ScholaTransit Driver',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: ThemeMode.system,
          routerConfig: ref.watch(appRouterProvider),
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
