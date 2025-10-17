import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/models/student_model.dart';
import '../../../core/providers/trip_provider.dart';
import '../../../core/theme/app_theme.dart';

class StudentDetailsScreen extends ConsumerWidget {
  final int studentId;

  const StudentDetailsScreen({super.key, required this.studentId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tripState = ref.watch(tripProvider);
    final student = tripState.students.firstWhere(
      (s) => s.id == studentId,
      orElse: () => throw Exception('Student not found'),
    );

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: CustomScrollView(
        slivers: [
          // Custom App Bar
          SliverAppBar(
            expandedHeight: 200.h,
            floating: false,
            pinned: true,
            backgroundColor: _getStatusColor(student.status),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      _getStatusColor(student.status),
                      _getStatusColor(student.status).withOpacity(0.8),
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: EdgeInsets.all(20.w),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Row(
                          children: [
                            // Student Avatar
                            Container(
                              width: 80.w,
                              height: 80.w,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withOpacity(0.2),
                                border: Border.all(
                                  color: Colors.white,
                                  width: 3,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
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
                                        errorBuilder:
                                            (context, error, stackTrace) =>
                                                _buildAvatarFallback(student),
                                      ),
                                    )
                                  : _buildAvatarFallback(student),
                            ),
                            SizedBox(width: 16.w),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    student.fullName,
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineSmall
                                        ?.copyWith(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
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
                                        color: Colors.white.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(
                                          12.r,
                                        ),
                                      ),
                                      child: Text(
                                        'Grade ${student.grade}',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                              color: Colors.white,
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
                                vertical: 8.h,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20.r),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    _getStatusIcon(student.status),
                                    color: _getStatusColor(student.status),
                                    size: 16.sp,
                                  ),
                                  SizedBox(width: 4.w),
                                  Text(
                                    _getStatusText(student.status),
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelSmall
                                        ?.copyWith(
                                          color: _getStatusColor(
                                            student.status,
                                          ),
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(20.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Quick Actions
                  _QuickActionsSection(student: student),
                  SizedBox(height: 24.h),

                  // Personal Information
                  _InfoSection(
                    title: 'Personal Information',
                    icon: Icons.person_outline,
                    children: [
                      if (student.studentId.isNotEmpty)
                        _InfoTile(
                          icon: Icons.badge_outlined,
                          label: 'Student ID',
                          value: student.studentId,
                        ),
                      if (student.school != null)
                        _InfoTile(
                          icon: Icons.school_outlined,
                          label: 'School',
                          value: student.school!,
                        ),
                      if (student.address != null)
                        _InfoTile(
                          icon: Icons.location_on_outlined,
                          label: 'Address',
                          value: student.address!,
                        ),
                      if (student.lastSeen != null)
                        _InfoTile(
                          icon: Icons.access_time_outlined,
                          label: 'Last Seen',
                          value: _formatDateTime(student.lastSeen!),
                        ),
                    ],
                  ),

                  SizedBox(height: 24.h),

                  // Contact Information
                  if (student.parentName != null ||
                      student.parentPhone != null ||
                      student.parentEmail != null)
                    _InfoSection(
                      title: 'Contact Information',
                      icon: Icons.contact_phone_outlined,
                      children: [
                        if (student.parentName != null)
                          _InfoTile(
                            icon: Icons.person_outline,
                            label: 'Parent/Guardian',
                            value: student.parentName!,
                          ),
                        if (student.parentPhone != null)
                          _InfoTile(
                            icon: Icons.phone_outlined,
                            label: 'Phone',
                            value: student.parentPhone!,
                            onTap: () =>
                                _makePhoneCall(context, student.parentPhone!),
                          ),
                        if (student.parentEmail != null)
                          _InfoTile(
                            icon: Icons.email_outlined,
                            label: 'Email',
                            value: student.parentEmail!,
                            onTap: () =>
                                _sendEmail(context, student.parentEmail!),
                          ),
                      ],
                    ),

                  SizedBox(height: 24.h),

                  // Trip Information
                  _InfoSection(
                    title: 'Trip Information',
                    icon: Icons.route_outlined,
                    children: [
                      if (student.assignedRoute != null)
                        _InfoTile(
                          icon: Icons.route_outlined,
                          label: 'Assigned Route',
                          value: 'Route ${student.assignedRoute}',
                        ),
                      _InfoTile(
                        icon: Icons.schedule_outlined,
                        label: 'Status',
                        value: _getStatusText(student.status),
                        valueColor: _getStatusColor(student.status),
                      ),
                      _InfoTile(
                        icon: Icons.calendar_today_outlined,
                        label: 'Created',
                        value: _formatDate(student.createdAt),
                      ),
                      _InfoTile(
                        icon: Icons.update_outlined,
                        label: 'Last Updated',
                        value: _formatDate(student.updatedAt),
                      ),
                    ],
                  ),

                  SizedBox(height: 24.h),

                  // Location Information
                  if (student.latitude != null && student.longitude != null)
                    _InfoSection(
                      title: 'Location',
                      icon: Icons.map_outlined,
                      children: [
                        _InfoTile(
                          icon: Icons.my_location_outlined,
                          label: 'Coordinates',
                          value:
                              '${student.latitude!.toStringAsFixed(6)}, ${student.longitude!.toStringAsFixed(6)}',
                          onTap: () => _openInMaps(
                            context,
                            student.latitude!,
                            student.longitude!,
                          ),
                        ),
                      ],
                    ),

                  SizedBox(height: 100.h), // Bottom padding
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarFallback(Student student) {
    return Center(
      child: Text(
        student.firstName[0].toUpperCase(),
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 32.sp,
        ),
      ),
    );
  }

  Color _getStatusColor(StudentStatus status) {
    switch (status) {
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

  IconData _getStatusIcon(StudentStatus status) {
    switch (status) {
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

  String _getStatusText(StudentStatus status) {
    switch (status) {
      case StudentStatus.waiting:
        return 'Waiting';
      case StudentStatus.onBus:
        return 'On Bus';
      case StudentStatus.pickedUp:
        return 'Picked Up';
      case StudentStatus.droppedOff:
        return 'Dropped Off';
      case StudentStatus.absent:
        return 'Absent';
    }
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

  String _formatDate(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }

  void _makePhoneCall(BuildContext context, String phoneNumber) {
    // TODO: Implement phone call functionality
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Calling $phoneNumber...')));
  }

  void _sendEmail(BuildContext context, String email) {
    // TODO: Implement email functionality
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Opening email to $email...')));
  }

  void _openInMaps(BuildContext context, double latitude, double longitude) {
    // TODO: Implement maps functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Opening maps at $latitude, $longitude...')),
    );
  }
}

class _QuickActionsSection extends StatelessWidget {
  final Student student;

  const _QuickActionsSection({required this.student});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
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
          Text(
            'Quick Actions',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 12.h),
          Row(
            children: [
              Expanded(
                child: _QuickActionButton(
                  icon: Icons.message_outlined,
                  label: 'Message',
                  color: AppTheme.primaryColor,
                  onTap: () {
                    // TODO: Implement messaging
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Opening message...')),
                    );
                  },
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: _QuickActionButton(
                  icon: Icons.phone_outlined,
                  label: 'Call',
                  color: AppTheme.successColor,
                  onTap: () {
                    if (student.parentPhone != null) {
                      _makePhoneCall(context, student.parentPhone!);
                    }
                  },
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: _QuickActionButton(
                  icon: Icons.location_on_outlined,
                  label: 'Location',
                  color: AppTheme.warningColor,
                  onTap: () {
                    if (student.latitude != null && student.longitude != null) {
                      _openInMaps(
                        context,
                        student.latitude!,
                        student.longitude!,
                      );
                    }
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _makePhoneCall(BuildContext context, String phoneNumber) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Calling $phoneNumber...')));
  }

  void _openInMaps(BuildContext context, double latitude, double longitude) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Opening maps at $latitude, $longitude...')),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12.r),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12.h),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: color.withOpacity(0.2), width: 1),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20.sp),
            SizedBox(height: 4.h),
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const _InfoSection({
    required this.title,
    required this.icon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
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
              Icon(icon, color: AppTheme.primaryColor, size: 20.sp),
              SizedBox(width: 8.w),
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          ...children,
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;
  final VoidCallback? onTap;

  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8.r),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 8.h),
        child: Row(
          children: [
            Icon(icon, size: 18.sp, color: AppTheme.textSecondary),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    value,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: valueColor ?? AppTheme.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            if (onTap != null)
              Icon(
                Icons.arrow_forward_ios,
                size: 14.sp,
                color: AppTheme.textTertiary,
              ),
          ],
        ),
      ),
    );
  }
}
