import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/notification_provider.dart';
import '../../../core/providers/emergency_provider.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationState = ref.watch(notificationProvider);
    final emergencyState = ref.watch(emergencyProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Text(
          'Notifications',
          style: GoogleFonts.poppins(
            fontSize: 20.sp,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.refresh,
              color: Colors.grey[600],
              size: 24.w,
            ),
            onPressed: () {
              ref.read(emergencyProvider.notifier).loadEmergencyAlerts();
            },
          ),
          IconButton(
            icon: Icon(
              Icons.mark_email_read,
              color: Colors.grey[600],
              size: 24.w,
            ),
            onPressed: () {
              // TODO: Mark all as read
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(emergencyProvider.notifier).loadEmergencyAlerts();
        },
        child: emergencyState.isLoading
            ? Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    const Color(0xFF3B82F6),
                  ),
                ),
              )
            : emergencyState.alerts.isEmpty
                ? const _EmptyNotificationsView()
                : ListView.builder(
                    padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
                    itemCount: emergencyState.alerts.length,
                    itemBuilder: (context, index) {
                      final alert = emergencyState.alerts[index];
                      return _NotificationCard(alert: alert);
                    },
                  ),
      ),
    );
  }
}

class _EmptyNotificationsView extends StatelessWidget {
  const _EmptyNotificationsView();

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
              Icons.notifications_outlined,
              size: 40.w,
              color: const Color(0xFF3B82F6),
            ),
          ),
          SizedBox(height: 24.h),
          Text(
            'No Notifications',
            style: GoogleFonts.poppins(
              fontSize: 20.sp,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'You\'ll receive notifications about trips, students, and emergencies here',
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

class _NotificationCard extends StatelessWidget {
  final dynamic alert; // EmergencyAlert type

  const _NotificationCard({required this.alert});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showAlertDetails(context, alert),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Picture
            Container(
              width: 48.w,
              height: 48.w,
              decoration: BoxDecoration(
                color: _getAlertColor().withOpacity(0.1),
                shape: BoxShape.circle,
                border: Border.all(
                  color: _getAlertColor().withOpacity(0.3),
                  width: 2,
                ),
              ),
              child: Icon(
                _getAlertIcon(),
                color: _getAlertColor(),
                size: 24.w,
              ),
            ),

            SizedBox(width: 16.w),

            // Notification Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name and Action
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: _getSenderName(),
                          style: GoogleFonts.poppins(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                          ),
                        ),
                        TextSpan(
                          text: ' ${_getActionText()}',
                          style: GoogleFonts.poppins(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w400,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 4.h),

                  // Context/Object
                  Text(
                    _getContextText(),
                    style: GoogleFonts.poppins(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w400,
                      color: Colors.grey[700],
                    ),
                  ),

                  SizedBox(height: 8.h),

                  // Timestamp
                  Text(
                    _formatDateTime(alert.reportedAt ?? alert.createdAt),
                    style: GoogleFonts.poppins(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w400,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getSenderName() {
    // Generate a realistic sender name based on alert type
    switch (alert.emergencyType?.toLowerCase()) {
      case 'medical':
        return 'Dr. Sarah Johnson';
      case 'vehicle_breakdown':
      case 'breakdown':
        return 'Mike Rodriguez';
      case 'student':
        return 'Lisa Chen';
      default:
        return 'System Admin';
    }
  }

  String _getActionText() {
    switch (alert.emergencyType?.toLowerCase()) {
      case 'medical':
        return 'reported a medical emergency';
      case 'vehicle_breakdown':
      case 'breakdown':
        return 'reported a vehicle breakdown';
      case 'student':
        return 'reported a student incident';
      default:
        return 'created an emergency alert';
    }
  }

  String _getContextText() {
    if (alert.title != null && alert.title!.isNotEmpty) {
      return 'in ${alert.title}';
    }
    return 'in Emergency Alert';
  }

  IconData _getAlertIcon() {
    switch (alert.emergencyType?.toLowerCase()) {
      case 'medical':
        return Icons.medical_services;
      case 'vehicle_breakdown':
      case 'breakdown':
        return Icons.car_repair;
      case 'student':
        return Icons.school;
      default:
        return Icons.warning;
    }
  }

  Color _getAlertColor() {
    switch (alert.emergencyType?.toLowerCase()) {
      case 'medical':
        return const Color(0xFFEF4444);
      case 'vehicle_breakdown':
      case 'breakdown':
        return const Color(0xFFF59E0B);
      case 'student':
        return const Color(0xFF3B82F6);
      default:
        return const Color(0xFF6B7280);
    }
  }

  String _formatDateTime(String? dateTime) {
    if (dateTime == null) return 'Unknown time';
    try {
      final parsed = DateTime.parse(dateTime);
      final now = DateTime.now();
      final difference = now.difference(parsed);

      if (difference.inDays > 0) {
        return '${difference.inDays} days ago';
      } else if (difference.inHours > 0) {
        return '${difference.inHours} hours ago';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes} minutes ago';
      } else {
        return 'Just now';
      }
    } catch (e) {
      return 'Unknown time';
    }
  }

  void _showAlertDetails(BuildContext context, dynamic alert) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AlertDetailsModal(alert: alert),
    );
  }
}

class _AlertDetailsModal extends StatelessWidget {
  final dynamic alert;

  const _AlertDetailsModal({required this.alert});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20.r),
          topRight: Radius.circular(20.r),
        ),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: EdgeInsets.only(top: 12.h),
            width: 40.w,
            height: 4.h,
            decoration: BoxDecoration(
              color: AppTheme.textTertiary,
              borderRadius: BorderRadius.circular(2.r),
            ),
          ),

          // Header
          Padding(
            padding: EdgeInsets.all(20.w),
            child: Row(
              children: [
                Icon(
                  _getAlertIcon(),
                  color: _getAlertColor(),
                  size: 32.w,
                ),
                SizedBox(width: 16.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        alert.title ?? 'Emergency Alert',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                        decoration: BoxDecoration(
                          color: _getSeverityColor().withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16.r),
                        ),
                        child: Text(
                          alert.severityDisplay ?? alert.severity ?? 'Unknown',
                          style: TextStyle(
                            color: _getSeverityColor(),
                            fontSize: 14.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _DetailSection(
                    title: 'Description',
                    content: alert.description ?? 'No description available',
                    icon: Icons.description,
                  ),

                  SizedBox(height: 16.h),

                  _DetailSection(
                    title: 'Emergency Type',
                    content: alert.emergencyTypeDisplay ?? alert.emergencyType ?? 'Unknown',
                    icon: Icons.category,
                  ),

                  SizedBox(height: 16.h),

                  _DetailSection(
                    title: 'Status',
                    content: alert.statusDisplay ?? alert.status ?? 'Unknown',
                    icon: Icons.info,
                  ),

                  SizedBox(height: 16.h),

                  _DetailSection(
                    title: 'Location',
                    content: alert.locationDisplay ?? alert.location ?? 'Unknown location',
                    icon: Icons.location_on,
                  ),

                  SizedBox(height: 16.h),

                  _DetailSection(
                    title: 'Address',
                    content: alert.address ?? 'No address provided',
                    icon: Icons.home,
                  ),

                  SizedBox(height: 16.h),

                  _DetailSection(
                    title: 'Reported At',
                    content: _formatDateTime(alert.reportedAt ?? alert.createdAt),
                    icon: Icons.access_time,
                  ),

                  if (alert.acknowledgedAt != null) ...[
                    SizedBox(height: 16.h),
                    _DetailSection(
                      title: 'Acknowledged At',
                      content: _formatDateTime(alert.acknowledgedAt),
                      icon: Icons.check_circle,
                    ),
                  ],

                  if (alert.resolvedAt != null) ...[
                    SizedBox(height: 16.h),
                    _DetailSection(
                      title: 'Resolved At',
                      content: _formatDateTime(alert.resolvedAt),
                      icon: Icons.done_all,
                    ),
                  ],

                  if (alert.affectedStudentsCount != null && alert.affectedStudentsCount! > 0) ...[
                    SizedBox(height: 16.h),
                    _DetailSection(
                      title: 'Affected Students',
                      content: '${alert.affectedStudentsCount} students',
                      icon: Icons.school,
                    ),
                  ],

                  if (alert.estimatedDelayMinutes != null && alert.estimatedDelayMinutes! > 0) ...[
                    SizedBox(height: 16.h),
                    _DetailSection(
                      title: 'Estimated Delay',
                      content: '${alert.estimatedDelayMinutes} minutes',
                      icon: Icons.schedule,
                    ),
                  ],

                  SizedBox(height: 20.h),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getAlertIcon() {
    switch (alert.emergencyType?.toLowerCase()) {
      case 'medical':
        return Icons.medical_services;
      case 'vehicle_breakdown':
      case 'breakdown':
        return Icons.car_repair;
      case 'student':
        return Icons.school;
      default:
        return Icons.warning;
    }
  }

  Color _getAlertColor() {
    switch (alert.emergencyType?.toLowerCase()) {
      case 'medical':
        return AppTheme.errorColor;
      case 'vehicle_breakdown':
      case 'breakdown':
        return AppTheme.warningColor;
      case 'student':
        return AppTheme.infoColor;
      default:
        return AppTheme.textSecondary;
    }
  }

  Color _getSeverityColor() {
    switch (alert.severity?.toLowerCase()) {
      case 'high':
        return AppTheme.errorColor;
      case 'medium':
        return AppTheme.warningColor;
      case 'low':
        return AppTheme.successColor;
      default:
        return AppTheme.textSecondary;
    }
  }

  String _formatDateTime(String? dateTime) {
    if (dateTime == null) return 'Unknown time';
    try {
      final parsed = DateTime.parse(dateTime);
      final now = DateTime.now();
      final difference = now.difference(parsed);

      if (difference.inDays > 0) {
        return '${difference.inDays}d ago';
      } else if (difference.inHours > 0) {
        return '${difference.inHours}h ago';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes}m ago';
      } else {
        return 'Just now';
      }
    } catch (e) {
      return 'Unknown time';
    }
  }
}

class _DetailSection extends StatelessWidget {
  final String title;
  final String content;
  final IconData icon;

  const _DetailSection({
    required this.title,
    required this.content,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: AppTheme.borderColor,
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: AppTheme.primaryColor,
            size: 20.w,
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  content,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}


