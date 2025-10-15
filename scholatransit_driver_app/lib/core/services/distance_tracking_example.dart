import 'package:geolocator/geolocator.dart';
import '../models/trip_model.dart';
import 'realtime_distance_tracker.dart';
import 'realtime_location_service.dart';

/// Example usage of the real-time distance tracking system
class DistanceTrackingExample {
  /// Demonstrate real-time distance tracking
  static Future<void> demonstrateDistanceTracking() async {
    print(
      '📏 DistanceTrackingExample: Demonstrating real-time distance tracking...',
    );

    // Create a sample trip
    final trip = Trip(
      id: 1,
      tripId: 'TRP_DISTANCE_001',
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
      notes: 'Example trip for distance tracking',
      createdAt: DateTime.now().subtract(Duration(hours: 2)),
      updatedAt: DateTime.now(),
    );

    try {
      // Initialize location service
      print('\n📍 Initializing location service...');
      final locationInitialized = await RealtimeLocationService.initialize();
      if (!locationInitialized) {
        print('❌ Failed to initialize location service');
        return;
      }

      // Start location tracking
      print('\n📍 Starting location tracking...');
      final locationStarted = await RealtimeLocationService.startTracking(
        onLocationUpdate: _handleLocationUpdate,
        onLocationError: _handleLocationError,
        onSignificantLocationChange: _handleSignificantLocationChange,
      );

      if (!locationStarted) {
        print('❌ Failed to start location tracking');
        return;
      }

      // Start distance tracking
      print('\n📏 Starting distance tracking...');
      final distanceStarted =
          await RealtimeDistanceTracker.startDistanceTracking(
            trip: trip,
            onDistanceUpdate: _handleDistanceUpdate,
            onDistanceError: _handleDistanceError,
            onProgressUpdate: _handleProgressUpdate,
          );

      if (!distanceStarted) {
        print('❌ Failed to start distance tracking');
        return;
      }

      print('✅ Distance tracking started successfully!');
      print('📱 Real-time distance updates will be displayed...');

      // Simulate tracking for a few minutes
      print('\n⏱️ Simulating tracking for 3 minutes...');
      await Future.delayed(Duration(minutes: 3));

      // Display final statistics
      print('\n📊 Final Distance Statistics:');
      print('============================');
      final distanceInfo = RealtimeDistanceTracker.getDistanceInfo();
      distanceInfo.forEach((key, value) {
        print('$key: $value');
      });

      // Display formatted distances
      print('\n📏 Formatted Distances:');
      print('=======================');
      final formattedDistances =
          RealtimeDistanceTracker.getFormattedDistances();
      formattedDistances.forEach((key, value) {
        print('$key: $value');
      });

      // Stop tracking
      print('\n🛑 Stopping distance tracking...');
      RealtimeDistanceTracker.stopDistanceTracking();
      await RealtimeLocationService.stopTracking();
      print('✅ Distance tracking stopped');
    } catch (e) {
      print('❌ Error in distance tracking demonstration: $e');
    }
  }

  /// Handle location updates
  static void _handleLocationUpdate(Position position) {
    print('\n📍 Location Update:');
    print('===================');
    print('Position: ${position.latitude}, ${position.longitude}');
    print('Accuracy: ${position.accuracy}m');
    print('Speed: ${position.speed.toStringAsFixed(1)} m/s');
    print('Timestamp: ${position.timestamp}');
  }

  /// Handle location errors
  static void _handleLocationError(String error) {
    print('\n❌ Location Error:');
    print('==================');
    print('Error: $error');
  }

  /// Handle significant location changes
  static void _handleSignificantLocationChange(Position position) {
    print('\n📍 Significant Location Change:');
    print('===============================');
    print('New Position: ${position.latitude}, ${position.longitude}');
    print('Accuracy: ${position.accuracy}m');
  }

  /// Handle distance updates
  static void _handleDistanceUpdate(
    double remaining,
    double traveled,
    double total,
  ) {
    print('\n📏 Distance Update:');
    print('===================');
    print('Remaining Distance: ${(remaining / 1000).toStringAsFixed(2)} km');
    print('Distance Traveled: ${(traveled / 1000).toStringAsFixed(2)} km');
    print('Total Trip Distance: ${(total / 1000).toStringAsFixed(2)} km');

    // Calculate progress percentage
    final progress = total > 0
        ? (traveled / total * 100).clamp(0.0, 100.0)
        : 0.0;
    print('Progress: ${progress.toStringAsFixed(1)}%');
  }

