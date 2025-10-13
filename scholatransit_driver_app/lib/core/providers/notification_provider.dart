import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/notification_service.dart';

class NotificationState {
  final bool isEnabled;
  final List<Map<String, dynamic>> notifications;
  final String? error;

  const NotificationState({
    this.isEnabled = true,
    this.notifications = const [],
    this.error,
  });

  NotificationState copyWith({
    bool? isEnabled,
    List<Map<String, dynamic>>? notifications,
    String? error,
  }) {
    return NotificationState(
      isEnabled: isEnabled ?? this.isEnabled,
      notifications: notifications ?? this.notifications,
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

  void clearError() {
    state = state.copyWith(error: null);
  }
}

final notificationProvider =
    StateNotifierProvider<NotificationNotifier, NotificationState>((ref) {
      return NotificationNotifier();
    });

final isNotificationEnabledProvider = Provider<bool>((ref) {
  return ref.watch(notificationProvider).isEnabled;
});
