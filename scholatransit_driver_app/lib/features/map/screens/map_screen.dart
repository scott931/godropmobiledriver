import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'dart:typed_data';
import 'dart:ui' as ui;
import '../../../core/theme/app_theme.dart';
import '../../../core/config/app_config.dart';
import '../../../core/providers/location_provider.dart';
import '../../../core/providers/trip_provider.dart';

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  MapboxMap? _mapboxMap;
  Point? _currentLocation;
  List<Point> _routePoints = [];
  PointAnnotationManager? _pointAnnotationManager;
  PointAnnotation? _currentLocationAnnotation;
  PointAnnotation? _startLocationAnnotation;
  PointAnnotation? _endLocationAnnotation;

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

    // Try to get current location
    final locationState = ref.read(locationProvider);
    if (locationState.currentPosition != null) {
      _currentLocation = Point(
        coordinates: Position(
          locationState.currentPosition!.longitude,
          locationState.currentPosition!.latitude,
        ),
      );
      if (mounted) {
        setState(() {});
      }
    } else {
      // Try to get current location if not available
      try {
        await ref.read(locationProvider.notifier).getCurrentLocation();
        final updatedLocationState = ref.read(locationProvider);
        if (updatedLocationState.currentPosition != null) {
          _currentLocation = Point(
            coordinates: Position(
              updatedLocationState.currentPosition!.longitude,
              updatedLocationState.currentPosition!.latitude,
            ),
          );
          if (mounted) {
            setState(() {});
          }
        }
      } catch (e) {
        // Keep default location if getting current location fails
        print('Failed to get current location: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final locationState = ref.watch(locationProvider);
    final tripState = ref.watch(tripProvider);

    // Watch for changes in trip state and update map accordingly
    ref.listen(tripProvider, (previous, next) {
      if (_mapboxMap != null && next.currentTrip != null) {
        _loadTripRoute();
        _addTripMarkers();
      }
    });

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Live Map'),
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location),
            onPressed: () {
              _centerMapOnCurrentLocation();
            },
          ),
          IconButton(
            icon: const Icon(Icons.layers),
            onPressed: () {
              _showMapLayers();
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          _currentLocation == null
              ? const Center(
                  child: CircularProgressIndicator(),
                )
              : MapWidget(
              key: const ValueKey("mapWidget"),
              cameraOptions: CameraOptions(
                center: _currentLocation!,
                zoom: 15.0,
              ),
              styleUri: MapboxStyles.MAPBOX_STREETS,
              onMapCreated: (MapboxMap mapboxMap) async {
                _mapboxMap = mapboxMap;
                _pointAnnotationManager = await mapboxMap.annotations.createPointAnnotationManager();
                _addCurrentLocationMarker();
                _loadTripRoute();
              },
            ),
          // Debug info panel
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(8.r),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Trip Status',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14.sp,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  if (tripState.currentTrip != null) ...[
                    Text('Active Trip: ${tripState.currentTrip!.tripId}'),
                    Text('Status: ${tripState.currentTrip!.status.name}'),
                    Text('Route: ${tripState.currentTrip!.routeName ?? 'Unknown'}'),
                  ] else ...[
                    Text('No active trip'),
                  ],
                  Text('Total Trips: ${tripState.trips.length}'),
                  Text('Active Trips: ${tripState.trips.where((t) => t.isActive).length}'),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            onPressed: () {
              _refreshMapData();
            },
            child: const Icon(Icons.refresh),
            backgroundColor: AppTheme.secondaryColor,
            heroTag: "refresh",
          ),
          SizedBox(height: 8.h),
          FloatingActionButton(
            onPressed: () {
              _updateCurrentLocation();
            },
            child: const Icon(Icons.location_on),
            backgroundColor: AppTheme.primaryColor,
            heroTag: "location",
          ),
        ],
      ),
    );
  }

  void _addCurrentLocationMarker() async {
    if (_mapboxMap == null || _currentLocation == null || _pointAnnotationManager == null) return;

    try {
      // Remove existing current location marker
      if (_currentLocationAnnotation != null) {
        await _pointAnnotationManager!.delete(_currentLocationAnnotation!);
      }

      // Create current location marker
      final currentLocationMarker = PointAnnotationOptions(
        geometry: _currentLocation!,
        image: await _createMarkerImage(Colors.blue, '📍'),
      );

      _currentLocationAnnotation = await _pointAnnotationManager!.create(currentLocationMarker);
      print('✅ Current location marker added to map');
    } catch (e) {
      print('❌ Error adding current location marker: $e');
    }
  }

  void _loadTripRoute() async {
    if (_mapboxMap == null || _pointAnnotationManager == null) return;

    final tripState = ref.read(tripProvider);
    final currentTrip = tripState.currentTrip;

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
      if (currentTrip.startLatitude != null && currentTrip.startLongitude != null) {
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

        _startLocationAnnotation = await _pointAnnotationManager!.create(startMarker);
        print('✅ Start location marker added: ${currentTrip.startLatitude}, ${currentTrip.startLongitude}');
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

        _endLocationAnnotation = await _pointAnnotationManager!.create(endMarker);
        print('✅ End location marker added: ${currentTrip.endLatitude}, ${currentTrip.endLongitude}');
      }

      print('✅ Trip route markers added to map for trip: ${currentTrip.tripId}');
    } catch (e) {
      print('❌ Error adding trip route markers: $e');
    }
  }

  void _addTripMarkers() async {
    if (_mapboxMap == null || _pointAnnotationManager == null) return;

    final tripState = ref.read(tripProvider);
    final activeTrips = tripState.trips.where((trip) => trip.isActive).toList();

    if (activeTrips.isEmpty) {
      print('ℹ️ No active trips to display markers for');
      return;
    }

    try {
      print('🚌 Adding markers for ${activeTrips.length} active trips:');
      for (final trip in activeTrips) {
        if (trip.startLatitude != null && trip.startLongitude != null) {
          final tripPoint = Point(
            coordinates: Position(
              trip.startLongitude!,
              trip.startLatitude!,
            ),
          );

          final tripMarker = PointAnnotationOptions(
            geometry: tripPoint,
            image: await _createMarkerImage(Colors.orange, '🚌'),
          );

          await _pointAnnotationManager!.create(tripMarker);
          print('  ✅ Trip ${trip.tripId} marker added at: ${trip.startLatitude}, ${trip.startLongitude}');
        }
      }
      print('✅ All trip markers added to map');
    } catch (e) {
      print('❌ Error adding trip markers: $e');
    }
  }

  void _centerMapOnCurrentLocation() {
    if (_mapboxMap != null && _currentLocation != null) {
      _mapboxMap!.flyTo(
        CameraOptions(
          center: _currentLocation!,
          zoom: 15.0,
        ),
        MapAnimationOptions(duration: 1000),
      );
    }
  }

  void _showMapLayers() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: EdgeInsets.all(16.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Map Layers',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            SizedBox(height: 16.h),
            ListTile(
              leading: const Icon(Icons.traffic),
              title: const Text('Traffic'),
              onTap: () {
                // Toggle traffic layer
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.satellite),
              title: const Text('Satellite'),
              onTap: () {
                // Toggle satellite view
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _updateCurrentLocation() async {
    // Request location update
    await ref.read(locationProvider.notifier).getCurrentLocation();

    final locationState = ref.read(locationProvider);
    if (locationState.currentPosition != null) {
      setState(() {
        _currentLocation = Point(
          coordinates: Position(
            locationState.currentPosition!.longitude,
            locationState.currentPosition!.latitude,
          ),
        );
      });

      if (_mapboxMap != null) {
        _mapboxMap!.flyTo(
          CameraOptions(
            center: _currentLocation!,
            zoom: 15.0,
          ),
          MapAnimationOptions(duration: 1000),
        );
        _addCurrentLocationMarker();
      }
    }
  }

  void _refreshMapData() async {
    print('🔄 Refreshing map data...');

    // Refresh trip data
    await ref.read(tripProvider.notifier).loadTrips();

    // Update map with new data
    if (_mapboxMap != null) {
      _addCurrentLocationMarker();
      _loadTripRoute();
      _addTripMarkers();
    }
  }

  Future<Uint8List> _createMarkerImage(Color color, String emoji) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final size = 40.0;

    // Draw circle background
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    canvas.drawCircle(Offset(size / 2, size / 2), size / 2, paint);

    // Draw white border
    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    canvas.drawCircle(Offset(size / 2, size / 2), size / 2 - 1.5, borderPaint);

    // Convert to image
    final picture = recorder.endRecording();
    final image = await picture.toImage(size.toInt(), size.toInt());
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

    return byteData!.buffer.asUint8List();
  }
}


