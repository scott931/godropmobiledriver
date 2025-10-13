import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
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
      ref.read(tripProvider.notifier).loadActiveTrips();
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
        ref.read(tripProvider.notifier).loadActiveTrips();
      } else if (!next.isAuthenticated && previous?.isAuthenticated == true) {
        // User just logged out, reset trip state
        print('🔄 DEBUG: User logged out, resetting trip state...');
        ref.read(tripProvider.notifier).resetState();
      }
    });

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Text(
          'Dashboard',
          style: GoogleFonts.poppins(
            fontSize: 20.sp,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        actions: [
          Container(
            margin: EdgeInsets.only(right: 8.w),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: IconButton(
              icon: const Icon(Icons.notifications_outlined, color: Colors.black54),
              onPressed: () => context.go('/notifications'),
            ),
          ),
          Container(
            margin: EdgeInsets.only(right: 16.w),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: IconButton(
              icon: const Icon(Icons.account_circle_outlined, color: Colors.black54),
              onPressed: () => context.go('/profile'),
            ),
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
                padding: EdgeInsets.all(24.w),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20.r),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF667EEA).withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(12.w),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(16.r),
                          ),
                          child: Icon(
                            Icons.waving_hand,
                            color: Colors.white,
                            size: 24.w,
                          ),
                        ),
                        SizedBox(width: 16.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Welcome back,',
                                style: GoogleFonts.poppins(
                                  fontSize: 16.sp,
                                  color: Colors.white.withOpacity(0.9),
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                              SizedBox(height: 4.h),
                              Text(
                                authState.driver?.fullName ?? 'Driver',
                                style: GoogleFonts.poppins(
                                  fontSize: 22.sp,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16.h),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20.r),
                      ),
                      child: Text(
                        'Ready to start your day?',
                        style: GoogleFonts.poppins(
                          fontSize: 14.sp,
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
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
              Row(
                children: [
                  Container(
                    width: 4.w,
                    height: 24.h,
                    decoration: BoxDecoration(
                      color: const Color(0xFF667EEA),
                      borderRadius: BorderRadius.circular(2.r),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Text(
                    'Today\'s Overview',
                    style: GoogleFonts.poppins(
                      fontSize: 20.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                ],
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
          ? Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16.r),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF667EEA).withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: FloatingActionButton.extended(
                onPressed: () => context.go('/map'),
                icon: const Icon(Icons.location_on, color: Colors.white),
                label: Text(
                  'Track Location',
                  style: GoogleFonts.poppins(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                backgroundColor: const Color(0xFF667EEA),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16.r),
                ),
              ),
            )
          : Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16.r),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF667EEA).withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: FloatingActionButton(
                onPressed: () => context.go('/trips'),
                child: const Icon(Icons.add, color: Colors.white),
                backgroundColor: const Color(0xFF667EEA),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16.r),
                ),
              ),
            ),
    );
  }
}


