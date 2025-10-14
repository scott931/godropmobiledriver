import 'dart:math';

class TrafficService {
  static const double _baseTrafficMultiplier = 1.0;
  static const double _rushHourMultiplier = 1.5;
  static const double _lightTrafficMultiplier = 0.8;

  /// Get traffic multiplier based on time, location, and route characteristics
  static Future<double> getTrafficMultiplier({
    required double startLat,
    required double startLng,
    required double endLat,
    required double endLng,
    String? routeName,
    String? vehicleType,
  }) async {
    try {
      print('🚦 Traffic Service: Calculating traffic multiplier');

      // Base multiplier
      double multiplier = _baseTrafficMultiplier;

      // Time-based adjustments
      multiplier *= _getTimeBasedMultiplier();

      // Day of week adjustments
      multiplier *= _getDayOfWeekMultiplier();

      // Weather-based adjustments (simplified)
      multiplier *= _getWeatherMultiplier();

      // Route-specific adjustments
      multiplier *= _getRouteBasedMultiplier(routeName);

      // Vehicle type adjustments
      multiplier *= _getVehicleTypeMultiplier(vehicleType);

      // Ensure reasonable bounds
      multiplier = max(0.5, min(multiplier, 3.0));

      print(
        '🚦 Traffic Service: Final traffic multiplier: ${multiplier.toStringAsFixed(2)}',
      );

      return multiplier;
    } catch (e) {
      print('❌ Traffic Service: Error calculating traffic multiplier: $e');
      return _baseTrafficMultiplier;
    }
  }

  /// Get time-based traffic multiplier
  static double _getTimeBasedMultiplier() {
    final now = DateTime.now();
    final hour = now.hour;
    final minute = now.minute;
    final timeInMinutes = hour * 60 + minute;

    // Morning rush hour: 7:00 AM - 9:30 AM
    if (timeInMinutes >= 420 && timeInMinutes <= 570) {
      return _rushHourMultiplier;
    }

    // Afternoon rush hour: 4:00 PM - 6:30 PM
    if (timeInMinutes >= 960 && timeInMinutes <= 1110) {
      return _rushHourMultiplier;
    }

    // Late night/early morning: 11:00 PM - 5:00 AM
    if (timeInMinutes >= 1380 || timeInMinutes <= 300) {
      return _lightTrafficMultiplier;
    }

    // Midday: 10:00 AM - 2:00 PM
    if (timeInMinutes >= 600 && timeInMinutes <= 840) {
      return _lightTrafficMultiplier;
    }

    // Evening: 7:00 PM - 10:00 PM
    if (timeInMinutes >= 1140 && timeInMinutes <= 1320) {
      return 1.2; // Moderate traffic
    }

    return _baseTrafficMultiplier;
  }

  /// Get day of week traffic multiplier
  static double _getDayOfWeekMultiplier() {
    final dayOfWeek = DateTime.now().weekday;

    switch (dayOfWeek) {
      case DateTime.monday:
      case DateTime.friday:
        return 1.2; // Higher traffic on Mondays and Fridays
      case DateTime.tuesday:
      case DateTime.wednesday:
      case DateTime.thursday:
        return 1.0; // Normal traffic
      case DateTime.saturday:
        return 0.9; // Lighter traffic on weekends
      case DateTime.sunday:
        return 0.8; // Lightest traffic on Sundays
      default:
        return 1.0;
    }
  }

  /// Get weather-based traffic multiplier (simplified)
  static double _getWeatherMultiplier() {
    // This is a simplified implementation
    // In a real app, you would integrate with a weather API

    final hour = DateTime.now().hour;

    // Simulate weather impact based on time of day
    // (In reality, you'd check actual weather conditions)
    if (hour >= 6 && hour <= 8) {
      return 1.1; // Slightly higher traffic in morning
    } else if (hour >= 17 && hour <= 19) {
      return 1.2; // Higher traffic in evening
    }

    return 1.0;
  }

  /// Get route-based traffic multiplier
  static double _getRouteBasedMultiplier(String? routeName) {
    if (routeName == null) return 1.0;

    final route = routeName.toLowerCase();

    // High-traffic routes
    if (route.contains('highway') || route.contains('freeway')) {
      return 1.3;
    }

    // School routes (typically have more traffic during school hours)
    if (route.contains('school') || route.contains('academy')) {
      return 1.2;
    }

    // City center routes
    if (route.contains('downtown') || route.contains('city center')) {
      return 1.4;
    }

    // Residential routes (typically lighter traffic)
    if (route.contains('residential') || route.contains('suburb')) {
      return 0.9;
    }

    return 1.0;
  }

