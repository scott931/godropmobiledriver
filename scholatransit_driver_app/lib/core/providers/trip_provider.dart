import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/trip_model.dart';
import '../models/test_trip_factory.dart';
import '../models/student_model.dart';
import '../models/parent_model.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import '../services/eta_service.dart';
import '../services/eta_notification_service.dart';
import '../services/notification_service.dart';
import '../services/parent_notification_service.dart';
import '../services/location_service.dart';
import '../services/truck_h3_service.dart';
import '../config/app_config.dart';

/// Outcome of driver check-in verify API ([AppConfig.checkinVerifyQrEndpoint] / pin).
class DriverCheckinResult {
  final bool success;
  final String? message;
  const DriverCheckinResult._(this.success, this.message);
  factory DriverCheckinResult.ok() => const DriverCheckinResult._(true, null);
  factory DriverCheckinResult.fail(String message) =>
      DriverCheckinResult._(false, message);
}

class TripCompletionSummary {
  final String tripId;
  final DateTime completedAt;
  final String endLocation;
  final int studentCount;
  final int pickedUpCount;
  final int droppedOffCount;
  final double? distanceKm;
  final int? durationMinutes;

  const TripCompletionSummary({
    required this.tripId,
    required this.completedAt,
    required this.endLocation,
    required this.studentCount,
    required this.pickedUpCount,
    required this.droppedOffCount,
    this.distanceKm,
    this.durationMinutes,
  });

  String get message {
    final distanceText =
        distanceKm != null ? ', ${distanceKm!.toStringAsFixed(1)} km' : '';
    final durationText =
        durationMinutes != null ? ', ${durationMinutes} min' : '';
    return 'Trip $tripId completed. Students: $studentCount (picked: $pickedUpCount, dropped: $droppedOffCount)$distanceText$durationText.';
  }
}

class TripState {
  final bool isLoading;
  final List<Trip> trips;
  final Trip? currentTrip;
  final Trip? selectedTrip;
  final List<Student> students;
  final TripCompletionSummary? lastTripSummary;
  final String? error;

  const TripState({
    this.isLoading = false,
    this.trips = const [],
    this.currentTrip,
    this.selectedTrip,
    this.students = const [],
    this.lastTripSummary,
    this.error,
  });

  TripState copyWith({
    bool? isLoading,
    List<Trip>? trips,
    Trip? currentTrip,
    bool clearCurrentTrip = false,
    Trip? selectedTrip,
    List<Student>? students,
    TripCompletionSummary? lastTripSummary,
    bool clearLastTripSummary = false,
    String? error,
  }) {
    return TripState(
      isLoading: isLoading ?? this.isLoading,
      trips: trips ?? this.trips,
      currentTrip: clearCurrentTrip ? null : (currentTrip ?? this.currentTrip),
      selectedTrip: selectedTrip ?? this.selectedTrip,
      students: students ?? this.students,
      lastTripSummary: clearLastTripSummary
          ? null
          : (lastTripSummary ?? this.lastTripSummary),
      error: error,
    );
  }
}

class TripNotifier extends StateNotifier<TripState> {
  Timer? _refreshTimer;
  Timer? _liveLocationTimer;

  TripNotifier() : super(const TripState()) {
    _loadCurrentTrip();
    // Periodic refresh disabled - was causing whole-app UI refresh every 60s.
    // Use pull-to-refresh on trips/dashboard screens for updates.
  }

  Future<void> _loadCurrentTrip() async {
    final currentTrip = StorageService.getCurrentTrip();
    if (currentTrip != null) {
      state = state.copyWith(currentTrip: Trip.fromJson(currentTrip));
    }
    _syncLiveLocationTimer();
  }

  String? _currentUserRole() {
    final profile = StorageService.getUserProfile();
    if (profile == null) return null;

    Map<String, dynamic>? asMap(dynamic value) {
      if (value is Map<String, dynamic>) return value;
      if (value is Map) return Map<String, dynamic>.from(value);
      return null;
    }

    final profileData = asMap(profile['profile_data']);
    final role = profile['user_type'] ??
        profile['role'] ??
        profileData?['user_type'] ??
        profileData?['role'];
    if (role == null) return null;
    final normalized = role.toString().trim().toLowerCase();
    return normalized.isEmpty ? null : normalized;
  }

  bool _canManageStudentCheckin() {
    final role = _currentUserRole();
    return role == 'driver' || role == 'admin' || role == 'super_admin';
  }

  bool _isSchoolDriverForTripStart() {
    final profile = StorageService.getUserProfile();
    if (profile == null) return false;

    Map<String, dynamic>? asMap(dynamic value) {
      if (value is Map<String, dynamic>) return value;
      if (value is Map) return Map<String, dynamic>.from(value);
      return null;
    }

    String normalize(dynamic value) =>
        value == null ? '' : value.toString().trim().toLowerCase();

    final profileData = asMap(profile['profile_data']);
    final driverInfo = asMap(profile['driver_info']) ??
        asMap(profileData?['driver_info']) ??
        asMap(profileData?['driver']);

    final role = normalize(
      profile['user_type'] ??
          profile['role'] ??
          profileData?['user_type'] ??
          profileData?['role'] ??
          driverInfo?['user_type'] ??
          driverInfo?['role'],
    );

    if (role == 'school_driver' || role == 'school driver') {
      return true;
    }

    final schoolId = profile['school'] ??
        profile['school_id'] ??
        profileData?['school'] ??
        profileData?['school_id'] ??
        driverInfo?['school'] ??
        driverInfo?['school_id'];

    // Accept canonical driver role only when linked to a school context.
    return role == 'driver' && schoolId != null;
  }

  Map<String, dynamic> _driverRequestPayload() {
    final role = _currentUserRole() ?? 'unknown';
    return {
      // Backend compatibility: authorize check-in/check-out through driver request context.
      'driver_request': true,
      'requested_by_role': role,
    };
  }

