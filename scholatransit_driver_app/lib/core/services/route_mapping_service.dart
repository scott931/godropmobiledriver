import '../models/trip_model.dart';
import '../models/student_model.dart';
import '../models/parent_trip_model.dart';
import 'routing_service.dart';
import 'eta_service.dart';
import 'location_service.dart';

/// Represents a stop in the route with location and ETA
class RouteStop {
    final String id;
    final String name;
    final String address;
    final double latitude;
    final double longitude;
    final StopType type;
    final List<String> studentNames;
    final DateTime? scheduledTime;
    final Duration? eta;
    final double? distance;
    final bool isCompleted;

    RouteStop({
      required this.id,
      required this.name,
      required this.address,
      required this.latitude,
      required this.longitude,
      required this.type,
      this.studentNames = const [],
      this.scheduledTime,
      this.eta,
      this.distance,
      this.isCompleted = false,
    });

    String get formattedETA {
      if (eta == null) return 'Calculating...';
      final minutes = eta!.inMinutes;
      if (minutes < 60) return '$minutes min';
      final hours = minutes ~/ 60;
      final mins = minutes % 60;
      return '${hours}h ${mins}m';
    }
  }

/// Represents a complete route with all stops and path
class RouteMap {
  final List<RouteStop> stops;
  final List<Map<String, double>> routePath;
  final double totalDistance;
  final Duration totalDuration;
  final RouteStop? schoolStop;
  final Duration? etaToSchool;

  RouteMap({
    required this.stops,
    required this.routePath,
    required this.totalDistance,
    required this.totalDuration,
    this.schoolStop,
    this.etaToSchool,
  });

  String get formattedTotalDistance {
    if (totalDistance < 1000) {
      return '${totalDistance.toStringAsFixed(0)} m';
    }
    return '${(totalDistance / 1000).toStringAsFixed(2)} km';
  }

  String get formattedTotalDuration {
    final hours = totalDuration.inHours;
    final minutes = totalDuration.inMinutes % 60;
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
  }

  String get formattedETAToSchool {
    if (etaToSchool == null) return 'Calculating...';
    final minutes = etaToSchool!.inMinutes;
    if (minutes < 60) return '$minutes min';
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    return '${hours}h ${mins}m';
  }
}

