import 'dart:async';
import 'package:geolocator/geolocator.dart';
import '../models/trip_model.dart';
import '../models/eta_model.dart';
import 'realtime_location_service.dart';
import 'realtime_eta_updater.dart';

class TripTrackingService {
  static bool _isTracking = false;
  static Trip? _activeTrip;
  // Removed unused subscription variables

  // Callbacks
  static Function(Trip, ETAInfo)? _onTripUpdate;
  static Function(Trip, String)? _onTripError;
  static Function(Trip, Position)? _onLocationUpdate;
  static Function(Trip, ETAInfo)? _onETAUpdate;

  /// Start comprehensive trip tracking
  static Future<bool> startTripTracking({
    required Trip trip,
    Function(Trip, ETAInfo)? onTripUpdate,
    Function(Trip, String)? onTripError,
    Function(Trip, Position)? onLocationUpdate,
    Function(Trip, ETAInfo)? onETAUpdate,
  }) async {
    try {
      if (_isTracking) {
        print('⚠️ Trip tracking already active');
        return true;
      }

      print(
        '🚌 TripTrackingService: Starting comprehensive trip tracking for ${trip.tripId}',
      );

      // Validate trip
      if (!_validateTrip(trip)) {
        print('❌ Invalid trip for tracking');
        return false;
      }

      // Set active trip and callbacks
      _activeTrip = trip;
      _onTripUpdate = onTripUpdate;
      _onTripError = onTripError;
      _onLocationUpdate = onLocationUpdate;
      _onETAUpdate = onETAUpdate;

      // Initialize location service
      final locationInitialized = await RealtimeLocationService.initialize();
      if (!locationInitialized) {
        print('❌ Failed to initialize location service');
        return false;
      }

      // Start location tracking
      final locationStarted = await RealtimeLocationService.startTracking(
        onLocationUpdate: _handleLocationUpdate,
        onLocationError: _handleLocationError,
        onSignificantLocationChange: _handleSignificantLocationChange,
      );

      if (!locationStarted) {
        print('❌ Failed to start location tracking');
        return false;
      }

      // Start ETA updates
      final etaStarted = await RealtimeETAUpdater.startETAUpdates(
        trip: trip,
        onETAUpdate: _handleETAUpdate,
        onETAError: _handleETAError,
        onSignificantETAChange: _handleSignificantETAChange,
      );

      if (!etaStarted) {
        print('❌ Failed to start ETA updates');
        await RealtimeLocationService.stopTracking();
        return false;
      }

      _isTracking = true;
      print('✅ TripTrackingService: Comprehensive tracking started');
      return true;
    } catch (e) {
      print('❌ TripTrackingService: Failed to start tracking: $e');
      await stopTripTracking();
      return false;
    }
  }

  /// Validate trip for tracking
  static bool _validateTrip(Trip trip) {
    if (trip.endLatitude == null || trip.endLongitude == null) {
      print('❌ Trip missing destination coordinates');
      return false;
    }

    if (trip.status != TripStatus.inProgress) {
      print('❌ Trip is not in progress');
      return false;
    }

    return true;
  }

  /// Handle location updates
  static void _handleLocationUpdate(Position position) {
    if (_activeTrip == null) return;

    print(
      '📍 TripTrackingService: Location update for trip ${_activeTrip!.tripId}',
    );
    print(
      '📍 Position: ${position.latitude}, ${position.longitude} (accuracy: ${position.accuracy}m)',
    );

    // Notify callback
    _onLocationUpdate?.call(_activeTrip!, position);

    // Update trip with current location if needed
    _updateTripLocation(position);
  }

  /// Handle location errors
  static void _handleLocationError(String error) {
    if (_activeTrip == null) return;

    print(
      '❌ TripTrackingService: Location error for trip ${_activeTrip!.tripId}: $error',
    );
    _onTripError?.call(_activeTrip!, 'Location error: $error');
  }

  /// Handle significant location changes
  static void _handleSignificantLocationChange(Position position) {
    if (_activeTrip == null) return;

    print(
      '📍 TripTrackingService: Significant location change for trip ${_activeTrip!.tripId}',
    );

    // Force ETA update on significant location change
    RealtimeETAUpdater.forceETAUpdate();
  }