  /// When [AppConfig.seedTestActiveTrip] is true, persists an in-progress trip for the
  /// logged-in driver so map/schedule flows work without backend data.
  Future<void> seedTestActiveTripIfEnabled() async {
    if (!AppConfig.seedTestActiveTrip) return;
    final driverId = StorageService.getDriverId();
    if (driverId == null) return;
    final current = state.currentTrip;
    if (current != null &&
        current.isActive &&
        !current.tripId.startsWith('TEST_')) {
      return;
    }

    final variant = AppConfig.testTripSeedVariant.toLowerCase();
    final trip = variant == 'pending'
        ? TestTripFactory.pendingTrip(driverId: driverId)
        : TestTripFactory.activeTrip(driverId: driverId);
    await StorageService.saveCurrentTrip(trip.toJson());

    final withoutTest =
        state.trips.where((t) => t.tripId != trip.tripId).toList();
    state = state.copyWith(
      currentTrip: trip,
      trips: [...withoutTest, trip],
      error: null,
    );
    _syncLiveLocationTimer();
  }

  /// Client-side filtering: Filter trips to only show those assigned to the current driver
  /// This is a defense-in-depth measure to ensure drivers only see their own trips
  List<Trip> _filterTripsByDriverId(List<Trip> trips) {
    final driverId = StorageService.getDriverId();
    
    if (driverId == null) {
      print('⚠️ SECURITY: No driver ID found in storage. Filtering all trips for safety.');
      return [];
    }

    final filteredTrips = trips.where((trip) => trip.driverId == driverId).toList();
    
    if (filteredTrips.length != trips.length) {
      final filteredCount = trips.length - filteredTrips.length;
      print('🔒 SECURITY: Filtered out $filteredCount trip(s) not assigned to driver $driverId');
      print('🔒 SECURITY: Showing ${filteredTrips.length} trip(s) assigned to current driver');
    }
    
    return filteredTrips;
  }

