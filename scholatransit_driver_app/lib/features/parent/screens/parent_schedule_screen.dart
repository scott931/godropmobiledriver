import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/models/parent_trip_model.dart';
import '../../../core/providers/parent_provider.dart';

class ParentScheduleScreen extends ConsumerStatefulWidget {
  const ParentScheduleScreen({super.key});

  @override
  ConsumerState<ParentScheduleScreen> createState() =>
      _ParentScheduleScreenState();
}

class _ParentScheduleScreenState extends ConsumerState<ParentScheduleScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(parentProvider.notifier).loadParentTrips();
    });
  }

  @override
  Widget build(BuildContext context) {
    final parentState = ref.watch(parentProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Schedule'),
        backgroundColor: const Color(0xFF0052CC),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: parentState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () async {
                await ref.read(parentProvider.notifier).loadParentTrips();
              },
              child: _buildScheduleContent(context, parentState),
            ),
    );
  }

  Widget _buildScheduleContent(BuildContext context, ParentState parentState) {
    final trips = parentState.parentTrips;
    if (trips.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(height: 80.h),
          _buildEmptyState(context),
        ],
      );
    }

    final now = DateTime.now();
    final upcoming = trips
        .where(
          (t) =>
              !t.isActive &&
              t.scheduledStartTime.isAfter(now.subtract(const Duration(minutes: 5))),
        )
        .toList();
    final live = trips.where((t) => t.isActive).toList();
    final pastToday = trips
        .where(
          (t) =>
              !t.isActive &&
              !t.scheduledStartTime.isAfter(now.subtract(const Duration(minutes: 5))),
        )
        .toList();

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.all(16.w),
      children: [
        Text(
          'Your child’s trips',
          style: TextStyle(
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF0052CC),
          ),
        ),
        SizedBox(height: 8.h),
        Text(
          'See pickup and drop-off times before the bus starts.',
          style: TextStyle(fontSize: 14.sp, color: Colors.grey[700]),
        ),
        SizedBox(height: 20.h),
        if (upcoming.isNotEmpty) ...[
          _sectionTitle('Upcoming'),
          ...upcoming.map((trip) => _buildTripCard(context, trip)),
        ],
        if (live.isNotEmpty) ...[
          _sectionTitle('In progress'),
          ...live.map((trip) => _buildTripCard(context, trip)),
        ],
        if (pastToday.isNotEmpty) ...[
          _sectionTitle('Earlier today'),
          ...pastToday.map((trip) => _buildTripCard(context, trip)),
        ],
      ],
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h, top: 8.h),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14.sp,
          fontWeight: FontWeight.w600,
          color: Colors.grey[800],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.schedule_outlined, size: 80.w, color: Colors.grey[400]),
          SizedBox(height: 16.h),
          Text(
            'No trips scheduled',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 8.h),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.w),
            child: Text(
              'When your child has a trip assigned, it will appear here before it begins.',
              style: TextStyle(fontSize: 14.sp, color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTripCard(BuildContext context, ParentTrip trip) {
    return Card(
      margin: EdgeInsets.only(bottom: 16.h),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.directions_bus,
                  color: const Color(0xFF0052CC),
                  size: 24.w,
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text(
                    trip.tripName,
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: _getStatusColor(trip.status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Text(
                    trip.status.displayName,
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w500,
                      color: _getStatusColor(trip.status),
                    ),
                  ),
                ),
              ],
            ),
            if (trip.children.isNotEmpty) ...[
              SizedBox(height: 10.h),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.child_care, size: 18.w, color: Colors.grey[600]),
                  SizedBox(width: 6.w),
                  Expanded(
                    child: Text(
                      trip.children.map((c) => c.fullName).join(', '),
                      style: TextStyle(fontSize: 14.sp, color: Colors.grey[800]),
                    ),
                  ),
                ],
              ),
            ],
            SizedBox(height: 12.h),
            Row(
              children: [
                Icon(Icons.access_time, size: 16.w, color: Colors.grey[600]),
                SizedBox(width: 4.w),
                Expanded(
                  child: Text(
                    'Scheduled: ${_formatTime(trip.scheduledStartTime)} – ${_formatTime(trip.scheduledEndTime)}',
                    style: TextStyle(fontSize: 14.sp, color: Colors.grey[600]),
                  ),
                ),
              ],
            ),
            if (trip.isScheduled &&
                trip.scheduledStartTime.isAfter(DateTime.now())) ...[
              SizedBox(height: 6.h),
              Text(
                _startsInLabel(trip.scheduledStartTime),
                style: TextStyle(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF0052CC),
                ),
              ),
            ],
            SizedBox(height: 8.h),
            Row(
              children: [
                Icon(Icons.person, size: 16.w, color: Colors.grey[600]),
                SizedBox(width: 4.w),
                Expanded(
                  child: Text(
                    'Driver: ${trip.driverName}',
                    style: TextStyle(fontSize: 14.sp, color: Colors.grey[600]),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(TripStatus status) {
    switch (status) {
      case TripStatus.scheduled:
        return Colors.blue;
      case TripStatus.inProgress:
        return Colors.green;
      case TripStatus.completed:
        return Colors.grey;
      case TripStatus.cancelled:
        return Colors.red;
      case TripStatus.delayed:
        return Colors.orange;
    }
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  String _startsInLabel(DateTime scheduledStart) {
    final d = scheduledStart.difference(DateTime.now());
    if (d.isNegative) return 'Starting soon';
    if (d.inDays >= 1) {
      return 'Starts in ${d.inDays} day${d.inDays == 1 ? '' : 's'}';
    }
    if (d.inHours >= 1) {
      return 'Starts in ${d.inHours} h ${d.inMinutes.remainder(60)} min';
    }
    if (d.inMinutes >= 1) {
      return 'Starts in ${d.inMinutes} min';
    }
    return 'Starting soon';
  }
}
