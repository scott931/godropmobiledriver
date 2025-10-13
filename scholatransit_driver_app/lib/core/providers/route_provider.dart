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
  final String? error;

  const RouteState({
    this.isLoading = false,
    this.routes = const [],
    this.routeDetails,
    this.stops = const [],
    this.assignments = const [],
    this.error,
  });

  RouteState copyWith({
    bool? isLoading,
    List<RouteInfo>? routes,
    RouteInfo? routeDetails,
    List<RouteStop>? stops,
    List<RouteAssignment>? assignments,
    String? error,
  }) {
    return RouteState(
      isLoading: isLoading ?? this.isLoading,
      routes: routes ?? this.routes,
      routeDetails: routeDetails ?? this.routeDetails,
      stops: stops ?? this.stops,
      assignments: assignments ?? this.assignments,
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

  Future<void> loadDriverAssignments() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final driverId = StorageService.getDriverId();
      final response = await ApiService.get<Map<String, dynamic>>(
        AppConfig.routesAssignmentsEndpoint,
        queryParameters: driverId != null ? {'driver': driverId} : null,
      );

      if (response.success && response.data != null) {
        final data = response.data!;
        final assignments = (data['results'] as List?)
                ?.map((a) => RouteAssignment.fromJson(a))
                .toList() ??
            [];
        state = state.copyWith(isLoading: false, assignments: assignments);
      } else {
        state = state.copyWith(
          isLoading: false,
          error: response.error ?? 'Failed to load assignments',
        );
      }
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


