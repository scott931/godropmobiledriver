import 'dart:async';
import 'dart:math';
import 'package:geolocator/geolocator.dart';
import '../models/eta_model.dart';
import '../models/trip_model.dart';
import 'location_service.dart';
import 'traffic_service.dart';

class ETAService {
  static final List<Position> _recentPositions = [];
  static const int _maxRecentPositions = 10;
  static const double _defaultSpeedKmh = 30.0; // Default speed for school buses
  static const double _maxSpeedKmh = 80.0; // Maximum speed for school buses

  /// Calculate ETA for a trip based on current location and destination
  static Future<ETACalculationResult> calculateETA({
    required double currentLat,
    required double currentLng,
    required double destinationLat,
    required double destinationLng,
    required Trip trip,
    String? routeName,
    String? vehicleType,
  }) async {
    try {
      print('🚀 ETA Service: Calculating ETA for trip ${trip.tripId}');

      // Calculate distance
      final distance = LocationService.calculateDistance(
        currentLat,
        currentLng,
        destinationLat,
        destinationLng,
      );

      print(
        '📏 ETA Service: Distance: ${(distance / 1000).toStringAsFixed(2)} km',
      );

      // Get current speed
      final currentSpeed = await _getCurrentSpeed();
      print(
        '🚗 ETA Service: Current speed: ${currentSpeed?.toStringAsFixed(1)} km/h',
      );

      // Get traffic multiplier
      final trafficMultiplier = await TrafficService.getTrafficMultiplier(
        startLat: currentLat,
        startLng: currentLng,
        endLat: destinationLat,
        endLng: destinationLng,
      );
      print(
        '🚦 ETA Service: Traffic multiplier: ${trafficMultiplier.toStringAsFixed(2)}',
      );

      // Calculate estimated travel time
      final estimatedTravelTime = _calculateTravelTime(
        distance: distance,
        currentSpeed: currentSpeed,
        trafficMultiplier: trafficMultiplier,
        trip: trip,
      );

      // Calculate estimated arrival time
      final estimatedArrival = DateTime.now().add(estimatedTravelTime);

      // Check if delayed
      final isDelayed = estimatedArrival.isAfter(trip.scheduledEnd);
      final delayReason = isDelayed
          ? _getDelayReason(estimatedArrival, trip.scheduledEnd)
          : null;

      // Calculate destination arrival duration
      final arrivalDurationInfo = _calculateDestinationArrivalDuration(
        trip: trip,
        distance: distance,
        trafficMultiplier: trafficMultiplier,
      );

      final etaInfo = ETAInfo(
        estimatedArrival: estimatedArrival,
        distance: distance,
        currentSpeed: currentSpeed,
        isDelayed: isDelayed,
        delayReason: delayReason,
        calculatedAt: DateTime.now(),
        trafficMultiplier: trafficMultiplier,
        destinationArrivalDuration: arrivalDurationInfo['duration'],
        estimatedDepartureFromDestination: arrivalDurationInfo['departureTime'],
        arrivalProcessDescription: arrivalDurationInfo['description'],
      );

      print(
        '✅ ETA Service: ETA calculated - ${etaInfo.formattedTimeToArrival} (${isDelayed ? 'DELAYED' : 'ON TIME'})',
      );

      return ETACalculationResult.success(
        etaInfo,
        metadata: {
          'distance_km': distance / 1000,
          'traffic_multiplier': trafficMultiplier,
          'calculation_method': currentSpeed != null
              ? 'gps_based'
              : 'default_speed',
        },
      );
    } catch (e) {
      print('❌ ETA Service: Error calculating ETA: $e');
      return ETACalculationResult.error('Failed to calculate ETA: $e');
    }
  }

