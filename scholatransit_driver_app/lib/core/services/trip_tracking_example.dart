import 'package:geolocator/geolocator.dart';
import '../models/trip_model.dart';
import '../models/eta_model.dart';
import 'trip_tracking_service.dart';
import 'realtime_location_service.dart';
import 'realtime_eta_updater.dart';
import 'background_location_service.dart';

/// Example usage of the comprehensive trip tracking system
class TripTrackingExample {
  /// Demonstrate complete trip tracking with real-time ETA updates
  static Future<void> demonstrateTripTracking() async {
    print(
      '🚌 TripTrackingExample: Demonstrating comprehensive trip tracking...',
    );

    // Create a sample trip
    final trip = Trip(
      id: 1,
      tripId: 'TRP_TRACKING_001',
      driverId: 1,
      vehicleId: 1,
      routeId: 1,
      type: TripType.pickup,
      status: TripStatus.inProgress,
      startLatitude: -1.2210399,
      startLongitude: 36.9192349,
      endLatitude: -1.2921000,
      endLongitude: 36.8219000,
      scheduledStart: DateTime.now().subtract(Duration(hours: 1)),
      scheduledEnd: DateTime.now().add(Duration(hours: 2)),
      actualStart: DateTime.now().subtract(Duration(minutes: 30)),
      notes: 'Example trip for comprehensive tracking',
      createdAt: DateTime.now().subtract(Duration(hours: 2)),
      updatedAt: DateTime.now(),
    );

    try {
      // Initialize background location service
      print('\n🌙 Initializing background location service...');
      final backgroundInitialized =
          await BackgroundLocationService.initialize();
      if (!backgroundInitialized) {
        print('❌ Failed to initialize background location service');
        return;
      }

      // Check and request permissions
      print('\n📍 Checking location permissions...');
      final permissions =
          await BackgroundLocationService.getLocationPermissions();
      print('📍 Permission status: $permissions');

      if (!permissions['location_permission_granted']!) {
        print('📍 Requesting location permissions...');
        final permissionGranted =
            await BackgroundLocationService.requestLocationPermissions();
        if (!permissionGranted) {
          print('❌ Location permission denied');
          return;
        }
      }

      // Start comprehensive trip tracking
      print('\n🚌 Starting comprehensive trip tracking...');
      final trackingStarted = await TripTrackingService.startTripTracking(
        trip: trip,
        onTripUpdate: _handleTripUpdate,
        onTripError: _handleTripError,
        onLocationUpdate: _handleLocationUpdate,
        onETAUpdate: _handleETAUpdate,
      );

      if (!trackingStarted) {
        print('❌ Failed to start trip tracking');
        return;
      }

      print('✅ Trip tracking started successfully!');
      print(
        '📱 You can now minimize the app - tracking will continue in background',
      );

      // Simulate tracking for a few minutes
      print('\n⏱️ Simulating tracking for 2 minutes...');
      await Future.delayed(Duration(minutes: 2));

      // Display tracking statistics
      print('\n📊 Tracking Statistics:');
      print('======================');
      final stats = TripTrackingService.getTrackingStats();
      stats.forEach((key, value) {
        print('$key: $value');
      });

      // Get route information
      print('\n🗺️ Route Information:');
      print('====================');
      final routeInfo = await TripTrackingService.getRouteInfo();
      if (routeInfo != null) {
        print('Distance: ${routeInfo['distance_km']?.toStringAsFixed(2)} km');
        print(
          'Duration: ${routeInfo['duration_minutes']?.toStringAsFixed(1)} minutes',
        );
        print('Route points: ${routeInfo['coordinates_count']}');
      }

      // Stop tracking
      print('\n🛑 Stopping trip tracking...');
      await TripTrackingService.stopTripTracking();
      print('✅ Trip tracking stopped');
    } catch (e) {
      print('❌ Error in trip tracking demonstration: $e');
    }
  }

  /// Handle trip updates
  static void _handleTripUpdate(Trip trip, ETAInfo etaInfo) {
    print('\n🔄 Trip Update:');
    print('===============');
    print('Trip ID: ${trip.tripId}');
    print('ETA: ${etaInfo.formattedTimeToArrival}');
    print('Distance: ${etaInfo.formattedDistance}');
    print('Arrival Duration: ${etaInfo.formattedArrivalDuration}');
    print('Departure Time: ${etaInfo.formattedDepartureTime}');
    print('Status: ${etaInfo.isDelayed ? 'DELAYED' : 'ON TIME'}');
    if (etaInfo.delayReason != null) {
      print('Delay Reason: ${etaInfo.delayReason}');
    }
  }

  /// Handle trip errors
  static void _handleTripError(Trip trip, String error) {
    print('\n❌ Trip Error:');
    print('==============');
    print('Trip ID: ${trip.tripId}');
    print('Error: $error');
  }

  /// Handle location updates
  static void _handleLocationUpdate(Trip trip, Position position) {
    print('\n📍 Location Update:');
    print('===================');
    print('Trip ID: ${trip.tripId}');
    print('Position: ${position.latitude}, ${position.longitude}');
    print('Accuracy: ${position.accuracy}m');
    print('Speed: ${position.speed.toStringAsFixed(1)} m/s');
    print('Timestamp: ${position.timestamp}');
  }