/// Service for mapping routes with parent locations and calculating ETAs
class RouteMappingService {
  /// Calculate route map for a trip with all parent locations
  static Future<RouteMap?> calculateRouteMap({
    required Trip trip,
    required List<Student> students,
    double? currentLat,
    double? currentLng,
  }) async {
    try {
      print('🗺️ Route Mapping: Calculating route for trip ${trip.tripId}');

      // Get current location
      final currentPosition = currentLat != null && currentLng != null
          ? {'latitude': currentLat, 'longitude': currentLng}
          : LocationService.currentPosition != null
              ? {
                  'latitude': LocationService.currentPosition!.latitude,
                  'longitude': LocationService.currentPosition!.longitude,
                }
              : null;

      if (currentPosition == null) {
        print('❌ Route Mapping: No current location available');
        return null;
      }

      // Get school location (end location)
      if (trip.endLatitude == null || trip.endLongitude == null) {
        print('❌ Route Mapping: No school location available');
        return null;
      }

      final schoolLocation = {
        'latitude': trip.endLatitude!,
        'longitude': trip.endLongitude!,
      };

      // Get parent locations from students
      final parentStops = <RouteStop>[];
      for (final student in students) {
        if (student.latitude != null && student.longitude != null) {
          parentStops.add(
            RouteStop(
              id: 'student_${student.id}',
              name: student.parentName ?? '${student.firstName}\'s Parent',
              address: student.address ?? 'Unknown Address',
              latitude: student.latitude!,
              longitude: student.longitude!,
              type: StopType.pickup,
              studentNames: [student.fullName],
              scheduledTime: trip.scheduledStart,
            ),
          );
        }
      }

      if (parentStops.isEmpty) {
        print('⚠️ Route Mapping: No parent locations found');
        return null;
      }

      print(
        '📍 Route Mapping: Found ${parentStops.length} parent locations',
      );

      // Calculate optimal route order using nearest neighbor algorithm
      final orderedStops = _calculateOptimalRouteOrder(
        startLocation: currentPosition,
        stops: parentStops,
        endLocation: schoolLocation,
      );

      // Calculate route path and ETAs
      final routePath = <Map<String, double>>[];
      double totalDistance = 0;
      Duration totalDuration = Duration.zero;
      double? lastLat = currentPosition['latitude'];
      double? lastLng = currentPosition['longitude'];

      final stopsWithETA = <RouteStop>[];

      for (int i = 0; i < orderedStops.length; i++) {
        final stop = orderedStops[i];

        if (lastLat != null && lastLng != null) {
          // Get route to this stop
          final routeInfo = await RoutingService.getRouteInfo(
            startLat: lastLat,
            startLng: lastLng,
            endLat: stop.latitude,
            endLng: stop.longitude,
          );

          if (routeInfo != null) {
            routePath.addAll(routeInfo.coordinates);
            totalDistance += routeInfo.distance;
            totalDuration += Duration(seconds: routeInfo.duration.round());

            // Calculate ETA
            final etaResult = await ETAService.calculateETA(
              currentLat: lastLat,
              currentLng: lastLng,
              destinationLat: stop.latitude,
              destinationLng: stop.longitude,
              trip: trip,
            );

            final stopWithETA = RouteStop(
              id: stop.id,
              name: stop.name,
              address: stop.address,
              latitude: stop.latitude,
              longitude: stop.longitude,
              type: stop.type,
              studentNames: stop.studentNames,
              scheduledTime: stop.scheduledTime,
              eta: etaResult.success ? etaResult.etaInfo.timeToArrival : null,
              distance: routeInfo.distance,
            );

            stopsWithETA.add(stopWithETA);
            lastLat = stop.latitude;
            lastLng = stop.longitude;
          } else {
            // If routing fails, use straight-line distance
            final distance = LocationService.calculateDistance(
              lastLat,
              lastLng,
              stop.latitude,
              stop.longitude,
            );
            totalDistance += distance;

            stopsWithETA.add(stop);
            lastLat = stop.latitude;
            lastLng = stop.longitude;
          }
        }
      }

      // Calculate route back to school
      Duration? etaToSchool;
      if (lastLat != null && lastLng != null) {
        final routeToSchool = await RoutingService.getRouteInfo(
          startLat: lastLat,
          startLng: lastLng,
          endLat: schoolLocation['latitude']!,
          endLng: schoolLocation['longitude']!,
        );

        if (routeToSchool != null) {
          routePath.addAll(routeToSchool.coordinates);
          totalDistance += routeToSchool.distance;
          totalDuration += Duration(seconds: routeToSchool.duration.round());

          final etaResult = await ETAService.calculateETA(
            currentLat: lastLat,
            currentLng: lastLng,
            destinationLat: schoolLocation['latitude']!,
            destinationLng: schoolLocation['longitude']!,
            trip: trip,
          );

          etaToSchool = etaResult.success ? etaResult.etaInfo.timeToArrival : null;
        }
      }

      // Create school stop
      final schoolStop = RouteStop(
        id: 'school',
        name: trip.endLocation ?? 'School',
        address: trip.endLocation ?? 'School',
        latitude: schoolLocation['latitude']!,
        longitude: schoolLocation['longitude']!,
        type: StopType.school,
        eta: etaToSchool,
      );

      print(
        '✅ Route Mapping: Route calculated - ${stopsWithETA.length} stops, ${(totalDistance / 1000).toStringAsFixed(2)} km',
      );

      return RouteMap(
        stops: stopsWithETA,
        routePath: routePath,
        totalDistance: totalDistance,
        totalDuration: totalDuration,
        schoolStop: schoolStop,
        etaToSchool: etaToSchool,
      );
    } catch (e) {
      print('❌ Route Mapping: Error calculating route: $e');
      return null;
    }
  }

  /// Calculate optimal route order using nearest neighbor algorithm
  static List<RouteStop> _calculateOptimalRouteOrder({
    required Map<String, double> startLocation,
    required List<RouteStop> stops,
    required Map<String, double> endLocation,
  }) {
    if (stops.isEmpty) return [];

    final orderedStops = <RouteStop>[];
    final remainingStops = List<RouteStop>.from(stops);
    double? currentLat = startLocation['latitude'];
    double? currentLng = startLocation['longitude'];

    // Use nearest neighbor algorithm
    while (remainingStops.isNotEmpty && currentLat != null && currentLng != null) {
      RouteStop? nearestStop;
      double nearestDistance = double.infinity;

      for (final stop in remainingStops) {
        final distance = LocationService.calculateDistance(
          currentLat,
          currentLng,
          stop.latitude,
          stop.longitude,
        );

        if (distance < nearestDistance) {
          nearestDistance = distance;
          nearestStop = stop;
        }
      }

      if (nearestStop != null) {
        orderedStops.add(nearestStop);
        remainingStops.remove(nearestStop);
        currentLat = nearestStop.latitude;
        currentLng = nearestStop.longitude;
      } else {
        break;
      }
    }

    return orderedStops;
  }

