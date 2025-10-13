import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../services/location_service.dart';
import '../services/api_service.dart';
import '../config/app_config.dart';
import '../models/location_model.dart';

class LocationState {
  final bool isTracking;
  final Position? currentPosition;
  final String? currentAddress;
  final List<VehicleLocation> recentLocations;
  final VehicleLocation? selectedLocation;
  final String? error;

  const LocationState({
    this.isTracking = false,
    this.currentPosition,
    this.currentAddress,
    this.recentLocations = const [],
    this.selectedLocation,
    this.error,
  });

  LocationState copyWith({
    bool? isTracking,
    Position? currentPosition,
    String? currentAddress,
    List<VehicleLocation>? recentLocations,
    VehicleLocation? selectedLocation,
    String? error,
  }) {
    return LocationState(
      isTracking: isTracking ?? this.isTracking,
      currentPosition: currentPosition ?? this.currentPosition,
      currentAddress: currentAddress ?? this.currentAddress,
      recentLocations: recentLocations ?? this.recentLocations,
      selectedLocation: selectedLocation ?? this.selectedLocation,
      error: error,
    );
  }
}

class LocationNotifier extends StateNotifier<LocationState> {
  LocationNotifier() : super(const LocationState()) {
    _initializeLocationTracking();
  }

  Future<void> loadRecentLocations() async {
    try {
      final response = await ApiService.get<Map<String, dynamic>>(
        AppConfig.trackingLocationsEndpoint,
      );
      if (response.success && response.data != null) {
        final list = (response.data!['results'] as List?)
                ?.map((j) => VehicleLocation.fromJson(j))
                .toList() ??
            [];
        state = state.copyWith(recentLocations: list, error: null);
      } else {
        state = state.copyWith(error: response.error ?? 'Failed to load locations');
      }
    } catch (e) {
      state = state.copyWith(error: 'Failed to load locations: $e');
    }
  }

  Future<void> loadLocationDetails(int locationId) async {
    try {
      final response = await ApiService.get<Map<String, dynamic>>(
        '${AppConfig.trackingLocationsEndpoint}$locationId/',
      );
      if (response.success && response.data != null) {
        final loc = VehicleLocation.fromJson(response.data!);
        state = state.copyWith(selectedLocation: loc, error: null);
      } else {
        state = state.copyWith(
          error: response.error ?? 'Failed to load location details',
        );
      }
    } catch (e) {
      state = state.copyWith(error: 'Failed to load location details: $e');
    }
  }

  Future<void> loadVehicleLocations({int timeFilterMinutes = 30}) async {
    try {
      final response = await ApiService.get<Map<String, dynamic>>(
        AppConfig.trackingVehiclesLocationsEndpoint,
        queryParameters: {'time_filter_minutes': timeFilterMinutes},
      );
      if (response.success && response.data != null) {
        final list = (response.data!['locations'] as List?)
                ?.map((j) => VehicleLocation.fromJson(j))
                .toList() ??
            [];
        state = state.copyWith(recentLocations: list, error: null);
      } else {
        state = state.copyWith(
          error: response.error ?? 'Failed to load vehicle locations',
        );
      }
    } catch (e) {
      state = state.copyWith(error: 'Failed to load vehicle locations: $e');
    }
  }

  Future<bool> updateVehicleLocation({
    required int vehicleId,
    required int routeId,
    String? tripId,
    required String locationWkt,
    double? speed,
    double? heading,
    double? accuracy,
    double? altitude,
  }) async {
    try {
      final response = await ApiService.post<Map<String, dynamic>>(
        AppConfig.trackingLocationsUpdateEndpoint,
        data: {
          'vehicle': vehicleId,
          'route': routeId,
          'trip_id': tripId,
          'location': locationWkt,
          'speed': speed,
          'heading': heading,
          'accuracy': accuracy,
          'altitude': altitude,
        },
      );
      if (response.success && response.data != null) {
        final loc = VehicleLocation.fromJson(response.data!);
        state = state.copyWith(selectedLocation: loc, error: null);
        return true;
      }
      state = state.copyWith(error: response.error ?? 'Failed to update location');
      return false;
    } catch (e) {
      state = state.copyWith(error: 'Failed to update location: $e');
      return false;
    }
  }

  Future<void> _initializeLocationTracking() async {
    try {
      await LocationService.startLocationTracking();

      // Listen to location updates
      LocationService.locationStream.listen(
        (position) {
          state = state.copyWith(
            isTracking: true,
            currentPosition: position,
            error: null,
          );

          // Get address for current position
          _getCurrentAddress(position);
        },
        onError: (error) {
          state = state.copyWith(error: error.toString());
        },
      );
    } catch (e) {
      state = state.copyWith(
        error: 'Failed to initialize location tracking: $e',
      );
    }
  }

  Future<void> _getCurrentAddress(Position position) async {
    try {
      final address = await LocationService.getAddressFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (address != null) {
        state = state.copyWith(currentAddress: address);
      }
    } catch (e) {
      // Address lookup failed, but don't update error state
      // as location tracking is still working
    }
  }

  Future<void> startTracking() async {
    try {
      await LocationService.startLocationTracking();
      state = state.copyWith(isTracking: true, error: null);
    } catch (e) {
      state = state.copyWith(error: 'Failed to start location tracking: $e');
    }
  }

  Future<void> stopTracking() async {
    try {
      await LocationService.stopLocationTracking();
      state = state.copyWith(isTracking: false, error: null);
    } catch (e) {
      state = state.copyWith(error: 'Failed to stop location tracking: $e');
    }
  }

  Future<Position?> getCurrentPosition() async {
    try {
      final position = await LocationService.getCurrentPosition();
      if (position != null) {
        state = state.copyWith(currentPosition: position, error: null);
        await _getCurrentAddress(position);
      }
      return position;
    } catch (e) {
      state = state.copyWith(error: 'Failed to get current position: $e');
      return null;
    }
  }

  Future<void> getCurrentLocation() async {
    await getCurrentPosition();
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

final locationProvider = StateNotifierProvider<LocationNotifier, LocationState>(
  (ref) {
    return LocationNotifier();
  },
);

final currentPositionProvider = Provider<Position?>((ref) {
  return ref.watch(locationProvider).currentPosition;
});

final isLocationTrackingProvider = Provider<bool>((ref) {
  return ref.watch(locationProvider).isTracking;
});
