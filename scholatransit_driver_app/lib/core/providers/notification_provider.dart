import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/notification_service.dart';
import '../services/api_service.dart';
import '../config/app_config.dart';

class NotificationState {
  final bool isEnabled;
  final bool isLoading;
  final List<Map<String, dynamic>> notifications;
  final int unreadCount;
  final String? error;

  const NotificationState({
    this.isEnabled = true,
    this.isLoading = false,
    this.notifications = const [],
    this.unreadCount = 0,
    this.error,
  });

  NotificationState copyWith({
    bool? isEnabled,
    bool? isLoading,
    List<Map<String, dynamic>>? notifications,
    int? unreadCount,
    String? error,
  }) {
    return NotificationState(
      isEnabled: isEnabled ?? this.isEnabled,
      isLoading: isLoading ?? this.isLoading,
      notifications: notifications ?? this.notifications,
      unreadCount: unreadCount ?? this.unreadCount,
      error: error,
    );
  }
}

class NotificationNotifier extends StateNotifier<NotificationState> {
  NotificationNotifier() : super(const NotificationState());

  Future<void> initializeNotifications() async {
    try {
      await NotificationService.init();
      state = state.copyWith(isEnabled: true, error: null);
    } catch (e) {
      state = state.copyWith(error: 'Failed to initialize notifications: $e');
    }
  }

  Future<void> showTripNotification({
    required String title,
    required String body,
    String? tripId,
  }) async {
    try {
      await NotificationService.showTripNotification(
        title: title,
        body: body,
        tripId: tripId,
      );
      _addNotification(title, body, 'trip', tripId);
    } catch (e) {
      state = state.copyWith(error: 'Failed to show notification: $e');
    }
  }

  Future<void> showEmergencyNotification({
    required String title,
    required String body,
    String? emergencyId,
  }) async {
    try {
      await NotificationService.showEmergencyNotification(
        title: title,
        body: body,
        emergencyId: emergencyId,
      );
      _addNotification(title, body, 'emergency', emergencyId);
    } catch (e) {
      state = state.copyWith(
        error: 'Failed to show emergency notification: $e',
      );
    }
  }

  Future<void> showStudentStatusNotification({
    required String studentName,
    required String status,
    String? tripId,
  }) async {
    try {
      await NotificationService.showStudentStatusNotification(
        studentName: studentName,
        status: status,
        tripId: tripId,
      );
      _addNotification(
        'Student Status Update',
        '$studentName: $status',
        'student',
        tripId,
      );
    } catch (e) {
      state = state.copyWith(
        error: 'Failed to show student status notification: $e',
      );
    }
  }

  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? payload,
  }) async {
    try {
      await NotificationService.scheduleNotification(
        id: id,
        title: title,
        body: body,
        scheduledDate: scheduledDate,
        payload: payload,
      );
    } catch (e) {
      state = state.copyWith(error: 'Failed to schedule notification: $e');
    }
  }

  Future<void> cancelNotification(int id) async {
    try {
      await NotificationService.cancelNotification(id);
    } catch (e) {
      state = state.copyWith(error: 'Failed to cancel notification: $e');
    }
  }

  Future<void> cancelAllNotifications() async {
    try {
      await NotificationService.cancelAllNotifications();
    } catch (e) {
      state = state.copyWith(error: 'Failed to cancel all notifications: $e');
    }
  }

  Future<String?> getFCMToken() async {
    try {
      return await NotificationService.getFCMToken();
    } catch (e) {
      state = state.copyWith(error: 'Failed to get FCM token: $e');
      return null;
    }
  }

  Future<void> subscribeToTopic(String topic) async {
    try {
      await NotificationService.subscribeToTopic(topic);
    } catch (e) {
      state = state.copyWith(error: 'Failed to subscribe to topic: $e');
    }
  }

  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await NotificationService.unsubscribeFromTopic(topic);
    } catch (e) {
      state = state.copyWith(error: 'Failed to unsubscribe from topic: $e');
    }
  }

  Future<void> loadNotifications() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      print(
        '🔔 DEBUG: Loading notifications from ${AppConfig.notificationsEndpoint}',
      );
      final response = await ApiService.get<Map<String, dynamic>>(
        AppConfig.notificationsEndpoint,
      );

      print(
        '🔔 DEBUG: Notifications API Response - Success: ${response.success}',
      );
      print('🔔 DEBUG: Notifications API Response - Error: ${response.error}');
      print('🔔 DEBUG: Notifications API Response - Data: ${response.data}');

      if (response.success && response.data != null) {
        final data = response.data!;
        final notificationsList =
            (data['results'] as List?)
                ?.map((notification) => notification as Map<String, dynamic>)
                .toList() ??
            [];

        print(
          '🔔 DEBUG: Loaded ${notificationsList.length} notifications from server',
        );

        // Merge server notifications with local ones
        final allNotifications = [...notificationsList, ...state.notifications];
        final unreadCount = allNotifications.where((n) => !n['isRead']).length;

        state = state.copyWith(
          isLoading: false,
          notifications: allNotifications,
          unreadCount: unreadCount,
          error: null,
        );
      } else {
        print('🔔 DEBUG: ERROR - Notifications API failed: ${response.error}');
        state = state.copyWith(
          isLoading: false,
          error: 'Failed to load notifications: ${response.error}',
        );
      }
    } catch (e) {
      print('🔔 DEBUG: ERROR - Exception loading notifications: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load notifications: $e',
      );
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }

  void _addNotification(
    String title,
    String body,
    String type,
    String? payload,
  ) {
    final newNotification = {
      'id': DateTime.now().millisecondsSinceEpoch,
      'title': title,
      'body': body,
      'type': type,
      'payload': payload,
      'timestamp': DateTime.now().toIso8601String(),
      'isRead': false,
    };

    final updatedNotifications = [newNotification, ...state.notifications];
    state = state.copyWith(
      notifications: updatedNotifications,
      unreadCount: state.unreadCount + 1,
    );
  }

  void markAsRead(int notificationId) {
    final updatedNotifications = state.notifications.map((notification) {
      if (notification['id'] == notificationId && !notification['isRead']) {
        return {...notification, 'isRead': true};
      }
      return notification;
    }).toList();

    final unreadCount = updatedNotifications.where((n) => !n['isRead']).length;

    state = state.copyWith(
      notifications: updatedNotifications,
      unreadCount: unreadCount,
    );
  }

  void markAllAsRead() {
    final updatedNotifications = state.notifications.map((notification) {
      return {...notification, 'isRead': true};
    }).toList();

    state = state.copyWith(notifications: updatedNotifications, unreadCount: 0);
  }

  void clearAllNotifications() {
    state = state.copyWith(notifications: [], unreadCount: 0);
  }

  void dismissNotification(int notificationId) {
    final updatedNotifications = state.notifications
        .where((notification) => notification['id'] != notificationId)
        .toList();

    final unreadCount = updatedNotifications.where((n) => !n['isRead']).length;

    state = state.copyWith(
      notifications: updatedNotifications,
      unreadCount: unreadCount,
    );
  }
}

final notificationProvider =
    StateNotifierProvider<NotificationNotifier, NotificationState>((ref) {
      return NotificationNotifier();
    });

final isNotificationEnabledProvider = Provider<bool>((ref) {
  return ref.watch(notificationProvider).isEnabled;
});
