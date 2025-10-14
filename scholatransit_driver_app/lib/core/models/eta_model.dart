class ETAInfo {
  final DateTime estimatedArrival;
  final double distance; // in meters
  final double? currentSpeed; // in km/h
  final bool isDelayed;
  final String? delayReason;
  final DateTime calculatedAt;
  final double? trafficMultiplier;
  final Duration?
  destinationArrivalDuration; // Duration to complete arrival process
  final DateTime?
  estimatedDepartureFromDestination; // When bus will leave destination
  final String? arrivalProcessDescription; // Description of arrival process

  const ETAInfo({
    required this.estimatedArrival,
    required this.distance,
    this.currentSpeed,
    required this.isDelayed,
    this.delayReason,
    required this.calculatedAt,
    this.trafficMultiplier,
    this.destinationArrivalDuration,
    this.estimatedDepartureFromDestination,
    this.arrivalProcessDescription,
  });

  Duration get timeToArrival {
    return estimatedArrival.difference(DateTime.now());
  }

  String get formattedTimeToArrival {
    final duration = timeToArrival;
    if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes % 60}m';
    } else {
      return '${duration.inMinutes}m';
    }
  }

  String get formattedDistance {
    if (distance >= 1000) {
      return '${(distance / 1000).toStringAsFixed(1)} km';
    } else {
      return '${distance.toStringAsFixed(0)} m';
    }
  }

  bool get isRunningLate => isDelayed;

  /// Get formatted destination arrival duration
  String get formattedArrivalDuration {
    if (destinationArrivalDuration == null) return 'Not calculated';

    final duration = destinationArrivalDuration!;
    if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes % 60}m';
    } else {
      return '${duration.inMinutes}m';
    }
  }

  /// Get formatted departure time from destination
  String get formattedDepartureTime {
    if (estimatedDepartureFromDestination == null) return 'Not calculated';

    final departure = estimatedDepartureFromDestination!;
    final hour = departure.hour.toString().padLeft(2, '0');
    final minute = departure.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  /// Get total trip duration including arrival process
  Duration get totalTripDuration {
    final arrivalTime = estimatedArrival;
    final departureTime = estimatedDepartureFromDestination ?? estimatedArrival;
    return departureTime.difference(arrivalTime);
  }

  ETAInfo copyWith({
    DateTime? estimatedArrival,
    double? distance,
    double? currentSpeed,
    bool? isDelayed,
    String? delayReason,
    DateTime? calculatedAt,
    double? trafficMultiplier,
    Duration? destinationArrivalDuration,
    DateTime? estimatedDepartureFromDestination,
    String? arrivalProcessDescription,
  }) {
    return ETAInfo(
      estimatedArrival: estimatedArrival ?? this.estimatedArrival,
      distance: distance ?? this.distance,
      currentSpeed: currentSpeed ?? this.currentSpeed,
      isDelayed: isDelayed ?? this.isDelayed,
      delayReason: delayReason ?? this.delayReason,
      calculatedAt: calculatedAt ?? this.calculatedAt,
      trafficMultiplier: trafficMultiplier ?? this.trafficMultiplier,
      destinationArrivalDuration:
          destinationArrivalDuration ?? this.destinationArrivalDuration,
      estimatedDepartureFromDestination:
          estimatedDepartureFromDestination ??
          this.estimatedDepartureFromDestination,
      arrivalProcessDescription:
          arrivalProcessDescription ?? this.arrivalProcessDescription,
    );
  }

  factory ETAInfo.fromJson(Map<String, dynamic> json) {
    return ETAInfo(
      estimatedArrival: DateTime.parse(json['estimated_arrival']),
      distance: json['distance']?.toDouble() ?? 0.0,
      currentSpeed: json['current_speed']?.toDouble(),
      isDelayed: json['is_delayed'] ?? false,
      delayReason: json['delay_reason'],
      calculatedAt: DateTime.parse(json['calculated_at']),
      trafficMultiplier: json['traffic_multiplier']?.toDouble(),
      destinationArrivalDuration: json['destination_arrival_duration'] != null
          ? Duration(minutes: json['destination_arrival_duration'])
          : null,
      estimatedDepartureFromDestination:
          json['estimated_departure_from_destination'] != null
          ? DateTime.parse(json['estimated_departure_from_destination'])
          : null,
      arrivalProcessDescription: json['arrival_process_description'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'estimated_arrival': estimatedArrival.toIso8601String(),
      'distance': distance,
      'current_speed': currentSpeed,
      'is_delayed': isDelayed,
      'delay_reason': delayReason,
      'calculated_at': calculatedAt.toIso8601String(),
      'traffic_multiplier': trafficMultiplier,
      'destination_arrival_duration': destinationArrivalDuration?.inMinutes,
      'estimated_departure_from_destination': estimatedDepartureFromDestination
          ?.toIso8601String(),
      'arrival_process_description': arrivalProcessDescription,
    };
  }

  @override
  String toString() {
    return 'ETAInfo(estimatedArrival: $estimatedArrival, distance: $distance, isDelayed: $isDelayed)';
  }
}

class ETACalculationRequest {
  final double currentLatitude;
  final double currentLongitude;
  final double destinationLatitude;
  final double destinationLongitude;
  final DateTime scheduledArrival;
  final String? routeName;
  final String? vehicleType;

  const ETACalculationRequest({
    required this.currentLatitude,
    required this.currentLongitude,
    required this.destinationLatitude,
    required this.destinationLongitude,
    required this.scheduledArrival,
    this.routeName,
    this.vehicleType,
  });

  factory ETACalculationRequest.fromTrip({
    required double currentLat,
    required double currentLng,
    required double destLat,
    required double destLng,
    required DateTime scheduledEnd,
    String? routeName,
    String? vehicleType,
  }) {
    return ETACalculationRequest(
      currentLatitude: currentLat,
      currentLongitude: currentLng,
      destinationLatitude: destLat,
      destinationLongitude: destLng,
      scheduledArrival: scheduledEnd,
      routeName: routeName,
      vehicleType: vehicleType,
    );
  }
}

class ETACalculationResult {
  final ETAInfo etaInfo;
  final bool success;
  final String? error;
  final Map<String, dynamic>? metadata;

  const ETACalculationResult({
    required this.etaInfo,
    required this.success,
    this.error,
    this.metadata,
  });

  factory ETACalculationResult.success(
    ETAInfo etaInfo, {
    Map<String, dynamic>? metadata,
  }) {
    return ETACalculationResult(
      etaInfo: etaInfo,
      success: true,
      metadata: metadata,
    );
  }

  factory ETACalculationResult.error(String error) {
    return ETACalculationResult(
      etaInfo: ETAInfo(
        estimatedArrival: DateTime.now().add(Duration(minutes: 30)),
        distance: 0.0,
        isDelayed: false,
        calculatedAt: DateTime.now(),
      ),
      success: false,
      error: error,
    );
  }
}
