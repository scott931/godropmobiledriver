import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/trip_model.dart';
import '../models/student_model.dart';
import '../models/eta_model.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import '../services/eta_service.dart';
import '../services/eta_notification_service.dart';
import '../config/app_config.dart';

class TripState {
  final bool isLoading;
  final List<Trip> trips;
  final Trip? currentTrip;
  final Trip? selectedTrip;
  final List<Student> students;
  final String? error;

  const TripState({
    this.isLoading = false,
    this.trips = const [],
    this.currentTrip,
    this.selectedTrip,
    this.students = const [],
    this.error,
  });

  TripState copyWith({
    bool? isLoading,
    List<Trip>? trips,
    Trip? currentTrip,
    Trip? selectedTrip,
    List<Student>? students,
    String? error,
  }) {
    return TripState(
      isLoading: isLoading ?? this.isLoading,
      trips: trips ?? this.trips,
      currentTrip: currentTrip ?? this.currentTrip,
      selectedTrip: selectedTrip ?? this.selectedTrip,
      students: students ?? this.students,
      error: error,
    );
  }
}

class TripNotifier extends StateNotifier<TripState> {
  Timer? _refreshTimer;

  TripNotifier() : super(const TripState()) {
    _loadCurrentTrip();
    _startPeriodicRefresh();
  }

  Future<void> _loadCurrentTrip() async {
    final currentTrip = StorageService.getCurrentTrip();
    if (currentTrip != null) {
      state = state.copyWith(currentTrip: Trip.fromJson(currentTrip));
    }
  }

  Future<void> loadTrips() async {
    print('🚀 DEBUG: Starting to load trips...');
    state = state.copyWith(isLoading: true, error: null);

    try {
      print('📡 DEBUG: Making API call to ${AppConfig.driverTripsEndpoint}');
      final response = await ApiService.get<Map<String, dynamic>>(
        AppConfig.driverTripsEndpoint,
      );

      print('📥 DEBUG: API Response - Success: ${response.success}');
      print('📥 DEBUG: API Response - Error: ${response.error}');
      print('📥 DEBUG: API Response - Data: ${response.data}');

      if (response.success && response.data != null) {
        final data = response.data!;
        final tripsList =
            (data['trips'] as List?)
                ?.map((trip) => Trip.fromJson(trip))
                .toList() ??
            [];

        print('✅ DEBUG: Loaded ${tripsList.length} trips');
        state = state.copyWith(isLoading: false, trips: tripsList, error: null);
      } else {
        print('❌ DEBUG: API call failed - ${response.error}');
        state = state.copyWith(
          isLoading: false,
          error: response.error ?? 'Failed to load trips',
        );
      }
    } catch (e) {
      print('💥 DEBUG: Exception occurred - $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load trips: $e',
      );
    }
  }

  Future<void> loadActiveTrips() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final response = await ApiService.get<Map<String, dynamic>>(
        AppConfig.activeTripsEndpoint,
      );

