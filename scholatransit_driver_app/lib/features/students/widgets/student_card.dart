import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../core/models/student_model.dart';
import '../../../core/theme/app_theme.dart';

class StudentCard extends StatelessWidget {
  final Student student;
  final Function(StudentStatus)? onStatusUpdate;

  const StudentCard({super.key, required this.student, this.onStatusUpdate});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.go('/students/${student.id}'),
      child: Container(
        margin: EdgeInsets.only(bottom: 16.h),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16.r),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.white, _getStatusColor().withOpacity(0.05)],
          ),
          boxShadow: [
            BoxShadow(
              color: _getStatusColor().withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16.r),
          child: Column(
            children: [
              // Header Section with Gradient
              Container(
                padding: EdgeInsets.all(20.w),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      _getStatusColor().withOpacity(0.1),
                      _getStatusColor().withOpacity(0.05),
                    ],
                  ),
                ),
                child: Row(
                  children: [
                    // Enhanced Avatar
                    Container(
                      width: 60.w,
                      height: 60.w,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            _getStatusColor(),
                            _getStatusColor().withOpacity(0.8),
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: _getStatusColor().withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: student.profileImage != null
                          ? ClipOval(
                              child: Image.network(
                                student.profileImage!,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    _buildAvatarFallback(),
                              ),
                            )
                          : _buildAvatarFallback(),
                    ),
                    SizedBox(width: 16.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            student.fullName,
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textPrimary,
                                ),
                          ),
                          SizedBox(height: 4.h),
                          if (student.grade != null)
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 8.w,
                                vertical: 4.h,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8.r),
                              ),
                              child: Text(
                                'Grade ${student.grade}',
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: AppTheme.primaryColor,
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    // Status Badge
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 12.w,
                        vertical: 6.h,
                      ),
                      decoration: BoxDecoration(
                        color: _getStatusColor(),
                        borderRadius: BorderRadius.circular(20.r),
                        boxShadow: [
                          BoxShadow(
                            color: _getStatusColor().withOpacity(0.3),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _getStatusIcon(),
                            color: Colors.white,
                            size: 14.sp,
                          ),
                          SizedBox(width: 4.w),
                          Text(
                            _getStatusText(),
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Content Section
              Padding(
                padding: EdgeInsets.all(20.w),
                child: Column(
                  children: [
                    // Quick Info Row
                    Row(
                      children: [
                        if (student.school != null) ...[
                          Expanded(
                            child: _InfoChip(
                              icon: Icons.school_outlined,
                              label: 'School',
                              value: student.school!,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                          SizedBox(width: 8.w),
                        ],
                        if (student.parentName != null)
                          Expanded(
                            child: _InfoChip(
                              icon: Icons.person_outline,
                              label: 'Parent',
                              value: student.parentName!,
                              color: AppTheme.successColor,
                            ),
                          ),
                      ],
                    ),

                    if (student.school != null && student.parentName != null)
                      SizedBox(height: 12.h),

                    // Last Seen Info
                    if (student.lastSeen != null) ...[
                      Container(
                        padding: EdgeInsets.all(12.w),
                        decoration: BoxDecoration(
                          color: AppTheme.backgroundColor,
                          borderRadius: BorderRadius.circular(12.r),
                          border: Border.all(
                            color: AppTheme.borderColor,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.access_time,
                              size: 16.sp,
                              color: AppTheme.textSecondary,
                            ),
                            SizedBox(width: 8.w),
                            Text(
                              'Last seen: ${_formatDateTime(student.lastSeen!)}',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: AppTheme.textSecondary,
                                    fontWeight: FontWeight.w500,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 16.h),
                    ],

                    // Action Buttons
                    if (onStatusUpdate != null && _canUpdateStatus()) ...[
                      Row(
                        children: [
                          Expanded(
                            child: _ActionButton(
                              onPressed: () =>
                                  onStatusUpdate!(StudentStatus.onBus),
                              icon: Icons.directions_bus,
                              label: 'On Bus',
                              color: AppTheme.primaryColor,
                            ),
                          ),
                          SizedBox(width: 12.w),
                          Expanded(
                            child: _ActionButton(
                              onPressed: () =>
                                  onStatusUpdate!(StudentStatus.droppedOff),
                              icon: Icons.location_on,
                              label: 'Dropped Off',
                              color: AppTheme.successColor,
                            ),
                          ),
                        ],
                      ),
                    ] else if (onStatusUpdate != null) ...[
                      // View Details Button
                      SizedBox(
                        width: double.infinity,
                        child: _ActionButton(
                          onPressed: () =>
                              context.go('/students/${student.id}'),
                          icon: Icons.visibility,
                          label: 'View Details',
                          color: AppTheme.primaryColor,
                          isOutlined: true,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatarFallback() {
    return Center(
      child: Text(
        student.firstName[0].toUpperCase(),
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 24.sp,
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

  IconData _getStatusIcon() {
    switch (student.status) {
      case StudentStatus.waiting:
        return Icons.schedule;
      case StudentStatus.onBus:
        return Icons.directions_bus;
      case StudentStatus.pickedUp:
        return Icons.check_circle;
      case StudentStatus.droppedOff:
        return Icons.location_on;
      case StudentStatus.absent:
        return Icons.cancel;
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

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: color.withOpacity(0.2), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16.sp, color: color),
              SizedBox(width: 6.w),
              Text(
                label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: 4.h),
          Text(
            value,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final VoidCallback onPressed;
  final IconData icon;
  final String label;
  final Color color;
  final bool isOutlined;

  const _ActionButton({
    required this.onPressed,
    required this.icon,
    required this.label,
    required this.color,
    this.isOutlined = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isOutlined) {
      return OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 18.sp),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          side: BorderSide(color: color, width: 1.5),
          padding: EdgeInsets.symmetric(vertical: 12.h),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
        ),
      );
    }

    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18.sp),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: EdgeInsets.symmetric(vertical: 12.h),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
        elevation: 2,
        shadowColor: color.withOpacity(0.3),
      ),
    );
  }
}
