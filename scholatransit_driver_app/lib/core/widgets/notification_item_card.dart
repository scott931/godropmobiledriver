import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../features/notifications/screens/notification_details_screen.dart';

class NotificationItemCard extends ConsumerWidget {
  final Map<String, dynamic> notification;

  const NotificationItemCard({super.key, required this.notification});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final title = notification['title'] as String;
    final body = notification['body'] as String;
    final timestamp = DateTime.parse(notification['timestamp'] as String);
    final type = notification['type'] as String;

    return Container(
      margin: EdgeInsets.only(bottom: 1.h),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey[200]!, width: 1)),
      ),
      child: GestureDetector(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) =>
                  NotificationDetailsScreen(notification: notification),
            ),
          );
        },
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Type Label
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: _getTypeColor(type),
                  borderRadius: BorderRadius.circular(4.r),
                ),
                child: Text(
                  _getTypeLabel(type),
                  style: GoogleFonts.poppins(
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
              ),
              SizedBox(width: 12.w),

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

                    // Associated Name (if available)
                    if (notification['sender_name'] != null)
                      Text(
                        notification['sender_name'],
                        style: GoogleFonts.poppins(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w500,
                          color: Colors.red[600],
                        ),
                      ),
                  ],
                ),
              ),

              // Timestamp
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Icon(Icons.access_time, size: 12.w, color: Colors.grey[500]),
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
        ),
      ),
    );
  }

  Color _getTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'emergency':
        return Colors.red;
      case 'trip':
        return Colors.blue;
      case 'student':
        return Colors.green;
      case 'message':
        return Colors.orange;
      case 'comment':
        return Colors.purple;
      case 'connect':
        return Colors.blue;
      case 'joined':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _getTypeLabel(String type) {
    switch (type.toLowerCase()) {
      case 'emergency':
        return 'Emergency';
      case 'trip':
        return 'Trip';
      case 'student':
        return 'Student';
      case 'message':
        return 'Message';
      case 'comment':
        return 'Comment';
      case 'connect':
        return 'Connect';
      case 'joined':
        return 'Joined New User';
      default:
        return 'Notification';
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
