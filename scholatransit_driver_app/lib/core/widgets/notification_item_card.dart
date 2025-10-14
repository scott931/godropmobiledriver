import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../providers/notification_provider.dart';
import '../theme/app_theme.dart';

class NotificationItemCard extends ConsumerWidget {
  final Map<String, dynamic> notification;

  const NotificationItemCard({super.key, required this.notification});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isRead = notification['isRead'] as bool;
    final title = notification['title'] as String;
    final body = notification['body'] as String;
    final timestamp = DateTime.parse(notification['timestamp'] as String);
    final type = notification['type'] as String;

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      decoration: BoxDecoration(
        color: isRead ? Colors.white : const Color(0xFFF0F9FF),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: isRead ? const Color(0xFFE5E7EB) : const Color(0xFF3B82F6),
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
            color: _getTypeColor(type).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Icon(
            _getTypeIcon(type),
            color: _getTypeColor(type),
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
            Text(
              _formatTimestamp(timestamp),
              style: TextStyle(fontSize: 12.sp, color: AppTheme.textSecondary),
            ),
          ],
        ),
        trailing: isRead
            ? null
            : Container(
                width: 8.w,
                height: 8.w,
                decoration: BoxDecoration(
                  color: const Color(0xFF3B82F6),
                  borderRadius: BorderRadius.circular(4.r),
                ),
              ),
        onTap: () {
          if (!isRead) {
            ref
                .read(notificationProvider.notifier)
                .markAsRead(notification['id']);
          }
        },
      ),
    );
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'emergency':
        return Colors.red;
      case 'trip':
        return Colors.blue;
      case 'student':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'emergency':
        return Icons.warning;
      case 'trip':
        return Icons.directions_bus;
      case 'student':
        return Icons.school;
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
    } else {
      return '${difference.inDays}d ago';
    }
  }
}
