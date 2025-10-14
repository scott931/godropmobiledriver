import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../models/eta_model.dart';
import '../models/trip_model.dart';
import '../services/eta_service.dart';
import '../services/location_service.dart';

class ETAState {
  final ETAInfo? currentETA;
  final List<ETAInfo> etaHistory;
  final bool isCalculating;
  final String? error;
  final DateTime? lastUpdated;
  final bool isTracking;
  final Map<String, ETAInfo> tripETAs; // ETAs for multiple trips

  const ETAState({
    this.currentETA,
    this.etaHistory = const [],
    this.isCalculating = false,
    this.error,
    this.lastUpdated,
    this.isTracking = false,
    this.tripETAs = const {},
  });

  ETAState copyWith({
    ETAInfo? currentETA,
    List<ETAInfo>? etaHistory,
    bool? isCalculating,
    String? error,
    DateTime? lastUpdated,
    bool? isTracking,
    Map<String, ETAInfo>? tripETAs,
  }) {
    return ETAState(
      currentETA: currentETA ?? this.currentETA,
      etaHistory: etaHistory ?? this.etaHistory,
      isCalculating: isCalculating ?? this.isCalculating,
      error: error,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      isTracking: isTracking ?? this.isTracking,
      tripETAs: tripETAs ?? this.tripETAs,
    );
  }

  bool get hasError => error != null;
  bool get hasETA => currentETA != null;
  bool get isDelayed => currentETA?.isDelayed ?? false;
  Duration? get timeToArrival => currentETA?.timeToArrival;
}

class ETANotifier extends StateNotifier<ETAState> {
  Timer? _etaUpdateTimer;
  Timer? _locationUpdateTimer;
  StreamSubscription<Position>? _locationSubscription;
  Trip? _currentTrip;

  ETANotifier() : super(const ETAState()) {
    _initializeLocationTracking();
  }

  /// Initialize location tracking for ETA calculations
  void _initializeLocationTracking() async {
    try {
      await LocationService.init();
      _locationSubscription = LocationService.locationStream.listen(
        (position) => _onLocationUpdate(position),
        onError: (error) => _onLocationError(error),
      );
    } catch (e) {
      state = state.copyWith(
        error: 'Failed to initialize location tracking: $e',
      );
    }
  }

  /// Handle location updates
  void _onLocationUpdate(Position position) {
    if (_currentTrip != null && state.isTracking) {
      _calculateETAForCurrentTrip();
    }
  }

  /// Handle location errors
  void _onLocationError(dynamic error) {
    print('❌ ETA Provider: Location error: $error');
    state = state.copyWith(error: 'Location tracking error: $error');
  }

  /// Start ETA tracking for a trip
  Future<void> startETATracking(Trip trip) async {
    print('🚀 ETA Provider: Starting ETA tracking for trip ${trip.tripId}');

    _currentTrip = trip;
    state = state.copyWith(isTracking: true, error: null);

    // Calculate initial ETA
    await _calculateETAForCurrentTrip();

    // Start periodic updates
    _etaUpdateTimer?.cancel();
    _etaUpdateTimer = Timer.periodic(
      const Duration(minutes: 1), // Update every minute
      (timer) => _calculateETAForCurrentTrip(),
    );
  }

  /// Stop ETA tracking
  void stopETATracking() {
    print('🛑 ETA Provider: Stopping ETA tracking');

    _etaUpdateTimer?.cancel();
    _etaUpdateTimer = null;
    _currentTrip = null;

    state = state.copyWith(isTracking: false, currentETA: null);
  }

  /// Calculate ETA for the current trip
  Future<void> _calculateETAForCurrentTrip() async {
    if (_currentTrip == null) return;

    final currentPosition = LocationService.currentPosition;
    if (currentPosition == null) {
      print('❌ ETA Provider: No current position available');
      return;
    }

    if (_currentTrip!.endLatitude == null ||
        _currentTrip!.endLongitude == null) {
      print('❌ ETA Provider: Trip has no destination coordinates');
      return;
    }

    state = state.copyWith(isCalculating: true, error: null);

    try {
      final result = await ETAService.calculateETA(
        currentLat: currentPosition.latitude,
        currentLng: currentPosition.longitude,
        destinationLat: _currentTrip!.endLatitude!,
        destinationLng: _currentTrip!.endLongitude!,
        trip: _currentTrip!,
        routeName: _currentTrip!.routeName,
        vehicleType: 'school_bus',
      );

      if (result.success) {
        final newETA = result.etaInfo;
        final updatedHistory = List<ETAInfo>.from(state.etaHistory);
        updatedHistory.add(newETA);

        // Keep only last 20 ETA calculations
        if (updatedHistory.length > 20) {
          updatedHistory.removeAt(0);
        }

        state = state.copyWith(
          currentETA: newETA,
          etaHistory: updatedHistory,
          isCalculating: false,
          lastUpdated: DateTime.now(),
          error: null,
        );

        // Update trip-specific ETA
        final updatedTripETAs = Map<String, ETAInfo>.from(state.tripETAs);
        updatedTripETAs[_currentTrip!.tripId] = newETA;
        state = state.copyWith(tripETAs: updatedTripETAs);

        print('✅ ETA Provider: ETA updated - ${newETA.formattedTimeToArrival}');
      } else {
        state = state.copyWith(isCalculating: false, error: result.error);
      }
    } catch (e) {
      print('❌ ETA Provider: Error calculating ETA: $e');
      state = state.copyWith(
        isCalculating: false,
        error: 'Failed to calculate ETA: $e',
      );
    }
  }

