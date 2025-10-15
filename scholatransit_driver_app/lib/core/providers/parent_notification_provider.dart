import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/eta_model.dart';
import '../models/trip_model.dart';
import '../models/student_model.dart';
import '../services/parent_notification_service.dart';

class ParentNotificationState {
  final bool isActive;
  final bool isLoading;
  final List<Map<String, dynamic>> sentNotifications;
  final String? error;
  final Trip? currentTrip;
  final List<Student> studentsOnTrip;
  final ETAInfo? lastETA;
  final double? remainingDistance;
  final double? distanceTraveled;

  const ParentNotificationState({
    this.isActive = false,
    this.isLoading = false,
    this.sentNotifications = const [],
    this.error,
    this.currentTrip,
    this.studentsOnTrip = const [],
    this.lastETA,
    this.remainingDistance,
    this.distanceTraveled,
  });

  ParentNotificationState copyWith({
    bool? isActive,
    bool? isLoading,
    List<Map<String, dynamic>>? sentNotifications,
    String? error,
    Trip? currentTrip,
    List<Student>? studentsOnTrip,
    ETAInfo? lastETA,
    double? remainingDistance,
    double? distanceTraveled,
  }) {
    return ParentNotificationState(
      isActive: isActive ?? this.isActive,
      isLoading: isLoading ?? this.isLoading,
      sentNotifications: sentNotifications ?? this.sentNotifications,
      error: error,
      currentTrip: currentTrip ?? this.currentTrip,
      studentsOnTrip: studentsOnTrip ?? this.studentsOnTrip,
      lastETA: lastETA ?? this.lastETA,
      remainingDistance: remainingDistance ?? this.remainingDistance,
      distanceTraveled: distanceTraveled ?? this.distanceTraveled,
    );
  }
}