  /// Get vehicle type traffic multiplier
  static double _getVehicleTypeMultiplier(String? vehicleType) {
    if (vehicleType == null) return 1.0;

    final type = vehicleType.toLowerCase();

    switch (type) {
      case 'school_bus':
        return 1.1; // School buses may have slightly slower average speeds
      case 'minibus':
        return 1.0; // Normal multiplier for minibuses
      case 'van':
        return 0.95; // Vans might be slightly more maneuverable
      default:
        return 1.0;
    }
  }

  /// Get traffic conditions description
  static String getTrafficConditions(double multiplier) {
    if (multiplier <= 0.8) {
      return 'Light Traffic';
    } else if (multiplier <= 1.2) {
      return 'Normal Traffic';
    } else if (multiplier <= 1.5) {
      return 'Heavy Traffic';
    } else {
      return 'Severe Traffic';
    }
  }

  /// Get traffic color for UI display
  static int getTrafficColor(double multiplier) {
    if (multiplier <= 0.8) {
      return 0xFF4CAF50; // Green
    } else if (multiplier <= 1.2) {
      return 0xFFFF9800; // Orange
    } else if (multiplier <= 1.5) {
      return 0xFFFF5722; // Red
    } else {
      return 0xFFD32F2F; // Dark Red
    }
  }

  /// Get traffic icon for UI display
  static String getTrafficIcon(double multiplier) {
    if (multiplier <= 0.8) {
      return '🟢';
    } else if (multiplier <= 1.2) {
      return '🟡';
    } else if (multiplier <= 1.5) {
      return '🟠';
    } else {
      return '🔴';
    }
  }

  /// Calculate historical traffic patterns (simplified)
  static Future<Map<String, double>> getHistoricalTrafficPatterns({
    required double startLat,
    required double startLng,
    required double endLat,
    required double endLng,
  }) async {
    // This would typically integrate with historical traffic data
    // For now, return simplified patterns based on time of day

    final patterns = <String, double>{};
    final hour = DateTime.now().hour;

    // Simulate historical patterns
    patterns['morning_rush'] = hour >= 7 && hour <= 9 ? 1.5 : 1.0;
    patterns['afternoon_rush'] = hour >= 17 && hour <= 19 ? 1.4 : 1.0;
    patterns['weekend'] = DateTime.now().weekday >= 6 ? 0.8 : 1.0;
    patterns['holiday'] = 0.7; // Simplified holiday detection

    return patterns;
  }

  /// Get traffic alerts for the route
  static Future<List<String>> getTrafficAlerts({
    required double startLat,
    required double startLng,
    required double endLat,
    required double endLng,
  }) async {
    // This would integrate with traffic alert services
    // For now, return simulated alerts

    final alerts = <String>[];
    final hour = DateTime.now().hour;

    if (hour >= 7 && hour <= 9) {
      alerts.add('Morning rush hour traffic expected');
    }

    if (hour >= 17 && hour <= 19) {
      alerts.add('Evening rush hour traffic expected');
    }

    // Simulate random traffic incidents
    final random = Random();
    if (random.nextDouble() < 0.1) {
      // 10% chance of incident
      alerts.add('Traffic incident reported on route');
    }

    return alerts;
  }

  /// Get optimal departure time to avoid traffic
  static DateTime getOptimalDepartureTime({
    required DateTime scheduledArrival,
    required double trafficMultiplier,
  }) {
    // Calculate how much earlier to leave based on traffic
    final trafficDelay = Duration(
      minutes: ((trafficMultiplier - 1.0) * 30).round(),
    );
    return scheduledArrival.subtract(trafficDelay);
  }

  /// Check if current time is during rush hour
  static bool isRushHour() {
    final hour = DateTime.now().hour;
    return (hour >= 7 && hour <= 9) || (hour >= 17 && hour <= 19);
  }

  /// Get rush hour status
  static String getRushHourStatus() {
    final hour = DateTime.now().hour;

    if (hour >= 7 && hour <= 9) {
      return 'Morning Rush Hour';
    } else if (hour >= 17 && hour <= 19) {
      return 'Evening Rush Hour';
    } else {
      return 'Normal Traffic';
    }
  }
}
