import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/parent_model.dart';
import '../models/parent_trip_model.dart';
import '../services/parent_tracking_service.dart';
import '../services/parent_notification_service.dart';

class ParentState {
  final bool isLoading;
  final Parent? parent;
  final List<Child> children;
  final List<ParentTrip> activeTrips;
  final List<ParentTrip> tripHistory;
  final List<Map<String, dynamic>> notifications;
  final String? error;
  final Map<String, dynamic>? currentLocation;
  final int? unreadCount;

  const ParentState({
    this.isLoading = false,
    this.parent,
    this.children = const [],
    this.activeTrips = const [],
    this.tripHistory = const [],
    this.notifications = const [],
    this.error,
    this.currentLocation,
    this.unreadCount = 0,
  });

  ParentState copyWith({
    bool? isLoading,
    Parent? parent,
    List<Child>? children,
    List<ParentTrip>? activeTrips,
    List<ParentTrip>? tripHistory,
    List<Map<String, dynamic>>? notifications,
    String? error,
    Map<String, dynamic>? currentLocation,
    int? unreadCount,
  }) {
    return ParentState(
      isLoading: isLoading ?? this.isLoading,
      parent: parent ?? this.parent,
      children: children ?? this.children,
      activeTrips: activeTrips ?? this.activeTrips,
      tripHistory: tripHistory ?? this.tripHistory,
      notifications: notifications ?? this.notifications,
      error: error,
      currentLocation: currentLocation ?? this.currentLocation,
      unreadCount: unreadCount ?? this.unreadCount,
    );
  }
}

class ParentNotifier extends StateNotifier<ParentState> {
  ParentNotifier() : super(const ParentState()) {
    _initializeServices();
  }

  void _initializeServices() {
    // Listen to trip updates
    ParentTrackingService.tripStream.listen((trip) {
      _updateActiveTrip(trip);
    });

    // Listen to ETA updates
    ParentTrackingService.etaStream.listen((etaData) {
      _updateETA(etaData);
    });

    // Listen to notifications
    ParentNotificationService.notificationStream.listen((notification) {
      _addNotification(notification);
    });
  }

  Future<void> loadParentData() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      // Load active trips
      await loadActiveTrips();

      // Load trip history
      await loadTripHistory();

      // Load notifications
      await loadNotifications();

      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load parent data: $e',
      );
    }
  }

  Future<void> loadActiveTrips() async {
    try {
      final response = await ParentTrackingService.getActiveTrips();
      if (response.success && response.data != null) {
        state = state.copyWith(activeTrips: response.data!);
      }
    } catch (e) {
      print('❌ Failed to load active trips: $e');
    }
  }

  Future<void> loadTripHistory({DateTime? startDate, DateTime? endDate}) async {
    try {
      final response = await ParentTrackingService.getTripHistory(
        startDate: startDate,
        endDate: endDate,
        limit: 50,
      );
      if (response.success && response.data != null) {
        state = state.copyWith(tripHistory: response.data!);
      }
    } catch (e) {
      print('❌ Failed to load trip history: $e');
    }
  }

  Future<void> loadNotifications() async {
    try {
      final response = await ParentNotificationService.getParentNotifications(
        limit: 50,
        isRead: false,
      );
      if (response.success && response.data != null) {
        state = state.copyWith(notifications: response.data!);
      }
    } catch (e) {
      print('❌ Failed to load notifications: $e');
    }
  }

  Future<void> startTripTracking(int tripId) async {
    try {
      final success = await ParentTrackingService.startTripTracking(tripId);
      if (success) {
        print('✅ Started tracking trip $tripId');
      }
    } catch (e) {
      print('❌ Failed to start trip tracking: $e');
    }
  }

  Future<void> stopTripTracking() async {
    try {
      await ParentTrackingService.stopTripTracking();
      print('✅ Stopped trip tracking');
    } catch (e) {
      print('❌ Failed to stop trip tracking: $e');
    }
  }

  Future<void> startNotificationMonitoring() async {
    if (state.parent != null) {
      ParentNotificationService.startNotificationMonitoring(state.parent!.id);
    }
  }

  Future<void> stopNotificationMonitoring() async {
    ParentNotificationService.stopNotificationMonitoring();
  }

  void _updateActiveTrip(ParentTrip trip) {
    final updatedTrips = List<ParentTrip>.from(state.activeTrips);
    final index = updatedTrips.indexWhere((t) => t.id == trip.id);

    if (index >= 0) {
      updatedTrips[index] = trip;
    } else {
      updatedTrips.add(trip);
    }

    state = state.copyWith(activeTrips: updatedTrips);
  }

  void _updateETA(Map<String, dynamic> etaData) {
    // Update current location and ETA
    state = state.copyWith(currentLocation: etaData);
  }

  void _addNotification(Map<String, dynamic> notification) {
    final updatedNotifications = List<Map<String, dynamic>>.from(
      state.notifications,
    );
    updatedNotifications.insert(0, notification);

    state = state.copyWith(
      notifications: updatedNotifications,
      unreadCount: (state.unreadCount ?? 0) + 1,
    );
  }

  Future<void> markNotificationAsRead(int notificationId) async {
    try {
      await ParentNotificationService.markNotificationAsRead(
        notificationId: notificationId,
      );

      // Update local state
      final updatedNotifications = state.notifications.map((notification) {
        if (notification['id'] == notificationId) {
          return {...notification, 'is_read': true};
        }
        return notification;
      }).toList();

      state = state.copyWith(
        notifications: updatedNotifications,
        unreadCount: (state.unreadCount ?? 0) - 1,
      );
    } catch (e) {
      print('❌ Failed to mark notification as read: $e');
    }
  }

  Future<void> markAllNotificationsAsRead() async {
    if (state.parent != null) {
      try {
        await ParentNotificationService.markAllNotificationsAsRead(
          parentId: state.parent!.id,
        );

        state = state.copyWith(
          notifications: state.notifications.map((notification) {
            return {...notification, 'is_read': true};
          }).toList(),
          unreadCount: 0,
        );
      } catch (e) {
        print('❌ Failed to mark all notifications as read: $e');
      }
    }
  }

  Future<void> refreshData() async {
    await loadParentData();
  }

  @override
  void dispose() {
    stopTripTracking();
    stopNotificationMonitoring();
    super.dispose();
  }
}

final parentProvider = StateNotifierProvider<ParentNotifier, ParentState>((
  ref,
) {
  return ParentNotifier();
});
