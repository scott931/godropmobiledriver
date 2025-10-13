import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/models/trip_model.dart';
import '../../../core/theme/app_theme.dart';

class TripCard extends StatelessWidget {
  final Trip trip;
  final VoidCallback? onTap;
  final VoidCallback? onStart;
  final VoidCallback? onEnd;

  const TripCard({
    super.key,
    required this.trip,
    this.onTap,
    this.onStart,
    this.onEnd,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12.r),
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(8.w),
                    decoration: BoxDecoration(
                      color: _getStatusColor().withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8.r),
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
                          trip.tripId,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          _getTripTypeText(),
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: AppTheme.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 8.w,
                      vertical: 4.h,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor(),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Text(
                      _getStatusText(),
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),

              SizedBox(height: 16.h),

              // Trip Details
              Row(
                children: [
                  Expanded(
                    child: _TripDetailItem(
                      icon: Icons.schedule,
                      label: 'Scheduled',
                      value: _formatTime(trip.scheduledStart),
                    ),
                  ),
                  SizedBox(width: 16.w),
                  Expanded(
                    child: _TripDetailItem(
                      icon: Icons.location_on,
                      label: 'Start',
                      value: trip.startLocation ?? 'Unknown',
                    ),
                  ),
                ],
              ),

              if (trip.endLocation != null) ...[
                SizedBox(height: 12.h),
                Row(
                  children: [
                    Expanded(
                      child: _TripDetailItem(
                        icon: Icons.flag,
                        label: 'End',
                        value: trip.endLocation!,
                      ),
                    ),
                    SizedBox(width: 16.w),
                    Expanded(
                      child: _TripDetailItem(
                        icon: Icons.straighten,
                        label: 'Distance',
                        value: trip.distance != null
                            ? '${trip.distance!.toStringAsFixed(1)} km'
                            : 'N/A',
                      ),
                    ),
                  ],
                ),
              ],

              if (trip.notes != null && trip.notes!.isNotEmpty) ...[
                SizedBox(height: 12.h),
                Container(
                  padding: EdgeInsets.all(8.w),
                  decoration: BoxDecoration(
                    color: AppTheme.backgroundColor,
                    borderRadius: BorderRadius.circular(6.r),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.note,
                        size: 16.w,
                        color: AppTheme.textSecondary,
                      ),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: Text(
                          trip.notes!,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: AppTheme.textSecondary),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Action Buttons
              if (onStart != null || onEnd != null) ...[
                SizedBox(height: 16.h),
                Row(
                  children: [
                    if (onStart != null) ...[
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: onStart,
                          icon: const Icon(Icons.play_arrow),
                          label: const Text('Start Trip'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.successColor,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(vertical: 12.h),
                          ),
                        ),
                      ),
                      SizedBox(width: 12.w),
                    ],
                    if (onEnd != null) ...[
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: onEnd,
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
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor() {
    switch (trip.status) {
      case TripStatus.pending:
        return AppTheme.tripPending;
      case TripStatus.inProgress:
        return AppTheme.tripActive;
      case TripStatus.completed:
        return AppTheme.tripCompleted;
      case TripStatus.cancelled:
        return AppTheme.tripCancelled;
      case TripStatus.delayed:
        return AppTheme.tripDelayed;
    }
  }

  String _getStatusText() {
    switch (trip.status) {
      case TripStatus.pending:
        return 'PENDING';
      case TripStatus.inProgress:
        return 'ACTIVE';
      case TripStatus.completed:
        return 'DONE';
      case TripStatus.cancelled:
        return 'CANCELLED';
      case TripStatus.delayed:
        return 'DELAYED';
    }
  }

  String _getTripTypeText() {
    switch (trip.type) {
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
}

class _TripDetailItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _TripDetailItem({
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
            Icon(icon, size: 14.w, color: AppTheme.textSecondary),
            SizedBox(width: 4.w),
            Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppTheme.textSecondary),
            ),
          ],
        ),
        SizedBox(height: 4.h),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}


