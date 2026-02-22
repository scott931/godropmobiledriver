import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';
import '../config/app_config.dart';
import '../models/route_model.dart';
import '../services/storage_service.dart';

class RouteState {
  final bool isLoading;
  final List<RouteInfo> routes;
  final RouteInfo? routeDetails;
  final List<RouteStop> stops;
  final List<RouteAssignment> assignments;
  /// Vehicles from /drivers/me/vehicles/ or similar direct vehicles API
  final List<Map<String, dynamic>> vehicles;
  final String? error;

  const RouteState({
    this.isLoading = false,
    this.routes = const [],
    this.routeDetails,
    this.stops = const [],
    this.assignments = const [],
    this.vehicles = const [],
    this.error,
  });

  RouteState copyWith({
    bool? isLoading,
    List<RouteInfo>? routes,
    RouteInfo? routeDetails,
    List<RouteStop>? stops,
    List<RouteAssignment>? assignments,
    List<Map<String, dynamic>>? vehicles,
    String? error,
  }) {
    return RouteState(
      isLoading: isLoading ?? this.isLoading,
      routes: routes ?? this.routes,
      routeDetails: routeDetails ?? this.routeDetails,
      stops: stops ?? this.stops,
      assignments: assignments ?? this.assignments,
      vehicles: vehicles ?? this.vehicles,
      error: error,
    );
  }
}

class RouteNotifier extends StateNotifier<RouteState> {
  RouteNotifier() : super(const RouteState());

  Future<void> loadRoutes() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await ApiService.get<Map<String, dynamic>>(
        AppConfig.routesListEndpoint,
      );

