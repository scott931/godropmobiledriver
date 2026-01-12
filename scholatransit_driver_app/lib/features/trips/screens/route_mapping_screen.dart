import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';
import '../../../core/config/app_config.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/trip_provider.dart';
import '../../../core/providers/location_provider.dart';
import '../../../core/models/trip_model.dart';
import '../../../core/services/route_mapping_service.dart' show RouteMappingService, RouteMap, RouteStop;
import '../../../core/services/routing_service.dart';

class RouteMappingScreen extends ConsumerStatefulWidget {
  final int tripId;

  const RouteMappingScreen({super.key, required this.tripId});

  @override
  ConsumerState<RouteMappingScreen> createState() => _RouteMappingScreenState();
}

class _RouteMappingScreenState extends ConsumerState<RouteMappingScreen> {
  MapboxMap? _mapboxMap;
  RouteMap? _routeMap;
  bool _isLoading = true;
  String? _error;
  PointAnnotationManager? _pointAnnotationManager;
  PolylineAnnotationManager? _polylineAnnotationManager;
  final List<PointAnnotation> _stopAnnotations = [];
  PointAnnotation? _schoolAnnotation;
  PolylineAnnotation? _routePolyline;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadRouteMap();
    });
  }

  Future<void> _loadRouteMap() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final tripState = ref.read(tripProvider);
      final trip = tripState.selectedTrip ?? tripState.trips.firstWhere(
        (t) => t.id == widget.tripId,
        orElse: () => throw Exception('Trip not found'),
      );

      // Load students if not already loaded
      if (tripState.students.isEmpty) {
        await ref.read(tripProvider.notifier).loadTripStudents(trip.id);
      }

      final students = ref.read(tripProvider).students;
      final locationState = ref.read(locationProvider);
      final currentPosition = locationState.currentPosition;

      final routeMap = await RouteMappingService.calculateRouteMap(
        trip: trip,
        students: students,
        currentLat: currentPosition?.latitude,
        currentLng: currentPosition?.longitude,
      );

      if (routeMap != null) {
        setState(() {
          _routeMap = routeMap;
          _isLoading = false;
        });
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _updateMap();
        });
      } else {
        setState(() {
          _error = 'Failed to calculate route map';
          _isLoading = false;
        });
      }
    } catch (e) {
      print('❌ Route Mapping Screen: Error loading route: $e');
      setState(() {
        _error = 'Error loading route: $e';
        _isLoading = false;
      });
    }
  }

  void _updateMap() async {
    if (_mapboxMap == null || _routeMap == null) return;

    try {
      // Clear existing annotations
      await _clearAnnotations();

      // Add route polyline
      if (_routeMap!.routePath.isNotEmpty) {
        final coordinates = _routeMap!.routePath.map((coord) {
          return Position(coord['longitude']!, coord['latitude']!);
        }).toList();

        final lineString = LineString(coordinates: coordinates);

        _polylineAnnotationManager = await _mapboxMap!.annotations
            .createPolylineAnnotationManager();

        // Convert color string to int (format: #4285F4 -> 0xFF4285F4)
        final colorString = AppConfig.routeColorPrimary.replaceFirst('#', '');
        final routeColor = int.parse('0xFF$colorString');

        _routePolyline = await _polylineAnnotationManager!.create(
          PolylineAnnotationOptions(
            geometry: lineString,
            lineColor: routeColor,
            lineWidth: 4.0,
            lineOpacity: 0.8,
          ),
        );
      }

      // Add stop markers
      for (int i = 0; i < _routeMap!.stops.length; i++) {
        final stop = _routeMap!.stops[i];
        final annotation = await _pointAnnotationManager!.create(
          PointAnnotationOptions(
            geometry: Point(
              coordinates: Position(stop.longitude, stop.latitude),
            ),
            textField: '${i + 1}',
            textColor: Colors.white.value,
            textSize: 14.0,
            textOffset: [0.0, -2.0],
            iconColor: const Color(0xFF1E3A8A).value,
            iconSize: 1.2,
          ),
        );
        _stopAnnotations.add(annotation);
      }

      // Add school marker
      if (_routeMap!.schoolStop != null) {
        _schoolAnnotation = await _pointAnnotationManager!.create(
          PointAnnotationOptions(
            geometry: Point(
              coordinates: Position(
                _routeMap!.schoolStop!.longitude,
                _routeMap!.schoolStop!.latitude,
              ),
            ),
            textField: 'S',
            textColor: Colors.white.value,
            textSize: 14.0,
            iconColor: const Color(0xFF059669).value,
            iconSize: 1.2,
          ),
        );
      }

      // Fit bounds to show all stops
      if (_routeMap!.stops.isNotEmpty || _routeMap!.schoolStop != null) {
        final allPoints = <Position>[];
        for (final stop in _routeMap!.stops) {
          allPoints.add(Position(stop.longitude, stop.latitude));
        }
        if (_routeMap!.schoolStop != null) {
          allPoints.add(Position(
            _routeMap!.schoolStop!.longitude,
            _routeMap!.schoolStop!.latitude,
          ));
        }

        if (allPoints.isNotEmpty) {
          // Calculate center and zoom to fit all points
          double minLat = allPoints[0].lat.toDouble();
          double maxLat = allPoints[0].lat.toDouble();
          double minLng = allPoints[0].lng.toDouble();
          double maxLng = allPoints[0].lng.toDouble();

          for (final pos in allPoints) {
            final lat = pos.lat.toDouble();
            final lng = pos.lng.toDouble();
            if (lat < minLat) minLat = lat;
            if (lat > maxLat) maxLat = lat;
            if (lng < minLng) minLng = lng;
            if (lng > maxLng) maxLng = lng;
          }

          final centerLat = (minLat + maxLat) / 2;
          final centerLng = (minLng + maxLng) / 2;
          
          // Calculate zoom level based on bounds
          final latDiff = maxLat - minLat;
          final lngDiff = maxLng - minLng;
          final maxDiff = latDiff > lngDiff ? latDiff : lngDiff;
          double zoom = 12.0;
          if (maxDiff > 0.1) zoom = 11.0;
          if (maxDiff > 0.2) zoom = 10.0;
          if (maxDiff < 0.01) zoom = 14.0;
          if (maxDiff < 0.005) zoom = 15.0;

          await _mapboxMap!.flyTo(
            CameraOptions(
              center: Point(coordinates: Position(centerLng, centerLat)),
              zoom: zoom,
            ),
            MapAnimationOptions(duration: 1000),
          );
        }
      }
    } catch (e) {
      print('❌ Route Mapping Screen: Error updating map: $e');
    }
  }

  Future<void> _clearAnnotations() async {
    if (_pointAnnotationManager != null) {
      for (final annotation in _stopAnnotations) {
        await _pointAnnotationManager!.delete(annotation);
      }
      _stopAnnotations.clear();

      if (_schoolAnnotation != null) {
        await _pointAnnotationManager!.delete(_schoolAnnotation!);
        _schoolAnnotation = null;
      }
    }

    if (_polylineAnnotationManager != null && _routePolyline != null) {
      await _polylineAnnotationManager!.delete(_routePolyline!);
      _routePolyline = null;
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.grey[700], size: 24.w),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Route Map',
          style: GoogleFonts.poppins(
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1E3A8A),
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.grey[600], size: 24.w),
            onPressed: _loadRouteMap,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline,
                          size: 64.w, color: Colors.grey[400]),
                      SizedBox(height: 16.h),
                      Text(
                        _error!,
                        style: GoogleFonts.poppins(
                          fontSize: 16.sp,
                          color: Colors.grey[600],
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 24.h),
                      ElevatedButton(
                        onPressed: _loadRouteMap,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _routeMap == null
                  ? const Center(child: Text('No route data available'))
                  : Column(
                      children: [
                        // Map
                        Expanded(
                          child: MapWidget(
                            key: const ValueKey('route-map'),
                            cameraOptions: CameraOptions(
                              center: Point(
                                coordinates: Position(
                                  AppConfig.defaultLongitude,
                                  AppConfig.defaultLatitude,
                                ),
                              ),
                              zoom: 12.0,
                            ),
                            styleUri: MapboxStyles.MAPBOX_STREETS,
                            textureView: true,
                            onMapCreated: (MapboxMap mapboxMap) async {
                              _mapboxMap = mapboxMap;
                              _pointAnnotationManager =
                                  await mapboxMap.annotations
                                      .createPointAnnotationManager();
                              _polylineAnnotationManager =
                                  await mapboxMap.annotations
                                      .createPolylineAnnotationManager();
                              _updateMap();
                            },
                          ),
                        ),

                        // Route Summary
                        Container(
                          padding: EdgeInsets.all(20.w),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 10,
                                offset: const Offset(0, -2),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Summary Header
                              Row(
                                children: [
                                  Icon(Icons.route,
                                      color: const Color(0xFF1E3A8A), size: 24.w),
                                  SizedBox(width: 12.w),
                                  Text(
                                    'Route Summary',
                                    style: GoogleFonts.poppins(
                                      fontSize: 18.sp,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 16.h),

                              // Summary Stats
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildSummaryItem(
                                      icon: Icons.location_on,
                                      label: 'Stops',
                                      value: '${_routeMap!.stops.length}',
                                      color: const Color(0xFF1E3A8A),
                                    ),
                                  ),
                                  SizedBox(width: 12.w),
                                  Expanded(
                                    child: _buildSummaryItem(
                                      icon: Icons.straighten,
                                      label: 'Distance',
                                      value: _routeMap!.formattedTotalDistance,
                                      color: const Color(0xFF059669),
                                    ),
                                  ),
                                  SizedBox(width: 12.w),
                                  Expanded(
                                    child: _buildSummaryItem(
                                      icon: Icons.access_time,
                                      label: 'Duration',
                                      value: _routeMap!.formattedTotalDuration,
                                      color: const Color(0xFFDC2626),
                                    ),
                                  ),
                                ],
                              ),

                              // ETA to School
                              if (_routeMap!.etaToSchool != null) ...[
                                SizedBox(height: 16.h),
                                Container(
                                  padding: EdgeInsets.all(16.w),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF1E3A8A)
                                        .withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12.r),
                                    border: Border.all(
                                      color: const Color(0xFF1E3A8A)
                                          .withOpacity(0.3),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.school,
                                          color: const Color(0xFF1E3A8A),
                                          size: 24.w),
                                      SizedBox(width: 12.w),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'ETA to School',
                                              style: GoogleFonts.poppins(
                                                fontSize: 12.sp,
                                                color: Colors.grey[600],
                                              ),
                                            ),
                                            SizedBox(height: 4.h),
                                            Text(
                                              _routeMap!.formattedETAToSchool,
                                              style: GoogleFonts.poppins(
                                                fontSize: 18.sp,
                                                fontWeight: FontWeight.w600,
                                                color: const Color(0xFF1E3A8A),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],

                              // Stops List
                              SizedBox(height: 16.h),
                              Text(
                                'Stops (${_routeMap!.stops.length})',
                                style: GoogleFonts.poppins(
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black,
                                ),
                              ),
                              SizedBox(height: 12.h),
                              SizedBox(
                                height: 200.h,
                                child: ListView.builder(
                                  itemCount: _routeMap!.stops.length,
                                  itemBuilder: (context, index) {
                                    final stop = _routeMap!.stops[index];
                                    return _buildStopCard(stop, index + 1);
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
    );
  }

  Widget _buildSummaryItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20.w),
          SizedBox(height: 8.h),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12.sp,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStopCard(RouteStop stop, int stopNumber) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          // Stop Number
          Container(
            width: 40.w,
            height: 40.w,
            decoration: BoxDecoration(
              color: const Color(0xFF1E3A8A),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$stopNumber',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 16.sp,
                ),
              ),
            ),
          ),
          SizedBox(width: 12.w),
          // Stop Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  stop.name,
                  style: GoogleFonts.poppins(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  stop.address,
                  style: GoogleFonts.poppins(
                    fontSize: 12.sp,
                    color: Colors.grey[600],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (stop.studentNames.isNotEmpty) ...[
                  SizedBox(height: 4.h),
                  Text(
                    'Students: ${stop.studentNames.join(", ")}',
                    style: GoogleFonts.poppins(
                      fontSize: 11.sp,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ],
            ),
          ),
          // ETA
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (stop.eta != null)
                Text(
                  stop.formattedETA,
                  style: GoogleFonts.poppins(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF059669),
                  ),
                )
              else
                Text(
                  'Calculating...',
                  style: GoogleFonts.poppins(
                    fontSize: 12.sp,
                    color: Colors.grey[500],
                  ),
                ),
              if (stop.distance != null) ...[
                SizedBox(height: 4.h),
                Text(
                  stop.distance! < 1000
                      ? '${stop.distance!.toStringAsFixed(0)} m'
                      : '${(stop.distance! / 1000).toStringAsFixed(2)} km',
                  style: GoogleFonts.poppins(
                    fontSize: 11.sp,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _clearAnnotations();
    super.dispose();
  }
}
