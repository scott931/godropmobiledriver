import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/models/parent_trip_model.dart';

class RouteInfoCard extends StatelessWidget {
  final ParentTrip trip;

  const RouteInfoCard({super.key, required this.trip});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
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
              Icon(Icons.route, color: const Color(0xFF0052CC), size: 24.w),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  trip.routeName,
                  style: GoogleFonts.poppins(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
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
                  style: GoogleFonts.poppins(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w500,
                    color: _getStatusColor(trip.status),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          _buildScheduleInfo(),
          SizedBox(height: 16.h),
          if (trip.stops.isNotEmpty) ...[
            Text(
              'Route Stops',
              style: GoogleFonts.poppins(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
            SizedBox(height: 8.h),
            ...trip.stops.take(3).map((stop) => _buildStopItem(stop)),
            if (trip.stops.length > 3) ...[
              SizedBox(height: 8.h),
              GestureDetector(
                onTap: () => _viewFullRoute(context),
                child: Text(
                  'View ${trip.stops.length - 3} more stops',
                  style: GoogleFonts.poppins(
                    fontSize: 12.sp,
                    color: const Color(0xFF0052CC),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ],
          SizedBox(height: 16.h),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _contactDriver(context),
                  icon: Icon(Icons.phone, size: 16.w),
                  label: Text(
                    'Contact Driver',
                    style: GoogleFonts.poppins(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0052CC),
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 12.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleInfo() {
    return Column(
      children: [
        _buildTimeInfo(
          'Scheduled Start',
          trip.scheduledStartTime,
          trip.actualStartTime,
        ),
        SizedBox(height: 8.h),
        _buildTimeInfo(
          'Scheduled End',
          trip.scheduledEndTime,
          trip.actualEndTime,
        ),
      ],
    );
  }

  Widget _buildTimeInfo(String label, DateTime scheduled, DateTime? actual) {
    return Row(
      children: [
        Icon(Icons.access_time, size: 16.w, color: Colors.grey[600]),
        SizedBox(width: 4.w),
        Text(
          '$label: ',
          style: GoogleFonts.poppins(fontSize: 14.sp, color: Colors.grey[600]),
        ),
        Text(
          _formatTime(scheduled),
          style: GoogleFonts.poppins(
            fontSize: 14.sp,
            color: Colors.black,
            fontWeight: FontWeight.w500,
          ),
        ),
        if (actual != null) ...[
          SizedBox(width: 8.w),
          Text(
            '(Actual: ${_formatTime(actual)})',
            style: GoogleFonts.poppins(
              fontSize: 12.sp,
              color: Colors.green[600],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildStopItem(TripStop stop) {
    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(
          color: stop.isCompleted ? Colors.green[300]! : Colors.grey[300]!,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 8.w,
            height: 8.w,
            decoration: BoxDecoration(
              color: _getStopTypeColor(stop.type),
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  stop.name,
                  style: GoogleFonts.poppins(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w500,
                    color: Colors.black,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  stop.address,
                  style: GoogleFonts.poppins(
                    fontSize: 12.sp,
                    color: Colors.grey[600],
                  ),
                ),
                SizedBox(height: 4.h),
                Row(
                  children: [
                    Text(
                      '${stop.type.displayName} • ',
                      style: GoogleFonts.poppins(
                        fontSize: 12.sp,
                        color: _getStopTypeColor(stop.type),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      _formatTime(stop.scheduledTime),
                      style: GoogleFonts.poppins(
                        fontSize: 12.sp,
                        color: Colors.grey[600],
                      ),
                    ),
                    if (stop.actualTime != null) ...[
                      Text(
                        ' (${_formatTime(stop.actualTime!)})',
                        style: GoogleFonts.poppins(
                          fontSize: 12.sp,
                          color: Colors.green[600],
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          if (stop.isCompleted)
            Icon(Icons.check_circle, color: Colors.green[600], size: 16.w),
        ],
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

  Color _getStopTypeColor(StopType type) {
    switch (type) {
      case StopType.pickup:
        return Colors.blue;
      case StopType.dropoff:
        return Colors.green;
      case StopType.school:
        return Colors.purple;
    }
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  void _viewFullRoute(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        padding: EdgeInsets.all(20.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Full Route - ${trip.routeName}',
              style: GoogleFonts.poppins(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16.h),
            Expanded(
              child: ListView.builder(
                itemCount: trip.stops.length,
                itemBuilder: (context, index) {
                  final stop = trip.stops[index];
                  return _buildStopItem(stop);
                },
              ),
            ),
            SizedBox(height: 16.h),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0052CC),
                  padding: EdgeInsets.symmetric(vertical: 12.h),
                ),
                child: Text(
                  'Close',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _contactDriver(BuildContext context) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Calling ${trip.driverName}...')));
  }
}