class ParentNotificationNotifier
    extends StateNotifier<ParentNotificationState> {
  ParentNotificationNotifier() : super(const ParentNotificationState());

  /// Start sending notifications to parents for a trip
  Future<bool> startParentNotifications({
    required Trip trip,
    required List<Student> students,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      print(
        '📱 Parent Notification Provider: Starting notifications for trip ${trip.tripId}',
      );

      final success = await ParentNotificationService.startParentNotifications(
        trip: trip,
        students: students,
        onNotificationSent: _onNotificationSent,
        onNotificationError: _onNotificationError,
      );

      if (success) {
        state = state.copyWith(
          isLoading: false,
          isActive: true,
          currentTrip: trip,
          studentsOnTrip: students,
          error: null,
        );
        print('✅ Parent Notification Provider: Started successfully');
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'Failed to start parent notifications',
        );
        return false;
      }
    } catch (e) {
      print('❌ Parent Notification Provider: Error starting notifications: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to start parent notifications: $e',
      );
      return false;
    }
  }

  /// Stop sending notifications to parents
  Future<void> stopParentNotifications() async {
    try {
      print('📱 Parent Notification Provider: Stopping notifications');

      await ParentNotificationService.stopParentNotifications();

      state = state.copyWith(
        isActive: false,
        currentTrip: null,
        studentsOnTrip: [],
        lastETA: null,
        remainingDistance: null,
        distanceTraveled: null,
      );

      print('✅ Parent Notification Provider: Stopped successfully');
    } catch (e) {
      print('❌ Parent Notification Provider: Error stopping notifications: $e');
      state = state.copyWith(error: 'Failed to stop parent notifications: $e');
    }
  }

  /// Send ETA update to all parents
  Future<void> sendETAUpdate(ETAInfo etaInfo) async {
    if (!state.isActive || state.studentsOnTrip.isEmpty) {
      print(
        '⚠️ Parent Notification Provider: Cannot send ETA update - not active or no students',
      );
      return;
    }

    try {
      print(
        '📱 Parent Notification Provider: Sending ETA update to all parents',
      );

      for (final student in state.studentsOnTrip) {
        if (student.parentPhone != null || student.parentEmail != null) {
          await ParentNotificationService.sendETAUpdate(
            etaInfo: etaInfo,
            studentName: student.fullName,
            parentPhone: student.parentPhone ?? '',
            parentEmail: student.parentEmail ?? '',
          );
        }
      }

      state = state.copyWith(lastETA: etaInfo);
      print('✅ Parent Notification Provider: ETA update sent to all parents');
    } catch (e) {
      print('❌ Parent Notification Provider: Error sending ETA update: $e');
      state = state.copyWith(error: 'Failed to send ETA update: $e');
    }
  }

  /// Send distance update to all parents
  Future<void> sendDistanceUpdate({
    required double remainingDistance,
    required double distanceTraveled,
  }) async {
    if (!state.isActive || state.studentsOnTrip.isEmpty) {
      print(
        '⚠️ Parent Notification Provider: Cannot send distance update - not active or no students',
      );
      return;
    }

    try {
      print(
        '📱 Parent Notification Provider: Sending distance update to all parents',
      );

      for (final student in state.studentsOnTrip) {
        if (student.parentPhone != null || student.parentEmail != null) {
          await ParentNotificationService.sendDistanceUpdate(
            remainingDistance: remainingDistance,
            distanceTraveled: distanceTraveled,
            studentName: student.fullName,
            parentPhone: student.parentPhone ?? '',
            parentEmail: student.parentEmail ?? '',
          );
        }
      }

      state = state.copyWith(
        remainingDistance: remainingDistance,
        distanceTraveled: distanceTraveled,
      );
      print(
        '✅ Parent Notification Provider: Distance update sent to all parents',
      );
    } catch (e) {
      print(
        '❌ Parent Notification Provider: Error sending distance update: $e',
      );
      state = state.copyWith(error: 'Failed to send distance update: $e');
    }
  }

  /// Send arrival notification to all parents
  Future<void> sendArrivalNotification(String arrivalLocation) async {
    if (!state.isActive || state.studentsOnTrip.isEmpty) {
      print(
        '⚠️ Parent Notification Provider: Cannot send arrival notification - not active or no students',
      );
      return;
    }

    try {
      print(
        '📱 Parent Notification Provider: Sending arrival notification to all parents',
      );

      for (final student in state.studentsOnTrip) {
        if (student.parentPhone != null || student.parentEmail != null) {
          await ParentNotificationService.sendArrivalNotification(
            studentName: student.fullName,
            parentPhone: student.parentPhone ?? '',
            parentEmail: student.parentEmail ?? '',
            arrivalLocation: arrivalLocation,
          );
        }
      }

      print(
        '✅ Parent Notification Provider: Arrival notification sent to all parents',
      );
    } catch (e) {
      print(
        '❌ Parent Notification Provider: Error sending arrival notification: $e',
      );
      state = state.copyWith(error: 'Failed to send arrival notification: $e');
    }
  }

  /// Send delay notification to all parents
  Future<void> sendDelayNotification({
    required String delayReason,
    required int delayMinutes,
  }) async {
    if (!state.isActive || state.studentsOnTrip.isEmpty) {
      print(
        '⚠️ Parent Notification Provider: Cannot send delay notification - not active or no students',
      );
      return;
    }

    try {
      print(
        '📱 Parent Notification Provider: Sending delay notification to all parents',
      );

      for (final student in state.studentsOnTrip) {
        if (student.parentPhone != null || student.parentEmail != null) {
          await ParentNotificationService.sendDelayNotification(
            studentName: student.fullName,
            parentPhone: student.parentPhone ?? '',
            parentEmail: student.parentEmail ?? '',
            delayReason: delayReason,
            delayMinutes: delayMinutes,
          );
        }
      }

      print(
        '✅ Parent Notification Provider: Delay notification sent to all parents',
      );
    } catch (e) {
      print(
        '❌ Parent Notification Provider: Error sending delay notification: $e',
      );
      state = state.copyWith(error: 'Failed to send delay notification: $e');
    }
  }

  /// Handle notification sent callback
  void _onNotificationSent(String message) {
    final newNotification = {
      'timestamp': DateTime.now().toIso8601String(),
      'message': message,
      'type': 'sent',
    };

    state = state.copyWith(
      sentNotifications: [...state.sentNotifications, newNotification],
    );
  }

  /// Handle notification error callback
  void _onNotificationError(String error) {
    final errorNotification = {
      'timestamp': DateTime.now().toIso8601String(),
      'message': error,
      'type': 'error',
    };

    state = state.copyWith(
      sentNotifications: [...state.sentNotifications, errorNotification],
      error: error,
    );
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }

  /// Get notification history
  List<Map<String, dynamic>> get notificationHistory => state.sentNotifications;

  /// Check if notifications are active
  bool get isActive => state.isActive;

  /// Get current trip
  Trip? get currentTrip => state.currentTrip;

  /// Get students on trip
  List<Student> get studentsOnTrip => state.studentsOnTrip;
}

final parentNotificationProvider =
    StateNotifierProvider<ParentNotificationNotifier, ParentNotificationState>(
      (ref) => ParentNotificationNotifier(),
    );