  /// Get current speed based on recent GPS positions
  static Future<double?> _getCurrentSpeed() async {
    try {
      // Add current position to recent positions
      final currentPosition = LocationService.currentPosition;
      if (currentPosition == null) return null;

      _recentPositions.add(currentPosition);

      // Keep only recent positions
      if (_recentPositions.length > _maxRecentPositions) {
        _recentPositions.removeAt(0);
      }

      // Need at least 2 positions to calculate speed
      if (_recentPositions.length < 2) return null;

      // Calculate speed from last two positions
      final lastPosition = _recentPositions[_recentPositions.length - 1];
      final secondLastPosition = _recentPositions[_recentPositions.length - 2];

      final distance = LocationService.calculateDistance(
        secondLastPosition.latitude,
        secondLastPosition.longitude,
        lastPosition.latitude,
        lastPosition.longitude,
      );

      final timeDiff = lastPosition.timestamp.difference(
        secondLastPosition.timestamp,
      );
      if (timeDiff.inSeconds == 0) return null;

      final speedMs = distance / timeDiff.inSeconds;
      final speedKmh = speedMs * 3.6; // Convert m/s to km/h

      // Filter out unrealistic speeds
      if (speedKmh > _maxSpeedKmh || speedKmh < 0) return null;

      return speedKmh;
    } catch (e) {
      print('❌ ETA Service: Error getting current speed: $e');
      return null;
    }
  }

  /// Calculate travel time based on distance, speed, and traffic
  static Duration _calculateTravelTime({
    required double distance,
    double? currentSpeed,
    required double trafficMultiplier,
    required Trip trip,
  }) {
    // Use current speed if available, otherwise use default speed
    final effectiveSpeed = currentSpeed ?? _defaultSpeedKmh;

    // Apply traffic multiplier
    final adjustedSpeed = effectiveSpeed / trafficMultiplier;

    // Ensure minimum speed for school buses
    final finalSpeed = max(adjustedSpeed, 10.0); // Minimum 10 km/h

    // Calculate time in seconds
    final timeInSeconds =
        (distance / 1000) / finalSpeed * 3600; // Convert to seconds

    // Add buffer time for school bus operations (stops, traffic lights, etc.)
    final bufferTime = _calculateBufferTime(distance, trip);

    return Duration(seconds: (timeInSeconds + bufferTime).round());
  }

  /// Calculate buffer time based on trip characteristics
  static double _calculateBufferTime(double distance, Trip trip) {
    double bufferMinutes = 0;

    // Base buffer time
    bufferMinutes += 5; // 5 minutes base buffer

    // Distance-based buffer
    final distanceKm = distance / 1000;
    bufferMinutes += distanceKm * 0.5; // 0.5 minutes per km

    // Trip type adjustments
    switch (trip.type) {
      case TripType.pickup:
        bufferMinutes += 10; // Extra time for student pickup
        break;
      case TripType.dropoff:
        bufferMinutes += 8; // Extra time for student dropoff
        break;
      case TripType.emergency:
        bufferMinutes -= 5; // Less buffer for emergency trips
        break;
      case TripType.scheduled:
        bufferMinutes += 5; // Standard buffer for scheduled trips
        break;
    }

    // Time of day adjustments
    final hour = DateTime.now().hour;
    if (hour >= 7 && hour <= 9) {
      bufferMinutes += 10; // Morning rush hour
    } else if (hour >= 15 && hour <= 17) {
      bufferMinutes += 8; // Afternoon rush hour
    }

    return bufferMinutes * 60; // Convert to seconds
  }

  /// Get delay reason for delayed trips
  static String? _getDelayReason(
    DateTime estimatedArrival,
    DateTime scheduledEnd,
  ) {
    final delayMinutes = estimatedArrival.difference(scheduledEnd).inMinutes;

    if (delayMinutes <= 5) {
      return 'Minor delay due to traffic';
    } else if (delayMinutes <= 15) {
      return 'Moderate delay due to traffic conditions';
    } else if (delayMinutes <= 30) {
      return 'Significant delay due to heavy traffic';
    } else {
      return 'Major delay due to traffic and road conditions';
    }
  }

