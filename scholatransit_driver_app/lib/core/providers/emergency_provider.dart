import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';
import '../config/app_config.dart';

class EmergencyAlert {
  final int id;
  final String emergencyType;
  final String emergencyTypeDisplay;
  final String severity;
  final String severityDisplay;
  final String status;
  final String statusDisplay;
  final String title;
  final String description;
  final Map<String, dynamic>? vehicle;
  final Map<String, dynamic>? route;
  final List<Map<String, dynamic>> students;
  final String? location;
  final String? locationDisplay;
  final String address;
  final Map<String, dynamic>? reportedBy;
  final Map<String, dynamic>? assignedTo;
  final String reportedAt;
  final String? acknowledgedAt;
  final String? resolvedAt;
  final String estimatedResolution;
  final int affectedStudentsCount;
  final int estimatedDelayMinutes;
  final bool notificationSent;
  final bool parentNotificationSent;
  final bool schoolNotificationSent;
  final Map<String, dynamic> metadata;
  final int? durationMinutes;
  final bool isActive;
  final List<Map<String, dynamic>> updates;
  final String createdAt;
  final String updatedAt;

  const EmergencyAlert({
    required this.id,
    required this.emergencyType,
    required this.emergencyTypeDisplay,
    required this.severity,
    required this.severityDisplay,
    required this.status,
    required this.statusDisplay,
    required this.title,
    required this.description,
    this.vehicle,
    this.route,
    required this.students,
    this.location,
    this.locationDisplay,
    required this.address,
    this.reportedBy,
    this.assignedTo,
    required this.reportedAt,
    this.acknowledgedAt,
    this.resolvedAt,
    required this.estimatedResolution,
    required this.affectedStudentsCount,
    required this.estimatedDelayMinutes,
    required this.notificationSent,
    required this.parentNotificationSent,
    required this.schoolNotificationSent,
    required this.metadata,
    this.durationMinutes,
    required this.isActive,
    required this.updates,
    required this.createdAt,
    required this.updatedAt,
  });