      if (response.success && response.data != null) {
        final data = response.data!;
        final list = (data['results'] as List?)
                ?.map((r) => RouteInfo.fromJson(r))
                .toList() ??
            [];
        state = state.copyWith(isLoading: false, routes: list);
      } else {
        state = state.copyWith(
          isLoading: false,
          error: response.error ?? 'Failed to load routes',
        );
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Failed to load routes: $e');
    }
  }

  Future<void> loadRouteDetails(int routeId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await ApiService.get<Map<String, dynamic>>(
        '${AppConfig.routesListEndpoint}$routeId/',
      );

      if (response.success && response.data != null) {
        final data = response.data!;
        final details = RouteInfo.fromJson(data);
        final stops = (data['stops'] as List?)
                ?.map((s) => RouteStop.fromJson(s))
                .toList() ??
            [];
        final assignments = (data['assignments'] as List?)
                ?.map((a) => RouteAssignment.fromJson(a))
                .toList() ??
            [];

        state = state.copyWith(
          isLoading: false,
          routeDetails: details,
          stops: stops,
          assignments: assignments,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          error: response.error ?? 'Failed to load route details',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load route details: $e',
      );
    }
  }

  static List<Map<String, dynamic>> _parseVehiclesFromResponse(Map<String, dynamic>? data) {
    if (data == null) return [];
    final list = data['results'] as List? ?? data['vehicles'] as List? ?? data['data'] as List?;
    if (list == null) return [];
    final out = <Map<String, dynamic>>[];
    for (final item in list) {
      if (item is Map) {
        final m = Map<String, dynamic>.from(item);
        final id = m['id'] ?? m['vehicle_id'];
        final idInt = id is int ? id : (id != null ? int.tryParse(id.toString()) : null);
        if (idInt != null && idInt > 0) out.add(m);
      }
    }
    return out;
  }

  Future<void> loadDriverAssignments() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final driverId = StorageService.getDriverId();
      List<RouteAssignment> assignments = [];
      List<Map<String, dynamic>> vehicles = [];

      // 1. Primary: GET /api/v1/users/admin/drivers/:id/assignments/
      if (driverId != null) {
        final path = AppConfig.driverAdminAssignmentsEndpoint
            .replaceFirst(':id', driverId.toString());
        var assignmentsResp = await ApiService.get<Map<String, dynamic>>(path);
        if (assignmentsResp.success && assignmentsResp.data != null) {
          final data = assignmentsResp.data!;
          final list = data['results'] as List? ??
              data['assignments'] as List? ??
              data['data'] as List? ??
              data['vehicle_assignments'] as List?;
          if (list != null && list.isNotEmpty) {
            for (final item in list) {
              if (item is Map) {
                final m = Map<String, dynamic>.from(item);
                try {
                  final a = RouteAssignment.fromJson(m);
                  if (a.vehicleId > 0) assignments.add(a);
                } catch (_) {}
                final v = m['vehicle'] ?? m['assigned_vehicle'];
                int? vid = v is int
                    ? v
                    : (v is Map
                        ? ((v['id'] ?? v['vehicle_id']) as int?)
                        : null) ??
                        (m['vehicle_id'] as int?);
                if (vid == null && (m['id'] != null || m['vehicle_id'] != null)) {
                  vid = (m['id'] ?? m['vehicle_id']) as int?;
                }
                if (vid != null &&
                    vid > 0 &&
                    !vehicles.any((e) => (e['id'] ?? e['vehicle_id']) == vid)) {
                  String? name;
                  String? plate;
                  if (v is Map) {
                    name = (v['name'] ?? v['license_plate'] ??
                            v['license_plate_number'])
                        ?.toString();
                    plate = (v['license_plate'] ??
                            v['license_plate_number'] ??
                            name)
                        ?.toString();
                  }
                  if (name == null || plate == null) {
                    name ??= (m['name'] ?? m['vehicle_name'])?.toString();
                    plate ??= (m['license_plate'] ?? m['license_plate_number'])?.toString();
                  }
                  vehicles.add({
                    'id': vid,
                    'vehicle_id': vid,
                    'name': name ?? 'Vehicle $vid',
                    'license': plate ?? vid.toString(),
                    'license_plate': plate ?? vid.toString(),
                  });
                }
              }
            }
          }
        }
      }

      // 2. Fallback: Try /drivers/me/vehicles/ - uses auth token, no driver_id needed
      if (vehicles.isEmpty) {
        var vehiclesResp = await ApiService.get<Map<String, dynamic>>(
          AppConfig.driverMeVehiclesEndpoint,
        );
        if (vehiclesResp.success && vehiclesResp.data != null) {
          vehicles = _parseVehiclesFromResponse(vehiclesResp.data!);
        }
      }

      // 3. Fallback: Try /vehicle-assignments/?driver_id=X - same structure desktop may use
      if (driverId != null && vehicles.isEmpty) {
        final vaResp = await ApiService.get<Map<String, dynamic>>(
          AppConfig.vehicleAssignmentsEndpoint,
          queryParameters: {'driver_id': driverId},
        );
        if (vaResp.success && vaResp.data != null) {
          final list = vaResp.data!['results'] as List? ??
              vaResp.data!['assignments'] as List? ??
              vaResp.data!['data'] as List? ??
              vaResp.data!['vehicle_assignments'] as List?;
          if (list != null) {
            for (final item in list) {
              if (item is Map) {
                final m = Map<String, dynamic>.from(item);
                final v = m['vehicle'] ?? m['assigned_vehicle'];
                final vid = v is int
                    ? v
                    : (v is Map ? ((v['id'] ?? v['vehicle_id']) as int?) : null) ??
                        (m['vehicle_id'] as int?);
                if (vid != null && vid > 0 && !vehicles.any((e) => (e['id'] ?? e['vehicle_id']) == vid)) {
                  String? name;
                  String? plate;
                  if (v is Map) {
                    name = (v['name'] ?? v['license_plate'] ?? v['license_plate_number'])?.toString();
                    plate = (v['license_plate'] ?? v['license_plate_number'] ?? name)?.toString();
                  }
                  vehicles.add({
                    'id': vid,
                    'vehicle_id': vid,
                    'name': name ?? 'Vehicle $vid',
                    'license_plate': plate ?? vid.toString(),
                  });
                }
              }
            }
          }
        }
      }

      if (driverId != null) {
        // 1. Try /drivers/me/assignments/ - driver-specific (no query param)
        var response = await ApiService.get<Map<String, dynamic>>(
          AppConfig.driverMeAssignmentsEndpoint,
        );
        if (response.success && response.data != null) {
          final data = response.data!;
          final list = data['results'] as List? ??
              data['assignments'] as List? ??
              data['data'] as List?;
          if (list != null && list.isNotEmpty) {
            for (final item in list) {
              if (item is Map) {
                try {
                  final a = RouteAssignment.fromJson(Map<String, dynamic>.from(item));
                  if (a.vehicleId > 0) assignments.add(a);
                } catch (_) {}
              }
            }
          }
        }

        // 2. Try /routes/assignments/?driver=X or ?driver_id=X
        if (assignments.isEmpty) {
          response = await ApiService.get<Map<String, dynamic>>(
            AppConfig.routesAssignmentsEndpoint,
            queryParameters: {'driver': driverId},
          );
          if (response.success && response.data != null) {
            final data = response.data!;
            final list = data['results'] as List? ?? data['assignments'] as List?;
            if (list != null) {
              for (final item in list) {
                if (item is Map) {
                  try {
                    final a = RouteAssignment.fromJson(Map<String, dynamic>.from(item));
                    if (a.vehicleId > 0) assignments.add(a);
                  } catch (_) {}
                }
              }
            }
          }
        }

        // 3. Same with driver_id param (some backends use driver_id)
        if (assignments.isEmpty) {
          response = await ApiService.get<Map<String, dynamic>>(
            AppConfig.routesAssignmentsEndpoint,
            queryParameters: {'driver_id': driverId},
          );
          if (response.success && response.data != null) {
            final data = response.data!;
            final list = data['results'] as List? ?? data['assignments'] as List?;
            if (list != null) {
              for (final item in list) {
                if (item is Map) {
                  try {
                    final a = RouteAssignment.fromJson(Map<String, dynamic>.from(item));
                    if (a.vehicleId > 0) assignments.add(a);
                  } catch (_) {}
                }
              }
            }
          }
        }

        // 4. Try /drivers/assignments/ (uses auth, returns current driver's)
        if (assignments.isEmpty) {
          response = await ApiService.get<Map<String, dynamic>>(
            AppConfig.driverAssignmentsEndpoint,
          );
          if (response.success && response.data != null) {
            final data = response.data!;
            final list = data['results'] as List? ?? data['assignments'] as List? ?? data['data'] as List?;
            if (list != null && list.isNotEmpty) {
              for (final item in list) {
                if (item is Map) {
                  try {
                    final a = RouteAssignment.fromJson(Map<String, dynamic>.from(item));
                    if (a.vehicleId > 0) assignments.add(a);
                  } catch (_) {}
                }
              }
            }
        }
      }
    }

      state = state.copyWith(isLoading: false, assignments: assignments, vehicles: vehicles);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load assignments: $e',
      );
    }
  }
}

final routeProvider = StateNotifierProvider<RouteNotifier, RouteState>((ref) {
  return RouteNotifier();
});


