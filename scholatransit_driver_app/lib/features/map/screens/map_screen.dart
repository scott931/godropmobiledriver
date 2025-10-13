import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:typed_data';
import 'dart:ui' as ui;
import '../../../core/theme/app_theme.dart';
import '../../../core/config/app_config.dart';
import '../../../core/providers/location_provider.dart';
import '../../../core/providers/trip_provider.dart';
import '../../../core/models/trip_model.dart';

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
      backgroundColor: const Color(0xFFF3F4F6),
      body: Stack(
        children: [
          // Map
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
                _addTestMarker();
                _addCurrentLocationMarker();

                // Force load active trips and then add markers
                await ref.read(tripProvider.notifier).loadActiveTrips();
                _loadTripRoute();
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
            ),
          ),

          // Current Location Button
          Positioned(
            bottom: 30.h,
            right: 16.w,
            child: _CurrentLocationButton(
              onPressed: _centerMapOnCurrentLocation,
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
    if (_mapboxMap == null || _currentLocation == null || _pointAnnotationManager == null) {
      print('❌ Cannot add current location marker - missing dependencies');
      return;
    }

    try {
      print('🔍 DEBUG: Adding current location marker at: ${_currentLocation!.coordinates.lat}, ${_currentLocation!.coordinates.lng}');

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
      print('✅ Current location marker added to map at: ${_currentLocation!.coordinates.lat}, ${_currentLocation!.coordinates.lng}');
    } catch (e) {
      print('❌ Error adding current location marker: $e');
    }
  }

  void _loadTripRoute() async {
    if (_mapboxMap == null || _pointAnnotationManager == null) {
      print('❌ Map or annotation manager not ready for trip route');
      return;
    }

    final tripState = ref.read(tripProvider);
    final currentTrip = tripState.currentTrip;

    print('🔍 DEBUG: Current trip: ${currentTrip?.tripId}');
    print('🔍 DEBUG: Current trip status: ${currentTrip?.status.name}');
    print('🔍 DEBUG: Current trip start coords: ${currentTrip?.startLatitude}, ${currentTrip?.startLongitude}');
    print('🔍 DEBUG: Current trip end coords: ${currentTrip?.endLatitude}, ${currentTrip?.endLongitude}');

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
    if (_mapboxMap == null || _pointAnnotationManager == null) {
      print('❌ Map or annotation manager not ready');
      return;
    }

    final tripState = ref.read(tripProvider);
    print('🔍 DEBUG: Total trips loaded: ${tripState.trips.length}');
    print('🔍 DEBUG: Trip states: ${tripState.trips.map((t) => '${t.tripId}: ${t.status.name}').join(', ')}');

    final activeTrips = tripState.trips.where((trip) => trip.isActive).toList();
    print('🔍 DEBUG: Active trips found: ${activeTrips.length}');

    if (activeTrips.isEmpty) {
      print('ℹ️ No active trips to display markers for');
      return;
    }

    try {
      print('🚌 Adding markers for ${activeTrips.length} active trips:');
      for (final trip in activeTrips) {
        print('🔍 DEBUG: Trip ${trip.tripId} - Start: ${trip.startLatitude}, ${trip.startLongitude}');
        print('🔍 DEBUG: Trip ${trip.tripId} - End: ${trip.endLatitude}, ${trip.endLongitude}');
        print('🔍 DEBUG: Trip ${trip.tripId} - Status: ${trip.status.name}');

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
        } else {
          print('  ❌ Trip ${trip.tripId} has no valid coordinates');
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

    // Refresh active trip data
    await ref.read(tripProvider.notifier).loadActiveTrips();

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

// Modern Trip Details Card with Dropdown

class _TripDetailsCard extends StatefulWidget {
  final TripState tripState;
  final Point? currentLocation;

  const _TripDetailsCard({
    required this.tripState,
    this.currentLocation,
  });

  @override
  State<_TripDetailsCard> createState() => _TripDetailsCardState();
}

class _TripDetailsCardState extends State<_TripDetailsCard> {
  bool _isExpanded = false;

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
                        color: currentTrip != null ? const Color(0xFF667EEA) : Colors.grey[400],
                        shape: BoxShape.circle,
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            currentTrip != null ? 'Active Trip' : 'No Active Trip',
                            style: GoogleFonts.poppins(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w600,
                              color: Colors.black,
                            ),
                          ),
                          SizedBox(height: 2.h),
                          Text(
                            currentTrip?.tripId ?? 'Start a trip to see details',
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
                            _isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
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
                        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                        decoration: BoxDecoration(
                          color: _getStatusColor(currentTrip.status).withOpacity(0.1),
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
                  Container(
                    height: 1.h,
                    color: Colors.grey[200],
                  ),
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
                  SizedBox(height: 12.h),

                  if (currentTrip.startLocation != null)
                    _TripDetailRow(
                      icon: Icons.location_on,
                      label: 'Start Location',
                      value: currentTrip.startLocation!,
                    ),

                  if (currentTrip.startLocation != null)
                    SizedBox(height: 12.h),

                  if (currentTrip.endLocation != null)
                    _TripDetailRow(
                      icon: Icons.flag,
                      label: 'End Location',
                      value: currentTrip.endLocation!,
                    ),

                  if (currentTrip.endLocation != null)
                    SizedBox(height: 12.h),

                  _TripDetailRow(
                    icon: Icons.schedule,
                    label: 'Duration',
                    value: currentTrip.duration != null ? '${currentTrip.duration} minutes' : 'Not available',
                  ),
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
        Icon(
          icon,
          size: 16.w,
          color: Colors.grey[600],
        ),
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
        icon: Icon(
          Icons.my_location,
          color: Colors.grey[700],
          size: 24.w,
        ),
      ),
    );
  }
}