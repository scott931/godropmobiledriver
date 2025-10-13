import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/trip_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../widgets/dashboard_stats_card.dart';
import '../widgets/quick_actions_card.dart';
import '../widgets/current_trip_card.dart';
import '../widgets/recent_trips_card.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    // Load dashboard data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(tripProvider.notifier).loadTrips();
    });
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final tripState = ref.watch(tripProvider);

    // Listen for authentication state changes and reload trips
    ref.listen<AuthState>(authProvider, (previous, next) {
      if (next.isAuthenticated && previous?.isAuthenticated != next.isAuthenticated) {
        // User just logged in, reload trips
        print('🔄 DEBUG: User logged in, reloading trips...');
        ref.read(tripProvider.notifier).loadTrips();
      } else if (!next.isAuthenticated && previous?.isAuthenticated == true) {
        // User just logged out, reset trip state
        print('🔄 DEBUG: User logged out, resetting trip state...');
        ref.read(tripProvider.notifier).resetState();
      }
    });

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () => context.go('/notifications'),
          ),
          IconButton(
            icon: const Icon(Icons.account_circle_outlined),
            onPressed: () => context.go('/profile'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(tripProvider.notifier).loadTrips();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome Section
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(20.w),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppTheme.primaryColor, AppTheme.primaryVariant],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16.r),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome back,',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      authState.driver?.fullName ?? 'Driver',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      'Ready to start your day?',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 24.h),

              // Current Trip Section
              if (tripState.currentTrip != null) ...[
                CurrentTripCard(trip: tripState.currentTrip!),
                SizedBox(height: 24.h),
              ],

              // Quick Actions
              QuickActionsCard(),
              SizedBox(height: 24.h),

              // Dashboard Stats
              Text(
                'Today\'s Overview',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16.h),

              Row(
                children: [
                  Expanded(
                    child: DashboardStatsCard(
                      title: 'Active Trips',
                      value: tripState.trips
                          .where((trip) => trip.isActive)
                          .length
                          .toString(),
                      icon: Icons.directions_bus,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  SizedBox(width: 16.w),
                  Expanded(
                    child: DashboardStatsCard(
                      title: 'Completed',
                      value: tripState.trips
                          .where((trip) => trip.isCompleted)
                          .length
                          .toString(),
                      icon: Icons.check_circle,
                      color: AppTheme.successColor,
                    ),
                  ),
                ],
              ),

              SizedBox(height: 16.h),

              Row(
                children: [
                  Expanded(
                    child: DashboardStatsCard(
                      title: 'Students',
                      value: tripState.students.length.toString(),
                      icon: Icons.school,
                      color: AppTheme.secondaryColor,
                    ),
                  ),
                  SizedBox(width: 16.w),
                  Expanded(
                    child: DashboardStatsCard(
                      title: 'Distance',
                      value:
                          '${tripState.trips.fold(0.0, (sum, trip) => sum + (trip.distance ?? 0))} km',
                      icon: Icons.straighten,
                      color: AppTheme.infoColor,
                    ),
                  ),
                ],
              ),

              SizedBox(height: 24.h),

              // Recent Trips
              RecentTripsCard(),

              SizedBox(height: 24.h),
            ],
          ),
        ),
      ),
      floatingActionButton: tripState.currentTrip != null
          ? FloatingActionButton.extended(
              onPressed: () => context.go('/map'),
              icon: const Icon(Icons.location_on),
              label: const Text('Track Location'),
              backgroundColor: AppTheme.primaryColor,
            )
          : FloatingActionButton(
              onPressed: () => context.go('/trips'),
              child: const Icon(Icons.add),
              backgroundColor: AppTheme.primaryColor,
            ),
    );
  }
}