  Future<void> loadTrips() async {
    print('🚀 DEBUG: Starting to load trips...');
    state = state.copyWith(isLoading: true, error: null);

    final driverId = StorageService.getDriverId();
    if (driverId != null) {
      await loadDriverTrips(driverId);
      return;
    }

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

        // Apply client-side filtering as defense-in-depth
        final filteredTrips = _filterTripsByDriverId(tripsList);

        print('✅ DEBUG: Loaded ${tripsList.length} trips, filtered to ${filteredTrips.length} assigned trips');
        state = state.copyWith(isLoading: false, trips: filteredTrips, error: null);
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

  /// Load trips for the driver dashboard. Uses GET /tracking/trips/driver/?driver_id={id}
  /// when driver ID is available (returns trips with vehicle data per trip). Falls back
  /// to /tracking/trips/active/ when no driver ID (e.g. before profile loads).
  Future<void> loadActiveTrips() async {
    if (state.isLoading) return;
    state = state.copyWith(isLoading: true, error: null);

    final driverId = StorageService.getDriverId();
    if (driverId != null) {
      // Use driver-specific endpoint - returns trips with vehicle data per trip
      await loadDriverTrips(driverId);
      // Set current trip from active trips
      final activeTrips = state.trips.where((trip) => trip.isActive).toList();
      if (activeTrips.isNotEmpty) {
        state = state.copyWith(currentTrip: activeTrips.first);
      } else {
        state = state.copyWith(clearCurrentTrip: true);
      }
      _syncLiveLocationTimer();
      return;
    }

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

        // Apply client-side filtering as defense-in-depth
        final filteredTrips = _filterTripsByDriverId(tripsList);

        // Set the first active trip as current trip if available
        final activeTrips = filteredTrips.where((trip) => trip.isActive).toList();
        final currentTrip = activeTrips.isNotEmpty ? activeTrips.first : null;

        state = state.copyWith(
          isLoading: false,
          trips: filteredTrips,
          currentTrip: currentTrip,
          error: null,
        );
        _syncLiveLocationTimer();
      } else {
        state = state.copyWith(
          isLoading: false,
          error: response.error ?? 'Failed to load active trips',
        );
        _syncLiveLocationTimer();
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load active trips: $e',
      );
      _syncLiveLocationTimer();
    }
  }

  /// Loads all trips assigned to this driver for the schedule screen (upcoming, active, past).
  /// Unlike [loadActiveTrips], does not bail when already loading so pull-to-refresh works reliably.
  Future<void> loadDriverSchedule() async {
    final driverId = StorageService.getDriverId();
    if (driverId != null) {
      await loadDriverTrips(driverId);
      final activeTrips = state.trips.where((trip) => trip.isActive).toList();
      if (activeTrips.isNotEmpty) {
        state = state.copyWith(currentTrip: activeTrips.first);
      } else {
        state = state.copyWith(clearCurrentTrip: true);
      }
      _syncLiveLocationTimer();
      return;
    }
    await loadActiveTrips();
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

        // Apply client-side filtering as defense-in-depth
        // This is especially important for loadAllTrips which may return all trips
        final filteredTrips = _filterTripsByDriverId(tripsList);

        state = state.copyWith(isLoading: false, trips: filteredTrips, error: null);
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

        // Apply client-side filtering as defense-in-depth
        final filteredTrips = _filterTripsByDriverId(tripsList);

        state = state.copyWith(isLoading: false, trips: filteredTrips, error: null);
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
    final driverId = StorageService.getDriverId();
    if (driverId != null) {
      await loadDriverTrips(driverId);
      return;
    }

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

        // Apply client-side filtering as defense-in-depth
        final filteredTrips = _filterTripsByDriverId(tripsList);

        state = state.copyWith(isLoading: false, trips: filteredTrips, error: null);
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

        // Apply client-side filtering as defense-in-depth
        final filteredTrips = _filterTripsByDriverId(tripsList);

        state = state.copyWith(isLoading: false, trips: filteredTrips, error: null);
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
    if (!_isSchoolDriverForTripStart()) {
      state = state.copyWith(
        error: 'Only school drivers are allowed to start trips.',
      );
      return false;
    }

    final gpsEnabled = await Geolocator.isLocationServiceEnabled();
    if (!gpsEnabled) {
      state = state.copyWith(
        error:
            'GPS is required to start trip. Please enable location services.',
      );
      return false;
    }

    if (latitude == null || longitude == null) {
      state = state.copyWith(
        error: 'Current GPS location is required to start trip.',
      );
      return false;
    }

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

        _syncLiveLocationTimer();

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

  TripCompletionSummary _buildTripSummary(Trip trip) {
    var pickedUpCount = 0;
    var droppedOffCount = 0;

    for (final student in state.students) {
      if (student.status == StudentStatus.pickedUp) {
        pickedUpCount++;
      } else if (student.status == StudentStatus.droppedOff) {
        droppedOffCount++;
      }
    }

    return TripCompletionSummary(
      tripId: trip.tripId,
      completedAt: trip.actualEnd ?? DateTime.now(),
      endLocation: trip.endLocation ?? 'Unknown location',
      studentCount: state.students.length,
      pickedUpCount: pickedUpCount,
      droppedOffCount: droppedOffCount,
      distanceKm: trip.distance,
      durationMinutes: trip.duration,
    );
  }

  Future<bool> endTrip({
    /// Trip row the driver tapped (schedule / details). When null, uses [TripState.currentTrip].
    Trip? trip,
    required String endLocation,
    double? latitude,
    double? longitude,
    String? notes,
  }) async {
    final resolved = trip ?? state.currentTrip;
    if (resolved == null) {
      state = state.copyWith(error: 'No active trip to end');
      return false;
    }
    if (!resolved.isActive) {
      state = state.copyWith(
        error: 'Only trips in progress can be ended.',
      );
      return false;
    }
    final driverId = StorageService.getDriverId();
    if (driverId != null && resolved.driverId != driverId) {
      state = state.copyWith(error: 'You can only end your own trips.');
      return false;
    }

    // Backend-aligned guard: do not allow trip end while checked-in students
    // are still not checked out.
    await loadTripStudents(resolved.id, tripContext: resolved);
    final notCheckedOut = state.students.where(
      (s) =>
          s.status == StudentStatus.onBus || s.status == StudentStatus.pickedUp,
    );
    final pendingList = notCheckedOut.toList();
    final pendingCheckoutCount = pendingList.length;
    if (pendingCheckoutCount > 0) {
      final pendingNames = pendingList
          .map((s) => s.fullName.trim())
          .where((name) => name.isNotEmpty)
          .toList();
      final previewNames = pendingNames.take(3).join(', ');
      final hasMore = pendingNames.length > 3;
      final namesSuffix = previewNames.isEmpty
          ? ''
          : hasMore
              ? ' Pending: $previewNames and ${pendingNames.length - 3} more.'
              : ' Pending: $previewNames.';
      state = state.copyWith(
        error:
            'Cannot end trip. $pendingCheckoutCount checked-in student(s) still need checkout.$namesSuffix',
      );
      return false;
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      final response = await ApiService.post<Map<String, dynamic>>(
        AppConfig.endTripEndpoint,
        data: {
          'trip_id': resolved.tripId,
          'end_location': endLocation,
          'latitude': latitude,
          'longitude': longitude,
          'notes': notes,
        },
      );

      if (response.success && response.data != null) {
        final ended = Trip.fromJson(response.data!);
        final summary = _buildTripSummary(ended);
        final endedWasCurrent =
            state.currentTrip != null &&
            state.currentTrip!.tripId == ended.tripId;
        if (endedWasCurrent) {
          await StorageService.clearCurrentTrip();
        }

        // Update the trips list to reflect the new status
        final updatedTrips = state.trips.map((t) {
          if (t.tripId == ended.tripId) {
            return ended;
          }
          return t;
        }).toList();

        state = state.copyWith(
          isLoading: false,
          clearCurrentTrip: endedWasCurrent,
          trips: updatedTrips,
          lastTripSummary: summary,
          error: null,
        );

        // Force a refresh of trips to ensure UI is updated
        await loadTrips();

        _syncLiveLocationTimer();

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
      final h3Index = (AppConfig.enableH3Tracking &&
              TruckH3Service.isInitialized)
          ? TruckH3Service.positionToH3String(latitude, longitude)
          : null;

      final trip = state.currentTrip;
      if (trip == null) return false;

      final response = await ApiService.post<Map<String, dynamic>>(
        AppConfig.updateLocationEndpoint,
        data: {
          // Backend expects Trip.trip_id (string), not integer PK
          'trip_id': trip.tripId,
          'latitude': latitude,
          'longitude': longitude,
          if (address != null) 'address': address,
          if (speed != null) 'speed': speed,
          if (heading != null) 'heading': heading,
          if (accuracy != null) 'accuracy': accuracy,
          if (h3Index != null) 'h3_index': h3Index,
          if (h3Index != null) 'h3_resolution': TruckH3Service.routeResolution,
        },
      );

      return response.success;
    } catch (e) {
      return false;
    }
  }

  /// Starts/stops periodic POSTs to [AppConfig.updateLocationEndpoint] while [TripState.currentTrip] is active.
  void _syncLiveLocationTimer() {
    _liveLocationTimer?.cancel();
    _liveLocationTimer = null;
    final trip = state.currentTrip;
    if (trip == null || !trip.isActive) {
      return;
    }

    final interval = Duration(seconds: AppConfig.locationUpdateInterval);
    _liveLocationTimer = Timer.periodic(interval, (_) {
      unawaited(_postLiveLocationTick());
    });
    unawaited(_postLiveLocationTick());
  }

  Future<void> _postLiveLocationTick() async {
    if (AppConfig.useSimulatedVehicleMotion) {
      return;
    }
    final trip = state.currentTrip;
    if (trip == null || !trip.isActive) {
      _syncLiveLocationTimer();
      return;
    }
    final pos = await LocationService.getCurrentPosition();
    if (pos == null) return;

    double? speedKmh;
    if (pos.speed >= 0) {
      speedKmh = pos.speed * 3.6;
    }
    double? heading = pos.heading;
    if (heading < 0) {
      heading = null;
    }

    await updateLocation(
      latitude: pos.latitude,
      longitude: pos.longitude,
      speed: speedKmh,
      heading: heading,
      accuracy: pos.accuracy,
    );
  }

  Future<void> loadTripStudents(int tripId, {Trip? tripContext}) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      // Prefer explicit trip (e.g. end-trip from schedule) so we do not require a prior firstWhere match.
      final Trip trip;
      if (tripContext != null && tripContext.id == tripId) {
        trip = tripContext;
      } else {
        trip = state.trips.firstWhere((t) => t.id == tripId);
      }

      if (trip.routeId == null) {
        print('❌ DEBUG: Trip ${trip.tripId} has no route ID');
        state = state.copyWith(
          isLoading: false,
          students: [],
          error: 'Trip has no associated route',
        );
        return;
      }

      print(
        '🔍 DEBUG: Loading students for trip ${trip.tripId} (route: ${trip.routeId})',
      );

      // Try multiple endpoints in order of preference
      List<Student> studentsList = [];
      String? lastError;

      // 1. Try trip-specific passengers endpoint (supported by backend)
      try {
        print('🚀 DEBUG: Trying trip passengers endpoint...');
        final tripResponse = await ApiService.get<Map<String, dynamic>>(
          '${AppConfig.tripDetailsEndpoint}${trip.tripId}/passengers/',
        );

        if (tripResponse.success && tripResponse.data != null) {
          final data = tripResponse.data!;
          studentsList =
              (data['results'] as List?)
                  ?.map((student) => Student.fromJson(student))
                  .toList() ??
              [];
          print(
            '✅ DEBUG: Trip passengers endpoint successful: ${studentsList.length} students',
          );
        } else {
          lastError = tripResponse.error;
          print('❌ DEBUG: Trip passengers failed: $lastError');
        }
      } catch (e) {
        lastError = e.toString();
        print('❌ DEBUG: Trip passengers exception: $e');
      }

      // 2. Try general students endpoint with filtering (may have permission issues)
      if (studentsList.isEmpty) {
        try {
          print('🚀 DEBUG: Trying general students endpoint...');
          final studentsResponse = await ApiService.get<Map<String, dynamic>>(
            '${AppConfig.studentsEndpoint}students/?limit=500',
          );

          if (studentsResponse.success && studentsResponse.data != null) {
            final data = studentsResponse.data!;
            print('🔍 DEBUG: API Response structure: ${data.keys.toList()}');

            // Get all students from results array
            if (data['results'] != null) {
              print('🔍 DEBUG: Found students in results array');
              final allStudents =
                  (data['results'] as List?)
                      ?.map((student) => Student.fromJson(student))
                      .toList() ??
                  [];

              print('🔍 DEBUG: Total students found: ${allStudents.length}');
              if (allStudents.isNotEmpty) {
                print(
                  '🔍 DEBUG: First student structure: ${allStudents.first.toJson()}',
                );
              }

              // Filter students by route ID
              studentsList = allStudents.where((student) {
                return student.assignedRoute == trip.routeId;
              }).toList();

              print(
                '🔍 DEBUG: Students filtered for route ${trip.routeId}: ${studentsList.length}',
              );
            }
            print(
              '✅ DEBUG: General students endpoint successful: ${studentsList.length} students',
            );
          } else {
            lastError = studentsResponse.error;
            print('❌ DEBUG: General students failed: $lastError');
          }
        } catch (e) {
          lastError = e.toString();
          print('❌ DEBUG: General students exception: $e');
        }
      }

      // Update state based on results
      if (studentsList.isNotEmpty) {
        print(
          '✅ DEBUG: Successfully loaded ${studentsList.length} students for trip ${trip.tripId}',
        );
        state = state.copyWith(
          isLoading: false,
          students: studentsList,
          error: null,
        );
      } else {
        print('❌ DEBUG: All endpoints failed. Last error: $lastError');
        state = state.copyWith(
          isLoading: false,
          students: [],
          error: lastError ?? 'No students found for this trip',
        );
      }
    } catch (e) {
      print('💥 DEBUG: Exception loading students: $e');
      state = state.copyWith(
        isLoading: false,
        students: [],
        error: 'Failed to load students: $e',
      );
    }
  }

  /// Load students by route ID
  Future<void> loadStudentsByRoute(int routeId) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      print('🔍 DEBUG: Loading students for route $routeId');

      // Try multiple endpoints in order of preference
      List<Student> studentsList = [];
      String? lastError;

      // Backend has no /routes/{id}/passengers endpoint; use students list + route filter.
      try {
        print(
          '🚀 DEBUG: Trying general students endpoint for route $routeId...',
        );
        final studentsResponse = await ApiService.get<Map<String, dynamic>>(
          '${AppConfig.studentsEndpoint}students/?limit=500',
        );

        if (studentsResponse.success && studentsResponse.data != null) {
          final data = studentsResponse.data!;
          final allStudents =
              (data['results'] as List?)
                  ?.map((student) => Student.fromJson(student))
                  .toList() ??
              [];

          // Filter students by route ID
          studentsList = allStudents.where((student) {
            return student.assignedRoute == routeId;
          }).toList();

          print(
            '✅ DEBUG: General students endpoint successful for route $routeId: ${studentsList.length} students (filtered from ${allStudents.length} total)',
          );
        } else {
          lastError = studentsResponse.error;
          print(
            '❌ DEBUG: General students failed for route $routeId: $lastError',
          );
        }
      } catch (e) {
        lastError = e.toString();
        print('❌ DEBUG: General students exception for route $routeId: $e');
      }

      // Update state based on results
      if (studentsList.isNotEmpty) {
        print(
          '✅ DEBUG: Successfully loaded ${studentsList.length} students for route $routeId',
        );
        state = state.copyWith(
          isLoading: false,
          students: studentsList,
          error: null,
        );
      } else {
        print(
          '❌ DEBUG: All endpoints failed for route $routeId. Last error: $lastError',
        );
        state = state.copyWith(
          isLoading: false,
          students: [],
          error: lastError ?? 'Failed to load students for route',
        );
      }
    } catch (e) {
      print('💥 DEBUG: Exception loading students for route: $e');
      state = state.copyWith(
        isLoading: false,
        students: [],
        error: 'Failed to load students for route: $e',
      );
    }
  }

  /// Get the number of students for a specific trip
  Future<int> getTripStudentCount(int tripId) async {
    try {
      // Find the trip to get its routeId
      final trip = state.trips.firstWhere((t) => t.id == tripId);

      if (trip.routeId == null) {
        print('❌ DEBUG: Trip ${trip.tripId} has no route ID');
        return 0;
      }

      print(
        '🔍 DEBUG: Getting student count for trip ${trip.tripId} (route: ${trip.routeId})',
      );

      // Try multiple endpoints in order of preference
      List<Student> studentsList = [];

      // 1. Try trip-specific passengers endpoint (supported by backend)
      try {
        print('🚀 DEBUG: Trying trip passengers endpoint for count...');
        final tripResponse = await ApiService.get<Map<String, dynamic>>(
          '${AppConfig.tripDetailsEndpoint}${trip.tripId}/passengers/',
        );

        if (tripResponse.success && tripResponse.data != null) {
          final data = tripResponse.data!;
          studentsList =
              (data['results'] as List?)
                  ?.map((student) => Student.fromJson(student))
                  .toList() ??
              [];
          print(
            '✅ DEBUG: Trip passengers endpoint successful for count: ${studentsList.length} students',
          );
        } else {
          print(
            '❌ DEBUG: Trip passengers failed for count: ${tripResponse.error}',
          );
        }
      } catch (e) {
        print('❌ DEBUG: Trip passengers exception for count: $e');
      }

      // 2. Try general students endpoint with filtering (may have permission issues)
      if (studentsList.isEmpty) {
        try {
          print('🚀 DEBUG: Trying general students endpoint for count...');
          final studentsResponse = await ApiService.get<Map<String, dynamic>>(
            '${AppConfig.studentsEndpoint}students/?limit=500',
          );

          if (studentsResponse.success && studentsResponse.data != null) {
            final data = studentsResponse.data!;
            print(
              '🔍 DEBUG: Student count API Response structure: ${data.keys.toList()}',
            );

            // Get all students from results array
            if (data['results'] != null) {
              print('🔍 DEBUG: Found students in results array for count');
              final allStudents =
                  (data['results'] as List?)
                      ?.map((student) => Student.fromJson(student))
                      .toList() ??
                  [];

              print(
                '🔍 DEBUG: Total students found for count: ${allStudents.length}',
              );

              // Filter students by route ID
              studentsList = allStudents.where((student) {
                return student.assignedRoute == trip.routeId;
              }).toList();

              print(
                '🔍 DEBUG: Students filtered for route ${trip.routeId}: ${studentsList.length}',
              );
            }
            print(
              '✅ DEBUG: General students endpoint successful for count: ${studentsList.length} students',
            );
          } else {
            print(
              '❌ DEBUG: General students failed for count: ${studentsResponse.error}',
            );
          }
        } catch (e) {
          print('❌ DEBUG: General students exception for count: $e');
        }
      }

      print(
        '✅ DEBUG: Found ${studentsList.length} students for trip ${trip.tripId}',
      );
      return studentsList.length;
    } catch (e) {
      print('💥 DEBUG: Exception getting student count: $e');
      return 0;
    }
  }

  /// Get the total number of students across all active trips (fleet count)
  Future<int> getFleetStudentCount() async {
    try {
      int totalStudents = 0;

      // Get all active trips
      final activeTrips = state.trips.where((trip) => trip.isActive).toList();

      print(
        '🔍 DEBUG: Getting fleet student count for ${activeTrips.length} active trips',
      );

      // For each active trip, get the student count
      for (final trip in activeTrips) {
        final studentCount = await getTripStudentCount(trip.id);
        totalStudents += studentCount;
        print('🔍 DEBUG: Trip ${trip.tripId} has $studentCount students');
      }

      print('✅ DEBUG: Total fleet student count: $totalStudents');
      return totalStudents;
    } catch (e) {
      print('💥 DEBUG: Exception getting fleet student count: $e');
      return 0;
    }
  }

  /// Get student count for multiple trips (fleet overview)
  Future<Map<String, int>> getFleetStudentCounts() async {
    try {
      Map<String, int> tripStudentCounts = {};

      // Get all active trips
      final activeTrips = state.trips.where((trip) => trip.isActive).toList();

      print(
        '🔍 DEBUG: Getting student counts for ${activeTrips.length} active trips',
      );

      // For each active trip, get the student count
      for (final trip in activeTrips) {
        final studentCount = await getTripStudentCount(trip.id);
        tripStudentCounts[trip.tripId] = studentCount;
        print('🔍 DEBUG: Trip ${trip.tripId} has $studentCount students');
      }

      print('✅ DEBUG: Fleet student counts: $tripStudentCounts');
      return tripStudentCounts;
    } catch (e) {
      print('💥 DEBUG: Exception getting fleet student counts: $e');
      return {};
    }
  }

  Future<bool> updateStudentStatus(int studentId, StudentStatus status) async {
    try {
      final currentTrip = state.currentTrip;
      if (currentTrip == null) {
        print('❌ Trip Provider: No current trip available for status update');
        return false;
      }

      // Get current location
      String locationWkt = 'POINT(0 0)'; // Default fallback
      try {
        final position = await LocationService.getCurrentPosition();
        if (position != null) {
          locationWkt = 'POINT(${position.longitude} ${position.latitude})';
          print(
            '📍 Trip Provider: Using current location: ${position.latitude}, ${position.longitude}',
          );
        } else {
          print(
            '⚠️ Trip Provider: Could not get current location, using default',
          );
        }
      } catch (e) {
        print('⚠️ Trip Provider: Error getting location: $e, using default');
      }

      print(
        '📤 Trip Provider: Updating student status for student $studentId to ${status.name}',
      );
      print(
        '📤 Trip Provider: Using endpoint: ${AppConfig.trackingStudentStatusUpdateEndpoint}',
      );
      print(
        '📤 Trip Provider: Data: {student: $studentId, vehicle: ${currentTrip.vehicleId ?? 0}, route: ${currentTrip.routeId ?? 0}, status: ${status.name}, location: $locationWkt}',
      );

      final response = await ApiService.post<Map<String, dynamic>>(
        AppConfig.trackingStudentStatusUpdateEndpoint,
        data: {
          'student': studentId,
          'vehicle': currentTrip.vehicleId ?? 0,
          'route': currentTrip.routeId ?? 0,
          'status': status.name,
          'location': locationWkt,
          'notes': 'Status updated via driver app',
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

        // Send automated notifications
        await _sendStatusUpdateNotifications(studentId, status);

        return true;
      }

      return false;
    } catch (e) {
      print('❌ Trip Provider: Error updating student status: $e');
      return false;
    }
  }

  /// Send automated notifications when student status changes
  Future<void> _sendStatusUpdateNotifications(
    int studentId,
    StudentStatus status,
  ) async {
    try {
      // Find the student to get their details
      final student = state.students.firstWhere(
        (s) => s.id == studentId,
        orElse: () => throw Exception('Student not found'),
      );

      print(
        '📱 Trip Provider: Sending status update notifications for ${student.fullName} - ${status.name}',
      );

      // Send local notification to driver
      await _sendLocalStatusNotification(student, status);

      // Send parent notification if parent contact info is available
      await _sendParentStatusNotification(student, status);

      print('✅ Trip Provider: Status update notifications sent successfully');
    } catch (e) {
      print('❌ Trip Provider: Error sending status update notifications: $e');
    }
  }

  /// Send local notification to driver
  Future<void> _sendLocalStatusNotification(
    Student student,
    StudentStatus status,
  ) async {
    try {
      final statusMessage = _getStatusDisplayMessage(status);
      await NotificationService.showStudentStatusNotification(
        studentName: student.fullName,
        status: statusMessage,
        tripId: state.currentTrip?.id.toString(),
      );
      print(
        '📱 Trip Provider: Local notification sent for ${student.fullName}',
      );
    } catch (e) {
      print('❌ Trip Provider: Error sending local notification: $e');
    }
  }

  /// Send notification to parent
  Future<void> _sendParentStatusNotification(
    Student student,
    StudentStatus status,
  ) async {
    try {
      // Only send notifications for pickup and dropoff events
      if (status != StudentStatus.pickedUp && status != StudentStatus.droppedOff) {
        print(
          '⚠️ Trip Provider: Skipping parent notification for status ${status.name}',
        );
        return;
      }

      // Check if we have parent IDs
      if (student.parentIds.isEmpty) {
        print(
          '⚠️ Trip Provider: No parent IDs found for ${student.fullName}, trying student ID approach',
        );
        // Fallback: use student ID and let backend route to parents
        await _sendNotificationWithStudentId(student, status);
        return;
      }

      // Determine notification type and message
      final notificationType = status == StudentStatus.pickedUp
          ? 'student_pickup'
          : 'student_dropoff';
      
      final title = status == StudentStatus.pickedUp
          ? 'Student Picked Up'
          : 'Student Dropped Off';
      
      final message = status == StudentStatus.pickedUp
          ? 'Your child ${student.fullName} has been picked up'
          : 'Your child ${student.fullName} has been dropped off';

      // Get current location for the notification
      String? locationWkt;
      try {
        final position = await LocationService.getCurrentPosition();
        if (position != null) {
          locationWkt = 'POINT(${position.longitude} ${position.latitude})';
        }
      } catch (e) {
        print('⚠️ Trip Provider: Could not get location for notification: $e');
      }

      // Send notification to each parent
      int successCount = 0;
      int failureCount = 0;

      for (final parentId in student.parentIds) {
        try {
          final response = await ApiService.post<Map<String, dynamic>>(
            AppConfig.notificationsEndpoint,
            data: {
              'recipient': parentId, // Use parent ID as recipient
              'student': student.id,
              'notification_type': notificationType,
              'priority': 'normal',
              'title': title,
              'message': message,
              if (state.currentTrip?.vehicleId != null)
                'vehicle': state.currentTrip!.vehicleId,
              if (state.currentTrip?.routeId != null)
                'route': state.currentTrip!.routeId,
              if (locationWkt != null) 'location': locationWkt,
              'channels': ['push', 'sms', 'email'],
              'metadata': {
                'trip_id': state.currentTrip?.id,
                'student_name': student.fullName,
                'timestamp': DateTime.now().toIso8601String(),
              },
            },
          );

          if (response.success) {
            successCount++;
            print(
              '✅ Trip Provider: Notification sent to parent $parentId for ${student.fullName}',
            );
          } else {
            failureCount++;
            print(
              '❌ Trip Provider: Failed to send notification to parent $parentId: ${response.error}',
            );
          }
        } catch (e) {
          failureCount++;
          print(
            '❌ Trip Provider: Error sending notification to parent $parentId: $e',
          );
        }
      }

      print(
        '📱 Trip Provider: Parent notifications sent for ${student.fullName} - ${status.name} (Success: $successCount, Failed: $failureCount)',
      );
    } catch (e) {
      print('❌ Trip Provider: Error sending parent notification: $e');
    }
  }

  /// Fallback: Send notification using student ID (backend routes to parents)
  Future<void> _sendNotificationWithStudentId(
    Student student,
    StudentStatus status,
  ) async {
    final notificationType = status == StudentStatus.pickedUp
        ? 'student_pickup'
        : 'student_dropoff';
    
    final title = status == StudentStatus.pickedUp
        ? 'Student Picked Up'
        : 'Student Dropped Off';
    
    final message = status == StudentStatus.pickedUp
        ? 'Your child ${student.fullName} has been picked up'
        : 'Your child ${student.fullName} has been dropped off';

    String? locationWkt;
    try {
      final position = await LocationService.getCurrentPosition();
      if (position != null) {
        locationWkt = 'POINT(${position.longitude} ${position.latitude})';
      }
    } catch (e) {
      print('⚠️ Trip Provider: Could not get location for notification: $e');
    }

    final response = await ApiService.post<Map<String, dynamic>>(
      AppConfig.notificationsEndpoint,
      data: {
        'student': student.id,
        'notification_type': notificationType,
        'priority': 'normal',
        'title': title,
        'message': message,
        if (state.currentTrip?.vehicleId != null)
          'vehicle': state.currentTrip!.vehicleId,
        if (state.currentTrip?.routeId != null)
          'route': state.currentTrip!.routeId,
        if (locationWkt != null) 'location': locationWkt,
        'channels': ['push', 'sms', 'email'],
        'metadata': {
          'trip_id': state.currentTrip?.id,
          'student_name': student.fullName,
          'timestamp': DateTime.now().toIso8601String(),
        },
      },
    );

    if (response.success) {
      print(
        '✅ Trip Provider: Parent notification sent via student ID for ${student.fullName}',
      );
    } else {
      print(
        '❌ Trip Provider: Failed to send parent notification via student ID: ${response.error}',
      );
    }
  }

  /// Convert StudentStatus to ChildStatus for parent notifications
  ChildStatus _convertToChildStatus(StudentStatus status) {
    switch (status) {
      case StudentStatus.waiting:
        return ChildStatus.waiting;
      case StudentStatus.onBus:
        return ChildStatus.onBus;
      case StudentStatus.pickedUp:
        return ChildStatus.pickedUp;
      case StudentStatus.droppedOff:
        return ChildStatus.droppedOff;
      case StudentStatus.absent:
        return ChildStatus.absent;
    }
  }

  /// Get display message for status
  String _getStatusDisplayMessage(StudentStatus status) {
    switch (status) {
      case StudentStatus.waiting:
        return 'Waiting for pickup';
      case StudentStatus.onBus:
        return 'On the way';
      case StudentStatus.pickedUp:
        return 'Picked up';
      case StudentStatus.droppedOff:
        return 'Dropped off';
      case StudentStatus.absent:
        return 'Absent';
    }
  }

  /// Parse string status to StudentStatus enum
  StudentStatus? _parseStringToStudentStatus(String status) {
    switch (status.toLowerCase()) {
      case 'waiting':
        return StudentStatus.waiting;
      case 'onbus':
      case 'on_bus':
        return StudentStatus.onBus;
      case 'pickedup':
      case 'picked_up':
        return StudentStatus.pickedUp;
      case 'droppedoff':
      case 'dropped_off':
        return StudentStatus.droppedOff;
      case 'absent':
        return StudentStatus.absent;
      default:
        print('⚠️ Trip Provider: Unknown status string: $status');
        return null;
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

      if (response.success) {
        // Convert string status to StudentStatus enum and send notifications
        final studentStatus = _parseStringToStudentStatus(status);
        if (studentStatus != null) {
          await _sendStatusUpdateNotifications(studentId, studentStatus);
        }
      }

      return response.success;
    } catch (e) {
      print('❌ Trip Provider: Error in trackingUpdateStudentStatus: $e');
      return false;
    }
  }

  /// POST `/checkin/verify/qr-code/` with the **full** scanned payload (not a parsed ID).
  /// Backend records [CheckinSession] and updates transit status when appropriate.
  Future<DriverCheckinResult> verifyCheckinWithQrCode({
    required String qrCodeData,
    required bool isPickup,
  }) async {
    final trimmed = qrCodeData.trim();
    if (trimmed.isEmpty) {
      return DriverCheckinResult.fail('Empty QR code');
    }

    try {
      if (!_canManageStudentCheckin()) {
        return DriverCheckinResult.fail(
          'Check-in is restricted to driver or admin with driver request.',
        );
      }

      final trip = state.currentTrip;
      final checkinType = isPickup ? 'pickup' : 'dropoff';

      final body = <String, dynamic>{
        'qr_code_data': trimmed,
        'checkin_type': checkinType,
        if (trip?.vehicleId != null) 'vehicle_id': trip!.vehicleId,
        if (trip?.routeId != null) 'route_id': trip!.routeId,
        if (trip != null && trip.tripId.isNotEmpty) 'trip_id': trip.tripId,
        ..._driverRequestPayload(),
      };

      print(
        '🔍 Trip Provider: POST ${AppConfig.checkinVerifyQrEndpoint} checkin_type=$checkinType',
      );

      final response = await ApiService.post<Map<String, dynamic>>(
        AppConfig.checkinVerifyQrEndpoint,
        data: body,
      );

      if (response.success) {
        if (state.currentTrip != null) {
          await loadTripStudents(state.currentTrip!.id);
        }
        return DriverCheckinResult.ok();
      }

      final err = response.error ?? 'Verification failed';
      print('❌ Trip Provider: QR verify failed: $err');
      return DriverCheckinResult.fail(err);
    } catch (e) {
      print('💥 Trip Provider: Exception during QR verify: $e');
      return DriverCheckinResult.fail('Network error: $e');
    }
  }

  /// POST `/checkin/verify/pin-code/` (e.g. manual PIN entry with known student id).
  Future<DriverCheckinResult> verifyCheckinWithPin({
    required int studentId,
    required String pinCode,
    required bool isPickup,
  }) async {
    final pin = pinCode.trim();
    if (pin.isEmpty) {
      return DriverCheckinResult.fail('Empty PIN');
    }

    try {
      if (!_canManageStudentCheckin()) {
        return DriverCheckinResult.fail(
          'Check-in is restricted to driver or admin with driver request.',
        );
      }

      final trip = state.currentTrip;
      final checkinType = isPickup ? 'pickup' : 'dropoff';

      final body = <String, dynamic>{
        'student_id': studentId,
        'pin_code': pin,
        'checkin_type': checkinType,
        if (trip?.vehicleId != null) 'vehicle_id': trip!.vehicleId,
        if (trip?.routeId != null) 'route_id': trip!.routeId,
        if (trip != null && trip.tripId.isNotEmpty) 'trip_id': trip.tripId,
        ..._driverRequestPayload(),
      };

      final response = await ApiService.post<Map<String, dynamic>>(
        AppConfig.checkinVerifyPinEndpoint,
        data: body,
      );

      if (response.success) {
        if (state.currentTrip != null) {
          await loadTripStudents(state.currentTrip!.id);
        }
        return DriverCheckinResult.ok();
      }

      final err = response.error ?? 'PIN verification failed';
      return DriverCheckinResult.fail(err);
    } catch (e) {
      return DriverCheckinResult.fail('Network error: $e');
    }
  }

  /// POST `/checkin/verify/manual/` — driver selects student from roster (no QR/PIN).
  Future<DriverCheckinResult> verifyCheckinManual({
    required int studentId,
    required bool isPickup,
    String? notes,
  }) async {
    try {
      if (!_canManageStudentCheckin()) {
        return DriverCheckinResult.fail(
          'Check-in is restricted to driver or admin with driver request.',
        );
      }

      final trip = state.currentTrip;
      final checkinType = isPickup ? 'pickup' : 'dropoff';

      final body = <String, dynamic>{
        'student_id': studentId,
        'checkin_type': checkinType,
        if (trip?.vehicleId != null) 'vehicle_id': trip!.vehicleId,
        if (trip?.routeId != null) 'route_id': trip!.routeId,
        if (trip != null && trip.tripId.isNotEmpty) 'trip_id': trip.tripId,
        if (notes != null && notes.trim().isNotEmpty) 'notes': notes.trim(),
        ..._driverRequestPayload(),
      };

      final response = await ApiService.post<Map<String, dynamic>>(
        AppConfig.checkinVerifyManualEndpoint,
        data: body,
      );

      if (response.success) {
        if (state.currentTrip != null) {
          await loadTripStudents(state.currentTrip!.id);
        }
        return DriverCheckinResult.ok();
      }

      final err = response.error ?? 'Manual check-in failed';
      return DriverCheckinResult.fail(err);
    } catch (e) {
      return DriverCheckinResult.fail('Network error: $e');
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
    _syncLiveLocationTimer();
  }

  void updateTripInList(Trip updatedTrip) {
    print('🔄 DEBUG: Updating trip ${updatedTrip.tripId} in trips list');
    final updatedTrips = state.trips.map((t) {
      if (t.tripId == updatedTrip.tripId) {
        return updatedTrip;
      }
      return t;
    }).toList();

    // Apply client-side filtering as defense-in-depth when updating trips
    final filteredTrips = _filterTripsByDriverId(updatedTrips);

    state = state.copyWith(trips: filteredTrips);
  }

  Future<void> refreshTrips() async {
    await loadTrips();
  }

  void _startPeriodicRefresh() {
    // Refresh trips every 60 seconds - background only, no loading state
    _refreshTimer = Timer.periodic(const Duration(seconds: 60), (timer) {
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

        // Apply client-side filtering as defense-in-depth
        final filteredTrips = _filterTripsByDriverId(tripsList);

        // Only update if trips have changed
        if (filteredTrips.length != state.trips.length ||
            _hasTripStatusChanged(filteredTrips)) {
          state = state.copyWith(trips: filteredTrips, error: null);
        }
      }
    } catch (e) {
      // Silent refresh - don't update error state
      print('Silent refresh failed: $e');
    }
  }

  bool _hasTripStatusChanged(List<Trip> newTrips) {
    if (state.trips.length != newTrips.length) return true;

    final byId = {for (final t in newTrips) t.id: t};
    for (final t in state.trips) {
      final updated = byId[t.id];
      if (updated == null || updated.status != t.status) return true;
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
    if (currentTrip.endLatitude == null || currentTrip.endLongitude == null) {
      return;
    }

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
    _liveLocationTimer?.cancel();
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

// Fleet Student Count Providers
final fleetStudentCountProvider = FutureProvider<int>((ref) async {
  final tripNotifier = ref.read(tripProvider.notifier);
  return await tripNotifier.getFleetStudentCount();
});

final fleetStudentCountsProvider = FutureProvider<Map<String, int>>((
  ref,
) async {
  final tripNotifier = ref.read(tripProvider.notifier);
  return await tripNotifier.getFleetStudentCounts();
});

// Trip-specific student count provider
final tripStudentCountProvider = FutureProvider.family<int, int>((
  ref,
  tripId,
) async {
  final tripNotifier = ref.read(tripProvider.notifier);
  return await tripNotifier.getTripStudentCount(tripId);
});
