import 'dart:async';
import 'package:geolocator/geolocator.dart';
import '../models/parent_trip_model.dart';
import '../models/parent_model.dart';
import 'api_service.dart';

class ParentTrackingService {
  static StreamSubscription<Position>? _locationSubscription;
  static final StreamController<ParentTrip> _tripController =
      StreamController<ParentTrip>.broadcast();
  static final StreamController<Map<String, dynamic>> _etaController =
      StreamController<Map<String, dynamic>>.broadcast();

  static Stream<ParentTrip> get tripStream => _tripController.stream;
  static Stream<Map<String, dynamic>> get etaStream => _etaController.stream;

  /// Get active trips for parent's children
  static Future<ApiResponse<List<ParentTrip>>> getActiveTrips() async {
    return ApiService.get<List<ParentTrip>>('/parent/trips/active/');
  }

  /// Get trip details with real-time location
  static Future<ApiResponse<ParentTrip>> getTripDetails(int tripId) async {
    return ApiService.get<ParentTrip>('/parent/trips/$tripId/');
  }

  /// Start real-time tracking for a trip
  static Future<bool> startTripTracking(int tripId) async {
    try {
      // Start location stream
      _locationSubscription =
          Geolocator.getPositionStream(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.medium,
              distanceFilter: 50,
            ),
          ).listen((position) {
            _updateTripLocation(tripId, position);
          });

      // Start trip updates
      _startTripUpdates(tripId);
      return true;
    } catch (e) {
      print('❌ Failed to start trip tracking: $e');
      return false;
    }
  }

  /// Stop real-time tracking
  static Future<void> stopTripTracking() async {
    await _locationSubscription?.cancel();
    _locationSubscription = null;
  }

  /// Update trip location and calculate ETA
  static Future<void> _updateTripLocation(int tripId, Position position) async {
    try {
      // Get current trip data
      final response = await getTripDetails(tripId);
      if (response.success && response.data != null) {
        final trip = response.data!;

        // Calculate ETA to next stop
        final eta = await _calculateETA(position, trip);

        // Update trip with new location
        final updatedTrip = trip.copyWith(
          currentLatitude: position.latitude,
          currentLongitude: position.longitude,
          lastLocationUpdate: DateTime.now(),
          estimatedArrivalMinutes: eta,
        );

        _tripController.add(updatedTrip);
        _etaController.add({
          'trip_id': tripId,
          'eta_minutes': eta,
          'current_location': {
            'latitude': position.latitude,
            'longitude': position.longitude,
          },
          'timestamp': DateTime.now().toIso8601String(),
        });
      }
    } catch (e) {
      print('❌ Failed to update trip location: $e');
    }
  }

  /// Start periodic trip updates
  static void _startTripUpdates(int tripId) {
    Timer.periodic(const Duration(seconds: 30), (timer) async {
      try {
        final response = await getTripDetails(tripId);
        if (response.success && response.data != null) {
          _tripController.add(response.data!);
        }
      } catch (e) {
        print('❌ Failed to update trip: $e');
      }
    });
  }

  /// Calculate ETA to next stop
  static Future<int> _calculateETA(
    Position currentPosition,
    ParentTrip trip,
  ) async {
    try {
      if (trip.stops.isEmpty) return 0;

      // Find next uncompleted stop
      final nextStop = trip.stops.firstWhere(
        (stop) => !stop.isCompleted,
        orElse: () => trip.stops.last,
      );

      // Calculate distance to next stop
      final distance = Geolocator.distanceBetween(
        currentPosition.latitude,
        currentPosition.longitude,
        nextStop.latitude,
        nextStop.longitude,
      );

      // Estimate time based on distance (assuming average speed of 30 km/h)
      final estimatedMinutes = (distance / 500)
          .round(); // 500 meters per minute
      return estimatedMinutes.clamp(0, 120); // Cap at 2 hours
    } catch (e) {
      print('❌ Failed to calculate ETA: $e');
      return 0;
    }
  }

  /// Get trip history for parent's children
  static Future<ApiResponse<List<ParentTrip>>> getTripHistory({
    DateTime? startDate,
    DateTime? endDate,
    int? limit,
  }) async {
    final queryParams = <String, dynamic>{};
    if (startDate != null)
      queryParams['start_date'] = startDate.toIso8601String();
    if (endDate != null) queryParams['end_date'] = endDate.toIso8601String();
    if (limit != null) queryParams['limit'] = limit;

    return ApiService.get<List<ParentTrip>>(
      '/parent/trips/history/',
      queryParameters: queryParams,
    );
  }

  /// Get child's current status
  static Future<ApiResponse<Map<String, dynamic>>> getChildStatus(
    int childId,
  ) async {
    return ApiService.get<Map<String, dynamic>>(
      '/parent/children/$childId/status/',
    );
  }

  /// Get route information for parent's children
  static Future<ApiResponse<Map<String, dynamic>>> getRouteInfo(
    int routeId,
  ) async {
    return ApiService.get<Map<String, dynamic>>('/parent/routes/$routeId/');
  }

  /// Get driver information
  static Future<ApiResponse<Map<String, dynamic>>> getDriverInfo(
    int driverId,
  ) async {
    return ApiService.get<Map<String, dynamic>>('/parent/drivers/$driverId/');
  }

  /// Dispose resources
  static Future<void> dispose() async {
    await _locationSubscription?.cancel();
    await _tripController.close();
    await _etaController.close();
  }
}

// Extension to add copyWith method to ParentTrip
extension ParentTripCopyWith on ParentTrip {
  ParentTrip copyWith({
    int? id,
    String? tripName,
    String? routeName,
    String? driverName,
    String? driverPhone,
    String? driverPhoto,
    DateTime? scheduledStartTime,
    DateTime? scheduledEndTime,
    DateTime? actualStartTime,
    DateTime? actualEndTime,
    TripStatus? status,
    List<Child>? children,
    String? busNumber,
    String? busColor,
    double? currentLatitude,
    double? currentLongitude,
    String? currentAddress,
    DateTime? lastLocationUpdate,
    int? estimatedArrivalMinutes,
    List<TripStop>? stops,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ParentTrip(
      id: id ?? this.id,
      tripName: tripName ?? this.tripName,
      routeName: routeName ?? this.routeName,
      driverName: driverName ?? this.driverName,
      driverPhone: driverPhone ?? this.driverPhone,
      driverPhoto: driverPhoto ?? this.driverPhoto,
      scheduledStartTime: scheduledStartTime ?? this.scheduledStartTime,
      scheduledEndTime: scheduledEndTime ?? this.scheduledEndTime,
      actualStartTime: actualStartTime ?? this.actualStartTime,
      actualEndTime: actualEndTime ?? this.actualEndTime,
      status: status ?? this.status,
      children: children ?? this.children,
      busNumber: busNumber ?? this.busNumber,
      busColor: busColor ?? this.busColor,
      currentLatitude: currentLatitude ?? this.currentLatitude,
      currentLongitude: currentLongitude ?? this.currentLongitude,
      currentAddress: currentAddress ?? this.currentAddress,
      lastLocationUpdate: lastLocationUpdate ?? this.lastLocationUpdate,
      estimatedArrivalMinutes:
          estimatedArrivalMinutes ?? this.estimatedArrivalMinutes,
      stops: stops ?? this.stops,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
