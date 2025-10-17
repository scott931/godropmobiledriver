import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/providers/parent_provider.dart';

class ParentScheduleScreen extends ConsumerWidget {
  const ParentScheduleScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
          : _buildScheduleContent(context, ref, parentState),
    );
  }

  Widget _buildScheduleContent(
    BuildContext context,
    WidgetRef ref,
    parentState,
  ) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Today\'s Schedule',
            style: TextStyle(
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF0052CC),
            ),
          ),
          SizedBox(height: 16.h),
          if (parentState.activeTrips.isEmpty)
            _buildEmptyState(context)
          else
            ...parentState.activeTrips.map(
              (trip) => _buildTripCard(context, trip),
            ),
        ],
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
            'No Scheduled Trips',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'There are no scheduled trips for today.',
            style: TextStyle(fontSize: 14.sp, color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTripCard(BuildContext context, trip) {
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
            SizedBox(height: 12.h),
            Row(
              children: [
                Icon(Icons.access_time, size: 16.w, color: Colors.grey[600]),
                SizedBox(width: 4.w),
                Text(
                  'Scheduled: ${_formatTime(trip.scheduledStartTime)}',
                  style: TextStyle(fontSize: 14.sp, color: Colors.grey[600]),
                ),
              ],
            ),
            SizedBox(height: 8.h),
            Row(
              children: [
                Icon(Icons.person, size: 16.w, color: Colors.grey[600]),
                SizedBox(width: 4.w),
                Text(
                  'Driver: ${trip.driverName}',
                  style: TextStyle(fontSize: 14.sp, color: Colors.grey[600]),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(status) {
    switch (status) {
      case 'scheduled':
        return Colors.blue;
      case 'in_progress':
        return Colors.green;
      case 'completed':
        return Colors.grey;
      case 'cancelled':
        return Colors.red;
      case 'delayed':
        return Colors.orange;
      default:
        return Colors.blue;
    }
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}
