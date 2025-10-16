import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/providers/notification_provider.dart';
import '../../../core/providers/emergency_provider.dart';
import '../../../core/widgets/notification_item_card.dart';
import 'emergency_alert_details_screen.dart';

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
      padding: EdgeInsets.zero,
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
    final title = alertData['title'] as String;
    final body = alertData['body'] as String;
    final timestamp = DateTime.parse(alertData['timestamp'] as String);
    final status = alert['status'] as String;
    final severity = alert['severity'] as String;

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => EmergencyAlertDetailsScreen(alert: alert),
          ),
        );
      },
      child: Container(
        margin: EdgeInsets.only(bottom: 1.h),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
            bottom: BorderSide(color: Colors.grey[200]!, width: 1),
          ),
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Type Label at the top
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: _getSeverityColor(severity),
                  borderRadius: BorderRadius.circular(4.r),
                ),
                child: Text(
                  'Emergency',
                  style: GoogleFonts.poppins(
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
              ),
              SizedBox(height: 12.h),

              // Main Content Row
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Main Content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title
                        Text(
                          title,
                          style: GoogleFonts.poppins(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                            height: 1.3,
                          ),
                        ),
                        SizedBox(height: 4.h),

                        // Description
                        Text(
                          body,
                          style: GoogleFonts.poppins(
                            fontSize: 12.sp,
                            color: Colors.grey[600],
                            height: 1.4,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 6.h),

                        // Status and Severity
                        Row(
                          children: [
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 6.w,
                                vertical: 2.h,
                              ),
                              decoration: BoxDecoration(
                                color: _getStatusColor(status).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(3.r),
                              ),
                              child: Text(
                                status.toUpperCase(),
                                style: GoogleFonts.poppins(
                                  fontSize: 9.sp,
                                  fontWeight: FontWeight.w600,
                                  color: _getStatusColor(status),
                                ),
                              ),
                            ),
                            SizedBox(width: 6.w),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 6.w,
                                vertical: 2.h,
                              ),
                              decoration: BoxDecoration(
                                color: _getSeverityColor(
                                  severity,
                                ).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(3.r),
                              ),
                              child: Text(
                                severity.toUpperCase(),
                                style: GoogleFonts.poppins(
                                  fontSize: 9.sp,
                                  fontWeight: FontWeight.w600,
                                  color: _getSeverityColor(severity),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Timestamp
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 12.w,
                        color: Colors.grey[500],
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        _formatTimestamp(timestamp),
                        style: GoogleFonts.poppins(
                          fontSize: 10.sp,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
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
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      // Format as "24 Nov 2018 at 9:30 AM" like in the design
      final months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];
      final day = timestamp.day;
      final month = months[timestamp.month - 1];
      final year = timestamp.year;
      final hour = timestamp.hour;
      final minute = timestamp.minute;
      final period = hour >= 12 ? 'PM' : 'AM';
      final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
      final minuteStr = minute.toString().padLeft(2, '0');

      return '$day $month $year at $displayHour:$minuteStr $period';
    }
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
