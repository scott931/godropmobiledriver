import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/providers/trip_provider.dart';
import '../../../core/providers/location_provider.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/models/trip_model.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/location_service.dart';

class TripsScreen extends ConsumerStatefulWidget {
  const TripsScreen({super.key});

  @override
  ConsumerState<TripsScreen> createState() => _TripsScreenState();
}

class _TripsScreenState extends ConsumerState<TripsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(tripProvider.notifier).loadActiveTrips();
    });
  }

  @override
  Widget build(BuildContext context) {
    final tripState = ref.watch(tripProvider);

    // Listen for auth changes - only reset on logout (initState handles initial load)
    ref.listen<AuthState>(authProvider, (previous, next) {
      if (previous != null && !next.isAuthenticated && previous!.isAuthenticated) {
        ref.read(tripProvider.notifier).resetState();
      }
    });

    // Get all trips without filtering
    final filteredTrips = tripState.trips;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Column(
        children: [
          // Modern Header with Gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [const Color(0xFF1E3A8A), const Color(0xFF3B82F6)],
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: EdgeInsets.all(20.w),
                child: Column(
                  children: [
                    // Navigation and Title
                    Row(
                      children: [
                        // GestureDetector(
                        //   onTap: () => context.pop(),
                        //   child: Container(
                        //     padding: EdgeInsets.all(8.w),
                        //     decoration: BoxDecoration(
                        //       color: Colors.white.withOpacity(0.2),
                        //       borderRadius: BorderRadius.circular(8.r),
                        //     ),
                        //     child: Icon(
                        //       Icons.arrow_back,
                        //       color: Colors.white,
                        //       size: 20.w,
                        //     ),
                        //   ),
                        // ),
                        // SizedBox(width: 16.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'My Trips',
                                style: GoogleFonts.poppins(
                                  fontSize: 24.sp,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(height: 4.h),
                              Text(
                                '${filteredTrips.length} trips found',
                                style: GoogleFonts.poppins(
                                  fontSize: 14.sp,
                                  color: Colors.white.withOpacity(0.8),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.all(8.w),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          child: Icon(
                            Icons.filter_list,
                            color: Colors.white,
                            size: 20.w,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Trips List
          Expanded(
            child: tripState.isLoading
                ? Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        const Color(0xFF3B82F6),
                      ),
                    ),
                  )
                : filteredTrips.isEmpty
                ? _EmptyState()
                : RefreshIndicator(
                    onRefresh: () async {
                      await ref.read(tripProvider.notifier).loadActiveTrips();
                    },
                    child: ListView.builder(
                      padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 80.h),
                      itemCount: filteredTrips.length,
                      itemBuilder: (context, index) {
                        final trip = filteredTrips[index];
                        return Padding(
                          padding: EdgeInsets.only(bottom: 16.h),
                          child: _ModernTripCard(
                            trip: trip,
                            onTap: () =>
                                context.go('/trips/details/${trip.id}'),
                            onStart: trip.status == TripStatus.pending
                                ? () => _startTrip(trip)
                                : null,
                            onEnd: trip.status == TripStatus.inProgress
                                ? () => _endTrip(trip)
                                : null,
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF3B82F6).withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: FloatingActionButton(
          onPressed: () => _showNewTripDialog(context),
          backgroundColor: const Color(0xFF3B82F6),
          child: Icon(Icons.add, color: Colors.white, size: 24.w),
        ),
      ),
    );
  }

  void _showNewTripDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Start New Trip'),
        content: const Text(
          'This feature will be available soon. You can start trips from the trips list.',
        ),
        actions: [
          TextButton(onPressed: () => context.pop(), child: const Text('OK')),
        ],
      ),
    );
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

class _ModernTripCard extends StatefulWidget {
  final Trip trip;
  final VoidCallback? onTap;
  final VoidCallback? onStart;
  final VoidCallback? onEnd;

  const _ModernTripCard({
    required this.trip,
    this.onTap,
    this.onStart,
    this.onEnd,
  });

  @override
  State<_ModernTripCard> createState() => _ModernTripCardState();
}

class _ModernTripCardState extends State<_ModernTripCard> {
  String? _startLocationName;
  String? _endLocationName;
  bool _isLoadingLocations = false;

  @override
  void initState() {
    super.initState();
    _loadLocationNames();
  }

  Future<void> _loadLocationNames() async {
    if (_isLoadingLocations) return;

    setState(() => _isLoadingLocations = true);

    // Get start location name
    if (widget.trip.startLatitude != null && widget.trip.startLongitude != null) {
      final startName = await LocationService.getAddressFromCoordinates(
        widget.trip.startLatitude!,
        widget.trip.startLongitude!,
      );
      if (mounted) {
        setState(() => _startLocationName = startName);
      }
    } else if (widget.trip.startLocation != null &&
               !widget.trip.startLocation!.startsWith('SRID')) {
      // If it's already a name, use it
      setState(() => _startLocationName = widget.trip.startLocation);
    }

    // Get end location name
    if (widget.trip.endLatitude != null && widget.trip.endLongitude != null) {
      final endName = await LocationService.getAddressFromCoordinates(
        widget.trip.endLatitude!,
        widget.trip.endLongitude!,
      );
      if (mounted) {
        setState(() => _endLocationName = endName);
      }
    } else if (widget.trip.endLocation != null &&
               !widget.trip.endLocation!.startsWith('SRID')) {
      // If it's already a name, use it
      setState(() => _endLocationName = widget.trip.endLocation);
    }

    if (mounted) {
      setState(() => _isLoadingLocations = false);
    }
  }

  String _getStartLocationDisplay() {
    if (_startLocationName != null) return _startLocationName!;
    if (widget.trip.startLocation != null &&
        !widget.trip.startLocation!.startsWith('SRID')) {
      return widget.trip.startLocation!;
    }
    return 'Loading...';
  }

  String _getEndLocationDisplay() {
    if (_endLocationName != null) return _endLocationName!;
    if (widget.trip.endLocation != null &&
        !widget.trip.endLocation!.startsWith('SRID')) {
      return widget.trip.endLocation!;
    }
    return 'Loading...';
  }

  String _getDurationDisplay() {
    // If actual duration is available, use it
    if (widget.trip.actualDuration != null) {
      final minutes = widget.trip.actualDuration!.inMinutes;
      if (minutes >= 60) {
        return '${minutes ~/ 60}h ${minutes % 60}m';
      }
      return '$minutes min';
    }

    // If duration field is provided, use it
    if (widget.trip.duration != null) {
      if (widget.trip.duration! >= 60) {
        return '${widget.trip.duration! ~/ 60}h ${widget.trip.duration! % 60}m';
      }
      return '${widget.trip.duration} min';
    }

    // Calculate from scheduled times
    final scheduledDuration = widget.trip.scheduledDuration;
    final minutes = scheduledDuration.inMinutes;
    if (minutes >= 60) {
      return '${minutes ~/ 60}h ${minutes % 60}m';
    }
    return '$minutes min';
  }

  String _getDistanceDisplay() {
    // If distance is provided by backend, use it
    if (widget.trip.distance != null) {
      if (widget.trip.distance! >= 1.0) {
        return '${widget.trip.distance!.toStringAsFixed(1)} km';
      }
      return '${(widget.trip.distance! * 1000).toStringAsFixed(0)} m';
    }

    // Calculate distance from coordinates if available
    if (widget.trip.startLatitude != null &&
        widget.trip.startLongitude != null &&
        widget.trip.endLatitude != null &&
        widget.trip.endLongitude != null) {
      final distance = LocationService.calculateDistance(
        widget.trip.startLatitude!,
        widget.trip.startLongitude!,
        widget.trip.endLatitude!,
        widget.trip.endLongitude!,
      );
      final distanceKm = distance / 1000;
      if (distanceKm >= 1.0) {
        return '${distanceKm.toStringAsFixed(1)} km';
      }
      return '${distance.toStringAsFixed(0)} m';
    }

    return 'N/A';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
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
        child: Padding(
          padding: EdgeInsets.all(20.w),
          child: Column(
            children: [
              // Header with Trip ID and Status
              Row(
                children: [
                  Container(
                    width: 40.w,
                    height: 40.w,
                    decoration: BoxDecoration(
                      color: _getStatusColor().withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    child: Icon(
                      Icons.directions_bus,
                      color: _getStatusColor(),
                      size: 20.w,
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.trip.routeName ?? widget.trip.tripId,
                          style: GoogleFonts.poppins(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                          ),
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          _getTripTypeText(),
                          style: GoogleFonts.poppins(
                            fontSize: 12.sp,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 12.w,
                      vertical: 6.h,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor().withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Text(
                      _getStatusText(),
                      style: GoogleFonts.poppins(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                        color: _getStatusColor(),
                      ),
                    ),
                  ),
                ],
              ),

              SizedBox(height: 20.h),

              // Route Information
              Row(
                children: [
                  // Start Location
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _getStartLocationDisplay(),
                          style: GoogleFonts.poppins(
                            fontSize: 12.sp,
                            color: Colors.grey[600],
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          _formatTime(widget.trip.scheduledStart),
                          style: GoogleFonts.poppins(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Route Visual
                  Expanded(
                    child: Column(
                      children: [
                        Container(height: 1.h, color: Colors.grey[300]),
                        SizedBox(height: 8.h),
                        Container(
                          width: 24.w,
                          height: 24.w,
                          decoration: BoxDecoration(
                            color: const Color(0xFF3B82F6),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.directions_bus,
                            color: Colors.white,
                            size: 12.w,
                          ),
                        ),
                        SizedBox(height: 8.h),
                        Container(height: 1.h, color: Colors.grey[300]),
                      ],
                    ),
                  ),

                  // End Location
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          _getEndLocationDisplay(),
                          style: GoogleFonts.poppins(
                            fontSize: 12.sp,
                            color: Colors.grey[600],
                          ),
                          textAlign: TextAlign.right,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          _formatTime(widget.trip.scheduledEnd),
                          style: GoogleFonts.poppins(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                          ),
                          textAlign: TextAlign.right,
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              SizedBox(height: 16.h),

              // ETA Information
              if (widget.trip.estimatedArrival != null) _buildETAInfo(),

              SizedBox(height: 16.h),

              // Trip Details and Actions
              Row(
                children: [
                  // Trip Details
                  Expanded(
                    child: Row(
                      children: [
                        _TripAttribute(
                          icon: Icons.schedule,
                          label: 'Duration',
                          value: _getDurationDisplay(),
                        ),
                        SizedBox(width: 16.w),
                        _TripAttribute(
                          icon: Icons.straighten,
                          label: 'Distance',
                          value: _getDistanceDisplay(),
                        ),
                      ],
                    ),
                  ),

                  // Action Button
                  if (widget.onStart != null || widget.onEnd != null)
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 16.w,
                        vertical: 8.h,
                      ),
                      decoration: BoxDecoration(
                        color: widget.onStart != null
                            ? const Color(0xFF10B981)
                            : const Color(0xFFEF4444),
                        borderRadius: BorderRadius.circular(20.r),
                      ),
                      child: GestureDetector(
                        onTap: widget.onStart ?? widget.onEnd,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              widget.onStart != null ? Icons.play_arrow : Icons.stop,
                              color: Colors.white,
                              size: 16.w,
                            ),
                            SizedBox(width: 4.w),
                            Text(
                              widget.onStart != null ? 'Start' : 'End',
                              style: GoogleFonts.poppins(
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
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
        ),
      ),
    );
  }

  Color _getStatusColor() {
    switch (widget.trip.status) {
      case TripStatus.pending:
        return const Color(0xFFF59E0B);
      case TripStatus.inProgress:
        return const Color(0xFF10B981);
      case TripStatus.completed:
        return const Color(0xFF3B82F6);
      case TripStatus.cancelled:
        return const Color(0xFFEF4444);
      case TripStatus.delayed:
        return const Color(0xFFF59E0B);
    }
  }

  String _getStatusText() {
    switch (widget.trip.status) {
      case TripStatus.pending:
        return 'PENDING';
      case TripStatus.inProgress:
        return 'ACTIVE';
      case TripStatus.completed:
        return 'COMPLETED';
      case TripStatus.cancelled:
        return 'CANCELLED';
      case TripStatus.delayed:
        return 'DELAYED';
    }
  }

  String _getTripTypeText() {
    switch (widget.trip.type) {
      case TripType.pickup:
        return 'Pickup Trip';
      case TripType.dropoff:
        return 'Drop-off Trip';
      case TripType.scheduled:
        return 'Scheduled Trip';
      case TripType.emergency:
        return 'Emergency Trip';
    }
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  Widget _buildETAInfo() {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: widget.trip.isRunningLate
            ? Colors.red.withOpacity(0.1)
            : Colors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(
          color: widget.trip.isRunningLate
              ? Colors.red.withOpacity(0.3)
              : Colors.green.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            widget.trip.isRunningLate ? Icons.warning : Icons.schedule,
            color: widget.trip.isRunningLate ? Colors.red : Colors.green,
            size: 16.w,
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ETA: ${widget.trip.formattedTimeToArrival}',
                  style: GoogleFonts.poppins(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: widget.trip.isRunningLate ? Colors.red : Colors.green,
                  ),
                ),
                if (widget.trip.trafficConditions != 'Unknown') ...[
                  SizedBox(height: 2.h),
                  Text(
                    widget.trip.trafficConditions,
                    style: GoogleFonts.poppins(
                      fontSize: 10.sp,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (widget.trip.isRunningLate) ...[
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
        ],
      ),
    );
  }
}

class _TripAttribute extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _TripAttribute({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 12.w, color: Colors.grey[600]),
            SizedBox(width: 4.w),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 10.sp,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        SizedBox(height: 2.h),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 12.sp,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80.w,
            height: 80.w,
            decoration: BoxDecoration(
              color: const Color(0xFF3B82F6).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.directions_bus_outlined,
              size: 40.w,
              color: const Color(0xFF3B82F6),
            ),
          ),
          SizedBox(height: 24.h),
          Text(
            'No trips found',
            style: GoogleFonts.poppins(
              fontSize: 20.sp,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'Your trips will appear here when assigned',
            style: GoogleFonts.poppins(
              fontSize: 14.sp,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
