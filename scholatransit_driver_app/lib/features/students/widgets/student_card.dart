import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/models/student_model.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/avatar_color_utils.dart';

class StudentCard extends StatelessWidget {
  final Student student;
  final Function(StudentStatus)? onStatusUpdate;

  const StudentCard({super.key, required this.student, this.onStatusUpdate});

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor();

    return GestureDetector(
      onTap: () => context.go('/students/${student.id}'),
      child: Container(
        margin: EdgeInsets.only(bottom: 10.h),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14.r),
          border: Border(
            left: BorderSide(
              color: statusColor,
              width: 4.w,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: statusColor.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
              spreadRadius: 0,
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
          child: Row(
            children: [
              // Avatar with Status Ring
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: statusColor,
                    width: 2.5.w,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: statusColor.withOpacity(0.2),
                      blurRadius: 6,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Container(
                  width: 52.w,
                  height: 52.w,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AvatarColorUtils.getColorForName(student.firstName)
                        .withOpacity(0.1),
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
              ),
              SizedBox(width: 12.w),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            student.fullName,
                            style: GoogleFonts.poppins(
                              fontSize: 15.sp,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                              letterSpacing: -0.3,
                            ),
                          ),
                        ),
                        // Status Badge
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 10.w,
                            vertical: 4.h,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor,
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          child: Text(
                            _getStatusText(),
                            style: GoogleFonts.poppins(
                              fontSize: 10.sp,
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 6.h),
                    if (student.grade != null || student.school != null)
                      Row(
                        children: [
                          if (student.grade != null) ...[
                            Icon(
                              Icons.school_outlined,
                              size: 12.w,
                              color: Colors.grey[600],
                            ),
                            SizedBox(width: 4.w),
                            Text(
                              'Grade ${student.grade}',
                              style: GoogleFonts.poppins(
                                fontSize: 12.sp,
                                color: Colors.grey[700],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                          if (student.grade != null && student.school != null)
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 6.w),
                              child: Container(
                                width: 3.w,
                                height: 3.w,
                                decoration: BoxDecoration(
                                  color: Colors.grey[400],
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                          if (student.school != null) ...[
                            Expanded(
                              child: Text(
                                student.school!,
                                style: GoogleFonts.poppins(
                                  fontSize: 12.sp,
                                  color: Colors.grey[700],
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ],
                      ),
                    if (onStatusUpdate != null && _canUpdateStatus()) ...[
                      SizedBox(height: 8.h),
                      Row(
                        children: [
                          Expanded(
                            child: _ActionButton(
                              onPressed: () => onStatusUpdate!(StudentStatus.onBus),
                              label: 'On Bus',
                              icon: Icons.directions_bus,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                          SizedBox(width: 8.w),
                          Expanded(
                            child: _ActionButton(
                              onPressed: () =>
                                  onStatusUpdate!(StudentStatus.droppedOff),
                              label: 'Dropped',
                              icon: Icons.check_circle,
                              color: AppTheme.successColor,
                            ),
                          ),
                        ],
                      ),
                    ] else if (onStatusUpdate != null) ...[
                      SizedBox(height: 6.h),
                      _ActionButton(
                        onPressed: () => context.go('/students/${student.id}'),
                        label: 'View',
                        icon: Icons.arrow_forward_ios,
                        color: AppTheme.primaryColor,
                        isOutlined: true,
                        isFullWidth: true,
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
    final avatarColor = AvatarColorUtils.getColorForName(student.firstName);
    return Center(
      child: Text(
        student.firstName[0].toUpperCase(),
        style: GoogleFonts.poppins(
          color: avatarColor,
          fontWeight: FontWeight.w700,
          fontSize: 20.sp,
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

class _ActionButton extends StatelessWidget {
  final VoidCallback onPressed;
  final String label;
  final IconData icon;
  final Color color;
  final bool isOutlined;
  final bool isFullWidth;

  const _ActionButton({
    required this.onPressed,
    required this.label,
    required this.icon,
    required this.color,
    this.isOutlined = false,
    this.isFullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    final button = isOutlined
        ? OutlinedButton.icon(
            onPressed: onPressed,
            icon: Icon(icon, size: 14.w),
            label: Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 11.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: color,
              side: BorderSide(color: color, width: 1.5),
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
              minimumSize: Size(0, 32.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.r),
              ),
            ),
          )
        : ElevatedButton.icon(
            onPressed: onPressed,
            icon: Icon(icon, size: 14.w, color: Colors.white),
            label: Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 11.sp,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: color,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
              minimumSize: Size(0, 32.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.r),
              ),
              elevation: 1,
              shadowColor: color.withOpacity(0.3),
            ),
          );

    return isFullWidth ? SizedBox(width: double.infinity, child: button) : button;
  }
}