  /// Handle ETA updates
  static void _handleETAUpdate(Trip trip, ETAInfo etaInfo) {
    print('\n🕐 ETA Update:');
    print('==============');
    print('Trip ID: ${trip.tripId}');
    print('Estimated Arrival: ${etaInfo.estimatedArrival}');
    print('Time to Arrival: ${etaInfo.formattedTimeToArrival}');
    print('Distance: ${etaInfo.formattedDistance}');
    print(
      'Current Speed: ${etaInfo.currentSpeed?.toStringAsFixed(1) ?? 'N/A'} km/h',
    );
    print(
      'Traffic Conditions: ${etaInfo.trafficMultiplier?.toStringAsFixed(2) ?? 'N/A'}',
    );
    print('Arrival Process: ${etaInfo.arrivalProcessDescription}');
  }

  /// Demonstrate different trip types and their tracking characteristics
  static Future<void> demonstrateTripTypeTracking() async {
    print(
      '\n🚌 TripTrackingExample: Demonstrating tracking for different trip types...',
    );

    final tripTypes = [
      TripType.pickup,
      TripType.dropoff,
      TripType.emergency,
      TripType.scheduled,
    ];

    for (final tripType in tripTypes) {
      print('\n📋 Trip Type: ${tripType.name.toUpperCase()}');
      print('===============================');

      // Create sample trip for this type
      final trip = Trip(
        id: 1,
        tripId: 'TRP_${tripType.name.toUpperCase()}_TRACKING',
        driverId: 1,
        vehicleId: 1,
        routeId: 1,
        type: tripType,
        status: TripStatus.inProgress,
        startLatitude: -1.2210399,
        startLongitude: 36.9192349,
        endLatitude: -1.2921000,
        endLongitude: 36.8219000,
        scheduledStart: DateTime.now(),
        scheduledEnd: DateTime.now().add(Duration(hours: 2)),
        actualStart: DateTime.now(),
        notes: 'Example ${tripType.name} trip for tracking',
        createdAt: DateTime.now().subtract(Duration(hours: 1)),
        updatedAt: DateTime.now(),
      );

      try {
        // Start tracking for this trip type
        final trackingStarted = await TripTrackingService.startTripTracking(
          trip: trip,
          onTripUpdate: (trip, eta) => print(
            '${tripType.name} trip update: ${eta.formattedTimeToArrival}',
          ),
          onTripError: (trip, error) =>
              print('${tripType.name} trip error: $error'),
          onLocationUpdate: (trip, position) => print(
            '${tripType.name} location: ${position.latitude}, ${position.longitude}',
          ),
          onETAUpdate: (trip, eta) =>
              print('${tripType.name} ETA: ${eta.formattedTimeToArrival}'),
        );

        if (trackingStarted) {
          print('✅ ${tripType.name} trip tracking started');

          // Simulate tracking for 30 seconds
          await Future.delayed(Duration(seconds: 30));

          // Stop tracking
          await TripTrackingService.stopTripTracking();
          print('✅ ${tripType.name} trip tracking stopped');
        } else {
          print('❌ Failed to start ${tripType.name} trip tracking');
        }
      } catch (e) {
        print('❌ Error tracking ${tripType.name} trip: $e');
      }
    }
  }

  /// Demonstrate battery optimization features
  static Future<void> demonstrateBatteryOptimization() async {
    print('\n🔋 TripTrackingExample: Demonstrating battery optimization...');

    try {
      // Check battery optimization status
      final isOptimizationDisabled =
          await BackgroundLocationService.isBatteryOptimizationDisabled();
      print('🔋 Battery optimization disabled: $isOptimizationDisabled');

      if (!isOptimizationDisabled) {
        print('🔋 Requesting battery optimization exemption...');
        final exemptionGranted =
            await BackgroundLocationService.requestBatteryOptimizationExemption();
        print('🔋 Exemption granted: $exemptionGranted');
      }

      // Demonstrate app lifecycle handling
      print('\n📱 Demonstrating app lifecycle handling...');
      BackgroundLocationService.handleAppLifecycleChange('paused');
      await Future.delayed(Duration(seconds: 2));
      BackgroundLocationService.handleAppLifecycleChange('resumed');

      print('✅ Battery optimization demonstration completed');
    } catch (e) {
      print('❌ Error in battery optimization demonstration: $e');
    }
  }

  /// Get comprehensive tracking statistics
  static Map<String, dynamic> getTrackingStatistics() {
    final tripStats = TripTrackingService.getTrackingStats();
    final locationStats = RealtimeLocationService.getLocationStats();
    final etaStats = RealtimeETAUpdater.getETAStats();
    final backgroundStats = BackgroundLocationService.getBackgroundStats();

    return {
      'trip_tracking': tripStats,
      'location_tracking': locationStats,
      'eta_updates': etaStats,
      'background_location': backgroundStats,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }
}