  /// Handle distance errors
  static void _handleDistanceError(String error) {
    print('\n❌ Distance Error:');
    print('===================');
    print('Error: $error');
  }

  /// Handle progress updates
  static void _handleProgressUpdate(double progress) {
    print('\n📊 Progress Update:');
    print('===================');
    print('Trip Progress: ${progress.toStringAsFixed(1)}%');

    // Show progress bar visualization
    final progressBar = _createProgressBar(progress);
    print('Progress Bar: $progressBar');
  }

  /// Create a visual progress bar
  static String _createProgressBar(double progress) {
    const int barLength = 20;
    final int filledLength = (progress / 100 * barLength).round();
    final int emptyLength = barLength - filledLength;

    final String filled = '█' * filledLength;
    final String empty = '░' * emptyLength;

    return '[$filled$empty]';
  }

  /// Demonstrate different trip scenarios
  static Future<void> demonstrateTripScenarios() async {
    print(
      '\n🚌 DistanceTrackingExample: Demonstrating different trip scenarios...',
    );

    final scenarios = [
      {
        'name': 'Short Trip',
        'trip': Trip(
          id: 1,
          tripId: 'TRP_SHORT_001',
          driverId: 1,
          vehicleId: 1,
          routeId: 1,
          type: TripType.pickup,
          status: TripStatus.inProgress,
          startLatitude: -1.2210399,
          startLongitude: 36.9192349,
          endLatitude: -1.2300000,
          endLongitude: 36.9200000,
          scheduledStart: DateTime.now(),
          scheduledEnd: DateTime.now().add(Duration(hours: 1)),
          actualStart: DateTime.now(),
          notes: 'Short trip scenario',
          createdAt: DateTime.now().subtract(Duration(hours: 1)),
          updatedAt: DateTime.now(),
        ),
      },
      {
        'name': 'Long Trip',
        'trip': Trip(
          id: 2,
          tripId: 'TRP_LONG_001',
          driverId: 1,
          vehicleId: 1,
          routeId: 1,
          type: TripType.dropoff,
          status: TripStatus.inProgress,
          startLatitude: -1.2210399,
          startLongitude: 36.9192349,
          endLatitude: -1.3500000,
          endLongitude: 36.7000000,
          scheduledStart: DateTime.now(),
          scheduledEnd: DateTime.now().add(Duration(hours: 3)),
          actualStart: DateTime.now(),
          notes: 'Long trip scenario',
          createdAt: DateTime.now().subtract(Duration(hours: 1)),
          updatedAt: DateTime.now(),
        ),
      },
    ];

    for (final scenario in scenarios) {
      print('\n📋 Scenario: ${scenario['name']}');
      print('===============================');

      final trip = scenario['trip'] as Trip;

      try {
        // Start distance tracking for this scenario
        final trackingStarted = await RealtimeDistanceTracker.startDistanceTracking(
          trip: trip,
          onDistanceUpdate: (remaining, traveled, total) {
            print(
              '${scenario['name']} - Remaining: ${(remaining / 1000).toStringAsFixed(2)} km',
            );
          },
          onDistanceError: (error) =>
              print('${scenario['name']} - Error: $error'),
          onProgressUpdate: (progress) => print(
            '${scenario['name']} - Progress: ${progress.toStringAsFixed(1)}%',
          ),
        );

        if (trackingStarted) {
          print('✅ ${scenario['name']} distance tracking started');

          // Simulate tracking for 30 seconds
          await Future.delayed(Duration(seconds: 30));

          // Stop tracking
          RealtimeDistanceTracker.stopDistanceTracking();
          print('✅ ${scenario['name']} distance tracking stopped');
        } else {
          print('❌ Failed to start ${scenario['name']} distance tracking');
        }
      } catch (e) {
        print('❌ Error in ${scenario['name']} scenario: $e');
      }
    }
  }

  /// Get comprehensive distance tracking statistics
  static Map<String, dynamic> getDistanceTrackingStatistics() {
    final distanceInfo = RealtimeDistanceTracker.getDistanceInfo();
    final locationStats = RealtimeLocationService.getLocationStats();
    final formattedDistances = RealtimeDistanceTracker.getFormattedDistances();

    return {
      'distance_tracking': distanceInfo,
      'location_tracking': locationStats,
      'formatted_distances': formattedDistances,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }
}
