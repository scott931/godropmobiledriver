import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../features/splash/screens/splash_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/auth/screens/otp_screen.dart';
import '../../features/auth/screens/forgot_password_screen.dart';
import '../../features/dashboard/screens/dashboard_screen.dart';
import '../../features/trips/screens/trips_screen.dart';
import '../../features/trips/screens/trip_details_screen.dart';
import '../../features/students/screens/students_screen.dart';
import '../../features/students/screens/student_details_screen.dart';
import '../../features/students/screens/qr_scanner_screen.dart';
import '../../features/notifications/screens/notifications_screen.dart';
import '../../features/notifications/screens/alert_details_screen.dart';
import '../../features/communication/screens/conversations_screen.dart';
import '../../features/communication/screens/chat_screen.dart';
import '../../features/profile/screens/driver_profile_screen.dart';
import '../../features/settings/screens/settings_screen.dart';
import '../../features/emergency/screens/emergency_screen.dart';
import '../../features/emergency/screens/create_alert_screen.dart';
import '../../features/map/screens/map_screen.dart';
import '../../features/parent/screens/parent_dashboard_screen.dart';
import '../../features/parent/screens/parent_tracking_screen.dart';
import '../../features/parent/screens/parent_schedule_screen.dart';
import '../../features/parent/screens/parent_messages_screen.dart';
import '../../features/parent/screens/parent_emergency_screen.dart';
import '../../features/parent/screens/parent_notifications_screen.dart';
import '../../features/parent/screens/parent_profile_screen.dart';
import '../widgets/simple_bottom_navigation.dart';
import '../providers/auth_provider.dart';
import '../providers/parent_auth_provider.dart';
import '../../features/communication/screens/whatsapp_redirect_screen.dart';
import '../../features/communication/screens/whatsapp_test_screen.dart';
import '../../features/communication/screens/whatsapp_debug_screen.dart';

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
      GoRoute(
        path: '/forgot-password',
        name: 'forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),

      // Main app routes
      ShellRoute(
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(
            path: '/dashboard',
            name: 'dashboard',
            builder: (context, state) {
              final authState = ref.watch(authProvider);
              final parentAuthState = ref.watch(parentAuthProvider);

              // Check if user is authenticated as driver
              if (authState.isAuthenticated && authState.driver != null) {
                return const DashboardScreen();
              }
              // Check if user is authenticated as parent
              else if (parentAuthState.isAuthenticated &&
                  parentAuthState.parent != null) {
                return const ParentDashboardScreen();
              }
              // Default to driver dashboard
              return const DashboardScreen();
            },
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
            path: '/students/:studentId',
            name: 'student-details',
            builder: (context, state) {
              final studentId = int.parse(state.pathParameters['studentId']!);
              return StudentDetailsScreen(studentId: studentId);
            },
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
            path: '/notifications/alert-details',
            name: 'alert-details',
            builder: (context, state) {
              final alertData = state.extra as Map<String, dynamic>;
              return AlertDetailsScreen(alertData: alertData);
            },
          ),
          GoRoute(
            path: '/conversations',
            name: 'conversations',
            builder: (context, state) => const ConversationsScreen(),
          ),
          GoRoute(
            path: '/conversations/chat/:conversationId',
            name: 'chat',
            builder: (context, state) {
              final conversationData = state.extra as Map<String, dynamic>;
              return ChatScreen(conversation: conversationData['conversation']);
            },
          ),
          GoRoute(
            path: '/conversations/whatsapp-redirect',
            name: 'whatsapp-redirect',
            builder: (context, state) {
              final extra = state.extra as Map<String, dynamic>;
              return WhatsAppRedirectScreen(
                contactName: extra['contactName'] as String,
                contactType: extra['contactType'] as String,
                phoneNumber: extra['phoneNumber'] as String?,
              );
            },
          ),
          GoRoute(
            path: '/whatsapp-test',
            name: 'whatsapp-test',
            builder: (context, state) => const WhatsAppTestScreen(),
          ),
          GoRoute(
            path: '/whatsapp-debug',
            name: 'whatsapp-debug',
            builder: (context, state) => const WhatsAppDebugScreen(),
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
            builder: (context, state) {
              final authState = ref.watch(authProvider);
              final parentAuthState = ref.watch(parentAuthProvider);

              // Check if user is authenticated as driver
              if (authState.isAuthenticated && authState.driver != null) {
                return const DriverProfileScreen();
              }
              // Check if user is authenticated as parent
              else if (parentAuthState.isAuthenticated &&
                  parentAuthState.parent != null) {
                return const ParentProfileScreen();
              }
              // Default to driver profile screen
              return const DriverProfileScreen();
            },
          ),
          GoRoute(
            path: '/settings',
            name: 'settings',
            builder: (context, state) => const SettingsScreen(),
          ),
        ],
      ),

      // Parent routes
      ShellRoute(
        builder: (context, state, child) => ParentMainShell(child: child),
        routes: [
          GoRoute(
            path: '/parent/dashboard',
            name: 'parent-dashboard',
            builder: (context, state) => const ParentDashboardScreen(),
          ),
          GoRoute(
            path: '/parent/tracking',
            name: 'parent-tracking',
            builder: (context, state) => const ParentTrackingScreen(),
          ),
          GoRoute(
            path: '/parent/schedule',
            name: 'parent-schedule',
            builder: (context, state) => const ParentScheduleScreen(),
          ),
          GoRoute(
            path: '/parent/messages',
            name: 'parent-messages',
            builder: (context, state) => const ParentMessagesScreen(),
          ),
          GoRoute(
            path: '/parent/emergency',
            name: 'parent-emergency',
            builder: (context, state) => const ParentEmergencyScreen(),
          ),
          GoRoute(
            path: '/parent/notifications',
            name: 'parent-notifications',
            builder: (context, state) => const ParentNotificationsScreen(),
          ),
          GoRoute(
            path: '/parent/profile',
            name: 'parent-profile',
            builder: (context, state) => const ParentProfileScreen(),
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
      bottomNavigationBar: SimpleBottomNavigation(
        currentIndex: _getCurrentIndex(context),
        onTap: (index) => _onTap(context, index),
      ),
    );
  }

  int _getCurrentIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    if (location.startsWith('/dashboard')) return 0;
    if (location.startsWith('/trips')) return 1;
    if (location.startsWith('/students')) return 2;
    if (location.startsWith('/map')) return 3;
    if (location.startsWith('/conversations')) return 4;
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
        context.go('/conversations');
        break;
    }
  }
}

