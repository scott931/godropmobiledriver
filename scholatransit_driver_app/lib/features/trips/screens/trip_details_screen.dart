import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers/trip_provider.dart';
import '../../../core/providers/location_provider.dart';
import '../../../core/models/trip_model.dart';
import '../../../core/theme/app_theme.dart';

class TripDetailsScreen extends ConsumerStatefulWidget {
  final int tripId;

  const TripDetailsScreen({super.key, required this.tripId});

  @override
  ConsumerState<TripDetailsScreen> createState() => _TripDetailsScreenState();
}

class _TripDetailsScreenState extends ConsumerState<TripDetailsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(tripProvider.notifier).loadTripDetails(widget.tripId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final tripState = ref.watch(tripProvider);
    final trip = tripState.selectedTrip;

    if (trip == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Trip Details')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text('Trip ${trip.tripId}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.read(tripProvider.notifier).loadTripDetails(widget.tripId);
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Trip Status Card
            _buildStatusCard(trip),
            SizedBox(height: 16.h),

            // Trip Information
            _buildInfoCard(trip),
            SizedBox(height: 16.h),

            // Route Information
            _buildRouteCard(trip),
            SizedBox(height: 16.h),

            // Students List
            _buildStudentsCard(),
            SizedBox(height: 16.h),

            // Trip Actions
            _buildActionsCard(trip),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard(Trip trip) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _getStatusGradient(trip.status),
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Column(
        children: [
          Icon(_getStatusIcon(trip.status), size: 48.w, color: Colors.white),
          SizedBox(height: 12.h),
          Text(
            _getStatusText(trip.status),
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            _getStatusDescription(trip.status),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.white.withOpacity(0.9),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(Trip trip) {
    return Container(
      width: double.infinity,
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Trip Information',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 16.h),
          _buildInfoRow('Trip ID', trip.tripId),
          _buildInfoRow('Type', _getTripTypeText(trip.type)),
          _buildInfoRow(
            'Scheduled Start',
            _formatDateTime(trip.scheduledStart),
          ),
          _buildInfoRow('Scheduled End', _formatDateTime(trip.scheduledEnd)),
          if (trip.actualStart != null)
            _buildInfoRow('Actual Start', _formatDateTime(trip.actualStart!)),
          if (trip.actualEnd != null)
            _buildInfoRow('Actual End', _formatDateTime(trip.actualEnd!)),
          if (trip.distance != null)
            _buildInfoRow(
              'Distance',
              '${trip.distance!.toStringAsFixed(1)} km',
            ),
          if (trip.duration != null)
            _buildInfoRow('Duration', _formatDuration(trip.duration!)),
        ],
      ),
    );
  }

  Widget _buildRouteCard(Trip trip) {
    return Container(
      width: double.infinity,
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Route Information',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 16.h),
          if (trip.startLocation != null)
            _buildLocationRow(
              'Start Location',
              trip.startLocation!,
              Icons.location_on,
              AppTheme.primaryColor,
            ),
          if (trip.endLocation != null)
            _buildLocationRow(
              'End Location',
              trip.endLocation!,
              Icons.location_off,
              AppTheme.successColor,
            ),
          if (trip.notes != null && trip.notes!.isNotEmpty) ...[
            SizedBox(height: 12.h),
            Text(
              'Notes',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
                color: AppTheme.textSecondary,
              ),
            ),
            SizedBox(height: 4.h),
            Text(trip.notes!, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ],
      ),
    );
  }

  Widget _buildStudentsCard() {
    final tripState = ref.watch(tripProvider);
    final students = tripState.students;

    return Container(
      width: double.infinity,
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Students (${students.length})',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: () => context.go('/students'),
                icon: const Icon(Icons.arrow_forward, size: 16),
                label: const Text('View All'),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          if (students.isEmpty)
            Center(
              child: Column(
                children: [
                  Icon(
                    Icons.school_outlined,
                    size: 48.w,
                    color: AppTheme.textTertiary,
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    'No students assigned',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textTertiary,
                    ),
                  ),
                ],
              ),
            )
          else
            ...students
                .take(3)
                .map(
                  (student) => Padding(
                    padding: EdgeInsets.only(bottom: 8.h),
                    child: _buildStudentRow(student),
                  ),
                ),
        ],
      ),
    );
  }

  Widget _buildActionsCard(Trip trip) {
    return Container(
      width: double.infinity,
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Actions',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 16.h),
          Row(
            children: [
              if (trip.status == TripStatus.pending)
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _startTrip(trip),
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Start Trip'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.successColor,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                    ),
                  ),
                ),
              if (trip.status == TripStatus.inProgress) ...[
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => context.go('/map'),
                    icon: const Icon(Icons.map),
                    label: const Text('Track Location'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                    ),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _endTrip(trip),
                    icon: const Icon(Icons.stop),
                    label: const Text('End Trip'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.errorColor,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120.w,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(value, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationRow(
    String label,
    String location,
    IconData icon,
    Color color,
  ) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20.w),
          SizedBox(width: 8.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(location, style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentRow(dynamic student) {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20.r,
            backgroundColor: AppTheme.primaryColor,
            child: Text(
              student.firstName[0].toUpperCase(),
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16.sp,
              ),
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${student.firstName} ${student.lastName}',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                ),
                Text(
                  'ID: ${student.studentId}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
            decoration: BoxDecoration(
              color: _getStudentStatusColor(student.status),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Text(
              _getStudentStatusText(student.status),
              style: TextStyle(
                color: Colors.white,
                fontSize: 12.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Color> _getStatusGradient(TripStatus status) {
    switch (status) {
      case TripStatus.pending:
        return [AppTheme.warningColor, AppTheme.warningColor.withOpacity(0.8)];
      case TripStatus.inProgress:
        return [AppTheme.primaryColor, AppTheme.primaryVariant];
      case TripStatus.completed:
        return [AppTheme.successColor, AppTheme.successColor.withOpacity(0.8)];
      case TripStatus.cancelled:
        return [AppTheme.errorColor, AppTheme.errorColor.withOpacity(0.8)];
      case TripStatus.delayed:
        return [AppTheme.warningColor, AppTheme.warningColor.withOpacity(0.8)];
    }
  }

  IconData _getStatusIcon(TripStatus status) {
    switch (status) {
      case TripStatus.pending:
        return Icons.schedule;
      case TripStatus.inProgress:
        return Icons.directions_bus;
      case TripStatus.completed:
        return Icons.check_circle;
      case TripStatus.cancelled:
        return Icons.cancel;
      case TripStatus.delayed:
        return Icons.warning;
    }
  }

  String _getStatusText(TripStatus status) {
    switch (status) {
      case TripStatus.pending:
        return 'Pending';
      case TripStatus.inProgress:
        return 'In Progress';
      case TripStatus.completed:
        return 'Completed';
      case TripStatus.cancelled:
        return 'Cancelled';
      case TripStatus.delayed:
        return 'Delayed';
    }
  }

  String _getStatusDescription(TripStatus status) {
    switch (status) {
      case TripStatus.pending:
        return 'Trip is scheduled and waiting to start';
      case TripStatus.inProgress:
        return 'Trip is currently active';
      case TripStatus.completed:
        return 'Trip has been completed successfully';
      case TripStatus.cancelled:
        return 'Trip has been cancelled';
      case TripStatus.delayed:
        return 'Trip is running behind schedule';
    }
  }

  String _getTripTypeText(TripType type) {
    switch (type) {
      case TripType.pickup:
        return 'Pickup';
      case TripType.dropoff:
        return 'Drop-off';
      case TripType.scheduled:
        return 'Scheduled';
      case TripType.emergency:
        return 'Emergency';
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  String _formatDuration(int minutes) {
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    if (hours > 0) {
      return '${hours}h ${mins}m';
    }
    return '${mins}m';
  }

  Color _getStudentStatusColor(dynamic status) {
    switch (status.toString().toLowerCase()) {
      case 'waiting':
        return AppTheme.warningColor;
      case 'on_bus':
        return AppTheme.primaryColor;
      case 'picked_up':
        return AppTheme.successColor;
      case 'dropped_off':
        return AppTheme.infoColor;
      case 'absent':
        return AppTheme.errorColor;
      default:
        return AppTheme.textTertiary;
    }
  }

  String _getStudentStatusText(dynamic status) {
    switch (status.toString().toLowerCase()) {
      case 'waiting':
        return 'Waiting';
      case 'on_bus':
        return 'On Bus';
      case 'picked_up':
        return 'Picked Up';
      case 'dropped_off':
        return 'Dropped Off';
      case 'absent':
        return 'Absent';
      default:
        return 'Unknown';
    }
  }

  Future<void> _startTrip(Trip trip) async {
    // Get current location
    final locationState = ref.read(locationProvider);
    final currentPosition = locationState.currentPosition;

    if (currentPosition == null) {
      // Try to get current position if not available
      await ref.read(locationProvider.notifier).getCurrentPosition();
      final updatedPosition = ref.read(locationProvider).currentPosition;

      if (updatedPosition == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Unable to get current location. Please enable location services.'),
              backgroundColor: AppTheme.errorColor,
            ),
          );
        }
        return;
      }
    }

    final position = currentPosition ?? ref.read(locationProvider).currentPosition!;

    final success = await ref
        .read(tripProvider.notifier)
        .startTrip(
          trip.tripId,
          startLocation: trip.startLocation ?? 'Unknown Location',
          latitude: position.latitude,
          longitude: position.longitude,
        );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Trip ${trip.tripId} started successfully'),
          backgroundColor: AppTheme.successColor,
        ),
      );
    }
  }

  Future<void> _endTrip(Trip trip) async {
    // Get current location
    final locationState = ref.read(locationProvider);
    final currentPosition = locationState.currentPosition;

    if (currentPosition == null) {
      // Try to get current position if not available
      await ref.read(locationProvider.notifier).getCurrentPosition();
      final updatedPosition = ref.read(locationProvider).currentPosition;

      if (updatedPosition == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Unable to get current location. Please enable location services.'),
              backgroundColor: AppTheme.errorColor,
            ),
          );
        }
        return;
      }
    }

    final position = currentPosition ?? ref.read(locationProvider).currentPosition!;

    final success = await ref
        .read(tripProvider.notifier)
        .endTrip(
          endLocation: trip.endLocation ?? 'Unknown Location',
          latitude: position.latitude,
          longitude: position.longitude,
        );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Trip ${trip.tripId} ended successfully'),
          backgroundColor: AppTheme.successColor,
        ),
      );
    }
  }
}
