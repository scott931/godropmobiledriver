import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
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
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.read(emergencyProvider.notifier).loadEmergencyAlerts();
            },
          ),
          IconButton(
            icon: const Icon(Icons.mark_email_read),
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
            ? const Center(child: CircularProgressIndicator())
            : emergencyState.alerts.isEmpty
                ? const _EmptyNotificationsView()
                : ListView.builder(
                    padding: EdgeInsets.all(16.w),
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
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_outlined,
            size: 64,
            color: AppTheme.textTertiary,
          ),
          SizedBox(height: 16),
          Text(
            'No Notifications',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textSecondary,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'You\'ll receive notifications about trips, students, and emergencies here',
            style: TextStyle(color: AppTheme.textTertiary),
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
    return Card(
      margin: EdgeInsets.only(bottom: 12.h),
      child: InkWell(
        onTap: () => _showAlertDetails(context, alert),
        borderRadius: BorderRadius.circular(8.r),
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    _getAlertIcon(),
                    color: _getAlertColor(),
                    size: 24.w,
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Text(
                      alert.title ?? 'Emergency Alert',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                    decoration: BoxDecoration(
                      color: _getSeverityColor().withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Text(
                      alert.severityDisplay ?? alert.severity ?? 'Unknown',
                      style: TextStyle(
                        color: _getSeverityColor(),
                        fontSize: 12.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8.h),
              Text(
                alert.description ?? 'No description available',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textSecondary,
                ),
              ),
              SizedBox(height: 12.h),
              Row(
                children: [
                  Icon(Icons.access_time, size: 16.w, color: AppTheme.textTertiary),
                  SizedBox(width: 4.w),
                  Text(
                    _formatDateTime(alert.reportedAt ?? alert.createdAt),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.textTertiary,
                    ),
                  ),
                  const Spacer(),
                  if (alert.status == 'active')
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                      decoration: BoxDecoration(
                        color: AppTheme.errorColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Text(
                        'ACTIVE',
                        style: TextStyle(
                          color: AppTheme.errorColor,
                          fontSize: 10.sp,
                          fontWeight: FontWeight.bold,
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


