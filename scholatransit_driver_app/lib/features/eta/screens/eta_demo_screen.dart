import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/providers/eta_provider.dart';
import '../../../core/providers/trip_provider.dart';
import '../../../core/models/trip_model.dart';
import '../../../core/models/eta_model.dart';

class ETADemoScreen extends ConsumerStatefulWidget {
  const ETADemoScreen({super.key});

  @override
  ConsumerState<ETADemoScreen> createState() => _ETADemoScreenState();
}

class _ETADemoScreenState extends ConsumerState<ETADemoScreen> {
  @override
  Widget build(BuildContext context) {
    final etaState = ref.watch(etaProvider);
    final tripState = ref.watch(tripProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          'ETA Demo',
          style: GoogleFonts.poppins(
            fontSize: 20.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: const Color(0xFF3B82F6),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // ETA Status Card
          Container(
            margin: EdgeInsets.all(16.w),
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
                Text(
                  'Current ETA Status',
                  style: GoogleFonts.poppins(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                SizedBox(height: 16.h),

                if (etaState.currentETA != null) ...[
                  _buildETAInfo(etaState.currentETA!),
                ] else ...[
                  _buildNoETAState(),
                ],

                SizedBox(height: 16.h),

                // ETA Actions
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: etaState.isTracking
                            ? () => ref
                                  .read(etaProvider.notifier)
                                  .stopETATracking()
                            : () => _startETATracking(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: etaState.isTracking
                              ? Colors.red
                              : Colors.green,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 12.h),
                        ),
                        child: Text(
                          etaState.isTracking
                              ? 'Stop Tracking'
                              : 'Start Tracking',
                          style: GoogleFonts.poppins(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () =>
                            ref.read(etaProvider.notifier).refreshETA(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 12.h),
                        ),
                        child: Text(
                          'Refresh',
                          style: GoogleFonts.poppins(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Trip ETA List
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              itemCount: tripState.trips.length,
              itemBuilder: (context, index) {
                final trip = tripState.trips[index];
                return _buildTripETACard(trip);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildETAInfo(ETAInfo etaInfo) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: etaInfo.isDelayed
            ? Colors.red.withOpacity(0.1)
            : Colors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: etaInfo.isDelayed
              ? Colors.red.withOpacity(0.3)
              : Colors.green.withOpacity(0.3),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                etaInfo.isDelayed ? Icons.warning : Icons.schedule,
                color: etaInfo.isDelayed ? Colors.red : Colors.green,
                size: 24.w,
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ETA: ${etaInfo.formattedTimeToArrival}',
                      style: GoogleFonts.poppins(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                        color: etaInfo.isDelayed ? Colors.red : Colors.green,
                      ),
                    ),
                    Text(
                      'Distance: ${etaInfo.formattedDistance}',
                      style: GoogleFonts.poppins(
                        fontSize: 12.sp,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              if (etaInfo.isDelayed)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4.r),
                  ),
                  child: Text(
                    'DELAYED',
                    style: GoogleFonts.poppins(
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.red,
                    ),
                  ),
                ),
            ],
          ),

          if (etaInfo.trafficMultiplier != null) ...[
            SizedBox(height: 8.h),
            Row(
              children: [
                Icon(Icons.traffic, size: 16.w, color: Colors.grey[600]),
                SizedBox(width: 4.w),
                Text(
                  'Traffic: ${_getTrafficCondition(etaInfo.trafficMultiplier!)}',
                  style: GoogleFonts.poppins(
                    fontSize: 12.sp,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNoETAState() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.grey.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: Colors.grey[600], size: 24.w),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              'No ETA data available. Start a trip to see ETA information.',
              style: GoogleFonts.poppins(
                fontSize: 14.sp,
                color: Colors.grey[600],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTripETACard(Trip trip) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8.w,
                height: 8.w,
                decoration: BoxDecoration(
                  color: _getStatusColor(trip.status),
                  shape: BoxShape.circle,
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  trip.tripId,
                  style: GoogleFonts.poppins(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
              ),
              Text(
                _getStatusText(trip.status),
                style: GoogleFonts.poppins(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w500,
                  color: _getStatusColor(trip.status),
                ),
              ),
            ],
          ),

          SizedBox(height: 8.h),

          if (trip.estimatedArrival != null) ...[
            Row(
              children: [
                Icon(Icons.schedule, size: 16.w, color: Colors.blue),
                SizedBox(width: 4.w),
                Text(
                  'ETA: ${trip.formattedTimeToArrival}',
                  style: GoogleFonts.poppins(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w500,
                    color: Colors.blue,
                  ),
                ),
                if (trip.isRunningLate) ...[
                  SizedBox(width: 8.w),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 6.w,
                      vertical: 2.h,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4.r),
                    ),
                    child: Text(
                      'DELAYED',
                      style: GoogleFonts.poppins(
                        fontSize: 8.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.red,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ] else ...[
            Text(
              'No ETA available',
              style: GoogleFonts.poppins(
                fontSize: 12.sp,
                color: Colors.grey[600],
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _startETATracking() {
    final tripState = ref.read(tripProvider);
    if (tripState.currentTrip != null) {
      ref.read(etaProvider.notifier).startETATracking(tripState.currentTrip!);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No active trip to track ETA for'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  String _getTrafficCondition(double multiplier) {
    if (multiplier <= 0.8) return 'Light Traffic';
    if (multiplier <= 1.2) return 'Normal Traffic';
    if (multiplier <= 1.5) return 'Heavy Traffic';
    return 'Severe Traffic';
  }

  Color _getStatusColor(TripStatus status) {
    switch (status) {
      case TripStatus.pending:
        return Colors.orange;
      case TripStatus.inProgress:
        return Colors.green;
      case TripStatus.completed:
        return Colors.blue;
      case TripStatus.cancelled:
        return Colors.red;
      case TripStatus.delayed:
        return Colors.amber;
    }
  }

  String _getStatusText(TripStatus status) {
    switch (status) {
      case TripStatus.pending:
        return 'PENDING';
      case TripStatus.inProgress:
        return 'IN PROGRESS';
      case TripStatus.completed:
        return 'COMPLETED';
      case TripStatus.cancelled:
        return 'CANCELLED';
      case TripStatus.delayed:
        return 'DELAYED';
    }
  }
}
