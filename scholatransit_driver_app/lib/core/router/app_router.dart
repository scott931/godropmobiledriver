import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/splash/screens/splash_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/auth/screens/otp_screen.dart';
import '../../features/dashboard/screens/dashboard_screen.dart';
import '../../features/trips/screens/trips_screen.dart';
import '../../features/trips/screens/trip_details_screen.dart';
import '../../features/students/screens/students_screen.dart';
import '../../features/students/screens/qr_scanner_screen.dart';
import '../../features/notifications/screens/notifications_screen.dart';
import '../../features/profile/screens/profile_screen.dart';
import '../../features/profile/screens/driver_profile_screen.dart';
import '../../features/settings/screens/settings_screen.dart';
import '../../features/emergency/screens/emergency_screen.dart';
import '../../features/emergency/screens/create_alert_screen.dart';
import '../../features/map/screens/map_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/splash',
    routes: [
      // Splash route
      GoRoute(
        path: '/splash',
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),
      // Auth routes
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        name: 'register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/otp',
        name: 'otp',
        builder: (context, state) => const OtpScreen(),
      ),

      // Main app routes
      ShellRoute(
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(
            path: '/dashboard',
            name: 'dashboard',
            builder: (context, state) => const DashboardScreen(),
          ),
          GoRoute(
            path: '/trips',
            name: 'trips',
            builder: (context, state) => const TripsScreen(),
          ),
          GoRoute(
            path: '/trips/details/:tripId',
            name: 'trip-details',
            builder: (context, state) {
              final tripId = int.parse(state.pathParameters['tripId']!);
              return TripDetailsScreen(tripId: tripId);
            },
          ),
          GoRoute(
            path: '/students',
            name: 'students',
            builder: (context, state) => const StudentsScreen(),
          ),
          GoRoute(
            path: '/students/qr-scanner',
            name: 'qr-scanner',
            builder: (context, state) => const QRScannerScreen(),
          ),
          GoRoute(
            path: '/map',
            name: 'map',
            builder: (context, state) => const MapScreen(),
          ),
          GoRoute(
            path: '/notifications',
            name: 'notifications',
            builder: (context, state) => const NotificationsScreen(),
          ),
          GoRoute(
            path: '/emergency',
            name: 'emergency',
            builder: (context, state) => const EmergencyScreen(),
          ),
          GoRoute(
            path: '/emergency/create-alert',
            name: 'create-alert',
            builder: (context, state) => const CreateAlertScreen(),
          ),
          GoRoute(
            path: '/profile',
            name: 'profile',
            builder: (context, state) => const DriverProfileScreen(),
          ),
          GoRoute(
            path: '/settings',
            name: 'settings',
            builder: (context, state) => const SettingsScreen(),
          ),
        ],
      ),
    ],
  );
});

class MainShell extends ConsumerWidget {
  final Widget child;

  const MainShell({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _getCurrentIndex(context),
        onTap: (index) => _onTap(context, index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.directions_bus),
            label: 'Trips',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.school), label: 'Students'),
          BottomNavigationBarItem(icon: Icon(Icons.map), label: 'Map'),
          BottomNavigationBarItem(
            icon: Icon(Icons.emergency),
            label: 'Emergency',
          ),
        ],
      ),
    );
  }

  int _getCurrentIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    if (location.startsWith('/dashboard')) return 0;
    if (location.startsWith('/trips')) return 1;
    if (location.startsWith('/students')) return 2;
    if (location.startsWith('/map')) return 3;
    if (location.startsWith('/emergency')) return 4;
    return 0;
  }

  void _onTap(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go('/dashboard');
        break;
      case 1:
        context.go('/trips');
        break;
      case 2:
        context.go('/students');
        break;
      case 3:
        context.go('/map');
        break;
      case 4:
        context.go('/emergency');
        break;
    }
  }
}

class AppRouter {
  static GoRouter router(WidgetRef ref) => ref.read(appRouterProvider);
}
