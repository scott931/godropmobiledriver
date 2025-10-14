# ETA (Estimated Time of Arrival) System

This document describes the comprehensive ETA system implemented for the Scholatransit Driver App.

## Overview

The ETA system provides real-time estimated arrival times for school bus trips, taking into account:
- Current location and speed
- Traffic conditions
- Route characteristics
- Historical data
- Time of day patterns

## Architecture

### Core Components

1. **ETA Models** (`lib/core/models/eta_model.dart`)
   - `ETAInfo`: Contains ETA calculation results
   - `ETACalculationRequest`: Input parameters for ETA calculation
   - `ETACalculationResult`: Wrapper for calculation results

2. **ETA Service** (`lib/core/services/eta_service.dart`)
   - Main ETA calculation logic
   - Speed calculation from GPS data
   - Travel time estimation
   - Buffer time calculations

3. **Traffic Service** (`lib/core/services/traffic_service.dart`)
   - Traffic condition analysis
   - Time-based traffic patterns
   - Route-specific adjustments
   - Weather impact simulation

4. **ETA Provider** (`lib/core/providers/eta_provider.dart`)
   - State management for ETA data
   - Real-time ETA updates
   - Location tracking integration

5. **ETA Notifications** (`lib/core/services/eta_notification_service.dart`)
   - Scheduled arrival notifications
   - Delay alerts
   - Traffic condition updates

## Features

### Real-time ETA Calculation
- GPS-based speed detection
- Traffic-aware routing
- Dynamic updates every minute
- Historical accuracy tracking

### Traffic Intelligence
- Rush hour detection
- Day-of-week patterns
- Route-specific adjustments
- Weather impact simulation

### Smart Notifications
- 15-minute arrival warning
- 5-minute arrival alert
- Delay notifications
- Traffic condition updates

### Visual Indicators
- Color-coded ETA status
- Delay warnings
- Traffic condition display
- Real-time updates

## Usage

### Basic ETA Calculation

```dart
// Calculate ETA for a trip
final result = await ETAService.calculateETA(
  currentLat: 40.7128,
  currentLng: -74.0060,
  destinationLat: 40.7589,
  destinationLng: -73.9851,
  trip: trip,
  routeName: 'Route A',
  vehicleType: 'school_bus',
);

if (result.success) {
  final etaInfo = result.etaInfo;
  print('ETA: ${etaInfo.formattedTimeToArrival}');
  print('Distance: ${etaInfo.formattedDistance}');
  print('Delayed: ${etaInfo.isDelayed}');
}
```

### ETA State Management

```dart
// Start ETA tracking for a trip
ref.read(etaProvider.notifier).startETATracking(trip);

// Get current ETA
final etaState = ref.watch(etaProvider);
final currentETA = etaState.currentETA;

// Stop tracking
ref.read(etaProvider.notifier).stopETATracking();
```

### Notifications

```dart
// Schedule ETA notifications
await ETANotificationService.scheduleETANotifications(
  trip: trip,
  etaInfo: etaInfo,
);

// Cancel notifications
await ETANotificationService.cancelETANotifications(trip.tripId);
```

## UI Integration

### Trip Cards
ETA information is automatically displayed in trip cards with:
- Time to arrival
- Delay status
- Traffic conditions
- Visual indicators

### Map Screen
The map screen shows:
- Current ETA for active trips
- Traffic conditions
- Delay warnings
- Real-time updates

### Demo Screen
A comprehensive demo screen (`lib/features/eta/screens/eta_demo_screen.dart`) shows:
- Current ETA status
- Trip ETA list
- Tracking controls
- Real-time updates

## Configuration

### Traffic Multipliers
- Light Traffic: 0.8x
- Normal Traffic: 1.0x
- Heavy Traffic: 1.5x
- Severe Traffic: 2.0x+

### Buffer Times
- Base buffer: 5 minutes
- Distance-based: 0.5 min/km
- Trip type adjustments:
  - Pickup: +10 minutes
  - Dropoff: +8 minutes
  - Emergency: -5 minutes

### Update Intervals
- ETA recalculation: 1 minute
- Location updates: Real-time
- Notification checks: Continuous

## API Integration

The ETA system is designed to work with:
- GPS location services
- Traffic data APIs (extensible)
- Weather services (extensible)
- Route optimization APIs (extensible)

## Error Handling

The system includes comprehensive error handling for:
- GPS unavailability
- Network connectivity issues
- Invalid coordinates
- Calculation failures

## Performance

- Optimized for mobile devices
- Minimal battery impact
- Efficient location tracking
- Smart update intervals

## Future Enhancements

1. **Machine Learning Integration**
   - Historical pattern analysis
   - Predictive ETA accuracy
   - Route optimization

2. **Advanced Traffic Data**
   - Real-time traffic APIs
   - Incident detection
   - Alternative route suggestions

3. **Weather Integration**
   - Weather-based adjustments
   - Seasonal patterns
   - Road condition factors

4. **Analytics**
   - ETA accuracy tracking
   - Performance metrics
   - User behavior analysis

## Testing

The ETA system includes:
- Unit tests for calculation logic
- Integration tests for services
- UI tests for display components
- Performance tests for real-time updates

## Dependencies

- `geolocator`: GPS location services
- `flutter_local_notifications`: Push notifications
- `riverpod`: State management
- `google_fonts`: UI styling

## Troubleshooting

### Common Issues

1. **ETA Not Updating**
   - Check GPS permissions
   - Verify location services
   - Ensure trip has valid coordinates

2. **Inaccurate ETAs**
   - Check traffic multiplier settings
   - Verify route characteristics
   - Review buffer time calculations

3. **Notifications Not Working**
   - Check notification permissions
   - Verify notification service initialization
   - Ensure proper scheduling

### Debug Information

Enable debug logging by setting:
```dart
// In your app initialization
ETAService.enableDebugLogging = true;
```

This will provide detailed logs for:
- ETA calculations
- Traffic analysis
- Location updates
- Notification scheduling

## Support

For issues or questions about the ETA system:
1. Check the debug logs
2. Verify all dependencies are installed
3. Ensure proper permissions are granted
4. Review the configuration settings
