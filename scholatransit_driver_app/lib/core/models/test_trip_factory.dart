import 'trip_model.dart';
import '../config/app_config.dart';

/// Dev-only synthetic trips for [AppConfig.seedTestActiveTrip].
///
/// Enable: `flutter run --dart-define=TEST_ACTIVE_TRIP=true`
/// Optional: `--dart-define=TEST_TRIP_VARIANT=pending` for a not-yet-started trip.
class TestTripFactory {
  TestTripFactory._();

  static double get _startLat => AppConfig.defaultLatitude;
  static double get _startLng => AppConfig.defaultLongitude;
  static double get _endLat => AppConfig.defaultLatitude + 0.04;
  static double get _endLng => AppConfig.defaultLongitude + 0.04;

  /// In-progress trip aligned with [driverId] and [AppConfig] default map center.
  static Trip activeTrip({required int driverId}) {
    final now = DateTime.now();
    final start = now.subtract(const Duration(minutes: 5));
    final end = now.add(const Duration(hours: 2));
    final eta = now.add(const Duration(minutes: 25));
    return Trip(
      id: 900001,
      tripId: 'TEST_ACTIVE_TRIP',
      driverId: driverId,
      driverName: 'Test driver',
      vehicleId: 1,
      vehicleName: 'Test vehicle',
      routeId: 1,
      routeName: 'Test route (dev)',
      status: TripStatus.inProgress,
      type: TripType.scheduled,
      scheduledStart: start,
      scheduledEnd: end,
      actualStart: start,
      actualEnd: null,
      startLocation: 'Test start (Nairobi area)',
      endLocation: 'Test school drop-off',
      currentLocation: 'En route (simulated)',
      startLatitude: _startLat,
      startLongitude: _startLng,
      endLatitude: _endLat,
      endLongitude: _endLng,
      notes: 'Synthetic trip — TEST_ACTIVE_TRIP',
      distance: 8200,
      duration: 25,
      createdAt: now,
      updatedAt: now,
      estimatedArrival: eta,
      currentSpeed: 32,
      etaIsDelayed: false,
      etaStatus: 'On Time',
      trafficMultiplier: 1.05,
      etaLastUpdated: now,
    );
  }

  /// Scheduled trip not yet started — for testing start-trip and list UI.
  static Trip pendingTrip({required int driverId}) {
    final now = DateTime.now();
    final scheduledStart = now.add(const Duration(minutes: 10));
    final scheduledEnd = scheduledStart.add(const Duration(hours: 1));
    return Trip(
      id: 900002,
      tripId: 'TEST_PENDING_TRIP',
      driverId: driverId,
      driverName: 'Test driver',
      vehicleId: 1,
      vehicleName: 'Test vehicle',
      routeId: 1,
      routeName: 'Test route (dev)',
      status: TripStatus.pending,
      type: TripType.pickup,
      scheduledStart: scheduledStart,
      scheduledEnd: scheduledEnd,
      actualStart: null,
      actualEnd: null,
      startLocation: 'Test pickup point',
      endLocation: 'Test school',
      startLatitude: _startLat,
      startLongitude: _startLng,
      endLatitude: _endLat,
      endLongitude: _endLng,
      notes: 'Synthetic trip — TEST_TRIP_VARIANT=pending',
      createdAt: now,
      updatedAt: now,
    );
  }
}
