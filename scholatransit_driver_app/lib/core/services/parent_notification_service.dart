import 'dart:async';
import '../models/parent_model.dart';
import '../models/parent_trip_model.dart';
import 'api_service.dart';

class ParentNotificationService {
  static final StreamController<Map<String, dynamic>> _notificationController =
      StreamController<Map<String, dynamic>>.broadcast();
  static Timer? _notificationTimer;

  static Stream<Map<String, dynamic>> get notificationStream =>
      _notificationController.stream;

  /// Send child status update notification
  static Future<ApiResponse<Map<String, dynamic>>> sendChildStatusUpdate({
    required int parentId,
    required int childId,
    required ChildStatus status,
    String? message,
    Map<String, dynamic>? additionalData,
  }) async {
    return ApiService.post<Map<String, dynamic>>(
      '/parent/notifications/child-status/',
      data: {
        'parent_id': parentId,
        'child_id': childId,
        'status': status.apiValue,
        'message': message ?? _getStatusMessage(status),
        'additional_data': additionalData,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  /// Send trip update notification
  static Future<ApiResponse<Map<String, dynamic>>> sendTripUpdate({
    required int parentId,
    required int tripId,
    required String updateType,
    required String message,
    Map<String, dynamic>? tripData,
  }) async {
    return ApiService.post<Map<String, dynamic>>(
      '/parent/notifications/trip-update/',
      data: {
        'parent_id': parentId,
        'trip_id': tripId,
        'update_type': updateType,
        'message': message,
        'trip_data': tripData,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  /// Send emergency alert to parent
  static Future<ApiResponse<Map<String, dynamic>>> sendEmergencyAlert({
    required int parentId,
    required String alertType,
    required String message,
    required String severity,
    Map<String, dynamic>? alertData,
  }) async {
    return ApiService.post<Map<String, dynamic>>(
      '/parent/notifications/emergency/',
      data: {
        'parent_id': parentId,
        'alert_type': alertType,
        'message': message,
        'severity': severity,
        'alert_data': alertData,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  /// Send ETA notification
  static Future<ApiResponse<Map<String, dynamic>>> sendETANotification({
    required int parentId,
    required int tripId,
    required int etaMinutes,
    required String stopName,
  }) async {
    return ApiService.post<Map<String, dynamic>>(
      '/parent/notifications/eta/',
      data: {
        'parent_id': parentId,
        'trip_id': tripId,
        'eta_minutes': etaMinutes,
        'stop_name': stopName,
        'message': _getETAMessage(etaMinutes, stopName),
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  /// Get parent notifications
  static Future<ApiResponse<List<Map<String, dynamic>>>>
  getParentNotifications({
    int? limit,
    int? offset,
    String? type,
    bool? isRead,
  }) async {
    final queryParams = <String, dynamic>{};
    if (limit != null) queryParams['limit'] = limit;
    if (offset != null) queryParams['offset'] = offset;
    if (type != null) queryParams['type'] = type;
    if (isRead != null) queryParams['is_read'] = isRead;

    return ApiService.get<List<Map<String, dynamic>>>(
      '/parent/notifications/',
      queryParameters: queryParams,
    );
  }

  /// Mark notification as read
  static Future<ApiResponse<Map<String, dynamic>>> markNotificationAsRead({
    required int notificationId,
  }) async {
    return ApiService.post<Map<String, dynamic>>(
      '/parent/notifications/$notificationId/read/',
    );
  }

  /// Mark all notifications as read
  static Future<ApiResponse<Map<String, dynamic>>> markAllNotificationsAsRead({
    required int parentId,
  }) async {
    return ApiService.post<Map<String, dynamic>>(
      '/parent/notifications/mark-all-read/',
      data: {'parent_id': parentId},
    );
  }

  /// Start real-time notification monitoring
  static void startNotificationMonitoring(int parentId) {
    _notificationTimer?.cancel();
    _notificationTimer = Timer.periodic(const Duration(seconds: 30), (
      timer,
    ) async {
      await _checkForNewNotifications(parentId);
    });
  }

  /// Stop real-time notification monitoring
  static void stopNotificationMonitoring() {
    _notificationTimer?.cancel();
    _notificationTimer = null;
  }

  /// Check for new notifications
  static Future<void> _checkForNewNotifications(int parentId) async {
    try {
      final response = await getParentNotifications(limit: 10, isRead: false);

      if (response.success && response.data != null) {
        for (final notification in response.data!) {
          _notificationController.add(notification);
        }
      }
    } catch (e) {
      print('❌ Failed to check for notifications: $e');
    }
  }

  /// Get status message for child status
  static String _getStatusMessage(ChildStatus status) {
    switch (status) {
      case ChildStatus.waiting:
        return 'Your child is waiting for the bus';
      case ChildStatus.onBus:
        return 'Your child is now on the bus';
      case ChildStatus.pickedUp:
        return 'Your child has been picked up';
      case ChildStatus.droppedOff:
        return 'Your child has been dropped off';
      case ChildStatus.absent:
        return 'Your child was absent today';
    }
  }

  /// Get ETA message
  static String _getETAMessage(int etaMinutes, String stopName) {
    if (etaMinutes <= 0) {
      return 'The bus has arrived at $stopName';
    } else if (etaMinutes == 1) {
      return 'The bus will arrive at $stopName in 1 minute';
    } else if (etaMinutes < 5) {
      return 'The bus will arrive at $stopName in $etaMinutes minutes';
    } else {
      return 'The bus is approximately $etaMinutes minutes away from $stopName';
    }
  }

  /// Send delay notification
  static Future<ApiResponse<Map<String, dynamic>>> sendDelayNotification({
    required int parentId,
    required int tripId,
    required int delayMinutes,
    required String reason,
  }) async {
    return ApiService.post<Map<String, dynamic>>(
      '/parent/notifications/delay/',
      data: {
        'parent_id': parentId,
        'trip_id': tripId,
        'delay_minutes': delayMinutes,
        'reason': reason,
        'message':
            'The bus is running $delayMinutes minutes late. Reason: $reason',
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  /// Send route change notification
  static Future<ApiResponse<Map<String, dynamic>>> sendRouteChangeNotification({
    required int parentId,
    required int tripId,
    required String oldRoute,
    required String newRoute,
    String? reason,
  }) async {
    return ApiService.post<Map<String, dynamic>>(
      '/parent/notifications/route-change/',
      data: {
        'parent_id': parentId,
        'trip_id': tripId,
        'old_route': oldRoute,
        'new_route': newRoute,
        'reason': reason,
        'message':
            'Route changed from $oldRoute to $newRoute${reason != null ? '. Reason: $reason' : ''}',
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  /// Get notification preferences
  static Future<ApiResponse<Map<String, dynamic>>> getNotificationPreferences({
    required int parentId,
  }) async {
    return ApiService.get<Map<String, dynamic>>(
      '/parent/notifications/preferences/$parentId/',
    );
  }

  /// Update notification preferences
  static Future<ApiResponse<Map<String, dynamic>>>
  updateNotificationPreferences({
    required int parentId,
    required Map<String, dynamic> preferences,
  }) async {
    return ApiService.put<Map<String, dynamic>>(
      '/parent/notifications/preferences/$parentId/',
      data: preferences,
    );
  }

  /// Dispose resources
  static Future<void> dispose() async {
    _notificationTimer?.cancel();
    await _notificationController.close();
  }
}