  /// Calculate destination arrival duration based on trip type and characteristics
  static Map<String, dynamic> _calculateDestinationArrivalDuration({
    required Trip trip,
    required double distance,
    required double trafficMultiplier,
  }) {
    try {
      print(
        '🕐 ETA Service: Calculating destination arrival duration for trip ${trip.tripId}',
      );

      // Base arrival duration in minutes
      double baseArrivalDuration = 0;

      // Trip type specific durations
      switch (trip.type) {
        case TripType.pickup:
          baseArrivalDuration = _calculatePickupArrivalDuration(trip, distance);
          break;
        case TripType.dropoff:
          baseArrivalDuration = _calculateDropoffArrivalDuration(
            trip,
            distance,
          );
          break;
        case TripType.emergency:
          baseArrivalDuration = _calculateEmergencyArrivalDuration(
            trip,
            distance,
          );
          break;
        case TripType.scheduled:
          baseArrivalDuration = _calculateScheduledArrivalDuration(
            trip,
            distance,
          );
          break;
      }

      // Apply traffic multiplier to arrival duration
      final adjustedDuration = baseArrivalDuration * trafficMultiplier;

      // Add time-of-day adjustments
      final timeOfDayMultiplier = _getTimeOfDayArrivalMultiplier();
      final finalDuration = adjustedDuration * timeOfDayMultiplier;

      // Calculate departure time
      final arrivalTime = DateTime.now().add(
        Duration(minutes: finalDuration.round()),
      );
      final departureTime = arrivalTime.add(
        Duration(minutes: finalDuration.round()),
      );

      // Generate description
      final description = _generateArrivalProcessDescription(
        trip,
        finalDuration,
      );

      print(
        '✅ ETA Service: Arrival duration calculated: ${finalDuration.toStringAsFixed(1)} minutes',
      );
      print('📝 ETA Service: Process description: $description');

      return {
        'duration': Duration(minutes: finalDuration.round()),
        'departureTime': departureTime,
        'description': description,
      };
    } catch (e) {
      print('❌ ETA Service: Error calculating arrival duration: $e');
      return {
        'duration': Duration(minutes: 15), // Default 15 minutes
        'departureTime': DateTime.now().add(Duration(minutes: 30)),
        'description': 'Standard arrival process',
      };
    }
  }

  /// Calculate pickup arrival duration
  static double _calculatePickupArrivalDuration(Trip trip, double distance) {
    double duration = 20; // Base 20 minutes for pickup

    // Distance-based adjustments
    final distanceKm = distance / 1000;
    if (distanceKm > 10) {
      duration += 5; // Extra time for longer distances
    }

    // Add time for student boarding process
    duration += 10; // 10 minutes for student boarding

    // Add time for safety checks
    duration += 5; // 5 minutes for safety checks

    return duration;
  }

  /// Calculate dropoff arrival duration
  static double _calculateDropoffArrivalDuration(Trip trip, double distance) {
    double duration = 15; // Base 15 minutes for dropoff

    // Distance-based adjustments
    final distanceKm = distance / 1000;
    if (distanceKm > 10) {
      duration += 3; // Extra time for longer distances
    }

    // Add time for student disembarking process
    duration += 8; // 8 minutes for student disembarking

    // Add time for safety checks
    duration += 3; // 3 minutes for safety checks

    return duration;
  }

  /// Calculate emergency arrival duration
  static double _calculateEmergencyArrivalDuration(Trip trip, double distance) {
    double duration = 5; // Base 5 minutes for emergency (minimal process)

    // Emergency trips have minimal arrival process
    duration += 2; // 2 minutes for emergency procedures

    return duration;
  }

  /// Calculate scheduled arrival duration
  static double _calculateScheduledArrivalDuration(Trip trip, double distance) {
    double duration = 12; // Base 12 minutes for scheduled trips

    // Distance-based adjustments
    final distanceKm = distance / 1000;
    if (distanceKm > 10) {
      duration += 4; // Extra time for longer distances
    }

    // Add time for standard procedures
    duration += 6; // 6 minutes for standard procedures

    return duration;
  }

  /// Get time-of-day multiplier for arrival duration
  static double _getTimeOfDayArrivalMultiplier() {
    final hour = DateTime.now().hour;

    // Rush hour adjustments
    if (hour >= 7 && hour <= 9) {
      return 1.3; // 30% longer during morning rush
    } else if (hour >= 15 && hour <= 17) {
      return 1.2; // 20% longer during afternoon rush
    } else if (hour >= 22 || hour <= 6) {
      return 0.8; // 20% shorter during night hours
    }

    return 1.0; // Normal duration
  }

  /// Generate arrival process description
  static String _generateArrivalProcessDescription(Trip trip, double duration) {
    final durationMinutes = duration.round();

    switch (trip.type) {
      case TripType.pickup:
        return 'Student pickup process: Arrival, boarding, safety checks (${durationMinutes}min)';
      case TripType.dropoff:
        return 'Student dropoff process: Arrival, disembarking, safety checks (${durationMinutes}min)';
      case TripType.emergency:
        return 'Emergency arrival process: Quick arrival and emergency procedures (${durationMinutes}min)';
      case TripType.scheduled:
        return 'Scheduled arrival process: Standard arrival and procedures (${durationMinutes}min)';
    }
  }

