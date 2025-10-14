import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
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
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.close, color: Colors.grey[700], size: 24.w),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/trips');
            }
          },
        ),
        title: Text(
          '${trip.startLocation ?? "Unknown"} to ${trip.endLocation ?? "Unknown"}',
          style: GoogleFonts.poppins(
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1E3A8A),
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.grey[600], size: 24.w),
            onPressed: () {
              ref.read(tripProvider.notifier).loadTripDetails(widget.tripId);
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Trip Date Header
            _buildTripDateHeader(trip),
            SizedBox(height: 24.h),

            // Trip Route Card
            _buildRouteCard(trip),
            SizedBox(height: 24.h),

            // Trip Information Card
            _buildInfoCard(trip),
            SizedBox(height: 24.h),

            // Students List Card
            _buildStudentsCard(),
            SizedBox(height: 24.h),

            // Trip Actions Card
            _buildActionsCard(trip),
            SizedBox(height: 20.h),
          ],
        ),
      ),
    );
  }

  Widget _buildTripDateHeader(Trip trip) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
      decoration: BoxDecoration(
        color: const Color(0xFF1E3A8A),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Row(
        children: [
          Icon(Icons.directions_bus, color: Colors.white, size: 24.w),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _formatDate(trip.scheduledStart),
                  style: GoogleFonts.poppins(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  'Trip ID: ${trip.tripId}',
                  style: GoogleFonts.poppins(
                    fontSize: 14.sp,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16.r),
            ),
            child: Text(
              _getStatusText(trip.status),
              style: GoogleFonts.poppins(
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(Trip trip) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Trip Information Header
          Row(
            children: [
              Container(
                width: 4.w,
                height: 24.h,
                decoration: BoxDecoration(
                  color: const Color(0xFF1E3A8A),
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
              SizedBox(width: 12.w),
              Text(
                'Trip Information',
                style: GoogleFonts.poppins(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
            ],
          ),
          SizedBox(height: 24.h),

          // Trip Details Grid
          Row(
            children: [
              Expanded(
                child: _buildInfoItem(
                  icon: Icons.directions_bus,
                  label: 'Vehicle',
                  value: trip.vehicleName ?? 'Unknown',
                  color: const Color(0xFF1E3A8A),
                ),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: _buildInfoItem(
                  icon: Icons.person,
                  label: 'Driver',
                  value: trip.driverName ?? 'Unknown',
                  color: const Color(0xFF059669),
                ),
              ),
            ],
          ),

          SizedBox(height: 16.h),

          Row(
            children: [
              Expanded(
                child: _buildInfoItem(
                  icon: Icons.schedule,
                  label: 'Duration',
                  value: trip.duration != null
                      ? _formatDuration(trip.duration!)
                      : 'N/A',
                  color: const Color(0xFFDC2626),
                ),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: _buildInfoItem(
                  icon: Icons.straighten,
                  label: 'Distance',
                  value: trip.distance != null
                      ? '${trip.distance!.toStringAsFixed(1)} km'
                      : 'N/A',
                  color: const Color(0xFF7C3AED),
                ),
              ),
            ],
          ),

          SizedBox(height: 16.h),

          // Trip Type
          Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Row(
              children: [
                Icon(Icons.category, color: Colors.grey[600], size: 20.w),
                SizedBox(width: 12.w),
                Text(
                  'Trip Type:',
                  style: GoogleFonts.poppins(
                    fontSize: 14.sp,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(width: 8.w),
                Text(
                  _getTripTypeText(trip.type),
                  style: GoogleFonts.poppins(
                    fontSize: 14.sp,
                    color: Colors.black,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRouteCard(Trip trip) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Route Header
          Row(
            children: [
              Container(
                width: 4.w,
                height: 24.h,
                decoration: BoxDecoration(
                  color: const Color(0xFF1E3A8A),
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
              SizedBox(width: 12.w),
              Text(
                'Route Details',
                style: GoogleFonts.poppins(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
            ],
          ),
          SizedBox(height: 24.h),

          // Departure Information
          _buildLocationSection(
            icon: Icons.directions_bus,
            time: _formatTime(trip.scheduledStart),
            location: trip.startLocation ?? 'Unknown',
            label: 'Departure',
            color: const Color(0xFF1E3A8A),
          ),

          SizedBox(height: 20.h),

          // Route Line with Details
          _buildRouteLine(trip),

          SizedBox(height: 20.h),

          // Arrival Information
          _buildLocationSection(
            icon: Icons.bus_alert,
            time: _formatTime(trip.scheduledEnd),
            location: trip.endLocation ?? 'Unknown',
            label: 'Arrival',
            color: const Color(0xFF059669),
          ),

          if (trip.notes != null && trip.notes!.isNotEmpty) ...[
            SizedBox(height: 24.h),
            Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Notes',
                    style: GoogleFonts.poppins(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    trip.notes!,
                    style: GoogleFonts.poppins(
                      fontSize: 14.sp,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
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
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Students Header
          Row(
            children: [
              Container(
                width: 4.w,
                height: 24.h,
                decoration: BoxDecoration(
                  color: const Color(0xFF1E3A8A),
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
              SizedBox(width: 12.w),
              Text(
                'Students (${students.length})',
                style: GoogleFonts.poppins(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => context.go('/students'),
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 12.w,
                    vertical: 6.h,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E3A8A).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Text(
                    'View All',
                    style: GoogleFonts.poppins(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1E3A8A),
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 20.h),

          if (students.isEmpty)
            Center(
              child: Column(
                children: [
                  Container(
                    width: 60.w,
                    height: 60.w,
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.school_outlined,
                      size: 30.w,
                      color: Colors.grey[400],
                    ),
                  ),
                  SizedBox(height: 12.h),
                  Text(
                    'No students assigned',
                    style: GoogleFonts.poppins(
                      fontSize: 16.sp,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
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
                    padding: EdgeInsets.only(bottom: 12.h),
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
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Actions Header
          Row(
            children: [
              Container(
                width: 4.w,
                height: 24.h,
                decoration: BoxDecoration(
                  color: const Color(0xFF1E3A8A),
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
              SizedBox(width: 12.w),
              Text(
                'Trip Actions',
                style: GoogleFonts.poppins(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
            ],
          ),
          SizedBox(height: 20.h),

          // Action Buttons
          if (trip.status == TripStatus.pending)
            _buildActionButton(
              icon: Icons.play_arrow,
              label: 'Start Trip',
              description: 'Begin the scheduled trip',
              color: const Color(0xFF059669),
              onTap: () => _startTrip(trip),
            ),

          if (trip.status == TripStatus.inProgress) ...[
            _buildActionButton(
              icon: Icons.map,
              label: 'Track Location',
              description: 'View real-time location tracking',
              color: const Color(0xFF1E3A8A),
              onTap: () => context.go('/map'),
            ),
            SizedBox(height: 12.h),
            _buildActionButton(
              icon: Icons.stop,
              label: 'End Trip',
              description: 'Complete the current trip',
              color: const Color(0xFFDC2626),
              onTap: () => _endTrip(trip),
            ),
          ],

          if (trip.status == TripStatus.completed)
            _buildActionButton(
              icon: Icons.check_circle,
              label: 'Trip Completed',
              description: 'This trip has been completed successfully',
              color: const Color(0xFF059669),
              onTap: null,
            ),

          if (trip.status == TripStatus.cancelled)
            _buildActionButton(
              icon: Icons.cancel,
              label: 'Trip Cancelled',
              description: 'This trip has been cancelled',
              color: const Color(0xFFDC2626),
              onTap: null,
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
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Container(
            width: 40.w,
            height: 40.w,
            decoration: BoxDecoration(
              color: _getStudentStatusColor(student.status).withOpacity(0.1),
              shape: BoxShape.circle,
              border: Border.all(
                color: _getStudentStatusColor(student.status).withOpacity(0.3),
                width: 2,
              ),
            ),
            child: Center(
              child: Text(
                student.firstName[0].toUpperCase(),
                style: GoogleFonts.poppins(
                  color: _getStudentStatusColor(student.status),
                  fontWeight: FontWeight.bold,
                  fontSize: 16.sp,
                ),
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
                  style: GoogleFonts.poppins(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  'ID: ${student.studentId}',
                  style: GoogleFonts.poppins(
                    fontSize: 12.sp,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
            decoration: BoxDecoration(
              color: _getStudentStatusColor(student.status).withOpacity(0.1),
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(
                color: _getStudentStatusColor(student.status).withOpacity(0.3),
              ),
            ),
            child: Text(
              _getStudentStatusText(student.status),
              style: GoogleFonts.poppins(
                color: _getStudentStatusColor(student.status),
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
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

  Widget _buildLocationSection({
    required IconData icon,
    required String time,
    required String location,
    required String label,
    required Color color,
  }) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20.w),
        SizedBox(width: 12.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$time - $location',
                style: GoogleFonts.poppins(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
              SizedBox(height: 2.h),
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 12.sp,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRouteLine(Trip trip) {
    return Row(
      children: [
        SizedBox(width: 10.w),
        Container(
          width: 2.w,
          height: 40.h,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(1.r),
          ),
        ),
        SizedBox(width: 20.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${_formatDuration(trip.duration ?? 0)} trip',
                style: GoogleFonts.poppins(
                  fontSize: 12.sp,
                  color: Colors.grey[600],
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                '${trip.routeName ?? 'Unknown Route'}',
                style: GoogleFonts.poppins(
                  fontSize: 12.sp,
                  color: Colors.grey[600],
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                'Vehicle: ${trip.vehicleName ?? 'Unknown'}',
                style: GoogleFonts.poppins(
                  fontSize: 12.sp,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16.w),
              SizedBox(width: 8.w),
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 12.sp,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required String description,
    required Color color,
    required VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: onTap != null ? color.withOpacity(0.1) : Colors.grey[100],
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: onTap != null ? color.withOpacity(0.3) : Colors.grey[300]!,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                color: onTap != null ? color : Colors.grey[400],
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Icon(icon, color: Colors.white, size: 20.w),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.poppins(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                      color: onTap != null ? color : Colors.grey[600],
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    description,
                    style: GoogleFonts.poppins(
                      fontSize: 12.sp,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            if (onTap != null)
              Icon(Icons.arrow_forward_ios, color: color, size: 16.w),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final date = DateTime(dateTime.year, dateTime.month, dateTime.day);

    if (date == today) {
      return 'Today, ${_getDayName(dateTime.weekday)}';
    } else if (date == today.add(const Duration(days: 1))) {
      return 'Tomorrow, ${_getDayName(dateTime.weekday)}';
    } else {
      return '${_getDayName(dateTime.weekday)}, ${_getMonthName(dateTime.month)} ${dateTime.day}';
    }
  }

  String _formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  String _getDayName(int weekday) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[weekday - 1];
  }

  String _getMonthName(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[month - 1];
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
              content: Text(
                'Unable to get current location. Please enable location services.',
              ),
              backgroundColor: AppTheme.errorColor,
            ),
          );
        }
        return;
      }
    }

    final position =
        currentPosition ?? ref.read(locationProvider).currentPosition!;

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
              content: Text(
                'Unable to get current location. Please enable location services.',
              ),
              backgroundColor: AppTheme.errorColor,
            ),
          );
        }
        return;
      }
    }

    final position =
        currentPosition ?? ref.read(locationProvider).currentPosition!;

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