      if (response.success && response.data != null) {
        final data = response.data!;
        final tripsList =
            (data['trips'] as List?)
                ?.map((trip) => Trip.fromBackend(trip))
                .toList() ??
            [];

        // Set the first active trip as current trip if available
        final activeTrips = tripsList.where((trip) => trip.isActive).toList();
        final currentTrip = activeTrips.isNotEmpty ? activeTrips.first : null;

        state = state.copyWith(
          isLoading: false,
          trips: tripsList,
          currentTrip: currentTrip,
          error: null,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          error: response.error ?? 'Failed to load active trips',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load active trips: $e',
      );
    }
  }

  Future<void> loadAllTrips() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final response = await ApiService.get<Map<String, dynamic>>(
        AppConfig.allTripsEndpoint,
      );

      if (response.success && response.data != null) {
        final data = response.data!;
        // Try both 'trips' and 'results' to handle different API response formats
        final tripsData = data['trips'] ?? data['results'];
        final tripsList =
            (tripsData as List?)
                ?.map((trip) => Trip.fromBackend(trip))
                .toList() ??
            [];

        state = state.copyWith(isLoading: false, trips: tripsList, error: null);
      } else {
        state = state.copyWith(
          isLoading: false,
          error: response.error ?? 'Failed to load trips',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load trips: $e',
      );
    }
  }

  Future<void> loadDriverTrips(int driverId) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final response = await ApiService.get<Map<String, dynamic>>(
        AppConfig.driverTripsEndpoint,
        queryParameters: {'driver_id': driverId},
      );

      if (response.success && response.data != null) {
        final data = response.data!;
        final tripsList =
            (data['trips'] as List?)
                ?.map((trip) => Trip.fromBackend(trip))
                .toList() ??
            [];

        state = state.copyWith(isLoading: false, trips: tripsList, error: null);
      } else {
        state = state.copyWith(
          isLoading: false,
          error: response.error ?? 'Failed to load driver trips',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load driver trips: $e',
      );
    }
  }

  Future<void> loadCurrentDriverTrips() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final response = await ApiService.get<Map<String, dynamic>>(
        AppConfig.driverTripsEndpoint,
      );

      if (response.success && response.data != null) {
        final data = response.data!;
        final tripsList =
            (data['trips'] as List?)
                ?.map((trip) => Trip.fromBackend(trip))
                .toList() ??
            [];

        state = state.copyWith(isLoading: false, trips: tripsList, error: null);
      } else {
        state = state.copyWith(
          isLoading: false,
          error: response.error ?? 'Failed to load current driver trips',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load current driver trips: $e',
      );
    }
  }

  Future<void> loadCurrentDriverTripsWithFilters({
    String? status,
    String? tripType,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final queryParameters = <String, dynamic>{};
      if (status != null) queryParameters['status'] = status;
      if (tripType != null) queryParameters['trip_type'] = tripType;

      final response = await ApiService.get<Map<String, dynamic>>(
        AppConfig.driverTripsEndpoint,
        queryParameters: queryParameters.isNotEmpty ? queryParameters : null,
      );

      if (response.success && response.data != null) {
        final data = response.data!;
        final tripsList =
            (data['trips'] as List?)
                ?.map((trip) => Trip.fromBackend(trip))
                .toList() ??
            [];

        state = state.copyWith(isLoading: false, trips: tripsList, error: null);
      } else {
        state = state.copyWith(
          isLoading: false,
          error: response.error ?? 'Failed to load filtered driver trips',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load filtered driver trips: $e',
      );
    }
  }

  Future<bool> startTrip(
    String tripId, {
    required String startLocation,
    double? latitude,
    double? longitude,
    String? notes,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final response = await ApiService.post<Map<String, dynamic>>(
        AppConfig.startTripEndpoint,
        data: {
          'trip_id': tripId,
          'start_location': startLocation,
          'latitude': latitude,
          'longitude': longitude,
          'notes': notes,
        },
      );

      if (response.success && response.data != null) {
        final trip = Trip.fromJson(response.data!);
        await StorageService.saveCurrentTrip(trip.toJson());

        // Update the trips list to reflect the new status
        final updatedTrips = state.trips.map((t) {
          if (t.tripId == trip.tripId) {
            print(
              '🔄 DEBUG: Updating trip ${trip.tripId} status from ${t.status} to ${trip.status}',
            );
            return trip;
          }
          return t;
        }).toList();

        print('🔄 DEBUG: Updated trips list with ${updatedTrips.length} trips');
        for (final t in updatedTrips) {
          print('🔄 DEBUG: Trip ${t.tripId} status: ${t.status}');
        }

        state = state.copyWith(
          isLoading: false,
          currentTrip: trip,
          trips: updatedTrips,
          error: null,
        );

        // Force a refresh of trips to ensure UI is updated
        await loadTrips();

        // Calculate ETA for the started trip
        await _calculateETAForTrip(trip, latitude, longitude);

        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          error: response.error ?? 'Failed to start trip',
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to start trip: $e',
      );
      return false;
    }
  }

  Future<bool> endTrip({
    required String endLocation,
    double? latitude,
    double? longitude,
    String? notes,
  }) async {
    if (state.currentTrip == null) {
      state = state.copyWith(error: 'No active trip to end');
      return false;
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      final response = await ApiService.post<Map<String, dynamic>>(
        AppConfig.endTripEndpoint,
        data: {
          'trip_id': state.currentTrip!.tripId,
          'end_location': endLocation,
          'latitude': latitude,
          'longitude': longitude,
          'notes': notes,
        },
      );

      if (response.success && response.data != null) {
        final trip = Trip.fromJson(response.data!);
        await StorageService.clearCurrentTrip();

        // Update the trips list to reflect the new status
        final updatedTrips = state.trips.map((t) {
          if (t.tripId == trip.tripId) {
            return trip;
          }
          return t;
        }).toList();

        state = state.copyWith(
          isLoading: false,
          currentTrip: null,
          trips: updatedTrips,
          error: null,
        );

        // Force a refresh of trips to ensure UI is updated
        await loadTrips();

        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          error: response.error ?? 'Failed to end trip',
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Failed to end trip: $e');
      return false;
    }
  }

  Future<bool> updateLocation({
    required double latitude,
    required double longitude,
    String? address,
    double? speed,
    double? heading,
    double? accuracy,
  }) async {
    try {
      final response = await ApiService.post<Map<String, dynamic>>(
        AppConfig.updateLocationEndpoint,
        data: {
          'trip_id': state.currentTrip?.id,
          'latitude': latitude,
          'longitude': longitude,
          'address': address,
          'speed': speed,
          'heading': heading,
          'accuracy': accuracy,
        },
      );

      return response.success;
    } catch (e) {
      return false;
    }
  }

  Future<void> loadTripStudents(int tripId) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      // Find the trip to get its string tripId
      final trip = state.trips.firstWhere((t) => t.id == tripId);

      // Try the trip-specific students endpoint first
      String endpoint =
          '${AppConfig.tripDetailsEndpoint}${trip.tripId}/students/';
      print(
        '🔍 DEBUG: Loading students for trip ${trip.tripId} from endpoint: $endpoint',
      );

      var response = await ApiService.get<Map<String, dynamic>>(endpoint);

      // If the trip-specific endpoint fails (404), try the general students endpoint
      if (!response.success && response.error?.contains('404') == true) {
        print(
          '⚠️ DEBUG: Trip-specific students endpoint not found, trying general students endpoint',
        );
        endpoint = '${AppConfig.studentsEndpoint}?trip_id=${trip.tripId}';
        print('🔍 DEBUG: Trying general students endpoint: $endpoint');

        response = await ApiService.get<Map<String, dynamic>>(endpoint);
      }

      if (response.success && response.data != null) {
        final data = response.data!;
        final studentsList =
            (data['results'] as List?)
                ?.map((student) => Student.fromJson(student))
                .toList() ??
            [];

        state = state.copyWith(
          isLoading: false,
          students: studentsList,
          error: null,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          error: response.error ?? 'Failed to load students',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load students: $e',
      );
    }
  }

  Future<bool> updateStudentStatus(int studentId, StudentStatus status) async {
    try {
      final response = await ApiService.post<Map<String, dynamic>>(
        AppConfig.studentStatusEndpoint,
        data: {
          'student_id': studentId,
          'status': status.name,
          'trip_id': state.currentTrip?.id,
        },
      );

      if (response.success) {
        // Update local state
        final updatedStudents = state.students.map((student) {
          if (student.id == studentId) {
            return student.copyWith(status: status);
          }
          return student;
        }).toList();

        state = state.copyWith(students: updatedStudents);
        return true;
      }

      return false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> trackingUpdateStudentStatus({
    required int studentId,
    required int vehicleId,
    required int routeId,
    required String status,
    required String locationWkt,
    String? notes,
  }) async {
    try {
      final response = await ApiService.post<Map<String, dynamic>>(
        AppConfig.trackingStudentStatusUpdateEndpoint,
        data: {
          'student': studentId,
          'vehicle': vehicleId,
          'route': routeId,
          'status': status,
          'location': locationWkt,
          'notes': notes,
        },
      );

      return response.success;
    } catch (e) {
      return false;
    }
  }

  Future<bool> checkInStudent(String studentId) async {
    try {
      final response = await ApiService.post<Map<String, dynamic>>(
        AppConfig.studentAttendanceEndpoint,
        data: {
          'student_id': studentId,
          'action': 'check_in',
          'timestamp': DateTime.now().toIso8601String(),
        },
      );

      if (response.success) {
        // Reload students to get updated status
        if (state.currentTrip != null) {
          await loadTripStudents(state.currentTrip!.id);
        }
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<void> loadTripDetails(int tripId) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      // Find the trip to get its string tripId
      final trip = state.trips.firstWhere((t) => t.id == tripId);
      final endpoint = '${AppConfig.tripDetailsEndpoint}${trip.tripId}/';
      print(
        '🔍 DEBUG: Loading trip details for ${trip.tripId} from endpoint: $endpoint',
      );

      final response = await ApiService.get<Map<String, dynamic>>(endpoint);

      print('📥 DEBUG: Trip details response - Success: ${response.success}');
      print('📥 DEBUG: Trip details response - Error: ${response.error}');
      print('📥 DEBUG: Trip details response - Data: ${response.data}');

      if (response.success && response.data != null) {
        final tripData = response.data!;
        print('🔍 DEBUG: Parsing trip details - Status: ${tripData['status']}');

        final trip = Trip.fromJson(tripData);
        print('🔍 DEBUG: Parsed trip status: ${trip.status}');

        state = state.copyWith(
          isLoading: false,
          selectedTrip: trip,
          error: null,
        );

        // Update the trip in the trips list with the latest data
        updateTripInList(trip);

        // Load students for this trip
        await loadTripStudents(tripId);
      } else {
        print('❌ DEBUG: Trip details API call failed - ${response.error}');
        state = state.copyWith(
          isLoading: false,
          error: response.error ?? 'Failed to load trip details',
        );
      }
    } catch (e) {
      print('💥 DEBUG: Exception in loadTripDetails - $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load trip details: $e',
      );
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }

  void resetState() {
    print('🔄 DEBUG: Resetting trip state...');
    state = const TripState();
  }

  void updateTripInList(Trip updatedTrip) {
    print('🔄 DEBUG: Updating trip ${updatedTrip.tripId} in trips list');
    final updatedTrips = state.trips.map((t) {
      if (t.tripId == updatedTrip.tripId) {
        return updatedTrip;
      }
      return t;
    }).toList();

    state = state.copyWith(trips: updatedTrips);
  }

  Future<void> refreshTrips() async {
    await loadTrips();
  }

  void _startPeriodicRefresh() {
    // Refresh trips every 30 seconds to get real-time updates
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (state.trips.isNotEmpty) {
        _refreshTripsSilently();
      }
    });
  }

  Future<void> _refreshTripsSilently() async {
    try {
      final response = await ApiService.get<Map<String, dynamic>>(
        AppConfig.driverTripsEndpoint,
      );

      if (response.success && response.data != null) {
        final data = response.data!;
        final tripsList =
            (data['trips'] as List?)
                ?.map((trip) => Trip.fromJson(trip))
                .toList() ??
            [];

        // Only update if trips have changed
        if (tripsList.length != state.trips.length ||
            _hasTripStatusChanged(tripsList)) {
          state = state.copyWith(trips: tripsList, error: null);
        }
      }
    } catch (e) {
      // Silent refresh - don't update error state
      print('Silent refresh failed: $e');
    }
  }

  bool _hasTripStatusChanged(List<Trip> newTrips) {
    if (state.trips.length != newTrips.length) return true;

    for (int i = 0; i < state.trips.length; i++) {
      if (i < newTrips.length && state.trips[i].status != newTrips[i].status) {
        return true;
      }
    }
    return false;
  }

  /// Calculate ETA for a trip
  Future<void> _calculateETAForTrip(
    Trip trip,
    double? currentLat,
    double? currentLng,
  ) async {
    try {
      if (trip.endLatitude == null || trip.endLongitude == null) {
        print(
          '❌ Trip Provider: Cannot calculate ETA - missing destination coordinates',
        );
        return;
      }

      if (currentLat == null || currentLng == null) {
        print(
          '❌ Trip Provider: Cannot calculate ETA - missing current location',
        );
        return;
      }

      print('🚀 Trip Provider: Calculating ETA for trip ${trip.tripId}');

      final result = await ETAService.calculateETA(
        currentLat: currentLat,
        currentLng: currentLng,
        destinationLat: trip.endLatitude!,
        destinationLng: trip.endLongitude!,
        trip: trip,
        routeName: trip.routeName,
        vehicleType: 'school_bus',
      );

      if (result.success) {
        final etaInfo = result.etaInfo;

        // Update trip with ETA information
        final updatedTrip = trip.copyWith(
          estimatedArrival: etaInfo.estimatedArrival,
          currentSpeed: etaInfo.currentSpeed,
          etaIsDelayed: etaInfo.isDelayed,
          etaStatus: ETAService.getETAStatus(etaInfo),
          trafficMultiplier: etaInfo.trafficMultiplier,
          etaLastUpdated: DateTime.now(),
        );

        // Update current trip in state
        state = state.copyWith(currentTrip: updatedTrip);

        // Update trip in trips list
        final updatedTrips = state.trips.map((t) {
          if (t.tripId == trip.tripId) {
            return updatedTrip;
          }
          return t;
        }).toList();

        state = state.copyWith(trips: updatedTrips);

        // Schedule ETA notifications
        await ETANotificationService.scheduleETANotifications(
          trip: updatedTrip,
          etaInfo: etaInfo,
        );

        print(
          '✅ Trip Provider: ETA calculated and updated for trip ${trip.tripId}',
        );
      } else {
        print('❌ Trip Provider: Failed to calculate ETA: ${result.error}');
      }
    } catch (e) {
      print('❌ Trip Provider: Error calculating ETA: $e');
    }
  }

  /// Update ETA for current trip
  Future<void> updateCurrentTripETA() async {
    if (state.currentTrip == null) return;

    final currentTrip = state.currentTrip!;
    if (currentTrip.endLatitude == null || currentTrip.endLongitude == null)
      return;

    // This would typically get current location from location service
    // For now, we'll use the trip's start coordinates as current location
    if (currentTrip.startLatitude != null &&
        currentTrip.startLongitude != null) {
      await _calculateETAForTrip(
        currentTrip,
        currentTrip.startLatitude,
        currentTrip.startLongitude,
      );
    }
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }
}

final tripProvider = StateNotifierProvider<TripNotifier, TripState>((ref) {
  return TripNotifier();
});

final currentTripProvider = Provider<Trip?>((ref) {
  return ref.watch(tripProvider).currentTrip;
});

final activeTripsProvider = Provider<List<Trip>>((ref) {
  return ref.watch(tripProvider).trips.where((trip) => trip.isActive).toList();
});

final tripStudentsProvider = Provider<List<Student>>((ref) {
  return ref.watch(tripProvider).students;
});
