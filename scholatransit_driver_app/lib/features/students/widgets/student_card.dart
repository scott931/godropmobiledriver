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
        margin: EdgeInsets.only(bottom: 12.h),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Row(
            children: [
              // Simple Avatar
              Container(
                width: 48.w,
                height: 48.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _getStatusColor().withOpacity(0.1),
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
              SizedBox(width: 12.w),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      student.fullName,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    if (student.grade != null)
                      Text(
                        'Grade ${student.grade}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    if (student.school != null) ...[
                      SizedBox(height: 2.h),
                      Text(
                        student.school!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              // Status and Actions
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Status Badge
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
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  SizedBox(height: 8.h),
                  // Action Buttons
                  if (onStatusUpdate != null && _canUpdateStatus()) ...[
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _SimpleButton(
                          onPressed: () => onStatusUpdate!(StudentStatus.onBus),
                          label: 'On Bus',
                          color: AppTheme.primaryColor,
                        ),
                        SizedBox(width: 8.w),
                        _SimpleButton(
                          onPressed: () =>
                              onStatusUpdate!(StudentStatus.droppedOff),
                          label: 'Dropped',
                          color: AppTheme.successColor,
                        ),
                      ],
                    ),
                  ] else if (onStatusUpdate != null) ...[
                    _SimpleButton(
                      onPressed: () => context.go('/students/${student.id}'),
                      label: 'View',
                      color: AppTheme.primaryColor,
                      isOutlined: true,
                    ),
                  ],
                ],
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
          color: _getStatusColor(),
          fontWeight: FontWeight.w600,
          fontSize: 18.sp,
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
}

class _SimpleButton extends StatelessWidget {
  final VoidCallback onPressed;
  final String label;
  final Color color;
  final bool isOutlined;

  const _SimpleButton({
    required this.onPressed,
    required this.label,
    required this.color,
    this.isOutlined = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isOutlined) {
      return TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          foregroundColor: color,
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.r),
            side: BorderSide(color: color, width: 1),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600),
        ),
      );
    }

    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600),
      ),
    );
  }
}