  /// Calculate route map from trip stops (if available)
  static Future<RouteMap?> calculateRouteMapFromStops({
    required Trip trip,
    List<TripStop>? stops,
    double? currentLat,
    double? currentLng,
  }) async {
    try {
      print('🗺️ Route Mapping: Calculating route from stops for trip ${trip.tripId}');

      // Get current location
      final currentPosition = currentLat != null && currentLng != null
          ? {'latitude': currentLat, 'longitude': currentLng}
          : LocationService.currentPosition != null
              ? {
                  'latitude': LocationService.currentPosition!.latitude,
                  'longitude': LocationService.currentPosition!.longitude,
                }
              : null;

      if (currentPosition == null) {
        print('❌ Route Mapping: No current location available');
        return null;
      }

      // Get school location
      if (trip.endLatitude == null || trip.endLongitude == null) {
        print('❌ Route Mapping: No school location available');
        return null;
      }

      final schoolLocation = {
        'latitude': trip.endLatitude!,
        'longitude': trip.endLongitude!,
      };

      // Convert stops to RouteStops
      final routeStops = <RouteStop>[];
      if (stops != null) {
        for (final stop in stops) {
          if (stop.type != StopType.school) {
            routeStops.add(
              RouteStop(
                id: 'stop_${stop.id}',
                name: stop.name,
                address: stop.address,
                latitude: stop.latitude,
                longitude: stop.longitude,
                type: stop.type,
                studentNames: stop.children.map((c) => c.fullName).toList(),
                scheduledTime: stop.scheduledTime,
                isCompleted: stop.isCompleted,
              ),
            );
          }
        }
      }

      if (routeStops.isEmpty) {
        print('⚠️ Route Mapping: No stops found');
        return null;
      }

      // Calculate optimal route order
      final orderedStops = _calculateOptimalRouteOrder(
        startLocation: currentPosition,
        stops: routeStops,
        endLocation: schoolLocation,
      );

      // Calculate route path and ETAs
      final routePath = <Map<String, double>>[];
      double totalDistance = 0;
      Duration totalDuration = Duration.zero;
      double? lastLat = currentPosition['latitude'];
      double? lastLng = currentPosition['longitude'];

      final stopsWithETA = <RouteStop>[];

      for (final stop in orderedStops) {
        if (lastLat != null && lastLng != null) {
          final routeInfo = await RoutingService.getRouteInfo(
            startLat: lastLat,
            startLng: lastLng,
            endLat: stop.latitude,
            endLng: stop.longitude,
          );

          if (routeInfo != null) {
            routePath.addAll(routeInfo.coordinates);
            totalDistance += routeInfo.distance;
            totalDuration += Duration(seconds: routeInfo.duration.round());

            final etaResult = await ETAService.calculateETA(
              currentLat: lastLat,
              currentLng: lastLng,
              destinationLat: stop.latitude,
              destinationLng: stop.longitude,
              trip: trip,
            );

            stopsWithETA.add(
              RouteStop(
                id: stop.id,
                name: stop.name,
                address: stop.address,
                latitude: stop.latitude,
                longitude: stop.longitude,
                type: stop.type,
                studentNames: stop.studentNames,
                scheduledTime: stop.scheduledTime,
                eta: etaResult.success ? etaResult.etaInfo.timeToArrival : null,
                distance: routeInfo.distance,
                isCompleted: stop.isCompleted,
              ),
            );

            lastLat = stop.latitude;
            lastLng = stop.longitude;
          }
        }
      }

      // Calculate route to school
      Duration? etaToSchool;
      if (lastLat != null && lastLng != null) {
        final routeToSchool = await RoutingService.getRouteInfo(
          startLat: lastLat,
          startLng: lastLng,
          endLat: schoolLocation['latitude']!,
          endLng: schoolLocation['longitude']!,
        );

        if (routeToSchool != null) {
          routePath.addAll(routeToSchool.coordinates);
          totalDistance += routeToSchool.distance;
          totalDuration += Duration(seconds: routeToSchool.duration.round());

          final etaResult = await ETAService.calculateETA(
            currentLat: lastLat,
            currentLng: lastLng,
            destinationLat: schoolLocation['latitude']!,
            destinationLng: schoolLocation['longitude']!,
            trip: trip,
          );

          etaToSchool = etaResult.success ? etaResult.etaInfo.timeToArrival : null;
        }
      }

      final schoolStop = RouteStop(
        id: 'school',
        name: trip.endLocation ?? 'School',
        address: trip.endLocation ?? 'School',
        latitude: schoolLocation['latitude']!,
        longitude: schoolLocation['longitude']!,
        type: StopType.school,
        eta: etaToSchool,
      );

      print(
        '✅ Route Mapping: Route calculated from stops - ${stopsWithETA.length} stops',
      );

      return RouteMap(
        stops: stopsWithETA,
        routePath: routePath,
        totalDistance: totalDistance,
        totalDuration: totalDuration,
        schoolStop: schoolStop,
        etaToSchool: etaToSchool,
      );
    } catch (e) {
      print('❌ Route Mapping: Error calculating route from stops: $e');
      return null;
    }
  }
}
