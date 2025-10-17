import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:geocoding/geocoding.dart' as geocoding;
import '../../../core/config/app_config.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/trip_provider.dart';
import '../../../core/models/trip_model.dart';
import '../../../core/services/routing_service.dart';
import '../../../core/services/realtime_distance_tracker.dart';
import '../../../core/services/location_service_resolver.dart';

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  MapboxMap? _mapboxMap;
  Point? _currentLocation;
  PointAnnotationManager? _pointAnnotationManager;
  PointAnnotation? _currentLocationAnnotation;
  PointAnnotation? _startLocationAnnotation;
  PointAnnotation? _endLocationAnnotation;
  PolylineAnnotationManager? _polylineAnnotationManager;
  PolylineAnnotation? _routePolyline;

  // Distance tracking variables
  double? _remainingDistance;
  double? _distanceTraveled;
  double? _totalTripDistance;
  double _progressPercentage = 0.0;
  Duration? _remainingTime;
  String? _currentStreetName;
  String? _destinationStreetName;
  final Map<String, String> _geocodeCache = {};

  // Route update throttling
  DateTime? _lastRouteUpdate;
  static const Duration _minRouteUpdateInterval = Duration(seconds: 3);

  // Location guidance
  String? _locationGuidance;
  bool _showLocationGuidance = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeMap();
    });
  }

  void _initializeMap() async {
    // Always set a default location first
    _currentLocation = Point(
      coordinates: Position(
        AppConfig.defaultLongitude,
        AppConfig.defaultLatitude,
      ),
    );

    // Trigger a rebuild to show the map
    if (mounted) {
      setState(() {});
    }

    // Use LocationServiceResolver to avoid conflicts
    try {
      final position = await LocationServiceResolver.getCurrentPosition();
      if (position != null) {
        _currentLocation = Point(
          coordinates: Position(position.longitude, position.latitude),
        );
        if (mounted) {
          setState(() {});
        }
        print('✅ Map initialized with LocationServiceResolver position');
        // Fly camera to the exact acquired GPS position
        if (_mapboxMap != null && _currentLocation != null) {
          _mapboxMap!.flyTo(
            CameraOptions(center: _currentLocation!, zoom: 16.0),
            MapAnimationOptions(duration: 1200),
          );
        }
      } else {
        print(
          '⚠️ Using default location - LocationServiceResolver position not available',
        );
      }
    } catch (e) {
      print('❌ Failed to get location from LocationServiceResolver: $e');
      // Keep default location
    }
  }

  @override
  Widget build(BuildContext context) {
    final tripState = ref.watch(tripProvider);

    // Watch for changes in trip state and update map accordingly
    ref.listen(tripProvider, (previous, next) {
      if (!mounted) return;

      print('🔄 DEBUG: Trip provider state changed');
      print('🔄 DEBUG: Previous currentTrip: ${previous?.currentTrip?.tripId}');
      print('🔄 DEBUG: Next currentTrip: ${next.currentTrip?.tripId}');
      print('🔄 DEBUG: Map ready: ${_mapboxMap != null}');

      if (_mapboxMap != null && next.currentTrip != null) {
        print('🔄 DEBUG: Triggering marker updates...');
        _loadTripRoute();
        _addTripMarkers();
        _startDistanceTracking(next.currentTrip!);
      } else if (_mapboxMap != null && next.currentTrip == null) {
        print('🔄 DEBUG: No active trip - clearing route polyline...');
        _clearRoutePolyline();
        _stopDistanceTracking();
      } else {
        print(
          '🔄 DEBUG: Skipping marker updates - map: ${_mapboxMap != null}, trip: ${next.currentTrip != null}',
        );
      }
    });

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      body: Stack(
        children: [
          // Map
          _currentLocation == null
              ? const Center(child: CircularProgressIndicator())
              : MapWidget(
                  key: const ValueKey("mapWidget"),
                  cameraOptions: CameraOptions(
                    center: _currentLocation!,
                    zoom: 15.0,
                  ),
                  styleUri: MapboxStyles.MAPBOX_STREETS,
                  onMapCreated: (MapboxMap mapboxMap) async {
                    print('🗺️ DEBUG: Map created successfully');
                    _mapboxMap = mapboxMap;
                    _pointAnnotationManager = await mapboxMap.annotations
                        .createPointAnnotationManager();
                    _polylineAnnotationManager = await mapboxMap.annotations
                        .createPolylineAnnotationManager();
                    print('🗺️ DEBUG: Point annotation manager created');
                    print('🗺️ DEBUG: Polyline annotation manager created');

                    _addTestMarker();
                    _addCurrentLocationMarker();

                    // Force load active trips and then add markers
                    print('🗺️ DEBUG: Loading active trips...');
                    await ref.read(tripProvider.notifier).loadActiveTrips();

                    print('🗺️ DEBUG: Calling _loadTripRoute()...');
                    _loadTripRoute();

                    print('🗺️ DEBUG: Calling _addTripMarkers()...');
                    _addTripMarkers();
                  },
                ),

          // Trip Details Card
          Positioned(
            top: 50.h,
            left: 16.w,
            right: 16.w,
            child: _TripDetailsCard(
              tripState: tripState,
              currentLocation: _currentLocation,
              remainingDistance: _remainingDistance,
              distanceTraveled: _distanceTraveled,
              totalTripDistance: _totalTripDistance,
              progressPercentage: _progressPercentage,
              remainingTime: _remainingTime,
              currentStreetName: _currentStreetName,
              destinationStreetName: _destinationStreetName,
            ),
          ),

          // Current Location Button
          Positioned(
            bottom: 30.h,
            right: 16.w,
            child: Tooltip(
              message: 'Center map on your current location',
              child: _CurrentLocationButton(
                onPressed: _centerMapOnCurrentLocation,
              ),
            ),
          ),

          // Debug Distance Button (only show when trip is active)
          if (tripState.currentTrip != null)
            Positioned(
              bottom: 90.h,
              right: 16.w,
              child: Tooltip(
                message: 'Debug distance tracking for current trip',
                child: _DebugDistanceButton(onPressed: _debugDistanceTracking),
              ),
            ),

          // Force Distance Update Button (only show when trip is active)
          if (tripState.currentTrip != null)
            Positioned(
              bottom: 150.h,
              right: 16.w,
              child: Tooltip(
                message: 'Force update distance calculations',
                child: _ForceDistanceUpdateButton(
                  onPressed: _forceDistanceUpdate,
                ),
              ),
            ),

          // Check Conflicts Button
          Positioned(
            bottom: 210.h,
            right: 16.w,
            child: Tooltip(
              message: 'Check for location service conflicts',
              child: _CheckConflictsButton(onPressed: _checkLocationConflicts),
            ),
          ),

          // Force Accept Location Button
          Positioned(
            bottom: 270.h,
            right: 16.w,
            child: Tooltip(
              message: 'Force accept current location',
              child: _ForceAcceptLocationButton(
                onPressed: _forceAcceptLocation,
              ),
            ),
          ),

          // Force Restart Location Service Button
          Positioned(
            bottom: 330.h,
            right: 16.w,
            child: Tooltip(
              message: 'Restart location service',
              child: _ForceRestartLocationButton(
                onPressed: _forceRestartLocationService,
              ),
            ),
          ),

          // Refresh Button
          Positioned(
            bottom: 90.h,
            right: 16.w,
            child: Tooltip(
              message: 'Refresh map data and location',
              child: _RefreshButton(onPressed: _refreshMapData),
            ),
          ),

          // Test Green Marker Button
          Positioned(
            bottom: 150.h,
            right: 16.w,
            child: Tooltip(
              message: 'Add test green marker for debugging',
              child: _TestGreenMarkerButton(onPressed: _addTestGreenMarker),
            ),
          ),

          // Zoom to Trip Route Button
          if (tripState.currentTrip != null)
            Positioned(
              bottom: 210.h,
              right: 16.w,
              child: Tooltip(
                message: 'Zoom to show trip route',
                child: _ZoomToStartButton(
                  onPressed: () => _zoomToTripRoute(tripState.currentTrip!),
                ),
              ),
            ),

          // Toggle Route Visibility Button
          if (tripState.currentTrip != null)
            Positioned(
              bottom: 270.h,
              right: 16.w,
              child: Tooltip(
                message: 'Toggle route visibility on/off',
                child: _ToggleRouteButton(onPressed: _toggleRouteVisibility),
              ),
            ),

          // Location Guidance Banner
          if (_showLocationGuidance && _locationGuidance != null)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: _LocationGuidanceBanner(
                message: _locationGuidance!,
                onDismiss: () {
                  setState(() {
                    _showLocationGuidance = false;
                  });
                },
              ),
            ),
        ],
      ),
    );
  }

  void _addTestMarker() async {
    if (_mapboxMap == null || _pointAnnotationManager == null) return;

    try {
      // Add a test marker at a known location (Nairobi, Kenya)
      final testPoint = Point(
        coordinates: Position(36.817223, -1.286389), // Nairobi coordinates
      );

      final testMarker = PointAnnotationOptions(
        geometry: testPoint,
        image: await _createMarkerImage(Colors.purple, '🧪'),
      );

      await _pointAnnotationManager!.create(testMarker);
      print('✅ Test marker added at Nairobi coordinates');
    } catch (e) {
      print('❌ Error adding test marker: $e');
    }
  }

  void _addCurrentLocationMarker() async {
    if (_mapboxMap == null ||
        _currentLocation == null ||
        _pointAnnotationManager == null) {
      print('❌ Cannot add current location marker - missing dependencies');
      return;
    }

    try {
      print(
        '🔍 DEBUG: Adding current location marker at: ${_currentLocation!.coordinates.lat}, ${_currentLocation!.coordinates.lng}',
      );

      // Remove existing current location marker
      if (_currentLocationAnnotation != null) {
        await _pointAnnotationManager!.delete(_currentLocationAnnotation!);
      }

      // Create current location marker with dark green color
      final currentLocationMarker = PointAnnotationOptions(
        geometry: _currentLocation!,
        image: await _createMarkerImage(Colors.green.shade800, '📍'),
      );

      _currentLocationAnnotation = await _pointAnnotationManager!.create(
        currentLocationMarker,
      );
      print(
        '✅ Current location marker added to map at: ${_currentLocation!.coordinates.lat}, ${_currentLocation!.coordinates.lng}',
      );
    } catch (e) {
      print('❌ Error adding current location marker: $e');
    }
  }

  void _loadTripRoute() async {
    if (!mounted) return;

    print('🚀 DEBUG: _loadTripRoute() called');

    if (_mapboxMap == null || _pointAnnotationManager == null) {
      print('❌ Map or annotation manager not ready for trip route');
      print('❌ Map ready: ${_mapboxMap != null}');
      print('❌ Annotation manager ready: ${_pointAnnotationManager != null}');
      return;
    }

    final tripState = ref.read(tripProvider);
    final currentTrip = tripState.currentTrip;

    print('🔍 DEBUG: Current trip: ${currentTrip?.tripId}');
    print('🔍 DEBUG: Current trip status: ${currentTrip?.status.name}');
    print('🔍 DEBUG: Current trip isActive: ${currentTrip?.isActive}');
    print(
      '🔍 DEBUG: Current trip start coords: ${currentTrip?.startLatitude}, ${currentTrip?.startLongitude}',
    );
    print(
      '🔍 DEBUG: Current trip end coords: ${currentTrip?.endLatitude}, ${currentTrip?.endLongitude}',
    );
    print('🔍 DEBUG: Total trips in state: ${tripState.trips.length}');
    print(
      '🔍 DEBUG: Active trips: ${tripState.trips.where((t) => t.isActive).length}',
    );

    if (currentTrip == null) {
      print('ℹ️ No active trip to display route for');
      return;
    }

    try {
      // Remove existing trip markers
      if (_startLocationAnnotation != null) {
        await _pointAnnotationManager!.delete(_startLocationAnnotation!);
        _startLocationAnnotation = null;
      }
      if (_endLocationAnnotation != null) {
        await _pointAnnotationManager!.delete(_endLocationAnnotation!);
        _endLocationAnnotation = null;
      }

      // Add start location marker
      if (currentTrip.startLatitude != null &&
          currentTrip.startLongitude != null) {
        print('🟢 DEBUG: Creating GREEN start marker...');
        print(
          '🟢 DEBUG: Start location: ${_getLocationName(currentTrip.startLatitude, currentTrip.startLongitude, currentTrip.startLocation)}',
        );

        final startPoint = Point(
          coordinates: Position(
            currentTrip.startLongitude!,
            currentTrip.startLatitude!,
          ),
        );

        final startMarker = PointAnnotationOptions(
          geometry: startPoint,
          image: await _createMarkerImage(Colors.green, '🚀'),
        );

        _startLocationAnnotation = await _pointAnnotationManager!.create(
          startMarker,
        );
        print(
          '✅ GREEN Start location marker added: ${_getLocationName(currentTrip.startLatitude, currentTrip.startLongitude, currentTrip.startLocation)}',
        );

        // Auto-zoom to trip route (shows both start and end)
        _zoomToTripRoute(currentTrip);
      } else {
        print('❌ DEBUG: Cannot create start marker - missing coordinates');
        print('❌ DEBUG: startLatitude: ${currentTrip.startLatitude}');
        print('❌ DEBUG: startLongitude: ${currentTrip.startLongitude}');
      }

      // Add end location marker
      if (currentTrip.endLatitude != null && currentTrip.endLongitude != null) {
        final endPoint = Point(
          coordinates: Position(
            currentTrip.endLongitude!,
            currentTrip.endLatitude!,
          ),
        );

        final endMarker = PointAnnotationOptions(
          geometry: endPoint,
          image: await _createMarkerImage(Colors.red, '🏁'),
        );

        _endLocationAnnotation = await _pointAnnotationManager!.create(
          endMarker,
        );
        print(
          '✅ End location marker added: ${_getLocationName(currentTrip.endLatitude, currentTrip.endLongitude, currentTrip.endLocation)}',
        );
      }

      // Draw route polyline from current location to destination
      print('🗺️ DEBUG: Drawing route from current location to destination...');
      await _drawRouteFromCurrentLocation(currentTrip);
      print('🗺️ DEBUG: Route from current location drawing completed');

      print(
        '✅ Trip route markers added to map for trip: ${currentTrip.tripId}',
      );
    } catch (e) {
      print('❌ Error adding trip route markers: $e');
    }
  }

  /// Draw route from current location to destination
  Future<void> _drawRouteFromCurrentLocation(Trip trip) async {
    if (_polylineAnnotationManager == null) {
      print('❌ Polyline annotation manager not ready');
      return;
    }

    if (trip.endLatitude == null || trip.endLongitude == null) {
      print('❌ Cannot draw route - missing destination coordinates');
      return;
    }

    try {
      // Get current location
      final currentLocation =
          await LocationServiceResolver.getCurrentPosition();
      if (currentLocation == null) {
        print('❌ Cannot draw route - no current location available');
        // Fall back to full route if no current location
        await _drawRoutePolyline(trip);
        return;
      }

      print('🗺️ Getting route from current location to destination...');
      print(
        '📍 Current location: ${currentLocation.latitude}, ${currentLocation.longitude}',
      );
      print('🏁 Destination: ${trip.endLatitude}, ${trip.endLongitude}');

      // Reverse geocode street names (non-blocking UI updates)
      // Current street
      _reverseGeocode(currentLocation.latitude, currentLocation.longitude).then(
        (name) {
          if (!mounted) return;
          if (name != null && name != _currentStreetName) {
            setState(() => _currentStreetName = name);
          }
        },
      );
      // Destination street
      if (trip.endLatitude != null && trip.endLongitude != null) {
        _reverseGeocode(trip.endLatitude!, trip.endLongitude!).then((name) {
          if (!mounted) return;
          if (name != null && name != _destinationStreetName) {
            setState(() => _destinationStreetName = name);
          }
        });
      }

      // Remove existing route polyline
      if (_routePolyline != null) {
        await _polylineAnnotationManager!.delete(_routePolyline!);
        _routePolyline = null;
      }

      // Get route coordinates from current location to destination
      final routeInfo = await RoutingService.getRouteInfo(
        startLat: currentLocation.latitude,
        startLng: currentLocation.longitude,
        endLat: trip.endLatitude!,
        endLng: trip.endLongitude!,
      );

      List<Position> routeCoordinates;

      if (routeInfo != null && routeInfo.coordinates.isNotEmpty) {
        // Use road-based route coordinates
        routeCoordinates = routeInfo.coordinates
            .map((coord) => Position(coord['longitude']!, coord['latitude']!))
            .toList();
        print(
          '✅ Using road-based route from current location with ${routeCoordinates.length} points',
        );
        print(
          '📏 Route distance: ${(routeInfo.distance / 1000).toStringAsFixed(2)} km',
        );
        print(
          '⏱️ Route duration: ${(routeInfo.duration / 60).toStringAsFixed(1)} min',
        );
      } else {
        // Fallback to straight line if routing fails
        print('⚠️ Routing service failed, using straight line as fallback');
        routeCoordinates = [
          Position(
            currentLocation.longitude,
            currentLocation.latitude,
          ), // Current location
          Position(trip.endLongitude!, trip.endLatitude!), // Destination
        ];
      }

      // Create route line coordinates
      final routeLine = LineString(coordinates: routeCoordinates);

      // Use green color for better identification of current location to destination
      Color routeColor = Colors.green;

      // Create polyline annotation
      final polylineOptions = PolylineAnnotationOptions(
        geometry: routeLine,
        lineColor: routeColor.value,
        lineWidth: 4.0,
        lineOpacity: 0.8,
      );

      _routePolyline = await _polylineAnnotationManager!.create(
        polylineOptions,
      );

      print(
        '✅ Route polyline drawn from current location to ${trip.endLatitude}, ${trip.endLongitude}',
      );
      print('✅ Route color: ${routeColor.toString()}');
      print(
        '✅ Route polyline created with ${routeCoordinates.length} coordinates',
      );
    } catch (e) {
      print('❌ Error drawing route from current location: $e');
      // Fall back to full route if current location route fails
      await _drawRoutePolyline(trip);
    }
  }

  Future<void> _drawRoutePolyline(Trip trip) async {
    if (_polylineAnnotationManager == null) {
      print('❌ Polyline annotation manager not ready');
      return;
    }

    if (trip.startLatitude == null ||
        trip.startLongitude == null ||
        trip.endLatitude == null ||
        trip.endLongitude == null) {
      print('❌ Cannot draw route polyline - missing coordinates');
      return;
    }

    try {
      // Remove existing route polyline
      if (_routePolyline != null) {
        await _polylineAnnotationManager!.delete(_routePolyline!);
        _routePolyline = null;
      }

      print('🗺️ Getting road-based route from routing service...');

      // Get route coordinates from routing service (road-based)
      final routeInfo = await RoutingService.getRouteInfo(
        startLat: trip.startLatitude!,
        startLng: trip.startLongitude!,
        endLat: trip.endLatitude!,
        endLng: trip.endLongitude!,
      );

      List<Position> routeCoordinates;

      if (routeInfo != null && routeInfo.coordinates.isNotEmpty) {
        // Use road-based route coordinates
        routeCoordinates = routeInfo.coordinates
            .map((coord) => Position(coord['longitude']!, coord['latitude']!))
            .toList();
        print(
          '✅ Using road-based route with ${routeCoordinates.length} points',
        );
        print(
          '📏 Route distance: ${(routeInfo.distance / 1000).toStringAsFixed(2)} km',
        );
        print(
          '⏱️ Route duration: ${(routeInfo.duration / 60).toStringAsFixed(1)} min',
        );
      } else {
        // Fallback to straight line if routing fails
        print('⚠️ Routing service failed, using straight line as fallback');
        routeCoordinates = [
          Position(trip.startLongitude!, trip.startLatitude!), // Start point
          Position(trip.endLongitude!, trip.endLatitude!), // End point
        ];
      }

      // Create route line coordinates
      final routeLine = LineString(coordinates: routeCoordinates);

      // Use green color for better identification of current location to destination
      Color routeColor = Colors.green;

      // Create polyline annotation
      final polylineOptions = PolylineAnnotationOptions(
        geometry: routeLine,
        lineColor: routeColor.value,
        lineWidth: 4.0,
        lineOpacity: 0.8,
      );

      _routePolyline = await _polylineAnnotationManager!.create(
        polylineOptions,
      );

      print(
        '✅ Route polyline drawn from ${trip.startLatitude}, ${trip.startLongitude} to ${trip.endLatitude}, ${trip.endLongitude}',
      );
      print('✅ Route color: ${routeColor.toString()} (${trip.status.name})');
      print(
        '✅ Route polyline created with ${routeCoordinates.length} coordinates',
      );
    } catch (e) {
      print('❌ Error drawing route polyline: $e');
    }
  }

  void _addTripMarkers() async {
    if (!mounted) return;

    if (_mapboxMap == null || _pointAnnotationManager == null) {
      print('❌ Map or annotation manager not ready');
      return;
    }

    final tripState = ref.read(tripProvider);
    print('🔍 DEBUG: Total trips loaded: ${tripState.trips.length}');
    print(
      '🔍 DEBUG: Trip states: ${tripState.trips.map((t) => '${t.tripId}: ${t.status.name}').join(', ')}',
    );

    final activeTrips = tripState.trips.where((trip) => trip.isActive).toList();
    print('🔍 DEBUG: Active trips found: ${activeTrips.length}');

    if (activeTrips.isEmpty) {
      print('ℹ️ No active trips to display markers for');
      return;
    }

    try {
      print('🚌 Adding markers for ${activeTrips.length} active trips:');
      for (final trip in activeTrips) {
        print(
          '🔍 DEBUG: Trip ${trip.tripId} - Start: ${_getLocationName(trip.startLatitude, trip.startLongitude, trip.startLocation)}',
        );
        print(
          '🔍 DEBUG: Trip ${trip.tripId} - End: ${_getLocationName(trip.endLatitude, trip.endLongitude, trip.endLocation)}',
        );
        print('🔍 DEBUG: Trip ${trip.tripId} - Status: ${trip.status.name}');

        if (trip.startLatitude != null && trip.startLongitude != null) {
          final tripPoint = Point(
            coordinates: Position(trip.startLongitude!, trip.startLatitude!),
          );

          final tripMarker = PointAnnotationOptions(
            geometry: tripPoint,
            image: await _createMarkerImage(Colors.orange, '🚌'),
          );

          await _pointAnnotationManager!.create(tripMarker);
          print(
            '  ✅ Trip ${trip.tripId} marker added at: ${_getLocationName(trip.startLatitude, trip.startLongitude, trip.startLocation)}',
          );
        } else {
          print('  ❌ Trip ${trip.tripId} has no valid coordinates');
        }
      }
      print('✅ All trip markers added to map');
    } catch (e) {
      print('❌ Error adding trip markers: $e');
    }
  }

  /// Start real-time distance tracking for a trip
  void _startDistanceTracking(Trip trip) async {
    try {
      print('📏 Starting distance tracking for trip ${trip.tripId}');

      // Check if location service is already running
      if (!LocationServiceResolver.getServiceStatus()['is_tracking']) {
        print('⚠️ Location service not running, starting it first...');
        final locationStarted = await LocationServiceResolver.startTracking(
          onLocationUpdate: (position) {
            print(
              '📍 Map received location update: ${position.latitude}, ${position.longitude}',
            );

            // Update current location and marker
            setState(() {
              _currentLocation = Point(
                coordinates: Position(position.longitude, position.latitude),
              );
            });

            // Update the current location marker with dark green color
            _addCurrentLocationMarker();

            // Force distance update on location change
            RealtimeDistanceTracker.forceDistanceUpdate();
          },
          onLocationError: (error) {
            print('❌ Map location error: $error');
          },
          onUserGuidance: (guidance) {
            print('💡 User guidance: $guidance');
            if (mounted) {
              setState(() {
                _locationGuidance = guidance;
                _showLocationGuidance = true;
              });

              // Auto-hide guidance after 10 seconds
              Timer(Duration(seconds: 10), () {
                if (mounted) {
                  setState(() {
                    _showLocationGuidance = false;
                  });
                }
              });
            }
          },
        );

        if (!locationStarted) {
          print('❌ Failed to start location service');
          return;
        }
      }

      print('📏 Setting up distance tracking callbacks...');
      final trackingStarted =
          await RealtimeDistanceTracker.startDistanceTracking(
            trip: trip,
            onDistanceUpdate: _handleDistanceUpdate,
            onDistanceError: _handleDistanceError,
            onProgressUpdate: _handleProgressUpdate,
          );

      if (trackingStarted) {
        print('✅ Distance tracking started successfully');
        print('📏 Callbacks registered:');
        print('  - onDistanceUpdate: _handleDistanceUpdate');
        print('  - onDistanceError: _handleDistanceError');
        print('  - onProgressUpdate: _handleProgressUpdate');

        // Print tracking status for debugging
        final status = await RealtimeDistanceTracker.getTrackingStatus();
        print('📊 Distance tracking status: $status');
      } else {
        print('❌ Failed to start distance tracking');
      }
    } catch (e) {
      print('❌ Error starting distance tracking: $e');
    }
  }

  /// Stop distance tracking
  void _stopDistanceTracking() {
    try {
      print('📏 Stopping distance tracking...');
      RealtimeDistanceTracker.stopDistanceTracking();

      // Reset distance variables
      _remainingDistance = null;
      _distanceTraveled = null;
      _totalTripDistance = null;
      _progressPercentage = 0.0;

      // Trigger UI update
      if (mounted) {
        setState(() {});
      }

      print('✅ Distance tracking stopped');
    } catch (e) {
      print('❌ Error stopping distance tracking: $e');
    }
  }

  /// Handle distance updates
  void _handleDistanceUpdate(
    double remaining,
    double traveled,
    double total,
  ) async {
    if (!mounted) return;

    print('📏 _handleDistanceUpdate called with:');
    print('  Remaining: ${(remaining / 1000).toStringAsFixed(2)} km');
    print('  Traveled: ${(traveled / 1000).toStringAsFixed(2)} km');
    print('  Total: ${(total / 1000).toStringAsFixed(2)} km');

    setState(() {
      _remainingDistance = remaining;
      _distanceTraveled = traveled;
      _totalTripDistance = total;
    });

    // Calculate remaining time
    final remainingTime = await _calculateRemainingTime();
    setState(() {
      _remainingTime = remainingTime;
    });

    print(
      '📏 UI state updated - _remainingDistance: $_remainingDistance, _distanceTraveled: $_distanceTraveled',
    );
    print('📏 Widget will receive:');
    print('  remainingDistance: $_remainingDistance');
    print('  distanceTraveled: $_distanceTraveled');
    print('  totalTripDistance: $_totalTripDistance');
    print('  remainingTime: ${_formatRemainingTime(_remainingTime)}');

    // Update route line to show only remaining portion
    _updateRouteLineForProgress();
  }

  /// Handle distance errors
  void _handleDistanceError(String error) {
    print('❌ Distance tracking error: $error');
  }

  /// Handle progress updates
  void _handleProgressUpdate(double progress) {
    if (!mounted) return;

    print(
      '📊 _handleProgressUpdate called with: ${progress.toStringAsFixed(1)}%',
    );

    setState(() {
      _progressPercentage = progress;
    });

    print('📊 UI state updated - _progressPercentage: $_progressPercentage');

    // Update route line to show only remaining portion
    _updateRouteLineForProgress();
  }

  /// Update route line to show only remaining portion based on progress
  void _updateRouteLineForProgress() async {
    if (_polylineAnnotationManager == null || _mapboxMap == null) {
      print('❌ Cannot update route line - missing dependencies');
      return;
    }

    // Throttle route updates to prevent excessive redraws
    final now = DateTime.now();
    if (_lastRouteUpdate != null &&
        now.difference(_lastRouteUpdate!) < _minRouteUpdateInterval) {
      print('🔄 Throttling route update (too frequent)');
      return;
    }
    _lastRouteUpdate = now;

    final tripState = ref.read(tripProvider);
    final currentTrip = tripState.currentTrip;
    if (currentTrip == null) {
      print('❌ No active trip for route line update');
      return;
    }

    try {
      // Get current location
      final currentLocation =
          await LocationServiceResolver.getCurrentPosition();
      if (currentLocation == null) {
        print('❌ No current location for route line update');
        return;
      }

      // Get remaining route coordinates based on current position
      final remainingRouteCoordinates =
          await RealtimeDistanceTracker.getRemainingRouteCoordinates();
      if (remainingRouteCoordinates == null ||
          remainingRouteCoordinates.isEmpty) {
        print(
          '❌ No remaining route coordinates available for route line update',
        );
        print('🔄 Falling back to current location route display...');
        // Fall back to showing the route from current location if no remaining coordinates
        await _drawRouteFromCurrentLocation(currentTrip);
        return;
      }

      // Get current route progress for logging
      final routeProgress =
          await RealtimeDistanceTracker.getCurrentRouteProgress();
      print(
        '🔄 Updating route line - Route Progress: ${(routeProgress * 100).toStringAsFixed(1)}%, Remaining points: ${remainingRouteCoordinates.length}',
      );

      if (remainingRouteCoordinates.isEmpty) {
        print('✅ Trip completed - clearing route line');
        await _clearRoutePolyline();
        return;
      }

      // Add current location as the starting point of remaining route
      final currentLocationCoord = {
        'latitude': currentLocation.latitude,
        'longitude': currentLocation.longitude,
      };

      final updatedRouteCoordinates = [
        currentLocationCoord,
        ...remainingRouteCoordinates,
      ];

      // Convert to Position objects
      final routePositions = updatedRouteCoordinates
          .map((coord) => Position(coord['longitude']!, coord['latitude']!))
          .toList();

      // Remove existing route polyline
      if (_routePolyline != null) {
        await _polylineAnnotationManager!.delete(_routePolyline!);
        _routePolyline = null;
      }

      // Create new route line with remaining portion
      final routeLine = LineString(coordinates: routePositions);

      // Use green color for better identification of current location to destination
      Color routeColor = Colors.green;

      // Create polyline annotation
      final polylineOptions = PolylineAnnotationOptions(
        geometry: routeLine,
        lineColor: routeColor.value,
        lineWidth: 4.0,
        lineOpacity: 0.8,
      );

      _routePolyline = await _polylineAnnotationManager!.create(
        polylineOptions,
      );

      print(
        '✅ Route line updated - Remaining points: ${routePositions.length}, Color: ${routeColor.toString()}',
      );
    } catch (e) {
      print('❌ Error updating route line for progress: $e');
    }
  }

  /// Debug distance tracking
  void _debugDistanceTracking() async {
    print('\n🔍 DEBUG: Distance Tracking Status');
    print('===================================');

    // Get tracking status
    final status = await RealtimeDistanceTracker.getTrackingStatus();
    status.forEach((key, value) {
      print('$key: $value');
    });

    // Get formatted distances
    final distances = RealtimeDistanceTracker.getFormattedDistances();
    print('\n📏 Formatted Distances:');
    distances.forEach((key, value) {
      print('$key: $value');
    });

    // Show current UI state
    print('\n📱 Current UI State:');
    print('_remainingDistance: $_remainingDistance');
    print('_distanceTraveled: $_distanceTraveled');
    print('_totalTripDistance: $_totalTripDistance');
    print('_progressPercentage: $_progressPercentage');

    // Force distance update
    print('\n🔄 Forcing distance update...');
    await RealtimeDistanceTracker.forceDistanceUpdate();

    // Show current location
    final currentLocation = await LocationServiceResolver.getCurrentPosition();
    if (currentLocation != null) {
      print('\n📍 Current Location:');
      print('Latitude: ${currentLocation.latitude}');
      print('Longitude: ${currentLocation.longitude}');
      print('Accuracy: ${currentLocation.accuracy}m');
      print('Speed: ${currentLocation.speed.toStringAsFixed(1)} m/s');
    } else {
      print('\n❌ No current location available');
    }
  }

  /// Force distance update for testing
  void _forceDistanceUpdate() async {
    print('🔄 Manually forcing distance update...');
    try {
      await RealtimeDistanceTracker.forceDistanceUpdate();
      print('✅ Distance update forced successfully');
    } catch (e) {
      print('❌ Error forcing distance update: $e');
    }
  }

  /// Check for location service conflicts
  void _checkLocationConflicts() async {
    print('\n🔍 Checking for location service conflicts...');
    try {
      final conflicts = await LocationServiceResolver.checkConflicts();

      print('🔍 Conflict Check Results:');
      print('Has conflicts: ${conflicts['has_conflicts']}');

      if (conflicts['conflicts'].isNotEmpty) {
        print('❌ Conflicts found:');
        for (final conflict in conflicts['conflicts']) {
          print('  - $conflict');
        }
      }

      if (conflicts['recommendations'].isNotEmpty) {
        print('💡 Recommendations:');
        for (final recommendation in conflicts['recommendations']) {
          print('  - $recommendation');
        }
      }

      print('📊 Service Status:');
      final status = conflicts['service_status'] as Map<String, dynamic>;
      status.forEach((key, value) {
        print('  $key: $value');
      });
    } catch (e) {
      print('❌ Error checking conflicts: $e');
    }
  }

  /// Force accept current location (for testing)
  void _forceAcceptLocation() async {
    print('🆘 Force accepting current location...');
    try {
      final position = await LocationServiceResolver.getCurrentPosition();
      if (position != null) {
        LocationServiceResolver.forceAcceptLocation(position);
        print('✅ Location force accepted: ${position.accuracy}m accuracy');
      } else {
        print('❌ No location available to force accept');
      }
    } catch (e) {
      print('❌ Error force accepting location: $e');
    }
  }

  /// Force restart location service (for debugging)
  void _forceRestartLocationService() async {
    print('🔄 Force restarting location service...');
    try {
      await LocationServiceResolver.forceRestart();
      print('✅ Location service force restarted');
    } catch (e) {
      print('❌ Error force restarting location service: $e');
    }
  }

  /// Calculate remaining time to destination
  Future<Duration?> _calculateRemainingTime() async {
    try {
      final tripState = ref.read(tripProvider);
      final currentTrip = tripState.currentTrip;
      if (currentTrip == null) return null;

      // Get remaining distance
      final remainingDistance = _remainingDistance;
      if (remainingDistance == null || remainingDistance <= 0) return null;

      // Get current speed (if available from location service)
      final currentLocation =
          await LocationServiceResolver.getCurrentPosition();
      if (currentLocation == null) return null;

      // Estimate speed based on recent movement (simplified)
      // In a real implementation, you'd track speed over time
      const double estimatedSpeedKmh = 30.0; // Default school bus speed

      // Calculate time in minutes
      final timeInMinutes = (remainingDistance / 1000) / estimatedSpeedKmh * 60;

      return Duration(minutes: timeInMinutes.round());
    } catch (e) {
      print('❌ Error calculating remaining time: $e');
      return null;
    }
  }

  /// Format remaining time for display
  String _formatRemainingTime(Duration? remainingTime) {
    if (remainingTime == null) return 'Calculating...';

    if (remainingTime.inHours > 0) {
      return '${remainingTime.inHours}h ${remainingTime.inMinutes % 60}m';
    } else {
      return '${remainingTime.inMinutes}m';
    }
  }

  /// Get location name from coordinates (simplified version)
  String _getLocationName(
    double? latitude,
    double? longitude,
    String? locationName,
  ) {
    if (locationName != null && locationName.isNotEmpty) {
      return locationName;
    }

    if (latitude != null && longitude != null) {
      // Return a simplified coordinate format for display
      return '${latitude.toStringAsFixed(4)}, ${longitude.toStringAsFixed(4)}';
    }

    return 'Unknown Location';
  }

  Future<String?> _reverseGeocode(double lat, double lng) async {
    final key = '${lat.toStringAsFixed(6)},${lng.toStringAsFixed(6)}';
    if (_geocodeCache.containsKey(key)) return _geocodeCache[key];
    try {
      final places = await geocoding.placemarkFromCoordinates(lat, lng);
      if (places.isNotEmpty) {
        final p = places.first;
        final street = [p.street, p.thoroughfare, p.subLocality]
            .where((e) => e != null && e!.trim().isNotEmpty)
            .map((e) => e!.trim())
            .toList()
            .join(', ');
        final city = [p.locality, p.administrativeArea]
            .where((e) => e != null && e!.trim().isNotEmpty)
            .map((e) => e!.trim())
            .toList()
            .join(', ');
        final result = street.isNotEmpty
            ? (city.isNotEmpty ? '$street • $city' : street)
            : (city.isNotEmpty ? city : null);
        if (result != null) {
          _geocodeCache[key] = result;
        }
        return result;
      }
    } catch (_) {}
    return null;
  }

  void _centerMapOnCurrentLocation() {
    () async {
      final fresh = await LocationServiceResolver.getCurrentPosition();
      if (fresh != null) {
        _currentLocation = Point(
          coordinates: Position(fresh.longitude, fresh.latitude),
        );
      }
      if (_mapboxMap != null && _currentLocation != null) {
        _mapboxMap!.flyTo(
          CameraOptions(center: _currentLocation!, zoom: 16.0),
          MapAnimationOptions(duration: 900),
        );
      }
    }();
  }

  void _zoomToTripRoute(Trip trip) {
    if (_mapboxMap == null) {
      print('❌ DEBUG: Cannot zoom - map not ready');
      return;
    }

    Point? target;
    if (trip.status == TripStatus.inProgress && _currentLocation != null) {
      target = _currentLocation!; // exact current GPS
    } else if (trip.status == TripStatus.pending &&
        trip.startLatitude != null &&
        trip.startLongitude != null) {
      target = Point(
        coordinates: Position(trip.startLongitude!, trip.startLatitude!),
      );
    } else if (trip.status == TripStatus.completed &&
        trip.endLatitude != null &&
        trip.endLongitude != null) {
      target = Point(
        coordinates: Position(trip.endLongitude!, trip.endLatitude!),
      );
    } else if (trip.startLatitude != null && trip.startLongitude != null) {
      // Fallback to start if status unknown
      target = Point(
        coordinates: Position(trip.startLongitude!, trip.startLatitude!),
      );
    }

    if (target != null) {
      _mapboxMap!.flyTo(
        CameraOptions(center: target, zoom: 15.5),
        MapAnimationOptions(duration: 1200),
      );
      print(
        '✅ DEBUG: Map zoomed to exact target for status ${trip.status.name}',
      );
    } else {
      print('❌ DEBUG: No valid target to zoom to');
    }
  }

  Future<void> _clearRoutePolyline() async {
    if (_polylineAnnotationManager != null && _routePolyline != null) {
      try {
        await _polylineAnnotationManager!.delete(_routePolyline!);
        _routePolyline = null;
        print('✅ Route polyline cleared');
      } catch (e) {
        print('❌ Error clearing route polyline: $e');
      }
    }
  }

  void _refreshMapData() async {
    if (!mounted) return;

    print('🔄 Refreshing map data...');

    // Refresh active trip data
    await ref.read(tripProvider.notifier).loadActiveTrips();

    // Update map with new data
    if (_mapboxMap != null) {
      _addCurrentLocationMarker();
      _loadTripRoute();
      _addTripMarkers();
    }
  }

  void _toggleRouteVisibility() async {
    if (_routePolyline == null) {
      // Route is not visible, show it from current location
      final tripState = ref.read(tripProvider);
      if (tripState.currentTrip != null) {
        await _drawRouteFromCurrentLocation(tripState.currentTrip!);
        print('✅ Route polyline shown from current location');
      }
    } else {
      // Route is visible, hide it
      await _clearRoutePolyline();
      print('✅ Route polyline hidden');
    }
  }

  void _addTestGreenMarker() async {
    if (_mapboxMap == null || _pointAnnotationManager == null) {
      print('❌ Cannot add test green marker - map not ready');
      return;
    }

    try {
      print('🟢 DEBUG: Adding test green marker...');

      // Add a test green marker at a known location
      final testPoint = Point(
        coordinates: Position(36.817223, -1.286389), // Nairobi coordinates
      );

      final testGreenMarker = PointAnnotationOptions(
        geometry: testPoint,
        image: await _createMarkerImage(Colors.green, '🚀'),
      );

      await _pointAnnotationManager!.create(testGreenMarker);
      print('✅ Test green marker added successfully');
    } catch (e) {
      print('❌ Error adding test green marker: $e');
    }
  }

  Future<Uint8List> _createMarkerImage(Color color, String emoji) async {
    print('🎨 DEBUG: Creating marker image - Color: $color, Emoji: $emoji');

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final size = 60.0; // Increased from 40.0 for better visibility

    // Draw pin shape background
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // Create pin shape (rounded rectangle with pointed bottom)
    final pinPath = Path();
    final pinWidth = size * 0.6;
    final pinHeight = size * 0.8;
    final cornerRadius = size * 0.15;

    // Top rounded rectangle
    pinPath.addRRect(
      RRect.fromLTRBR(
        (size - pinWidth) / 2,
        (size - pinHeight) / 2,
        (size + pinWidth) / 2,
        (size + pinHeight) / 2 - size * 0.1,
        Radius.circular(cornerRadius),
      ),
    );

    // Bottom pointed triangle
    pinPath.moveTo(size / 2, (size + pinHeight) / 2 - size * 0.1);
    pinPath.lineTo(
      size / 2 - pinWidth / 3,
      (size + pinHeight) / 2 + size * 0.1,
    );
    pinPath.lineTo(
      size / 2 + pinWidth / 3,
      (size + pinHeight) / 2 + size * 0.1,
    );
    pinPath.close();

    canvas.drawPath(pinPath, paint);

    // Draw white border
    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    canvas.drawPath(pinPath, borderPaint);

    // Draw emoji in the center
    final textPainter = TextPainter(
      text: TextSpan(
        text: emoji,
        style: TextStyle(fontSize: size * 0.4, color: Colors.white),
      ),
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        (size - textPainter.width) / 2,
        (size - textPainter.height) / 2 - size * 0.05, // Slightly above center
      ),
    );

    // Convert to image
    final picture = recorder.endRecording();
    final image = await picture.toImage(size.toInt(), size.toInt());
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

    print(
      '🎨 DEBUG: Pin marker image created successfully - Size: ${byteData!.lengthInBytes} bytes',
    );
    return byteData.buffer.asUint8List();
  }
}

