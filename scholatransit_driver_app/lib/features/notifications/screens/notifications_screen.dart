import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/providers/notification_provider.dart';
import '../../../core/providers/emergency_provider.dart';
import '../../../core/widgets/notification_item_card.dart';
import '../../../core/theme/app_theme.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    // Load notifications and emergency alerts when the screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(notificationProvider.notifier).loadNotifications();
      ref.read(emergencyProvider.notifier).loadEmergencyAlerts();
    });
  }

  @override
  Widget build(BuildContext context) {
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
            icon: Icon(Icons.refresh, color: Colors.grey[600], size: 24.w),
            onPressed: () async {
              await ref.read(notificationProvider.notifier).loadNotifications();
              await ref.read(emergencyProvider.notifier).loadEmergencyAlerts();
            },
          ),
          IconButton(
            icon: Icon(
              Icons.mark_email_read,
              color: Colors.grey[600],
              size: 24.w,
            ),
            onPressed: () {
              ref.read(notificationProvider.notifier).markAllAsRead();
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(notificationProvider.notifier).loadNotifications();
          await ref.read(emergencyProvider.notifier).loadEmergencyAlerts();
        },
        child: notificationState.isLoading
            ? const Center(child: CircularProgressIndicator())
            : notificationState.error != null
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 64.w, color: Colors.red),
                    SizedBox(height: 16.h),
                    Text(
                      'Error loading notifications',
                      style: GoogleFonts.poppins(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.red,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      notificationState.error!,
                      style: GoogleFonts.poppins(
                        fontSize: 12.sp,
                        color: Colors.grey[600],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 16.h),
                    ElevatedButton.icon(
                      onPressed: () async {
                        await ref
                            .read(notificationProvider.notifier)
                            .loadNotifications();
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                    ),
                  ],
                ),
              )
            : _buildNotificationsContent(notificationState, emergencyState),
      ),
    );
  }

  Widget _buildNotificationsContent(
    NotificationState notificationState,
    EmergencyState emergencyState,
  ) {
    final allItems = <Map<String, dynamic>>[];

    // Add regular notifications
    for (final notification in notificationState.notifications) {
      allItems.add({...notification, 'itemType': 'notification'});
    }

    // Add emergency alerts as notifications
    for (final alert in emergencyState.alerts) {
      allItems.add({
        'id': 'alert_${alert.id}',
        'title': alert.title,
        'body': alert.description,
        'type': 'emergency',
        'timestamp': alert.reportedAt,
        'isRead': false,
        'itemType': 'alert',
        'alertData': alert.toJson(),
      });
    }

    // Sort by timestamp (newest first)
    allItems.sort((a, b) {
      final aTime = DateTime.parse(a['timestamp']);
      final bTime = DateTime.parse(b['timestamp']);
      return bTime.compareTo(aTime);
    });

    if (allItems.isEmpty) {
      return const _EmptyNotificationsView();
    }

    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
      itemCount: allItems.length,
      itemBuilder: (context, index) {
        final item = allItems[index];
        if (item['itemType'] == 'alert') {
          return _buildEmergencyAlertCard(item, emergencyState);
        } else {
          return NotificationItemCard(notification: item);
        }
      },
    );
  }

  Widget _buildEmergencyAlertCard(
    Map<String, dynamic> alertData,
    EmergencyState emergencyState,
  ) {
    final alert = alertData['alertData'] as Map<String, dynamic>;
    final isRead = alertData['isRead'] as bool;
    final title = alertData['title'] as String;
    final body = alertData['body'] as String;
    final timestamp = DateTime.parse(alertData['timestamp'] as String);
    final status = alert['status'] as String;
    final severity = alert['severity'] as String;

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      decoration: BoxDecoration(
        color: isRead ? Colors.white : const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: isRead ? const Color(0xFFE5E7EB) : _getSeverityColor(severity),
          width: isRead ? 1 : 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: EdgeInsets.all(16.w),
        leading: Container(
          padding: EdgeInsets.all(8.w),
          decoration: BoxDecoration(
            color: _getSeverityColor(severity).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Icon(
            Icons.warning,
            color: _getSeverityColor(severity),
            size: 20.w,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: isRead ? FontWeight.w500 : FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 4.h),
            Text(
              body,
              style: TextStyle(fontSize: 14.sp, color: AppTheme.textSecondary),
            ),
            SizedBox(height: 8.h),
            Row(
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: _getStatusColor(status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(
                      color: _getStatusColor(status).withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    status.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10.sp,
                      fontWeight: FontWeight.bold,
                      color: _getStatusColor(status),
                    ),
                  ),
                ),
                SizedBox(width: 8.w),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: _getSeverityColor(severity).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(
                      color: _getSeverityColor(severity).withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    severity.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10.sp,
                      fontWeight: FontWeight.bold,
                      color: _getSeverityColor(severity),
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  _formatTimestamp(timestamp),
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!isRead)
              Container(
                width: 8.w,
                height: 8.w,
                decoration: BoxDecoration(
                  color: _getSeverityColor(severity),
                  borderRadius: BorderRadius.circular(4.r),
                ),
              ),
            SizedBox(width: 8.w),
            Icon(
              Icons.arrow_forward_ios,
              color: AppTheme.textSecondary,
              size: 16.w,
            ),
          ],
        ),
        onTap: () {
          _showAlertDetails(alert);
        },
      ),
    );
  }

  Color _getSeverityColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'critical':
        return Colors.purple;
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      case 'low':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return Colors.red;
      case 'resolved':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  void _showAlertDetails(Map<String, dynamic> alert) {
    // Debug: Print alert data to understand the structure
    print('🚨 DEBUG: Alert details data: $alert');
    print('🚨 DEBUG: Alert keys: ${alert.keys.toList()}');
    print('🚨 DEBUG: Status: ${alert['status']}');
    print('🚨 DEBUG: Severity: ${alert['severity']}');
    print('🚨 DEBUG: Emergency Type: ${alert['emergency_type']}');
    print('🚨 DEBUG: Address: ${alert['address']}');
    print('🚨 DEBUG: Vehicle: ${alert['vehicle']}');
    print('🚨 DEBUG: Route: ${alert['route']}');
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.r),
        ),
        title: Row(
          children: [
            Icon(
              Icons.warning,
              color: _getSeverityColor(alert['severity'] ?? ''),
              size: 24.w,
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Text(
                alert['title'] ?? 'Emergency Alert',
                style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                alert['description'] ?? 'No description available',
                style: TextStyle(fontSize: 14.sp),
              ),
              SizedBox(height: 16.h),
              _buildDetailRow(
                'Status',
                alert['status_display'] ?? alert['status'] ?? 'Unknown',
              ),
              _buildDetailRow(
                'Severity',
                alert['severity_display'] ?? alert['severity'] ?? 'Unknown',
              ),
              _buildDetailRow(
                'Type',
                alert['emergency_type_display'] ??
                    alert['emergency_type'] ??
                    'Unknown',
              ),
              _buildDetailRow(
                'Location',
                alert['address']?.toString() ?? 'Not specified',
              ),
              _buildDetailRow(
                'Affected Students',
                alert['affected_students_count']?.toString() ?? '0',
              ),
              _buildDetailRow(
                'Estimated Delay',
                alert['estimated_delay_minutes'] != null
                    ? '${alert['estimated_delay_minutes']} minutes'
                    : 'Not specified',
              ),
              _buildDetailRow(
                'Reported At',
                alert['reported_at'] != null
                    ? _formatTimestamp(DateTime.parse(alert['reported_at']))
                    : 'Not specified',
              ),
              _buildDetailRow(
                'Estimated Resolution',
                alert['estimated_resolution'] != null
                    ? _formatTimestamp(
                        DateTime.parse(alert['estimated_resolution']),
                      )
                    : 'Not specified',
              ),
              _buildDetailRow(
                'Vehicle',
                alert['vehicle'] != null
                    ? (alert['vehicle']['name'] ??
                          'Vehicle ${alert['vehicle']['id']}')
                    : 'Not specified',
              ),
              _buildDetailRow(
                'Route',
                alert['route'] != null
                    ? (alert['route']['name'] ??
                          'Route ${alert['route']['id']}')
                    : 'Not specified',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120.w,
            child: Text(
              '$label:',
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontSize: 12.sp, color: AppTheme.textPrimary),
            ),
          ),
        ],
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
