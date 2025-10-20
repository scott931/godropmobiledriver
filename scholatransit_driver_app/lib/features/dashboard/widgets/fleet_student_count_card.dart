import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/providers/trip_provider.dart';

class FleetStudentCountCard extends ConsumerWidget {
  const FleetStudentCountCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fleetStudentCountsAsync = ref.watch(fleetStudentCountsProvider);
    final activeTrips = ref.watch(activeTripsProvider);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.directions_bus, color: Colors.blue[600], size: 24.w),
              SizedBox(width: 12.w),
              Text(
                'Fleet Student Count',
                style: GoogleFonts.poppins(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          fleetStudentCountsAsync.when(
            data: (tripCounts) {
              if (tripCounts.isEmpty) {
                return _EmptyFleetState();
              }

              return Column(
                children: [
                  // Total count
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(16.w),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(color: Colors.blue[200]!),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total Fleet Students',
                          style: GoogleFonts.poppins(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w500,
                            color: Colors.blue[800],
                          ),
                        ),
                        Text(
                          '${tripCounts.values.fold(0, (sum, count) => sum + count)}',
                          style: GoogleFonts.poppins(
                            fontSize: 20.sp,
                            fontWeight: FontWeight.w700,
                            color: Colors.blue[800],
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 16.h),
                  // Individual trip counts
                  ...tripCounts.entries.map((entry) {
                    final trip = activeTrips.firstWhere(
                      (t) => t.tripId == entry.key,
                      orElse: () => activeTrips.first,
                    );
                    return _TripStudentCountItem(
                      tripName: trip.routeName ?? 'Trip ${trip.tripId}',
                      studentCount: entry.value,
                    );
                  }),
                ],
              );
            },
            loading: () => _LoadingState(),
            error: (error, stackTrace) => _ErrorState(error.toString()),
          ),
        ],
      ),
    );
  }
}

class _TripStudentCountItem extends StatelessWidget {
  final String tripName;
  final int studentCount;

  const _TripStudentCountItem({
    required this.tripName,
    required this.studentCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              tripName,
              style: GoogleFonts.poppins(
                fontSize: 14.sp,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
            decoration: BoxDecoration(
              color: Colors.blue[100],
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Text(
              '$studentCount students',
              style: GoogleFonts.poppins(
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
                color: Colors.blue[800],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyFleetState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(20.w),
      child: Column(
        children: [
          Icon(
            Icons.directions_bus_outlined,
            size: 48.w,
            color: Colors.grey[400],
          ),
          SizedBox(height: 12.h),
          Text(
            'No Active Trips',
            style: GoogleFonts.poppins(
              fontSize: 16.sp,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            'Start a trip to see student counts',
            style: GoogleFonts.poppins(
              fontSize: 12.sp,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadingState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(20.w),
      child: Column(
        children: [
          SizedBox(
            width: 24.w,
            height: 24.w,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[600]!),
            ),
          ),
          SizedBox(height: 12.h),
          Text(
            'Loading fleet data...',
            style: GoogleFonts.poppins(
              fontSize: 14.sp,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String error;

  const _ErrorState(this.error);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(20.w),
      child: Column(
        children: [
          Icon(Icons.error_outline, size: 48.w, color: Colors.red[400]),
          SizedBox(height: 12.h),
          Text(
            'Failed to load fleet data',
            style: GoogleFonts.poppins(
              fontSize: 16.sp,
              fontWeight: FontWeight.w500,
              color: Colors.red[600],
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            error,
            style: GoogleFonts.poppins(fontSize: 12.sp, color: Colors.red[500]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
