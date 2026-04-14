import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/providers/trip_provider.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/models/trip_model.dart';
import '../../../core/services/location_service.dart';
import '../utils/trip_action_handler.dart';

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
      ref.read(tripProvider.notifier).loadDriverSchedule();
    });
  }

  bool _canStartTrip(Trip trip) {
    return trip.status == TripStatus.pending;
  }

  @override
  Widget build(BuildContext context) {
    final tripState = ref.watch(tripProvider);

    ref.listen<AuthState>(authProvider, (previous, next) {
      if (previous != null && !next.isAuthenticated && previous.isAuthenticated) {
        ref.read(tripProvider.notifier).resetState();
      }
    });

    final trips = tripState.trips;
    final upcoming = trips.where((t) => _canStartTrip(t)).toList()
      ..sort((a, b) => a.scheduledStart.compareTo(b.scheduledStart));
    final live = trips.where((t) => t.isActive).toList();
    final past = trips
        .where(
          (t) =>
              !t.isActive &&
              (t.isCompleted || t.isCancelled || !_canStartTrip(t)),
        )
        .toList()
      ..sort((a, b) => b.scheduledStart.compareTo(a.scheduledStart));

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Column(
        children: [
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
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'My schedule',
                            style: GoogleFonts.poppins(
                              fontSize: 24.sp,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            '${trips.length} assignment${trips.length == 1 ? '' : 's'}',
                            style: GoogleFonts.poppins(
                              fontSize: 14.sp,
                              color: Colors.white.withOpacity(0.85),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: tripState.isLoading
                          ? null
                          : () {
                              ref.read(tripProvider.notifier).loadDriverSchedule();
                            },
                      icon: Icon(Icons.refresh, color: Colors.white, size: 24.w),
                      tooltip: 'Refresh',
                    ),
                  ],
                ),
              ),
            ),
          ),

          if (tripState.error != null && !tripState.isLoading)
            Padding(
              padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 0),
              child: Material(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8.r),
                child: Padding(
                  padding: EdgeInsets.all(12.w),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: Colors.red.shade700, size: 20.w),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: Text(
                          tripState.error!,
                          style: GoogleFonts.poppins(
                            fontSize: 13.sp,
                            color: Colors.red.shade900,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          Expanded(
            child: tripState.isLoading
                ? Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        const Color(0xFF3B82F6),
                      ),
                    ),
                  )
                : trips.isEmpty
                ? _EmptyState()
                : RefreshIndicator(
                    onRefresh: () async {
                      await ref.read(tripProvider.notifier).loadDriverSchedule();
                    },
                    child: ListView(
                      padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 32.h),
                      children: [
                        if (upcoming.isNotEmpty) ...[
                          _ScheduleSectionTitle(
                            title: 'Upcoming',
                            subtitle:
                                'Start a trip when you are ready to depart.',
                          ),
                          ...upcoming.map(
                            (trip) => Padding(
                              padding: EdgeInsets.only(bottom: 16.h),
                              child: _ModernTripCard(
                                trip: trip,
                                useProminentStart: true,
                                onTap: () =>
                                    context.go('/trips/details/${trip.id}'),
                                onStart: _canStartTrip(trip)
                                    ? () => _startTrip(trip)
                                    : null,
                                onEnd: null,
                              ),
                            ),
                          ),
                        ],
                        if (live.isNotEmpty) ...[
                          _ScheduleSectionTitle(
                            title: 'In progress',
                            subtitle: 'Trip is running — end when finished.',
                          ),
                          ...live.map(
                            (trip) => Padding(
                              padding: EdgeInsets.only(bottom: 16.h),
                              child: _ModernTripCard(
                                trip: trip,
                                useProminentStart: false,
                                onTap: () =>
                                    context.go('/trips/details/${trip.id}'),
                                onStart: null,
                                onEnd: () => _endTrip(trip),
                              ),
                            ),
                          ),
                        ],
                        if (past.isNotEmpty) ...[
                          _ScheduleSectionTitle(
                            title: 'Past',
                            subtitle: 'Completed or cancelled trips.',
                          ),
                          ...past.map(
                            (trip) => Padding(
                              padding: EdgeInsets.only(bottom: 16.h),
                              child: _ModernTripCard(
                                trip: trip,
                                useProminentStart: false,
                                onTap: () =>
                                    context.go('/trips/details/${trip.id}'),
                                onStart: null,
                                onEnd: null,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _startTrip(Trip trip) async {
    if (!mounted) return;
    await TripActionHandler.startTrip(ref: ref, context: context, trip: trip);
  }

  Future<void> _endTrip(Trip trip) async {
    if (!mounted) return;
    await TripActionHandler.endTrip(ref: ref, context: context, trip: trip);
  }
}

class _ScheduleSectionTitle extends StatelessWidget {
  final String title;
  final String subtitle;

  const _ScheduleSectionTitle({
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h, top: 8.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 18.sp,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1E3A8A),
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            subtitle,
            style: GoogleFonts.poppins(
              fontSize: 13.sp,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}

class _ModernTripCard extends StatefulWidget {
  final Trip trip;
  final VoidCallback? onTap;
  final VoidCallback? onStart;
  final VoidCallback? onEnd;
  final bool useProminentStart;

  const _ModernTripCard({
    required this.trip,
    this.onTap,
    this.onStart,
    this.onEnd,
    this.useProminentStart = false,
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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

                  if (!widget.useProminentStart &&
                      (widget.onStart != null || widget.onEnd != null))
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
                              widget.onStart != null
                                  ? Icons.play_arrow
                                  : Icons.stop,
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

              if (widget.useProminentStart && widget.onStart != null) ...[
                SizedBox(height: 16.h),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: widget.onStart,
                    icon: Icon(Icons.play_arrow, size: 22.w),
                    label: Text(
                      'Start trip',
                      style: GoogleFonts.poppins(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF059669),
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 14.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                    ),
                  ),
                ),
              ],
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
            'No schedule yet',
            style: GoogleFonts.poppins(
              fontSize: 20.sp,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          SizedBox(height: 8.h),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.w),
            child: Text(
              'Assigned trips will show here. Pull down to refresh.',
              style: GoogleFonts.poppins(
                fontSize: 14.sp,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
