import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/models/parent_trip_model.dart';

class BusTrackingCard extends StatelessWidget {
  final ParentTrip trip;

  const BusTrackingCard({super.key, required this.trip});

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
              Icon(
                Icons.directions_bus,
                color: _getStatusColor(trip.status),
                size: 24.w,
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  trip.tripName,
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
          SizedBox(height: 12.h),
          if (trip.currentAddress != null) ...[
            Row(
              children: [
                Icon(Icons.location_on, size: 16.w, color: Colors.grey[600]),
                SizedBox(width: 4.w),
                Expanded(
                  child: Text(
                    trip.currentAddress!,
                    style: GoogleFonts.poppins(
                      fontSize: 14.sp,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 8.h),
          ],
          if (trip.estimatedArrivalMinutes != null) ...[
            Row(
              children: [
                Icon(Icons.access_time, size: 16.w, color: Colors.grey[600]),
                SizedBox(width: 4.w),
                Text(
                  'ETA: ${trip.estimatedArrivalMinutes} minutes',
                  style: GoogleFonts.poppins(
                    fontSize: 14.sp,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            SizedBox(height: 8.h),
          ],
          Row(
            children: [
              Icon(Icons.person, size: 16.w, color: Colors.grey[600]),
              SizedBox(width: 4.w),
              Text(
                'Driver: ${trip.driverName}',
                style: GoogleFonts.poppins(
                  fontSize: 14.sp,
                  color: Colors.grey[600],
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => _callDriver(context),
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 12.w,
                    vertical: 6.h,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0052CC).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.phone,
                        size: 14.w,
                        color: const Color(0xFF0052CC),
                      ),
                      SizedBox(width: 4.w),
                      Text(
                        'Call',
                        style: GoogleFonts.poppins(
                          fontSize: 12.sp,
                          color: const Color(0xFF0052CC),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
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

  void _callDriver(BuildContext context) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Calling ${trip.driverName}...')));
  }
}
