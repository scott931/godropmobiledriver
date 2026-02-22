import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/trip_provider.dart';
import '../../../core/providers/route_provider.dart';
import '../../../core/models/trip_model.dart';
import '../../../core/models/route_model.dart';
import '../../../core/widgets/notification_badge.dart';
import '../../../core/config/app_config.dart';
import '../../../core/services/location_service_resolver.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  Point? _currentLocation;
  PointAnnotationManager? _pointAnnotationManager;
  PointAnnotation? _currentLocationAnnotation;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    // Load dashboard data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(tripProvider.notifier).loadActiveTrips();
      ref.read(routeProvider.notifier).loadDriverAssignments();
      _initializeMap();
    });
  }

  void _initializeMap() async {
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

    // Get current location
    try {
      final position = await LocationServiceResolver.getCurrentPosition();
      if (position != null) {
        _currentLocation = Point(
          coordinates: Position(position.longitude, position.latitude),
        );
        if (mounted) {
          setState(() {});
        }
      }
    } catch (e) {
      print('❌ Failed to get location: $e');
    }
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good Morning,';
    } else if (hour < 17) {
      return 'Good Afternoon,';
    } else {
      return 'Good Evening,';
    }
  }

  /// Safely converts API/JSON maps to Map<String, dynamic> to avoid type cast errors.
  static Map<String, dynamic>? _toMap(dynamic value) {
    if (value == null) return null;
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return null;
  }

  List<Map<String, dynamic>> _getAssignedVehicles(
    List<Trip> trips,
    List<RouteAssignment> routeAssignments,
    List<Map<String, dynamic>> directVehicles, {
    Map<String, dynamic>? profileRawData,
  }) {
    // Extract unique vehicles from trips, route assignments, direct vehicles API, and driver profile
    final Map<int, Map<String, dynamic>> uniqueVehicles = {};

    // 1. From trips (may have vehicleId + vehicleName)
    for (final trip in trips) {
      final vehicleId = trip.vehicleId;
      if (vehicleId != null && vehicleId > 0) {
        final name = trip.vehicleName ?? 'Vehicle $vehicleId';
        if (!uniqueVehicles.containsKey(vehicleId)) {
          uniqueVehicles[vehicleId] = {
            'id': vehicleId,
            'name': name,
            'license': trip.vehicleName ?? vehicleId.toString(),
            'type': _getVehicleTypeFromName(name),
            'status': trip.isActive ? 'Active' : 'Available',
          };
        } else if (trip.isActive) {
          uniqueVehicles[vehicleId]!['status'] = 'Active';
        }
      }
    }

    // 2. From route assignments (vehicleId + vehicleLicensePlate)
    for (final a in routeAssignments) {
      final vehicleId = a.vehicleId;
      if (vehicleId > 0 && !uniqueVehicles.containsKey(vehicleId)) {
        final name = a.vehicleLicensePlate.isNotEmpty
            ? a.vehicleLicensePlate
            : 'Vehicle $vehicleId';
        uniqueVehicles[vehicleId] = {
          'id': vehicleId,
          'name': name,
          'license': a.vehicleLicensePlate,
          'type': _getVehicleTypeFromName(name),
          'status': a.isActive ? 'Active' : 'Available',
        };
      }
    }

    // 3. From direct vehicles API (e.g. /drivers/me/vehicles/)
    for (final v in directVehicles) {
      final vid = (v['id'] ?? v['vehicle_id']) as int?;
      if (vid != null && vid > 0 && !uniqueVehicles.containsKey(vid)) {
        final n = (v['name'] ?? v['license_plate'] ?? v['license_plate_number'])?.toString();
        final lic = (v['license_plate'] ?? v['license_plate_number'] ?? n)?.toString();
        uniqueVehicles[vid] = {
          'id': vid,
          'name': n ?? 'Vehicle $vid',
          'license': lic ?? vid.toString(),
          'type': _getVehicleTypeFromName(n ?? ''),
          'status': 'Assigned',
        };
      }
    }

    // 4. From driver profile - use safe map access (avoids Map<dynamic,dynamic> cast errors)
    if (profileRawData != null) {
      final pd = _toMap(profileRawData['profile_data']);
      final di = _toMap(pd?['driver_info'] ?? pd?['driver']);
      final v = _toMap(profileRawData['assigned_vehicle']) ??
          _toMap(profileRawData['vehicle']) ??
          _toMap(pd?['assigned_vehicle']) ??
          _toMap(pd?['vehicle']) ??
          _toMap(di?['assigned_vehicle']) ??
          _toMap(di?['vehicle']);
      int? vehicleId;
      String? name;
      String? license;
      if (v != null) {
        vehicleId = (v['id'] ?? v['vehicle_id']) as int?;
        name = (v['name'] ?? v['license_plate'] ?? v['license_plate_number'])?.toString();
        license = (v['license_plate'] ?? v['license_plate_number'] ?? name)?.toString();
      }
      if (vehicleId == null &&
          (profileRawData['assigned_vehicle_id'] != null || profileRawData['vehicle_id'] != null)) {
        vehicleId = (profileRawData['assigned_vehicle_id'] ??
            profileRawData['vehicle_id']) as int?;
        name = (profileRawData['assigned_vehicle_name'] ??
            profileRawData['vehicle_name'] ??
            profileRawData['vehicle_license_plate'])?.toString();
        license = (profileRawData['vehicle_license_plate'] ??
            profileRawData['assigned_vehicle_license'] ??
            name)?.toString();
      }
      if (vehicleId != null && vehicleId > 0 && !uniqueVehicles.containsKey(vehicleId)) {
        uniqueVehicles[vehicleId] = {
          'id': vehicleId,
          'name': name ?? 'Vehicle $vehicleId',
          'license': license ?? vehicleId.toString(),
          'type': _getVehicleTypeFromName(name ?? ''),
          'status': 'Assigned',
        };
      }
    }

    // 5. Multiple assigned vehicles from profile (assigned_vehicles, vehicles arrays)
    if (profileRawData != null) {
      final pd = _toMap(profileRawData['profile_data']);
      final list = profileRawData['assigned_vehicles'] as List? ??
          pd?['assigned_vehicles'] as List? ??
          (profileRawData['vehicles'] as List?) ??
          (pd?['vehicles'] as List?);
      if (list != null) {
        for (final item in list) {
          final map = _toMap(item);
          if (map != null) {
            final vid = (map['id'] ?? map['vehicle_id']) as int?;
            if (vid != null && vid > 0 && !uniqueVehicles.containsKey(vid)) {
              final n = (map['name'] ?? map['license_plate'] ?? map['license_plate_number'])?.toString();
              final lic = (map['license_plate'] ?? map['license_plate_number'] ?? n)?.toString();
              uniqueVehicles[vid] = {
                'id': vid,
                'name': n ?? 'Vehicle $vid',
                'license': lic ?? vid.toString(),
                'type': _getVehicleTypeFromName(n ?? ''),
                'status': 'Assigned',
              };
            }
          }
        }
      }
    }

    return uniqueVehicles.values.toList();
  }

  String _getVehicleTypeFromName(String vehicleName) {
    final name = vehicleName.toLowerCase();
    if (name.contains('bus')) return 'bus';
    if (name.contains('van')) return 'van';
    if (name.contains('car')) return 'car';
    if (name.contains('truck')) return 'truck';
    return 'bus'; // Default to bus
  }

  IconData _getVehicleIcon(String type) {
    switch (type.toLowerCase()) {
      case 'bus':
        return Icons.directions_bus;
      case 'van':
        return Icons.airport_shuttle;
      case 'car':
        return Icons.directions_car;
      case 'truck':
        return Icons.local_shipping;
      default:
        return Icons.directions_bus;
    }
  }

  void _addCurrentLocationMarker() async {
    if (_pointAnnotationManager == null || _currentLocation == null) return;

    // Clear existing marker
    if (_currentLocationAnnotation != null) {
      await _pointAnnotationManager!.delete(_currentLocationAnnotation!);
    }

    // Create new marker with default style
    _currentLocationAnnotation = await _pointAnnotationManager!.create(
      PointAnnotationOptions(
        geometry: _currentLocation!,
        iconSize: 1.0,
        iconOffset: [0.0, 0.0],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final tripState = ref.watch(tripProvider);
    final routeState = ref.watch(routeProvider);

    // Listen for auth changes - only reset on logout (initState handles initial load)
    ref.listen<AuthState>(authProvider, (previous, next) {
      if (previous != null && !next.isAuthenticated && previous!.isAuthenticated) {
        ref.read(tripProvider.notifier).resetState();
      }
    });

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        automaticallyImplyLeading: false,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
        ),
        title: Row(
          children: [
            Text(
              'Dashboard',
              style: GoogleFonts.poppins(
                fontSize: 20.sp,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF0052CC),
              ),
            ),
            const Spacer(),
            Container(
              margin: EdgeInsets.only(right: 8.w),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: NotificationBadge(
                onPressed: () => context.go('/notifications'),
                child: IconButton(
                  icon: const Icon(
                    Icons.notifications_outlined,
                    color: Colors.black54,
                    size: 20,
                  ),
                  onPressed: () => context.go('/notifications'),
                ),
              ),
            ),
            Container(
              margin: EdgeInsets.only(right: 16.w),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: IconButton(
                icon: const Icon(
                  Icons.account_circle_outlined,
                  color: Colors.black54,
                  size: 20,
                ),
                onPressed: () => context.go('/profile'),
              ),
            ),
          ],
        ),
      ),
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: () async {
              if (_isRefreshing) return;
              if (!mounted) return;
              setState(() => _isRefreshing = true);
              try {
                // Refresh driver profile to get latest data (overlay shows "Refreshing..." below)
                await ref.read(authProvider.notifier).loadDriverProfile();
                if (!mounted) return;
                await ref.read(tripProvider.notifier).loadActiveTrips();
                if (!mounted) return;
                await ref.read(routeProvider.notifier).loadDriverAssignments();
              } finally {
                if (mounted) setState(() => _isRefreshing = false);
              }
            },
            child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Modern Header Section
              Container(
                width: double.infinity,
                padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 30.h),
                decoration: const BoxDecoration(color: Colors.white),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          _getGreeting(),
                          style: GoogleFonts.poppins(
                            fontSize: 16.sp,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        SizedBox(width: 8.w),
                        Icon(
                          Icons.waving_hand,
                          color: Colors.orange[400],
                          size: 20.w,
                        ),
                      ],
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      authState.driver?.fullName ?? 'Driver',
                      style: GoogleFonts.poppins(
                        fontSize: 22.sp,
                        color: Colors.black,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

              // Current Trip Banner
              Container(
                width: double.infinity,
                margin: EdgeInsets.symmetric(horizontal: 20.w),
                padding: EdgeInsets.all(24.w),
                decoration: BoxDecoration(
                  color: const Color(0xFF0052CC),
                  borderRadius: BorderRadius.circular(16.r),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0052CC).withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: tripState.trips.where((trip) => trip.isActive).isNotEmpty
                    ? _ActiveTripBanner(
                        activeTrip: tripState.trips
                            .where((trip) => trip.isActive)
                            .first,
                      )
                    : _NoActiveTripBanner(),
              ),

              SizedBox(height: 24.h),

              // Vehicle Position Section
              Container(
                margin: EdgeInsets.symmetric(horizontal: 20.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your Vehicle\'s Current Position',
                      style: GoogleFonts.poppins(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                    SizedBox(height: 16.h),

                    // Real Map Container
                    GestureDetector(
                      onTap: () => context.go('/map'),
                      child: Container(
                        height: 200.h,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12.r),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12.r),
                          child: Stack(
                            children: [
                              // Real Mapbox Map
                              if (_currentLocation != null)
                                MapWidget(
                                  key: const ValueKey("dashboardMapWidget"),
                                  cameraOptions: CameraOptions(
                                    center: _currentLocation!,
                                    zoom: 15.0,
                                  ),
                                  styleUri: MapboxStyles.MAPBOX_STREETS,
                                  onMapCreated: (MapboxMap mapboxMap) async {
                                    _pointAnnotationManager = await mapboxMap
                                        .annotations
                                        .createPointAnnotationManager();

                                    // Add current location marker
                                    _addCurrentLocationMarker();
                                  },
                                )
                              else
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.grey[100],
                                    borderRadius: BorderRadius.circular(12.r),
                                  ),
                                  child: const Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                ),

                              // Tap overlay
                              Positioned.fill(
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12.r),
                                    color: Colors.black.withOpacity(0.1),
                                  ),
                                  child: Center(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.location_on,
                                          color: Colors.green,
                                          size: 32.w,
                                        ),
                                        SizedBox(height: 8.h),
                                        Text(
                                          'Tap to view live map',
                                          style: GoogleFonts.poppins(
                                            fontSize: 12.sp,
                                            color: Colors.white,
                                            fontWeight: FontWeight.w600,
                                            shadows: [
                                              Shadow(
                                                color: Colors.black.withOpacity(
                                                  0.5,
                                                ),
                                                blurRadius: 4,
                                                offset: const Offset(0, 1),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 24.h),

              // Vehicle Cards Section
              Container(
                margin: EdgeInsets.symmetric(horizontal: 20.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your Assigned Vehicles',
                      style: GoogleFonts.poppins(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                    SizedBox(height: 16.h),
                    if (_getAssignedVehicles(
                          tripState.trips,
                          routeState.assignments,
                          routeState.vehicles,
                          profileRawData: authState.profileRawData,
                        ).isNotEmpty)
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            ..._getAssignedVehicles(
                                  tripState.trips,
                                  routeState.assignments,
                                  routeState.vehicles,
                                  profileRawData: authState.profileRawData,
                                )
                                    .take(5)
                                    .map(
                                  (vehicle) => Padding(
                                    padding: EdgeInsets.only(right: 16.w),
                                    child: _VehicleCard(
                                      title: vehicle['name'] ?? 'Vehicle',
                                      subtitle:
                                          vehicle['license'] ?? 'License Plate',
                                      status: vehicle['status'] ?? 'Available',
                                      statusColor: vehicle['status'] == 'Active'
                                          ? Colors.green
                                          : vehicle['status'] == 'In Use'
                                          ? Colors.orange
                                          : Colors.grey,
                                      vehicleIcon: _getVehicleIcon(
                                        vehicle['type'],
                                      ),
                                      onTap: () => context.go('/map'),
                                    ),
                                  ),
                                ),
                          ],
                        ),
                      )
                    else
                      Container(
                        height: 120.h,
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(12.r),
                          border: Border.all(color: Colors.grey[200]!),
                        ),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.directions_bus_outlined,
                                size: 32.w,
                                color: Colors.grey[400],
                              ),
                              SizedBox(height: 8.h),
                              Text(
                                'No vehicles assigned',
                                style: GoogleFonts.poppins(
                                  fontSize: 14.sp,
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              SizedBox(height: 24.h),

              // Quick Actions Section
              Container(
                margin: EdgeInsets.symmetric(horizontal: 20.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Quick Actions',
                      style: GoogleFonts.poppins(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                    SizedBox(height: 16.h),
                    Row(
                      children: [
                        Expanded(
                          child: _QuickActionCard(
                            icon: Icons.directions_bus,
                            label: 'Start Trip',
                            onTap: () => context.go('/trips'),
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: _QuickActionCard(
                            icon: Icons.school,
                            label: 'Students',
                            onTap: () => context.go('/students'),
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: _QuickActionCard(
                            icon: Icons.map,
                            label: 'Map',
                            onTap: () => context.go('/map'),
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: _QuickActionCard(
                            icon: Icons.emergency,
                            label: 'Emergency',
                            onTap: () => context.go('/emergency'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              SizedBox(height: 32.h),
            ],
          ),
            ),
          ),
          if (_isRefreshing)
            Positioned.fill(
              child: Container(
                color: Colors.black26,
                child: Center(
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 24.w,
                      vertical: 16.h,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12.r),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 32.w,
                          height: 32.h,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              const Color(0xFF0052CC),
                            ),
                          ),
                        ),
                        SizedBox(height: 12.h),
                        Text(
                          'Refreshing...',
                          style: GoogleFonts.poppins(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w500,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: tripState.currentTrip != null
          ? Tooltip(
              message: 'Track your current trip location on the map',
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16.r),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0052CC).withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: FloatingActionButton.extended(
                  onPressed: () => context.go('/map'),
                  icon: const Icon(Icons.location_on, color: Colors.white),
                  label: Text(
                    'Track Location',
                    style: GoogleFonts.poppins(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  backgroundColor: const Color(0xFF0052CC),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16.r),
                  ),
                ),
              ),
            )
          : Tooltip(
              message: 'Add a new trip to start tracking',
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16.r),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0052CC).withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: FloatingActionButton(
                  onPressed: () => context.go('/trips'),
                  backgroundColor: const Color(0xFF0052CC),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16.r),
                  ),
                  child: const Icon(Icons.add, color: Colors.white),
                ),
              ),
            ),
    );
  }
}

class _VehicleCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String status;
  final Color statusColor;
  final IconData vehicleIcon;
  final VoidCallback onTap;

  const _VehicleCard({
    required this.title,
    required this.subtitle,
    required this.status,
    required this.statusColor,
    required this.vehicleIcon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 160.w,
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40.w,
                  height: 40.w,
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Icon(vehicleIcon, color: Colors.grey[600], size: 20.w),
                ),
                const Spacer(),
                Container(
                  width: 8.w,
                  height: 8.w,
                  decoration: BoxDecoration(
                    color: statusColor,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.h),
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              subtitle,
              style: GoogleFonts.poppins(
                fontSize: 12.sp,
                color: Colors.grey[600],
                fontWeight: FontWeight.w400,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              status,
              style: GoogleFonts.poppins(
                fontSize: 12.sp,
                color: statusColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              width: 40.w,
              height: 40.w,
              decoration: BoxDecoration(
                color: const Color(0xFF0052CC).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Icon(icon, color: const Color(0xFF0052CC), size: 20.w),
            ),
            SizedBox(height: 8.h),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 12.sp,
                color: Colors.black,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ActiveTripBanner extends StatelessWidget {
  final dynamic activeTrip;

  const _ActiveTripBanner({required this.activeTrip});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Current Trip',
                style: GoogleFonts.poppins(
                  fontSize: 14.sp,
                  color: Colors.white.withOpacity(0.8),
                  fontWeight: FontWeight.w400,
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                activeTrip.routeName ?? 'Route ${activeTrip.routeId ?? 'N/A'}',
                style: GoogleFonts.poppins(
                  fontSize: 16.sp,
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        Container(
          width: 80.w,
          height: 60.h,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: const Icon(
            Icons.directions_bus,
            color: Colors.white,
            size: 32,
          ),
        ),
      ],
    );
  }
}

class _NoActiveTripBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'No Active Trip',
                style: GoogleFonts.poppins(
                  fontSize: 16.sp,
                  color: Colors.white.withOpacity(0.8),
                  fontWeight: FontWeight.w400,
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                'Start a new trip to begin tracking',
                style: GoogleFonts.poppins(
                  fontSize: 18.sp,
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        Container(
          width: 80.w,
          height: 60.h,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: const Icon(
            Icons.directions_bus_outlined,
            color: Colors.white,
            size: 32,
          ),
        ),
      ],
    );
  }
}
