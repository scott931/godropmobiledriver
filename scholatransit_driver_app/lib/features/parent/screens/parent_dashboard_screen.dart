import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import '../../../core/providers/parent_provider.dart';
import '../../../core/providers/parent_auth_provider.dart';
import '../../../core/models/parent_trip_model.dart';
import '../../../core/models/parent_model.dart';
import '../widgets/bus_tracking_card.dart';
import '../widgets/child_status_card.dart';

class ParentDashboardScreen extends ConsumerStatefulWidget {
  const ParentDashboardScreen({super.key});

  @override
  ConsumerState<ParentDashboardScreen> createState() =>
      _ParentDashboardScreenState();
}

class _ParentDashboardScreenState extends ConsumerState<ParentDashboardScreen> {
  MapboxMap? _mapController;
  PointAnnotationManager? _pointAnnotationManager;
  PointAnnotation? _busLocationAnnotation;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeDashboard();
    });
  }

  void _initializeDashboard() {
    // Load parent data
    ref.read(parentProvider.notifier).loadParentData();

    // Start notification monitoring
    ref.read(parentProvider.notifier).startNotificationMonitoring();
  }

  @override
  Widget build(BuildContext context) {
    final parentState = ref.watch(parentProvider);
    final authState = ref.watch(parentAuthProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        automaticallyImplyLeading: false,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
        ),
        title: Row(
          children: [
            Text(
              'SchoolSafe',
              style: GoogleFonts.poppins(
                fontSize: 20.sp,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF0052CC),
              ),
            ),
            const Spacer(),
            Container(
              margin: EdgeInsets.only(right: 8.w),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: IconButton(
                icon: const Icon(
                  Icons.notifications_outlined,
                  color: Colors.black54,
                  size: 20,
                ),
                onPressed: () => context.go('/parent/notifications'),
              ),
            ),
            Container(
              margin: EdgeInsets.only(right: 16.w),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: IconButton(
                icon: const Icon(
                  Icons.account_circle_outlined,
                  color: Colors.black54,
                  size: 20,
                ),
                onPressed: () => context.go('/parent/profile'),
              ),
            ),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(parentProvider.notifier).refreshData();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome Section
              _buildWelcomeSection(authState.parent),

              // Active Trips Section
              if (parentState.activeTrips.isNotEmpty) ...[
                _buildActiveTripsSection(parentState.activeTrips),
                SizedBox(height: 20.h),
              ],

              // Children Status Section
              if (parentState.children.isNotEmpty) ...[
                _buildChildrenStatusSection(parentState.children),
                SizedBox(height: 20.h),
              ],

              // Bus Tracking Map
              _buildBusTrackingMap(parentState),
              SizedBox(height: 20.h),

              // Quick Actions
              _buildQuickActionsSection(),
              SizedBox(height: 20.h),

              // Recent Notifications
              _buildRecentNotificationsSection(parentState.notifications),
              SizedBox(height: 20.h),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeSection(parent) {
    return Container(
      margin: EdgeInsets.all(20.w),
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0052CC), Color(0xFF0066FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0052CC).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Good ${_getGreeting()}!',
            style: GoogleFonts.poppins(
              fontSize: 24.sp,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            parent?.fullName ?? 'Parent',
            style: GoogleFonts.poppins(
              fontSize: 18.sp,
              fontWeight: FontWeight.w500,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            'Track your children\'s safety in real-time',
            style: GoogleFonts.poppins(
              fontSize: 14.sp,
              color: Colors.white.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveTripsSection(List<ParentTrip> activeTrips) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Active Trips',
            style: GoogleFonts.poppins(
              fontSize: 18.sp,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          SizedBox(height: 12.h),
          ...activeTrips.map((trip) => BusTrackingCard(trip: trip)),
        ],
      ),
    );
  }

  Widget _buildChildrenStatusSection(List<Child> children) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Children Status',
            style: GoogleFonts.poppins(
              fontSize: 18.sp,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          SizedBox(height: 12.h),
          ...children.map((child) => ChildStatusCard(child: child)),
        ],
      ),
    );
  }

  Widget _buildBusTrackingMap(ParentState parentState) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20.w),
      height: 200.h,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12.r),
        child: Stack(
          children: [
            // Map placeholder - in real implementation, use MapboxMap
            Container(
              width: double.infinity,
              height: double.infinity,
              color: Colors.grey[200],
              child: const Center(
                child: Icon(Icons.map, size: 48, color: Colors.grey),
              ),
            ),
            // Bus location indicator
            if (parentState.currentLocation != null)
              Positioned(
                top: 20.h,
                left: 20.w,
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 12.w,
                    vertical: 6.h,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20.r),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.directions_bus,
                        color: const Color(0xFF0052CC),
                        size: 16.w,
                      ),
                      SizedBox(width: 4.w),
                      Text(
                        'Bus Location',
                        style: GoogleFonts.poppins(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w500,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionsSection() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Actions',
            style: GoogleFonts.poppins(
              fontSize: 18.sp,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          SizedBox(height: 16.h),
          Row(
            children: [
              Expanded(
                child: _QuickActionCard(
                  icon: Icons.directions_bus,
                  label: 'Track Bus',
                  onTap: () => context.go('/parent/tracking'),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: _QuickActionCard(
                  icon: Icons.schedule,
                  label: 'Schedule',
                  onTap: () => context.go('/parent/schedule'),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: _QuickActionCard(
                  icon: Icons.chat,
                  label: 'Messages',
                  onTap: () => context.go('/parent/messages'),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: _QuickActionCard(
                  icon: Icons.emergency,
                  label: 'Emergency',
                  onTap: () => context.go('/parent/emergency'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRecentNotificationsSection(
    List<Map<String, dynamic>> notifications,
  ) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent Notifications',
                style: GoogleFonts.poppins(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
              TextButton(
                onPressed: () => context.go('/parent/notifications'),
                child: Text(
                  'View All',
                  style: GoogleFonts.poppins(
                    fontSize: 14.sp,
                    color: const Color(0xFF0052CC),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          if (notifications.isEmpty)
            Container(
              padding: EdgeInsets.all(20.w),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Center(
                child: Text(
                  'No recent notifications',
                  style: GoogleFonts.poppins(
                    fontSize: 14.sp,
                    color: Colors.grey[600],
                  ),
                ),
              ),
            )
          else
            ...notifications
                .take(3)
                .map(
                  (notification) => Container(
                    margin: EdgeInsets.only(bottom: 8.h),
                    padding: EdgeInsets.all(12.w),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8.r),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.notifications,
                          color: const Color(0xFF0052CC),
                          size: 20.w,
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: Text(
                            notification['message'] ?? 'Notification',
                            style: GoogleFonts.poppins(
                              fontSize: 14.sp,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
        ],
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Morning';
    if (hour < 17) return 'Afternoon';
    return 'Evening';
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              width: 40.w,
              height: 40.w,
              decoration: BoxDecoration(
                color: const Color(0xFF0052CC).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Icon(icon, color: const Color(0xFF0052CC), size: 20.w),
            ),
            SizedBox(height: 8.h),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 12.sp,
                color: Colors.black,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
