import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers/trip_provider.dart';
import '../../../core/providers/location_provider.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/models/trip_model.dart';
import '../../../core/theme/app_theme.dart';
import '../widgets/trip_card.dart';
import '../widgets/trip_filter_bottom_sheet.dart';

class TripsScreen extends ConsumerStatefulWidget {
  const TripsScreen({super.key});

  @override
  ConsumerState<TripsScreen> createState() => _TripsScreenState();
}

class _TripsScreenState extends ConsumerState<TripsScreen> {
  TripStatus? _selectedFilter;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(tripProvider.notifier).loadTrips();
    });
  }

  @override
  Widget build(BuildContext context) {
    final tripState = ref.watch(tripProvider);

    // Listen for authentication state changes and reload trips
    ref.listen<AuthState>(authProvider, (previous, next) {
      if (next.isAuthenticated && previous?.isAuthenticated != next.isAuthenticated) {
        // User just logged in, reload trips
        print('🔄 DEBUG: User logged in, reloading trips...');
        ref.read(tripProvider.notifier).loadTrips();
      } else if (!next.isAuthenticated && previous?.isAuthenticated == true) {
        // User just logged out, reset trip state
        print('🔄 DEBUG: User logged out, resetting trip state...');
        ref.read(tripProvider.notifier).resetState();
      }
    });

    // Filter trips based on search and filter
    final filteredTrips = tripState.trips.where((trip) {
      final matchesSearch =
          _searchQuery.isEmpty ||
          trip.tripId.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (trip.startLocation?.toLowerCase().contains(
                _searchQuery.toLowerCase(),
              ) ??
              false);

      final matchesFilter =
          _selectedFilter == null || trip.status == _selectedFilter;

      return matchesSearch && matchesFilter;
    }).toList();

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('My Trips'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFilterBottomSheet(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search and Filter Bar
          Container(
            padding: EdgeInsets.all(16.w),
            child: Column(
              children: [
                // Search Bar
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Search trips...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              setState(() {
                                _searchQuery = '';
                              });
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                ),
                SizedBox(height: 12.h),

                // Filter Chips
                if (_selectedFilter != null)
                  Row(
                    children: [
                      Chip(
                        label: Text(_getStatusText(_selectedFilter!)),
                        onDeleted: () {
                          setState(() {
                            _selectedFilter = null;
                          });
                        },
                        deleteIcon: const Icon(Icons.close, size: 18),
                      ),
                    ],
                  ),
              ],
            ),
          ),

          // Trips List
          Expanded(
            child: tripState.isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredTrips.isEmpty
                ? _EmptyState()
                : RefreshIndicator(
                    onRefresh: () async {
                      await ref.read(tripProvider.notifier).loadTrips();
                    },
                    child: ListView.builder(
                      padding: EdgeInsets.symmetric(horizontal: 16.w),
                      itemCount: filteredTrips.length,
                      itemBuilder: (context, index) {
                        final trip = filteredTrips[index];
                        return Padding(
                          padding: EdgeInsets.only(bottom: 12.h),
                          child: TripCard(
                            trip: trip,
                            onTap: () =>
                                context.go('/trips/details/${trip.id}'),
                            onStart: trip.status == TripStatus.pending
                                ? () => _startTrip(trip)
                                : null,
                            onEnd: trip.status == TripStatus.inProgress
                                ? () => _endTrip(trip)
                                : null,
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showNewTripDialog(context),
        child: const Icon(Icons.add),
        backgroundColor: AppTheme.primaryColor,
      ),
    );
  }

  void _showFilterBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => TripFilterBottomSheet(
        selectedFilter: _selectedFilter,
        onFilterSelected: (filter) {
          setState(() {
            _selectedFilter = filter;
          });
          Navigator.pop(context);
        },
      ),
    );
  }

  void _showNewTripDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Start New Trip'),
        content: const Text(
          'This feature will be available soon. You can start trips from the trips list.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _startTrip(Trip trip) async {
    // Get current location
    final locationState = ref.read(locationProvider);
    final currentPosition = locationState.currentPosition;

    if (currentPosition == null) {
      // Try to get current position if not available
      await ref.read(locationProvider.notifier).getCurrentPosition();
      final updatedPosition = ref.read(locationProvider).currentPosition;

      if (updatedPosition == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Unable to get current location. Please enable location services.'),
              backgroundColor: AppTheme.errorColor,
            ),
          );
        }
        return;
      }
    }

    final position = currentPosition ?? ref.read(locationProvider).currentPosition!;

    final success = await ref
        .read(tripProvider.notifier)
        .startTrip(
          trip.tripId,
          startLocation: trip.startLocation ?? 'Unknown Location',
          latitude: position.latitude,
          longitude: position.longitude,
        );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Trip ${trip.tripId} started successfully'),
          backgroundColor: AppTheme.successColor,
        ),
      );
    }
  }

  Future<void> _endTrip(Trip trip) async {
    // Get current location
    final locationState = ref.read(locationProvider);
    final currentPosition = locationState.currentPosition;

    if (currentPosition == null) {
      // Try to get current position if not available
      await ref.read(locationProvider.notifier).getCurrentPosition();
      final updatedPosition = ref.read(locationProvider).currentPosition;

      if (updatedPosition == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Unable to get current location. Please enable location services.'),
              backgroundColor: AppTheme.errorColor,
            ),
          );
        }
        return;
      }
    }

    final position = currentPosition ?? ref.read(locationProvider).currentPosition!;

    final success = await ref
        .read(tripProvider.notifier)
        .endTrip(
          endLocation: trip.endLocation ?? 'Unknown Location',
          latitude: position.latitude,
          longitude: position.longitude,
        );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Trip ${trip.tripId} ended successfully'),
          backgroundColor: AppTheme.successColor,
        ),
      );
    }
  }

  String _getStatusText(TripStatus status) {
    switch (status) {
      case TripStatus.pending:
        return 'Pending';
      case TripStatus.inProgress:
        return 'In Progress';
      case TripStatus.completed:
        return 'Completed';
      case TripStatus.cancelled:
        return 'Cancelled';
      case TripStatus.delayed:
        return 'Delayed';
    }
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.directions_bus_outlined,
            size: 64.w,
            color: AppTheme.textTertiary,
          ),
          SizedBox(height: 16.h),
          Text(
            'No trips found',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(color: AppTheme.textSecondary),
          ),
          SizedBox(height: 8.h),
          Text(
            'Your trips will appear here when assigned',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppTheme.textTertiary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}