  /// Calculate ETA for a specific trip (without starting tracking)
  Future<ETAInfo?> calculateETAForTrip(Trip trip) async {
    final currentPosition = LocationService.currentPosition;
    if (currentPosition == null) {
      print('❌ ETA Provider: No current position available');
      return null;
    }

    if (trip.endLatitude == null || trip.endLongitude == null) {
      print('❌ ETA Provider: Trip has no destination coordinates');
      return null;
    }

    try {
      final result = await ETAService.calculateETA(
        currentLat: currentPosition.latitude,
        currentLng: currentPosition.longitude,
        destinationLat: trip.endLatitude!,
        destinationLng: trip.endLongitude!,
        trip: trip,
        routeName: trip.routeName,
        vehicleType: 'school_bus',
      );

      if (result.success) {
        return result.etaInfo;
      } else {
        print('❌ ETA Provider: Failed to calculate ETA: ${result.error}');
        return null;
      }
    } catch (e) {
      print('❌ ETA Provider: Error calculating ETA: $e');
      return null;
    }
  }

  /// Get ETA for a specific trip
  ETAInfo? getETAForTrip(String tripId) {
    return state.tripETAs[tripId];
  }

  /// Get ETA accuracy percentage
  double getETAAccuracy() {
    return ETAService.getETAAccuracy(state.etaHistory);
  }

  /// Get traffic conditions
  String getTrafficConditions() {
    if (state.currentETA?.trafficMultiplier == null) {
      return 'Unknown';
    }

    final multiplier = state.currentETA!.trafficMultiplier!;
    if (multiplier <= 0.8) return 'Light Traffic';
    if (multiplier <= 1.2) return 'Normal Traffic';
    if (multiplier <= 1.5) return 'Heavy Traffic';
    return 'Severe Traffic';
  }

  /// Get delay status
  String getDelayStatus() {
    if (state.currentETA == null) return 'Unknown';

    if (state.currentETA!.isDelayed) {
      final delayMinutes = state.currentETA!.estimatedArrival
          .difference(_currentTrip?.scheduledEnd ?? DateTime.now())
          .inMinutes;

      if (delayMinutes <= 5) return 'Minor Delay';
      if (delayMinutes <= 15) return 'Moderate Delay';
      if (delayMinutes <= 30) return 'Significant Delay';
      return 'Major Delay';
    }

    return 'On Time';
  }

  /// Clear ETA history
  void clearETAHistory() {
    state = state.copyWith(etaHistory: [], currentETA: null);
  }

  /// Refresh ETA (force recalculation)
  Future<void> refreshETA() async {
    if (_currentTrip != null) {
      await _calculateETAForCurrentTrip();
    }
  }

  /// Get ETA status for display
  String getETAStatus() {
    if (state.currentETA == null) return 'Calculating...';

    if (state.currentETA!.isDelayed) {
      return 'Delayed';
    } else if (state.currentETA!.timeToArrival.inMinutes <= 5) {
      return 'Arriving Soon';
    } else if (state.currentETA!.timeToArrival.inMinutes <= 15) {
      return 'On Time';
    } else {
      return 'Scheduled';
    }
  }

  /// Get formatted ETA time
  String getFormattedETA() {
    if (state.currentETA == null) return '--';
    return ETAService.formatETA(state.currentETA!);
  }

  /// Get ETA color for UI
  int getETAColor() {
    if (state.currentETA == null) return 0xFF9E9E9E; // Grey

    if (state.currentETA!.isDelayed) {
      return 0xFFD32F2F; // Red
    } else if (state.currentETA!.timeToArrival.inMinutes <= 5) {
      return 0xFF4CAF50; // Green
    } else {
      return 0xFF2196F3; // Blue
    }
  }

  @override
  void dispose() {
    _etaUpdateTimer?.cancel();
    _locationUpdateTimer?.cancel();
    _locationSubscription?.cancel();
    super.dispose();
  }
}

// Provider instances
final etaProvider = StateNotifierProvider<ETANotifier, ETAState>((ref) {
  return ETANotifier();
});

// Convenience providers
final currentETAProvider = Provider<ETAInfo?>((ref) {
  return ref.watch(etaProvider).currentETA;
});

final etaTrackingProvider = Provider<bool>((ref) {
  return ref.watch(etaProvider).isTracking;
});

final etaErrorProvider = Provider<String?>((ref) {
  return ref.watch(etaProvider).error;
});

final etaStatusProvider = Provider<String>((ref) {
  final etaNotifier = ref.watch(etaProvider.notifier);
  return etaNotifier.getETAStatus();
});

final etaFormattedProvider = Provider<String>((ref) {
  final etaNotifier = ref.watch(etaProvider.notifier);
  return etaNotifier.getFormattedETA();
});

final etaColorProvider = Provider<int>((ref) {
  final etaNotifier = ref.watch(etaProvider.notifier);
  return etaNotifier.getETAColor();
});