  factory EmergencyAlert.fromJson(Map<String, dynamic> json) {
    return EmergencyAlert(
      id: json['id'] ?? 0,
      emergencyType: json['emergency_type'] ?? '',
      emergencyTypeDisplay: json['emergency_type_display'] ?? '',
      severity: json['severity'] ?? '',
      severityDisplay: json['severity_display'] ?? '',
      status: json['status'] ?? '',
      statusDisplay: json['status_display'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      vehicle: json['vehicle'] != null
          ? (json['vehicle'] is Map
                ? Map<String, dynamic>.from(json['vehicle'])
                : {'id': json['vehicle'], 'name': 'Vehicle ${json['vehicle']}'})
          : null,
      route: json['route'] != null
          ? (json['route'] is Map
                ? Map<String, dynamic>.from(json['route'])
                : {'id': json['route'], 'name': 'Route ${json['route']}'})
          : null,
      students: json['students'] != null && json['students'] is List
          ? (json['students'] as List)
                .map(
                  (s) => s is Map
                      ? Map<String, dynamic>.from(s)
                      : {'id': s, 'name': 'Student $s'},
                )
                .toList()
          : [],
      location: json['location'],
      locationDisplay: json['location_display'],
      address: json['address'] ?? '',
      reportedBy: json['reported_by'] != null
          ? (json['reported_by'] is Map
                ? Map<String, dynamic>.from(json['reported_by'])
                : {
                    'id': json['reported_by'],
                    'name': 'User ${json['reported_by']}',
                  })
          : null,
      assignedTo: json['assigned_to'] != null
          ? (json['assigned_to'] is Map
                ? Map<String, dynamic>.from(json['assigned_to'])
                : {
                    'id': json['assigned_to'],
                    'name': 'User ${json['assigned_to']}',
                  })
          : null,
      reportedAt: json['reported_at'] ?? '',
      acknowledgedAt: json['acknowledged_at'],
      resolvedAt: json['resolved_at'],
      estimatedResolution: json['estimated_resolution'] ?? '',
      affectedStudentsCount: json['affected_students_count'] ?? 0,
      estimatedDelayMinutes: json['estimated_delay_minutes'] ?? 0,
      notificationSent: json['notification_sent'] ?? false,
      parentNotificationSent: json['parent_notification_sent'] ?? false,
      schoolNotificationSent: json['school_notification_sent'] ?? false,
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
      durationMinutes: json['duration_minutes'],
      isActive: json['is_active'] ?? false,
      updates:
          (json['updates'] as List?)
              ?.map((u) => Map<String, dynamic>.from(u))
              .toList() ??
          [],
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'emergency_type': emergencyType,
      'emergency_type_display': emergencyTypeDisplay,
      'severity': severity,
      'severity_display': severityDisplay,
      'status': status,
      'status_display': statusDisplay,
      'title': title,
      'description': description,
      'vehicle': vehicle,
      'route': route,
      'students': students,
      'location': location,
      'location_display': locationDisplay,
      'address': address,
      'reported_by': reportedBy,
      'assigned_to': assignedTo,
      'reported_at': reportedAt,
      'acknowledged_at': acknowledgedAt,
      'resolved_at': resolvedAt,
      'estimated_resolution': estimatedResolution,
      'affected_students_count': affectedStudentsCount,
      'estimated_delay_minutes': estimatedDelayMinutes,
      'notification_sent': notificationSent,
      'parent_notification_sent': parentNotificationSent,
      'school_notification_sent': schoolNotificationSent,
      'metadata': metadata,
      'duration_minutes': durationMinutes,
      'is_active': isActive,
      'updates': updates,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
}

class EmergencyState {
  final bool isLoading;
  final List<EmergencyAlert> alerts;
  final EmergencyAlert? selectedAlert;
  final String? error;

  const EmergencyState({
    this.isLoading = false,
    this.alerts = const [],
    this.selectedAlert,
    this.error,
  });

  EmergencyState copyWith({
    bool? isLoading,
    List<EmergencyAlert>? alerts,
    EmergencyAlert? selectedAlert,
    String? error,
  }) {
    return EmergencyState(
      isLoading: isLoading ?? this.isLoading,
      alerts: alerts ?? this.alerts,
      selectedAlert: selectedAlert ?? this.selectedAlert,
      error: error,
    );
  }
}

class EmergencyNotifier extends StateNotifier<EmergencyState> {
  EmergencyNotifier() : super(const EmergencyState());

  Future<bool> createEmergencyAlert({
    required String emergencyType,
    required String severity,
    required String title,
    required String description,
    int? vehicle,
    int? route,
    List<int>? studentIds,
    required String location,
    required String address,
    String? estimatedResolution,
    int? affectedStudentsCount,
    int? estimatedDelayMinutes,
    Map<String, dynamic>? metadata,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      print('🚨 DEBUG: Creating emergency alert...');
      print('🚨 DEBUG: Type: $emergencyType, Severity: $severity');
      print('🚨 DEBUG: Title: $title');
      print('🚨 DEBUG: Vehicle: $vehicle, Route: $route');
      print('🚨 DEBUG: Location: $location, Address: $address');

      final vehicleId = (vehicle != null && vehicle > 0) ? vehicle : null;
      final routeId = (route != null && route > 0) ? route : null;
      final requestData = {
        'emergency_type': emergencyType,
        'severity': severity,
        'title': title,
        'description': description,
        if (vehicleId != null) 'vehicle': vehicleId,
        if (routeId != null) 'route': routeId,
        if (studentIds != null && studentIds.isNotEmpty) 'student_ids': studentIds,
        'location': location,
        'address': address,
        if (estimatedResolution != null)
          'estimated_resolution': estimatedResolution,
        if (affectedStudentsCount != null)
          'affected_students_count': affectedStudentsCount,
        if (estimatedDelayMinutes != null)
          'estimated_delay_minutes': estimatedDelayMinutes,
        if (metadata != null) 'metadata': metadata,
      };

      print('🚨 DEBUG: Request data: $requestData');

      final response = await ApiService.post<Map<String, dynamic>>(
        AppConfig.createEmergencyAlertEndpoint,
        data: requestData,
      );

      print('🚨 DEBUG: API Response - Success: ${response.success}');
      print('🚨 DEBUG: API Response - Error: ${response.error}');
      print('🚨 DEBUG: API Response - Data: ${response.data}');

      if (response.success && response.data != null) {
        final alert = EmergencyAlert.fromJson(response.data!);
        state = state.copyWith(
          isLoading: false,
          selectedAlert: alert,
          error: null,
        );
        print(
          '🚨 DEBUG: Emergency alert created successfully with ID: ${alert.id}',
        );
        return true;
      } else {
        final errorMessage =
            response.error ?? 'Failed to create emergency alert';
        print('🚨 DEBUG: Emergency alert creation failed: $errorMessage');
        state = state.copyWith(isLoading: false, error: errorMessage);
        return false;
      }
    } catch (e) {
      print('🚨 DEBUG: Exception during emergency alert creation: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to create emergency alert: $e',
      );
      return false;
    }
  }

  Future<void> loadEmergencyAlerts() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      print(
        '🚨 DEBUG: Loading emergency alerts from ${AppConfig.emergencyAlertsEndpoint}',
      );

      final response = await ApiService.get<Map<String, dynamic>>(
        AppConfig.emergencyAlertsEndpoint,
      );

      print(
        '🚨 DEBUG: Emergency alerts API Response - Success: ${response.success}',
      );
      print(
        '🚨 DEBUG: Emergency alerts API Response - Error: ${response.error}',
      );
      print('🚨 DEBUG: Emergency alerts API Response - Data: ${response.data}');

      if (response.success && response.data != null) {
        final data = response.data!;
        final alertsList =
            (data['results'] as List?)
                ?.map((alert) => EmergencyAlert.fromJson(alert))
                .toList() ??
            [];

        print('🚨 DEBUG: Parsed ${alertsList.length} emergency alerts');

        state = state.copyWith(
          isLoading: false,
          alerts: alertsList,
          error: null,
        );
        print('🚨 DEBUG: Emergency alerts loaded successfully');
      } else {
        print('🚨 DEBUG: Failed to load emergency alerts: ${response.error}');
        state = state.copyWith(
          isLoading: false,
          error: response.error ?? 'Failed to load emergency alerts',
        );
      }
    } catch (e) {
      print('🚨 DEBUG: Exception loading emergency alerts: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load emergency alerts: $e',
      );
    }
  }

  Future<void> loadEmergencyAlertDetails(int alertId) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final response = await ApiService.get<Map<String, dynamic>>(
        '${AppConfig.emergencyAlertsEndpoint}$alertId/',
      );

      if (response.success && response.data != null) {
        final alert = EmergencyAlert.fromJson(response.data!);
        state = state.copyWith(
          isLoading: false,
          selectedAlert: alert,
          error: null,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          error: response.error ?? 'Failed to load emergency alert details',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load emergency alert details: $e',
      );
    }
  }

