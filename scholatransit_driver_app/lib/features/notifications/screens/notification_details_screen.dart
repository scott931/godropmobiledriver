import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';

class NotificationDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> notification;

  const NotificationDetailsScreen({super.key, required this.notification});

  @override
  Widget build(BuildContext context) {
    final title = notification['title'] ?? 'Notification';
    final body = notification['body'] ?? 'No content available';
    final timestamp = DateTime.parse(notification['timestamp'] as String);
    final type = notification['type'] as String;
    final senderName = notification['sender_name'];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black, size: 24.w),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/notifications');
            }
          },
        ),
        title: Text(
          'Notification Details',
          style: GoogleFonts.poppins(
            fontSize: 20.sp,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.share, color: Colors.grey[600], size: 24.w),
            onPressed: () {
              _shareNotification();
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Card
            _buildHeaderCard(title, type, timestamp),
            SizedBox(height: 20.h),

            // Type and timestamp info
            _buildInfoCard(type, timestamp),
            SizedBox(height: 20.h),

            // Message content
            _buildMessageCard(body),
            SizedBox(height: 20.h),

            // Sender info if available
            if (senderName != null) _buildSenderCard(senderName),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCard(String title, String type, DateTime timestamp) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _getTypeColor(type).withOpacity(0.1),
            _getTypeColor(type).withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: _getTypeColor(type).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: _getTypeColor(type).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Icon(
                  _getTypeIcon(type),
                  color: _getTypeColor(type),
                  size: 24.w,
                ),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.poppins(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      _getTypeLabel(type),
                      style: GoogleFonts.poppins(
                        fontSize: 14.sp,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          Row(
            children: [
              Icon(Icons.access_time, size: 16.w, color: Colors.grey[600]),
              SizedBox(width: 8.w),
              Text(
                'Received ${_formatTimestamp(timestamp)}',
                style: GoogleFonts.poppins(
                  fontSize: 12.sp,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(String type, DateTime timestamp) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.grey[200]!, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, size: 20.w, color: Colors.black87),
              SizedBox(width: 8.w),
              Text(
                'Notification Information',
                style: GoogleFonts.poppins(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          _buildInfoRow('Type', _getTypeLabel(type), _getTypeColor(type)),
          _buildInfoRow(
            'Received',
            _formatTimestamp(timestamp),
            Colors.grey[600]!,
          ),
        ],
      ),
    );
  }

  Widget _buildMessageCard(String body) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.grey[200]!, width: 1),
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
              Icon(Icons.message, size: 20.w, color: Colors.black87),
              SizedBox(width: 8.w),
              Text(
                'Message Content',
                style: GoogleFonts.poppins(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          Text(
            body,
            style: GoogleFonts.poppins(
              fontSize: 14.sp,
              color: Colors.black87,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSenderCard(String senderName) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.blue[200]!, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.person, size: 20.w, color: Colors.blue[700]),
              SizedBox(width: 8.w),
              Text(
                'Sender Information',
                style: GoogleFonts.poppins(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.blue[700],
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Text(
            senderName,
            style: GoogleFonts.poppins(
              fontSize: 14.sp,
              color: Colors.black87,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, Color valueColor) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80.w,
            child: Text(
              '$label:',
              style: GoogleFonts.poppins(
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 12.sp,
                color: valueColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
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

  IconData _getTypeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'emergency':
        return Icons.warning;
      case 'trip':
        return Icons.directions_bus;
      case 'student':
        return Icons.school;
      case 'message':
        return Icons.message;
      case 'comment':
        return Icons.comment;
      case 'connect':
        return Icons.connect_without_contact;
      case 'joined':
        return Icons.person_add;
      default:
        return Icons.notifications;
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

  void _shareNotification() {
    // TODO: Implement sharing functionality
    // This could share the notification content via system share sheet
  }
}