// Modern Trip Details Card with Dropdown

class _TripDetailsCard extends StatefulWidget {
  final TripState tripState;
  final Point? currentLocation;
  final double? remainingDistance;
  final double? distanceTraveled;
  final double? totalTripDistance;
  final double progressPercentage;
  final Duration? remainingTime;
  final String? currentStreetName;
  final String? destinationStreetName;

  const _TripDetailsCard({
    required this.tripState,
    this.currentLocation,
    this.remainingDistance,
    this.distanceTraveled,
    this.totalTripDistance,
    this.progressPercentage = 0.0,
    this.remainingTime,
    this.currentStreetName,
    this.destinationStreetName,
  });

  @override
  State<_TripDetailsCard> createState() => _TripDetailsCardState();
}

class _TripDetailsCardState extends State<_TripDetailsCard> {
  bool _isExpanded = false;

  /// Format remaining time for display
  String _formatRemainingTime(Duration remainingTime) {
    if (remainingTime.inHours > 0) {
      return '${remainingTime.inHours}h ${remainingTime.inMinutes % 60}m';
    } else {
      return '${remainingTime.inMinutes}m';
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentTrip = widget.tripState.currentTrip;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Main Trip Info (Always Visible)
          Padding(
            padding: EdgeInsets.all(20.w),
            child: Column(
              children: [
                // Trip Header
                Row(
                  children: [
                    Container(
                      width: 12.w,
                      height: 12.w,
                      decoration: BoxDecoration(
                        color: currentTrip != null
                            ? const Color(0xFF667EEA)
                            : Colors.grey[400],
                        shape: BoxShape.circle,
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            currentTrip != null
                                ? 'Active Trip'
                                : 'No Active Trip',
                            style: GoogleFonts.poppins(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                          SizedBox(height: 2.h),
                          Text(
                            currentTrip?.tripId ??
                                'Start a trip to see details',
                            style: GoogleFonts.poppins(
                              fontSize: 12.sp,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (currentTrip != null)
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _isExpanded = !_isExpanded;
                          });
                        },
                        child: Container(
                          padding: EdgeInsets.all(8.w),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          child: Icon(
                            _isExpanded
                                ? Icons.keyboard_arrow_up
                                : Icons.keyboard_arrow_down,
                            color: Colors.grey[600],
                            size: 20.w,
                          ),
                        ),
                      ),
                  ],
                ),

                if (currentTrip != null) ...[
                  SizedBox(height: 16.h),

                  // Trip Status
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 12.w,
                          vertical: 6.h,
                        ),
                        decoration: BoxDecoration(
                          color: _getStatusColor(
                            currentTrip.status,
                          ).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: Text(
                          _getStatusText(currentTrip.status),
                          style: GoogleFonts.poppins(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w600,
                            color: _getStatusColor(currentTrip.status),
                          ),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${_formatTime(currentTrip.actualStart)}',
                        style: GoogleFonts.poppins(
                          fontSize: 12.sp,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          // Expanded Trip Details (Dropdown)
          if (_isExpanded && currentTrip != null)
            Container(
              padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 20.w),
              child: Column(
                children: [
                  Container(height: 1.h, color: Colors.grey[200]),
                  SizedBox(height: 16.h),

                  // Trip Details
                  _TripDetailRow(
                    icon: Icons.route,
                    label: 'Route',
                    value: currentTrip.routeName ?? 'Unknown',
                  ),
                  SizedBox(height: 12.h),

                  _TripDetailRow(
                    icon: Icons.directions_bus,
                    label: 'Vehicle',
                    value: currentTrip.vehicleName ?? 'Unknown',
                  ),
                  SizedBox(height: 12.h),

                  _TripDetailRow(
                    icon: Icons.person,
                    label: 'Driver',
                    value: currentTrip.driverName ?? 'Unknown',
                  ),

                  // Distance Information
                  // Debug: Check what distance values we have
                  if (widget.remainingDistance != null ||
                      widget.distanceTraveled != null) ...[
                    SizedBox(height: 8.h),
                    Container(
                      padding: EdgeInsets.all(8.w),
                      decoration: BoxDecoration(
                        color: Colors.yellow.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Text(
                        'DEBUG: remaining=${widget.remainingDistance}, traveled=${widget.distanceTraveled}, total=${widget.totalTripDistance}',
                        style: GoogleFonts.poppins(fontSize: 10.sp),
                      ),
                    ),
                  ],
                  // Always show distance information section
                  SizedBox(height: 16.h),
                  Container(
                    padding: EdgeInsets.all(16.w),
                    decoration: BoxDecoration(
                      color: const Color(0xFF667EEA).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Column(
                      children: [
                        // Streets (if available)
                        if (widget.currentStreetName != null ||
                            widget.destinationStreetName != null) ...[
                          Row(
                            children: [
                              Icon(
                                Icons.place,
                                size: 14.w,
                                color: Colors.green,
                              ),
                              SizedBox(width: 6.w),
                              Expanded(
                                child: Text(
                                  widget.currentStreetName ??
                                      'Current street resolving...',
                                  style: GoogleFonts.poppins(
                                    fontSize: 11.sp,
                                    color: Colors.green[700],
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 4.h),
                          Row(
                            children: [
                              Icon(Icons.flag, size: 14.w, color: Colors.red),
                              SizedBox(width: 6.w),
                              Expanded(
                                child: Text(
                                  widget.destinationStreetName ??
                                      'Destination street resolving...',
                                  style: GoogleFonts.poppins(
                                    fontSize: 11.sp,
                                    color: Colors.red[700],
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 10.h),
                        ],
                        // Progress Header
                        Row(
                          children: [
                            Icon(
                              Icons.timeline,
                              color: const Color(0xFF667EEA),
                              size: 20.w,
                            ),
                            SizedBox(width: 8.w),
                            Text(
                              'Trip Progress',
                              style: GoogleFonts.poppins(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF667EEA),
                              ),
                            ),
                            const Spacer(),
                            Text(
                              '${widget.progressPercentage.toStringAsFixed(1)}%',
                              style: GoogleFonts.poppins(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF667EEA),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 12.h),

                        // Progress Bar
                        Container(
                          height: 8.h,
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(4.r),
                          ),
                          child: FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor: (widget.progressPercentage / 100)
                                .clamp(0.0, 1.0),
                            child: Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFF667EEA),
                                borderRadius: BorderRadius.circular(4.r),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: 16.h),

                        // Distance Information
                        Row(
                          children: [
                            Expanded(
                              child: _DistanceInfo(
                                icon: Icons.navigation,
                                label: 'Remaining',
                                value: widget.remainingDistance != null
                                    ? '${(widget.remainingDistance! / 1000).toStringAsFixed(2)} km'
                                    : 'Calculating...',
                                color: Colors.orange,
                              ),
                            ),
                            SizedBox(width: 12.w),
                            Expanded(
                              child: _DistanceInfo(
                                icon: Icons.check_circle,
                                label: 'Traveled',
                                value: widget.distanceTraveled != null
                                    ? '${(widget.distanceTraveled! / 1000).toStringAsFixed(2)} km'
                                    : 'Calculating...',
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),

                        // Time Information
                        if (widget.remainingTime != null) ...[
                          SizedBox(height: 12.h),
                          _TimeInfo(
                            icon: Icons.access_time,
                            label: 'Estimated Arrival',
                            value: _formatRemainingTime(widget.remainingTime!),
                            color: Colors.blue,
                          ),
                        ],
                      ],
                    ),
                  ),
                  SizedBox(height: 12.h),

                  if (currentTrip.startLocation != null)
                    _TripDetailRow(
                      icon: Icons.location_on,
                      label: 'Start Location',
                      value: currentTrip.startLocation!,
                    ),

                  if (currentTrip.startLocation != null) SizedBox(height: 12.h),

                  if (currentTrip.endLocation != null)
                    _TripDetailRow(
                      icon: Icons.flag,
                      label: 'End Location',
                      value: currentTrip.endLocation!,
                    ),

                  if (currentTrip.endLocation != null) SizedBox(height: 12.h),

                  _TripDetailRow(
                    icon: Icons.schedule,
                    label: 'Duration',
                    value: currentTrip.duration != null
                        ? '${currentTrip.duration} minutes'
                        : 'Not available',
                  ),

                  // ETA Information
                  if (currentTrip.estimatedArrival != null) ...[
                    SizedBox(height: 12.h),
                    _buildETASection(currentTrip),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }

  Color _getStatusColor(TripStatus status) {
    switch (status) {
      case TripStatus.pending:
        return Colors.orange;
      case TripStatus.inProgress:
        return Colors.green;
      case TripStatus.completed:
        return Colors.blue;
      case TripStatus.cancelled:
        return Colors.red;
      case TripStatus.delayed:
        return Colors.amber;
    }
  }

  String _getStatusText(TripStatus status) {
    switch (status) {
      case TripStatus.pending:
        return 'PENDING';
      case TripStatus.inProgress:
        return 'IN PROGRESS';
      case TripStatus.completed:
        return 'COMPLETED';
      case TripStatus.cancelled:
        return 'CANCELLED';
      case TripStatus.delayed:
        return 'DELAYED';
    }
  }

  String _formatTime(DateTime? time) {
    if (time == null) return 'Not started';
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  Widget _buildETASection(Trip trip) {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: trip.isRunningLate
            ? Colors.red.withOpacity(0.1)
            : Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(
          color: trip.isRunningLate
              ? Colors.red.withOpacity(0.3)
              : Colors.blue.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // ETA Header
          Row(
            children: [
              Icon(
                trip.isRunningLate ? Icons.warning : Icons.access_time,
                size: 16.w,
                color: trip.isRunningLate ? Colors.red : Colors.blue,
              ),
              SizedBox(width: 8.w),
              Text(
                'Estimated Arrival',
                style: GoogleFonts.poppins(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                  color: trip.isRunningLate ? Colors.red : Colors.blue,
                ),
              ),
              const Spacer(),
              if (trip.isRunningLate)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4.r),
                  ),
                  child: Text(
                    'DELAYED',
                    style: GoogleFonts.poppins(
                      fontSize: 8.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.red,
                    ),
                  ),
                ),
            ],
          ),

          SizedBox(height: 8.h),

          // ETA Time
          Row(
            children: [
              Text(
                'ETA: ',
                style: GoogleFonts.poppins(
                  fontSize: 12.sp,
                  color: Colors.grey[600],
                ),
              ),
              Text(
                trip.formattedTimeToArrival,
                style: GoogleFonts.poppins(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: trip.isRunningLate ? Colors.red : Colors.blue,
                ),
              ),
              const Spacer(),
              Text(
                _formatETA(trip.estimatedArrival!),
                style: GoogleFonts.poppins(
                  fontSize: 10.sp,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),

          // Traffic Conditions
          if (trip.trafficConditions != 'Unknown') ...[
            SizedBox(height: 4.h),
            Row(
              children: [
                Icon(Icons.traffic, size: 12.w, color: Colors.grey[600]),
                SizedBox(width: 4.w),
                Text(
                  trip.trafficConditions,
                  style: GoogleFonts.poppins(
                    fontSize: 10.sp,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  String _formatETA(DateTime eta) {
    final now = DateTime.now();
    final difference = eta.difference(now);

    if (difference.inHours > 0) {
      return '${eta.hour.toString().padLeft(2, '0')}:${eta.minute.toString().padLeft(2, '0')}';
    } else {
      return '${eta.hour.toString().padLeft(2, '0')}:${eta.minute.toString().padLeft(2, '0')}';
    }
  }
}

class _TripDetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _TripDetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16.w, color: Colors.grey[600]),
        SizedBox(width: 12.w),
        Text(
          '$label:',
          style: GoogleFonts.poppins(
            fontSize: 12.sp,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(width: 8.w),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 12.sp,
              color: Colors.black,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _CurrentLocationButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _CurrentLocationButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 50.w,
      height: 50.w,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(Icons.my_location, color: Colors.grey[700], size: 24.w),
      ),
    );
  }
}

class _RefreshButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _RefreshButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 50.w,
      height: 50.w,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(Icons.refresh, color: Colors.grey[700], size: 24.w),
      ),
    );
  }
}

class _TestGreenMarkerButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _TestGreenMarkerButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 50.w,
      height: 50.w,
      decoration: BoxDecoration(
        color: Colors.green,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(Icons.place, color: Colors.white, size: 24.w),
      ),
    );
  }
}

class _ZoomToStartButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _ZoomToStartButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 50.w,
      height: 50.w,
      decoration: BoxDecoration(
        color: Colors.blue,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(Icons.navigation, color: Colors.white, size: 24.w),
      ),
    );
  }
}

class _ToggleRouteButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _ToggleRouteButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 50.w,
      height: 50.w,
      decoration: BoxDecoration(
        color: Colors.purple,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(Icons.route, color: Colors.white, size: 24.w),
      ),
    );
  }
}

// Distance Information Widget
class _DistanceInfo extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _DistanceInfo({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20.w),
          SizedBox(height: 4.h),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 10.sp,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 2.h),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 12.sp,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// Time Information Widget
class _TimeInfo extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _TimeInfo({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20.w),
          SizedBox(width: 8.w),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 10.sp,
                  color: color,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 2.h),
              Text(
                value,
                style: GoogleFonts.poppins(
                  fontSize: 14.sp,
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Debug Distance Button Widget
class _DebugDistanceButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _DebugDistanceButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 50.w,
      height: 50.w,
      decoration: BoxDecoration(
        color: Colors.orange,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(Icons.bug_report, color: Colors.white, size: 24.w),
      ),
    );
  }
}

// Force Distance Update Button Widget
class _ForceDistanceUpdateButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _ForceDistanceUpdateButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 50.w,
      height: 50.w,
      decoration: BoxDecoration(
        color: Colors.purple,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(Icons.refresh, color: Colors.white, size: 24.w),
      ),
    );
  }
}

// Location Guidance Banner Widget
class _LocationGuidanceBanner extends StatelessWidget {
  final String message;
  final VoidCallback onDismiss;

  const _LocationGuidanceBanner({
    required this.message,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.all(16.w),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.9),
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(Icons.location_off, color: Colors.white, size: 24.w),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.poppins(
                fontSize: 14.sp,
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          GestureDetector(
            onTap: onDismiss,
            child: Icon(Icons.close, color: Colors.white, size: 20.w),
          ),
        ],
      ),
    );
  }
}

// Check Conflicts Button Widget
class _CheckConflictsButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _CheckConflictsButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 50.w,
      height: 50.w,
      decoration: BoxDecoration(
        color: Colors.red,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(Icons.bug_report, color: Colors.white, size: 24.w),
      ),
    );
  }
}

// Force Accept Location Button Widget
class _ForceAcceptLocationButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _ForceAcceptLocationButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 50.w,
      height: 50.w,
      decoration: BoxDecoration(
        color: Colors.orange,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(Icons.location_on, color: Colors.white, size: 24.w),
      ),
    );
  }
}

class _ForceRestartLocationButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _ForceRestartLocationButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 50.w,
      height: 50.w,
      decoration: BoxDecoration(
        color: Colors.red,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(Icons.restart_alt, color: Colors.white, size: 24.w),
      ),
    );
  }
}
