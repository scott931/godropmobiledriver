# Start Trip API Integration

## Overview
This document describes the integration of the Start Trip API in the ScholaTransit Driver application. The API allows drivers to start trips with location data and notes.

## API Specification

### Endpoint
```
POST /api/v1/tracking/trips/start/
```

### Request Format
```json
{
  "trip_id": "TRP_PICKUP_2_2_20251010_223751",
  "start_location": "POINT(-1.2921 36.8219)",
  "latitude": -1.2921,
  "longitude": 36.8219,
  "notes": "Starting morning pickup route"
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
  "status": "In Progress",
  "start_location": "SRID=4326;POINT (36.8219 -1.2921)",
  "end_location": "SRID=4326;POINT (36.82312192691086 -1.2921736957314267)",
  "current_location": "SRID=4326;POINT (36.81432956660392 -1.2941461061046942)",
  "scheduled_start": "2024-01-15T11:00:00+03:00",
  "scheduled_end": "2024-01-15T12:00:00+03:00",
  "actual_start": "2025-10-13T20:19:58.899186+03:00",
  "actual_end": "2025-10-10T23:51:48+03:00",
  "total_distance": null,
  "average_speed": null,
  "max_speed": null,
  "notes": "",
  "delay_reason": null,
  "created_at": "2025-10-10T22:37:51.394652+03:00",
  "updated_at": "2025-10-13T20:19:58.899351+03:00"
}
```

## Implementation Details

### 1. Trip Provider Updates
The `TripProvider` class has been updated to handle the start trip functionality:

```dart
Future<bool> startTrip(
  String tripId, {
  required String startLocation,
  double? latitude,
  double? longitude,
  String? notes,
}) async {
  // Implementation details...
}
```

**Key Changes:**
- Changed `tripId` parameter from `int` to `String` to match API specification
- Maintains existing error handling and state management
- Saves current trip to local storage upon successful start

### 2. Trip Model Updates
The `Trip` model has been enhanced to handle the complete API response:

**New Fields Added:**
- `driverName`: String? - Name of the driver
- `vehicleName`: String? - Name of the vehicle
- `routeName`: String? - Name of the route
- `currentLocation`: String? - Current location as WKT string
- `delayReason`: String? - Reason for any delays
- `averageSpeed`: double? - Average speed during trip
- `maxSpeed`: double? - Maximum speed during trip

**Updated Methods:**
- `fromJson()`: Handles both direct API responses and backend tracking responses
- `fromBackend()`: Specifically handles tracking endpoint responses
- `toJson()`: Serializes trip data for storage and API calls
- `copyWith()`: Supports all new fields for state updates

### 3. API Service Integration
The existing `ApiService` handles the HTTP request with proper error handling:

```dart
final response = await ApiService.post<Map<String, dynamic>>(
  AppConfig.startTripEndpoint,
  data: {
    'trip_id': tripId,
    'start_location': startLocation,
    'latitude': latitude,
    'longitude': longitude,
    'notes': notes,
  },
);
```

## Usage Example

### Starting a Trip
```dart
// Get the trip provider
final tripProvider = ref.read(tripProvider.notifier);

// Start a trip
final success = await tripProvider.startTrip(
  "TRP_PICKUP_2_2_20251010_223751", // trip_id as string
  startLocation: "POINT(-1.2921 36.8219)",
  latitude: -1.2921,
  longitude: 36.8219,
  notes: "Starting morning pickup route",
);

if (success) {
  // Trip started successfully
  final currentTrip = ref.read(currentTripProvider);
  print('Trip started: ${currentTrip?.tripId}');
} else {
  // Handle error
  final error = ref.read(tripProvider).error;
  print('Failed to start trip: $error');
}
```

### Accessing Trip Data
```dart
// Get current trip
final currentTrip = ref.watch(currentTripProvider);

if (currentTrip != null) {
  print('Driver: ${currentTrip.driverName}');
  print('Vehicle: ${currentTrip.vehicleName}');
  print('Route: ${currentTrip.routeName}');
  print('Status: ${currentTrip.status}');
  print('Current Location: ${currentTrip.currentLocation}');
}
```

## Error Handling

The implementation includes comprehensive error handling:

1. **Network Errors**: Connection timeouts, no internet
2. **API Errors**: 400, 401, 403, 404, 422, 500 status codes
3. **Validation Errors**: Invalid trip_id, missing required fields
4. **State Management**: Loading states, error states

## Testing

A test script (`test-start-trip-api.js`) is provided to verify the API integration:

```bash
node test-start-trip-api.js
```

The test script:
- Sends a properly formatted request
- Validates the response structure
- Checks for required fields
- Verifies trip start success

## Configuration

The API endpoint is configured in `AppConfig`:

```dart
static const String startTripEndpoint = '/trips/start/';
```

Base URL: `https://schooltransit-backend-staging-ixld.onrender.com/api/v1`

## Security Considerations

1. **Authentication**: All requests require valid JWT tokens
2. **Authorization**: Only assigned drivers can start their trips
3. **Data Validation**: Server-side validation of all input data
4. **Rate Limiting**: API calls are rate-limited to prevent abuse

## Future Enhancements

1. **Offline Support**: Queue trip starts when offline
2. **Retry Logic**: Automatic retry for failed requests
3. **Background Sync**: Sync trip data in background
4. **Real-time Updates**: WebSocket integration for live updates

## Troubleshooting

### Common Issues

1. **Invalid trip_id**: Ensure the trip_id is a valid string format
2. **Authentication errors**: Check if the JWT token is valid and not expired
3. **Network errors**: Verify internet connectivity
4. **Location errors**: Ensure location permissions are granted

### Debug Logging

Enable debug logging in `AppConfig`:

```dart
static const bool enableLogging = true;
```

This will log all API requests and responses for debugging purposes.
