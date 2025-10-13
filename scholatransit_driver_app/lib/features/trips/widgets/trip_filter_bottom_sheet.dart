import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/models/trip_model.dart';
import '../../../core/theme/app_theme.dart';

class TripFilterBottomSheet extends StatelessWidget {
  final TripStatus? selectedFilter;
  final Function(TripStatus?) onFilterSelected;

  const TripFilterBottomSheet({
    super.key,
    this.selectedFilter,
    required this.onFilterSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.w),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Filter Trips',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 16.h),

          // Filter Options
          ...TripStatus.values.map(
            (status) => _FilterOption(
              status: status,
              isSelected: selectedFilter == status,
              onTap: () {
                onFilterSelected(selectedFilter == status ? null : status);
              },
            ),
          ),

          SizedBox(height: 16.h),

          // Clear All Button
          if (selectedFilter != null)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  onFilterSelected(null);
                },
                child: const Text('Clear Filter'),
              ),
            ),
        ],
      ),
    );
  }
}

class _FilterOption extends StatelessWidget {
  final TripStatus status;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterOption({
    required this.status,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8.r),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 16.w),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryColor.withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8.r),
        ),
        child: Row(
          children: [
            Container(
              width: 12.w,
              height: 12.w,
              decoration: BoxDecoration(
                color: _getStatusColor(),
                shape: BoxShape.circle,
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Text(
                _getStatusText(),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
            if (isSelected)
              Icon(Icons.check, color: AppTheme.primaryColor, size: 20.w),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor() {
    switch (status) {
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
}


