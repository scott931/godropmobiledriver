import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/models/student_model.dart';
import '../../../core/theme/app_theme.dart';

class StudentCard extends StatelessWidget {
  final Student student;
  final Function(StudentStatus)? onStatusUpdate;

  const StudentCard({super.key, required this.student, this.onStatusUpdate});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                CircleAvatar(
                  radius: 24.r,
                  backgroundColor: _getStatusColor().withOpacity(0.1),
                  child: Text(
                    student.firstName[0].toUpperCase(),
                    style: TextStyle(
                      color: _getStatusColor(),
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
                        student.fullName,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 2.h),
                      if (student.grade != null)
                        Text(
                          'Grade ${student.grade}',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: AppTheme.textSecondary),
                        ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
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

            // Student Details
            if (student.school != null) ...[
              _StudentDetailItem(
                icon: Icons.school,
                label: 'School',
                value: student.school!,
              ),
              SizedBox(height: 8.h),
            ],

            if (student.parentName != null) ...[
              _StudentDetailItem(
                icon: Icons.person,
                label: 'Parent',
                value: student.parentName!,
              ),
              SizedBox(height: 8.h),
            ],

            if (student.lastSeen != null) ...[
              _StudentDetailItem(
                icon: Icons.access_time,
                label: 'Last Seen',
                value: _formatDateTime(student.lastSeen!),
              ),
              SizedBox(height: 16.h),
            ],

            // Status Update Buttons
            if (onStatusUpdate != null && _canUpdateStatus()) ...[
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => onStatusUpdate!(StudentStatus.onBus),
                      icon: const Icon(Icons.directions_bus),
                      label: const Text('On Bus'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.primaryColor,
                        side: BorderSide(color: AppTheme.primaryColor),
                      ),
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () =>
                          onStatusUpdate!(StudentStatus.droppedOff),
                      icon: const Icon(Icons.location_on),
                      label: const Text('Dropped Off'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.successColor,
                        side: BorderSide(color: AppTheme.successColor),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getStatusColor() {
    switch (student.status) {
      case StudentStatus.waiting:
        return AppTheme.studentWaiting;
      case StudentStatus.onBus:
        return AppTheme.studentOnBus;
      case StudentStatus.pickedUp:
        return AppTheme.studentPickedUp;
      case StudentStatus.droppedOff:
        return AppTheme.studentDroppedOff;
      case StudentStatus.absent:
        return AppTheme.errorColor;
    }
  }

  String _getStatusText() {
    switch (student.status) {
      case StudentStatus.waiting:
        return 'WAITING';
      case StudentStatus.onBus:
        return 'ON BUS';
      case StudentStatus.pickedUp:
        return 'PICKED UP';
      case StudentStatus.droppedOff:
        return 'DROPPED OFF';
      case StudentStatus.absent:
        return 'ABSENT';
    }
  }

  bool _canUpdateStatus() {
    return student.status == StudentStatus.waiting ||
        student.status == StudentStatus.onBus;
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }
}

class _StudentDetailItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _StudentDetailItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16.w, color: AppTheme.textSecondary),
        SizedBox(width: 8.w),
        Text(
          '$label: ',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppTheme.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppTheme.textPrimary),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}