  Future<bool> createEmergencyUpdate({
    required int emergencyId,
    required String statusChange,
    required String message,
    String? estimatedResolution,
    int? affectedStudentsCount,
    int? estimatedDelayMinutes,
    String? location,
    String? address,
    bool notifyParents = false,
    bool notifySchool = false,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final response = await ApiService.post<Map<String, dynamic>>(
        '${AppConfig.emergencyUpdatesEndpoint}$emergencyId/updates/',
        data: {
          'emergency': emergencyId,
          'status_change': statusChange,
          'message': message,
          if (estimatedResolution != null)
            'estimated_resolution': estimatedResolution,
          if (affectedStudentsCount != null)
            'affected_students_count': affectedStudentsCount,
          if (estimatedDelayMinutes != null)
            'estimated_delay_minutes': estimatedDelayMinutes,
          if (location != null) 'location': location,
          if (address != null) 'address': address,
          'notify_parents': notifyParents,
          'notify_school': notifySchool,
        },
      );

      if (response.success && response.data != null) {
        state = state.copyWith(isLoading: false, error: null);
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          error: response.error ?? 'Failed to create emergency update',
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to create emergency update: $e',
      );
      return false;
    }
  }

  Future<void> loadEmergencyUpdates(int emergencyId) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final response = await ApiService.get<Map<String, dynamic>>(
        '${AppConfig.emergencyUpdatesEndpoint}$emergencyId/updates/',
      );

      if (response.success && response.data != null) {
        final data = response.data!;
        final updatesList =
            (data['results'] as List?)
                ?.map((update) => Map<String, dynamic>.from(update))
                .toList() ??
            [];

        // Update the selected alert with the new updates
        if (state.selectedAlert != null) {
          final updatedAlert = EmergencyAlert.fromJson({
            ...state.selectedAlert!.toJson(),
            'updates': updatesList,
          });
          state = state.copyWith(
            isLoading: false,
            selectedAlert: updatedAlert,
            error: null,
          );
        } else {
          state = state.copyWith(isLoading: false, error: null);
        }
      } else {
        state = state.copyWith(
          isLoading: false,
          error: response.error ?? 'Failed to load emergency updates',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load emergency updates: $e',
      );
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

final emergencyProvider =
    StateNotifierProvider<EmergencyNotifier, EmergencyState>(
      (ref) => EmergencyNotifier(),
    );

int? emergencyPositiveId(int? id) => (id != null && id > 0) ? id : null;

int? resolveEmergencyVehicleId({
  int? selected,
  int? tripVehicleId,
  Iterable<int> assignmentVehicleIds = const [],
  Iterable<int> listedVehicleIds = const [],
}) {
  for (final id in [
    selected,
    tripVehicleId,
    ...assignmentVehicleIds,
    ...listedVehicleIds,
  ]) {
    final resolved = emergencyPositiveId(id);
    if (resolved != null) return resolved;
  }
  return null;
}

int? resolveEmergencyRouteId({
  int? selected,
  int? tripRouteId,
  Iterable<int> assignmentRouteIds = const [],
  Iterable<int> listedRouteIds = const [],
}) {
  for (final id in [
    selected,
    tripRouteId,
    ...assignmentRouteIds,
    ...listedRouteIds,
  ]) {
    final resolved = emergencyPositiveId(id);
    if (resolved != null) return resolved;
  }
  return null;
}