  /// Handle ETA updates
  static void _handleETAUpdate(ETAInfo etaInfo) {
    if (_activeTrip == null) return;

    print('🕐 TripTrackingService: ETA update for trip ${_activeTrip!.tripId}');
    print(
      '🕐 ETA: ${etaInfo.formattedTimeToArrival} (${etaInfo.formattedDistance})',
    );

    // Notify callback
    _onETAUpdate?.call(_activeTrip!, etaInfo);
    _onTripUpdate?.call(_activeTrip!, etaInfo);
  }

  /// Handle ETA errors
  static void _handleETAError(String error) {
    if (_activeTrip == null) return;

    print(
      '❌ TripTrackingService: ETA error for trip ${_activeTrip!.tripId}: $error',
    );
    _onTripError?.call(_activeTrip!, 'ETA error: $error');
  }

  /// Handle significant ETA changes
  static void _handleSignificantETAChange(ETAInfo etaInfo) {
    if (_activeTrip == null) return;

    print(
      '🕐 TripTrackingService: Significant ETA change for trip ${_activeTrip!.tripId}',
    );
    print('🕐 New ETA: ${etaInfo.formattedTimeToArrival}');

    // Notify callback
    _onETAUpdate?.call(_activeTrip!, etaInfo);
    _onTripUpdate?.call(_activeTrip!, etaInfo);
  }

  /// Update trip with current location
  static void _updateTripLocation(Position position) {
    if (_activeTrip == null) return;

    // Update trip's current location (this would typically be sent to backend)
    print(
      '📍 Updating trip location: ${position.latitude}, ${position.longitude}',
    );

    // Here you would typically update the trip in your backend
    // For now, we'll just log the update
  }

  /// Stop trip tracking
  static Future<void> stopTripTracking() async {
    try {
      if (!_isTracking) {
        print('⚠️ Trip tracking not active');
        return;
      }

      print('🚌 TripTrackingService: Stopping trip tracking...');

      // Stop ETA updates
      RealtimeETAUpdater.stopETAUpdates();

      // Stop location tracking
      await RealtimeLocationService.stopTracking();

      // Clear state
      _activeTrip = null;
      _isTracking = false;

      // Clear callbacks
      _onTripUpdate = null;
      _onTripError = null;
      _onLocationUpdate = null;
      _onETAUpdate = null;

      print('✅ TripTrackingService: Trip tracking stopped');
    } catch (e) {
      print('❌ Error stopping trip tracking: $e');
    }
  }

  /// Get current trip
  static Trip? get activeTrip => _activeTrip;

  /// Get current ETA
  static ETAInfo? get currentETA => RealtimeETAUpdater.currentETA;

  /// Get current location
  static Position? get currentLocation =>
      RealtimeLocationService.currentPosition;

  /// Check if tracking is active
  static bool get isTracking => _isTracking;

  /// Get comprehensive tracking statistics
  static Map<String, dynamic> getTrackingStats() {
    final locationStats = RealtimeLocationService.getLocationStats();
    final etaStats = RealtimeETAUpdater.getETAStats();

    return {
      'is_tracking': _isTracking,
      'active_trip_id': _activeTrip?.tripId,
      'location_stats': locationStats,
      'eta_stats': etaStats,
      'tracking_duration_minutes': _activeTrip != null
          ? DateTime.now()
                .difference(_activeTrip!.actualStart ?? DateTime.now())
                .inMinutes
          : 0,
    };
  }

  /// Get route information for current trip
  static Future<Map<String, dynamic>?> getRouteInfo() async {
    if (_activeTrip == null) return null;
    return await RealtimeETAUpdater.getRouteInfo();
  }

  /// Force immediate location and ETA update
  static Future<void> forceUpdate() async {
    if (_isTracking) {
      print('🔄 TripTrackingService: Forcing immediate update...');
      await RealtimeETAUpdater.forceETAUpdate();
    }
  }

  /// Pause tracking (useful for battery optimization)
  static Future<void> pauseTracking() async {
    if (_isTracking) {
      print('⏸️ TripTrackingService: Pausing tracking...');
      await RealtimeLocationService.stopTracking();
      RealtimeETAUpdater.stopETAUpdates();
    }
  }

  /// Resume tracking
  static Future<bool> resumeTracking() async {
    if (_activeTrip == null) {
      print('❌ No active trip to resume tracking for');
      return false;
    }

    print('▶️ TripTrackingService: Resuming tracking...');
    return await startTripTracking(
      trip: _activeTrip!,
      onTripUpdate: _onTripUpdate,
      onTripError: _onTripError,
      onLocationUpdate: _onLocationUpdate,
      onETAUpdate: _onETAUpdate,
    );
  }
}
