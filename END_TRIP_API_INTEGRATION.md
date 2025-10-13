# End Trip API Integration

## Overview
This document describes the integration of the End Trip API in the ScholaTransit Driver application. The API allows drivers to end trips with location data and completion notes.

## API Specification

### Endpoint
```
POST /api/v1/tracking/trips/end/
```

### Request Format
```json
{
  "trip_id": "TRP_PICKUP_2_2_20251010_223751",
  "end_location": "SRID=4326;POINT (36.8065 -1.2657000000000047)",
  "latitude": -1.2921,
  "longitude": 36.8219,
  "notes": "Completed morning route successfully"
}
```

### Response Format
```json
{
  "id": 1,
  "trip_id": "TRP_PICKUP_2_2_20251010_223751",
  "driver": 8,
  "driver_name": "ScottK Kariuki",
  "vehicle": 2,
  "vehicle_name": "KDC 458R",
  "route": 2,
  "route_name": "Testing",
  "trip_type": "Student Pickup",
  "status": "Completed",
  "start_location": "SRID=4326;POINT (36.8219 -1.2921)",
  "end_location": "SRID=4326;POINT (36.8219 -1.2921)",
  "current_location": "SRID=4326;POINT (36.81432956660392 -1.2941461061046942)",
  "scheduled_start": "2024-01-15T11:00:00+03:00",
  "scheduled_end": "2024-01-15T12:00:00+03:00",
  "actual_start": "2025-10-13T20:19:58.899186+03:00",
  "actual_end": "2025-10-13T21:05:28.899140+03:00",
  "total_distance": null,
  "average_speed": null,
  "max_speed": null,
  "notes": "",
  "delay_reason": null,
  "created_at": "2025-10-10T22:37:51.394652+03:00",
  "updated_at": "2025-10-13T21:05:28.899276+03:00"
}
```

## Implementation Details

### 1. Trip Provider Updates
The `TripProvider` class has been updated to handle the end trip functionality:

```dart
Future<bool> endTrip({
  required String endLocation,
  double? latitude,
  double? longitude,
  String? notes,
}) async {
  // Implementation details...
}
```

**Key Changes:**
- Updated endpoint to use `/tracking/trips/end/` instead of `/trips/end/`
- Changed to use `tripId` (string) instead of `id` (integer) for the trip_id parameter
- Removed `odometerReading` parameter as it's not part of the API specification
- Maintains existing error handling and state management
- Clears current trip from local storage upon successful end

### 2. API Configuration Updates
Updated the endpoint configuration in `AppConfig`:

```dart
static const String endTripEndpoint = '/tracking/trips/end/';
```

### 3. Request Data Structure
The API request now matches the specification exactly:

```dart
data: {
  'trip_id': state.currentTrip!.tripId,  // String trip ID
  'end_location': endLocation,           // WKT format location
  'latitude': latitude,                   // Double latitude
  'longitude': longitude,                 // Double longitude
  'notes': notes,                        // Optional completion notes
}
```

## Usage Example

### Ending a Trip
```dart
// Get the trip provider
final tripProvider = ref.read(tripProvider.notifier);

// End the current trip
final success = await tripProvider.endTrip(
  endLocation: "SRID=4326;POINT (36.8065 -1.2657000000000047)",
  latitude: -1.2921,
  longitude: 36.8219,
  notes: "Completed morning route successfully",
);

if (success) {
  // Trip ended successfully
  print('Trip completed successfully');
  // Current trip is automatically cleared from state
} else {
  // Handle error
  final error = ref.read(tripProvider).error;
  print('Failed to end trip: $error');
}
```

### Checking Trip Status
```dart
// Check if there's an active trip
final currentTrip = ref.watch(currentTripProvider);

if (currentTrip == null) {
  print('No active trip');
} else {
  print('Active trip: ${currentTrip.tripId}');
  print('Status: ${currentTrip.status}');
}
```

## Error Handling

The implementation includes comprehensive error handling:

1. **No Active Trip**: Returns error if no current trip exists
2. **Network Errors**: Connection timeouts, no internet
3. **API Errors**: 400, 401, 403, 404, 422, 500 status codes
4. **Validation Errors**: Invalid trip_id, missing required fields
5. **State Management**: Loading states, error states

## State Management

### Before End Trip
```dart
// Current trip exists in state
final currentTrip = ref.read(currentTripProvider);
// currentTrip != null
// currentTrip.status == TripStatus.inProgress
```

### After End Trip
```dart
// Current trip is cleared from state
final currentTrip = ref.read(currentTripProvider);
// currentTrip == null
// Trip data is cleared from local storage
```

## API Response Handling

The response is parsed using the existing `Trip.fromJson()` method, which handles:

- **Status Update**: Trip status changes to "Completed"
- **End Time**: `actual_end` timestamp is set
- **Location Data**: End location is updated
- **Trip Metrics**: Distance, speed data (if available)
- **Notes**: Completion notes are stored

## Testing

A test script (`test-end-trip-api.js`) is provided to verify the API integration:

```bash
node test-end-trip-api.js
```

The test script:
- Sends a properly formatted request
- Validates the response structure
- Checks for required fields
- Verifies trip end success
- Calculates trip duration

## Configuration

The API endpoint is configured in `AppConfig`:

```dart
static const String endTripEndpoint = '/tracking/trips/end/';
```

Base URL: `https://schooltransit-backend-staging.onrender.com/api/v1`

## Security Considerations

1. **Authentication**: All requests require valid JWT tokens
2. **Authorization**: Only the assigned driver can end their trip
3. **Data Validation**: Server-side validation of all input data
4. **Trip State**: Only active trips can be ended

## Integration with Start Trip

The end trip functionality works seamlessly with the start trip API:

1. **Start Trip**: Creates active trip in state
2. **Trip Management**: Location updates, student management
3. **End Trip**: Completes trip and clears state

## Future Enhancements

1. **Offline Support**: Queue trip ends when offline
2. **Retry Logic**: Automatic retry for failed requests
3. **Background Sync**: Sync trip completion in background
4. **Analytics**: Trip duration and performance metrics

## Troubleshooting

### Common Issues

1. **No Active Trip**: Ensure a trip is started before trying to end it
2. **Invalid trip_id**: Check if the trip ID format is correct
3. **Authentication errors**: Verify JWT token is valid and not expired
4. **Network errors**: Check internet connectivity
5. **Location errors**: Ensure location permissions are granted

### Debug Logging

Enable debug logging in `AppConfig`:

```dart
static const bool enableLogging = true;
```

This will log all API requests and responses for debugging purposes.

## API Differences from Start Trip

| Aspect | Start Trip | End Trip |
|--------|------------|----------|
| Endpoint | `/trips/start/` | `/tracking/trips/end/` |
| Location Field | `start_location` | `end_location` |
| Status Change | `pending` → `In Progress` | `In Progress` → `Completed` |
| State Management | Sets current trip | Clears current trip |
| Required Fields | `trip_id`, `start_location` | `trip_id`, `end_location` |
| Optional Fields | `latitude`, `longitude`, `notes` | `latitude`, `longitude`, `notes` |