  /// Calculate ETA for multiple waypoints (useful for multi-stop trips)
  static Future<List<ETACalculationResult>> calculateMultiStopETA({
    required double currentLat,
    required double currentLng,
    required List<Map<String, dynamic>> waypoints,
    required Trip trip,
  }) async {
    final results = <ETACalculationResult>[];
    double currentLatitude = currentLat;
    double currentLongitude = currentLng;

    for (final waypoint in waypoints) {
      final result = await calculateETA(
        currentLat: currentLatitude,
        currentLng: currentLongitude,
        destinationLat: waypoint['latitude'],
        destinationLng: waypoint['longitude'],
        trip: trip,
        routeName: waypoint['name'],
      );

      results.add(result);

      // Update current position for next calculation
      if (result.success) {
        currentLatitude = waypoint['latitude'];
        currentLongitude = waypoint['longitude'];
      }
    }

    return results;
  }

  /// Get ETA accuracy based on recent calculations
  static double getETAAccuracy(List<ETAInfo> recentETAs) {
    if (recentETAs.length < 2) return 0.0;

    double totalError = 0.0;
    int validComparisons = 0;

    for (int i = 1; i < recentETAs.length; i++) {
      final previous = recentETAs[i - 1];
      final current = recentETAs[i];

      final timeDiff = current.calculatedAt
          .difference(previous.calculatedAt)
          .inMinutes;
      if (timeDiff > 0) {
        final expectedArrival = previous.estimatedArrival.add(
          Duration(minutes: timeDiff),
        );
        final actualError = current.estimatedArrival
            .difference(expectedArrival)
            .inMinutes
            .abs();
        totalError += actualError;
        validComparisons++;
      }
    }

    if (validComparisons == 0) return 0.0;

    final averageError = totalError / validComparisons;
    final accuracy = max(
      0.0,
      100.0 - (averageError * 2),
    ); // Convert to percentage

    return accuracy;
  }

  /// Clear recent positions (useful for testing or reset)
  static void clearRecentPositions() {
    _recentPositions.clear();
  }

  /// Get current ETA status for display
  static String getETAStatus(ETAInfo etaInfo) {
    if (etaInfo.isDelayed) {
      return 'Delayed';
    } else if (etaInfo.timeToArrival.inMinutes <= 5) {
      return 'Arriving Soon';
    } else if (etaInfo.timeToArrival.inMinutes <= 15) {
      return 'On Time';
    } else {
      return 'Scheduled';
    }
  }

  /// Format ETA for display
  static String formatETA(ETAInfo etaInfo) {
    final now = DateTime.now();
    final arrival = etaInfo.estimatedArrival;

    if (arrival.isBefore(now)) {
      return 'Overdue';
    }

    final duration = etaInfo.timeToArrival;

    if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes % 60}m';
    } else {
      return '${duration.inMinutes}m';
    }
  }

  /// Format enhanced ETA with arrival duration information
  static String formatEnhancedETA(ETAInfo etaInfo) {
    final basicETA = formatETA(etaInfo);
    final arrivalDuration = etaInfo.formattedArrivalDuration;
    final departureTime = etaInfo.formattedDepartureTime;

    return '$basicETA (Arrival: $arrivalDuration, Departure: $departureTime)';
  }

  /// Get comprehensive ETA summary
  static Map<String, dynamic> getETASummary(ETAInfo etaInfo) {
    return {
      'estimated_arrival': etaInfo.estimatedArrival.toIso8601String(),
      'time_to_arrival': etaInfo.formattedTimeToArrival,
      'distance': etaInfo.formattedDistance,
      'arrival_duration': etaInfo.formattedArrivalDuration,
      'departure_time': etaInfo.formattedDepartureTime,
      'total_trip_duration': etaInfo.totalTripDuration.inMinutes,
      'arrival_process': etaInfo.arrivalProcessDescription,
      'is_delayed': etaInfo.isDelayed,
      'delay_reason': etaInfo.delayReason,
      'traffic_conditions': etaInfo.trafficMultiplier != null
          ? 'Traffic multiplier: ${etaInfo.trafficMultiplier!.toStringAsFixed(2)}'
          : 'Traffic data unavailable',
    };
  }
}
