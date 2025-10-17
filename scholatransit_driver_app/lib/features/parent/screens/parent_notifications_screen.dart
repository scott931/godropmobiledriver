import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/providers/parent_provider.dart';

class ParentNotificationsScreen extends ConsumerWidget {
  const ParentNotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final parentState = ref.watch(parentProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: const Color(0xFF0052CC),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.mark_email_read),
            onPressed: () => _markAllAsRead(context, ref),
          ),
        ],
      ),
      body: parentState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : parentState.notifications.isEmpty
          ? _buildEmptyState(context)
          : _buildNotificationsList(context, ref, parentState),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_none, size: 80.w, color: Colors.grey[400]),
          SizedBox(height: 16.h),
          Text(
            'No Notifications',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'You will receive notifications about your child\'s bus status here.',
            style: TextStyle(fontSize: 14.sp, color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationsList(
    BuildContext context,
    WidgetRef ref,
    parentState,
  ) {
    return ListView.builder(
      padding: EdgeInsets.all(16.w),
      itemCount: parentState.notifications.length,
      itemBuilder: (context, index) {
        final notification = parentState.notifications[index];
        return _buildNotificationItem(context, ref, notification);
      },
    );
  }

  Widget _buildNotificationItem(
    BuildContext context,
    WidgetRef ref,
    notification,
  ) {
    return Card(
      margin: EdgeInsets.only(bottom: 12.h),
      elevation: notification.isRead ? 1 : 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getNotificationColor(
            notification.type,
          ).withOpacity(0.1),
          child: Icon(
            _getNotificationIcon(notification.type),
            color: _getNotificationColor(notification.type),
            size: 20.w,
          ),
        ),
        title: Text(
          notification.title,
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: notification.isRead
                ? FontWeight.normal
                : FontWeight.w600,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 4.h),
            Text(
              notification.message,
              style: TextStyle(fontSize: 14.sp, color: Colors.grey[600]),
            ),
            SizedBox(height: 4.h),
            Text(
              _formatTime(notification.createdAt),
              style: TextStyle(fontSize: 12.sp, color: Colors.grey[500]),
            ),
          ],
        ),
        trailing: PopupMenuButton(
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'mark_read',
              child: Row(
                children: [
                  Icon(Icons.mark_email_read, size: 16.w),
                  SizedBox(width: 8.w),
                  const Text('Mark as Read'),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, size: 16.w, color: Colors.red),
                  SizedBox(width: 8.w),
                  const Text('Delete', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
          onSelected: (value) =>
              _handleNotificationAction(context, ref, notification, value),
        ),
        onTap: () => _handleNotificationTap(context, ref, notification),
      ),
    );
  }

  IconData _getNotificationIcon(String type) {
    switch (type.toLowerCase()) {
      case 'pickup':
        return Icons.directions_bus;
      case 'dropoff':
        return Icons.home;
      case 'delay':
        return Icons.schedule;
      case 'emergency':
        return Icons.warning;
      case 'route_change':
        return Icons.route;
      case 'eta':
        return Icons.access_time;
      default:
        return Icons.notifications;
    }
  }

  Color _getNotificationColor(String type) {
    switch (type.toLowerCase()) {
      case 'pickup':
        return Colors.green;
      case 'dropoff':
        return Colors.blue;
      case 'delay':
        return Colors.orange;
      case 'emergency':
        return Colors.red;
      case 'route_change':
        return Colors.purple;
      case 'eta':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

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

  void _handleNotificationAction(
    BuildContext context,
    WidgetRef ref,
    notification,
    String action,
  ) {
    switch (action) {
      case 'mark_read':
        ref
            .read(parentProvider.notifier)
            .markNotificationAsRead(notification.id);
        break;
      case 'delete':
        _showDeleteConfirmation(context, ref, notification);
        break;
    }
  }

  void _handleNotificationTap(
    BuildContext context,
    WidgetRef ref,
    notification,
  ) {
    if (!notification.isRead) {
      ref.read(parentProvider.notifier).markNotificationAsRead(notification.id);
    }
    // Handle notification tap logic here
  }

  void _markAllAsRead(BuildContext context, WidgetRef ref) {
    ref.read(parentProvider.notifier).markAllNotificationsAsRead();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('All notifications marked as read')),
    );
  }

  void _showDeleteConfirmation(
    BuildContext context,
    WidgetRef ref,
    notification,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Notification'),
        content: const Text(
          'Are you sure you want to delete this notification?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Implement delete notification logic
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Notification deleted')),
              );
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
