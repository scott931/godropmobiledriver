import 'eta_service.dart';
import '../models/trip_model.dart';

/// Example usage of the enhanced ETA service with destination arrival duration
class ETAExample {
  /// Demonstrate enhanced ETA calculation with arrival duration
  static Future<void> demonstrateEnhancedETA() async {
    print('🚀 ETA Example: Demonstrating enhanced ETA calculation...');

    // Create a sample trip
    final trip = Trip(
      id: 1,
      tripId: 'TRP_EXAMPLE_001',
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
      notes: 'Example trip for ETA demonstration',
      createdAt: DateTime.now().subtract(Duration(hours: 2)),
      updatedAt: DateTime.now(),
    );

    // Current location (simulated)
    final currentLat = -1.2500000;
    final currentLng = 36.8500000;

    // Destination location
    final destinationLat = trip.endLatitude!;
    final destinationLng = trip.endLongitude!;

    try {
      // Calculate enhanced ETA
      final etaResult = await ETAService.calculateETA(
        currentLat: currentLat,
        currentLng: currentLng,
        destinationLat: destinationLat,
        destinationLng: destinationLng,
        trip: trip,
        routeName: 'Route 1',
        vehicleType: 'School Bus',
      );

      if (etaResult.success) {
        final etaInfo = etaResult.etaInfo;

        print('\n📊 Enhanced ETA Results:');
        print('========================');

        // Basic ETA information
        print('⏰ Estimated Arrival: ${etaInfo.estimatedArrival}');
        print('🕐 Time to Arrival: ${etaInfo.formattedTimeToArrival}');
        print('📏 Distance: ${etaInfo.formattedDistance}');
        print(
          '🚗 Current Speed: ${etaInfo.currentSpeed?.toStringAsFixed(1) ?? 'N/A'} km/h',
        );

        // Enhanced arrival duration information
        print('\n🎯 Destination Arrival Details:');
        print('==============================');
        print('⏱️ Arrival Duration: ${etaInfo.formattedArrivalDuration}');
        print('🚌 Departure Time: ${etaInfo.formattedDepartureTime}');
        print('📝 Process Description: ${etaInfo.arrivalProcessDescription}');
        print(
          '🔄 Total Trip Duration: ${etaInfo.totalTripDuration.inMinutes} minutes',
        );

        // Status information
        print('\n📋 Trip Status:');
        print('===============');
        print('⏰ Status: ${ETAService.getETAStatus(etaInfo)}');
        print('🚨 Delayed: ${etaInfo.isDelayed ? 'Yes' : 'No'}');
        if (etaInfo.delayReason != null) {
          print('📝 Delay Reason: ${etaInfo.delayReason}');
        }
        print(
          '🚦 Traffic Conditions: ${etaInfo.trafficMultiplier?.toStringAsFixed(2) ?? 'N/A'}',
        );

        // Enhanced ETA format
        print('\n🎯 Enhanced ETA Format:');
        print('========================');
        print('📱 Enhanced ETA: ${ETAService.formatEnhancedETA(etaInfo)}');

        // Comprehensive summary
        print('\n📊 Comprehensive ETA Summary:');
        print('==============================');
        final summary = ETAService.getETASummary(etaInfo);
        summary.forEach((key, value) {
          print('$key: $value');
        });
      } else {
        print('❌ ETA calculation failed: ${etaResult.error}');
      }
    } catch (e) {
      print('❌ Error in ETA demonstration: $e');
    }
  }

  /// Demonstrate different trip types and their arrival durations
  static Future<void> demonstrateTripTypeArrivalDurations() async {
    print(
      '\n🚌 ETA Example: Demonstrating arrival durations for different trip types...',
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
        tripId: 'TRP_${tripType.name.toUpperCase()}_001',
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
        notes: 'Example ${tripType.name} trip',
        createdAt: DateTime.now().subtract(Duration(hours: 1)),
        updatedAt: DateTime.now(),
      );

      try {
        final etaResult = await ETAService.calculateETA(
          currentLat: -1.2500000,
          currentLng: 36.8500000,
          destinationLat: trip.endLatitude!,
          destinationLng: trip.endLongitude!,
          trip: trip,
        );

        if (etaResult.success) {
          final etaInfo = etaResult.etaInfo;
          print('⏱️ Arrival Duration: ${etaInfo.formattedArrivalDuration}');
          print('📝 Process: ${etaInfo.arrivalProcessDescription}');
          print('🚌 Departure: ${etaInfo.formattedDepartureTime}');
        }
      } catch (e) {
        print('❌ Error calculating ETA for ${tripType.name}: $e');
      }
    }
  }
}