class ParentMainShell extends ConsumerWidget {
  final Widget child;

  const ParentMainShell({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: child,
      bottomNavigationBar: ParentBottomNavigation(
        currentIndex: _getCurrentIndex(context),
        onTap: (index) => _onTap(context, index),
      ),
    );
  }

  int _getCurrentIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    if (location.startsWith('/parent/dashboard')) return 0;
    if (location.startsWith('/parent/tracking')) return 1;
    if (location.startsWith('/parent/schedule')) return 2;
    if (location.startsWith('/parent/messages')) return 3;
    if (location.startsWith('/parent/emergency')) return 4;
    return 0;
  }

  void _onTap(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go('/parent/dashboard');
        break;
      case 1:
        context.go('/parent/tracking');
        break;
      case 2:
        context.go('/parent/schedule');
        break;
      case 3:
        context.go('/parent/messages');
        break;
      case 4:
        context.go('/parent/emergency');
        break;
    }
  }
}

class ParentBottomNavigation extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const ParentBottomNavigation({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(context, 0, Icons.dashboard, 'Dashboard'),
              _buildNavItem(context, 1, Icons.track_changes, 'Tracking'),
              _buildNavItem(context, 2, Icons.schedule, 'Schedule'),
              _buildNavItem(context, 3, Icons.chat, 'Messages'),
              _buildNavItem(context, 4, Icons.emergency, 'Emergency'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context,
    int index,
    IconData icon,
    String label,
  ) {
    final isSelected = currentIndex == index;

    return GestureDetector(
      onTap: () => onTap(index),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF0052CC).withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8.r),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 20.w,
              color: isSelected ? const Color(0xFF0052CC) : Colors.grey[600],
            ),
            SizedBox(height: 4.h),
            Text(
              label,
              style: TextStyle(
                fontSize: 10.sp,
                color: isSelected ? const Color(0xFF0052CC) : Colors.grey[600],
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AppRouter {
  static GoRouter router(WidgetRef ref) => ref.read(appRouterProvider);
}
