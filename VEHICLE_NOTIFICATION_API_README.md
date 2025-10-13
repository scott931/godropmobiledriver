# Vehicle Notification API Documentation

This document provides comprehensive documentation for the Vehicle Notification API, which allows retrieving notifications by vehicle for drivers, admins, and monitors.

## Table of Contents

1. [Overview](#overview)
2. [API Endpoints](#api-endpoints)
3. [Response Format](#response-format)
4. [Usage Examples](#usage-examples)
5. [Filtering and Pagination](#filtering-and-pagination)
6. [User Type Filtering](#user-type-filtering)
7. [React Component Usage](#react-component-usage)
8. [Error Handling](#error-handling)
9. [Testing](#testing)
10. [Best Practices](#best-practices)

## Overview

The Vehicle Notification API provides functionality to retrieve notifications associated with specific vehicles. This is particularly useful for:

- **Drivers**: View notifications related to their assigned vehicle
- **Admins**: Monitor notifications for specific vehicles in their fleet
- **Monitors**: Track notifications for vehicles they're responsible for

## API Endpoints

### Base Endpoint
```
GET /api/v1/notifications/vehicle/{vehicle_id}/
```

### Query Parameters

| Parameter | Type | Description | Default |
|-----------|------|-------------|---------|
| `user_type` | string | Filter by user type (driver, admin, monitor) | - |
| `notification_type` | string | Filter by notification type | - |
| `priority` | string | Filter by priority (high, medium, low, normal) | - |
| `status` | string | Filter by status (pending, sent, delivered, failed) | - |
| `is_read` | boolean | Filter by read status | - |
| `is_sent` | boolean | Filter by sent status | - |
| `is_delivered` | boolean | Filter by delivered status | - |
| `date_from` | string | Filter by date from (ISO format) | - |
| `date_to` | string | Filter by date to (ISO format) | - |
| `channels` | array | Filter by channels (push, sms, email) | - |
| `student` | integer | Filter by student ID | - |
| `route` | integer | Filter by route ID | - |
| `include_student_details` | boolean | Include student details | true |
| `include_vehicle_details` | boolean | Include vehicle details | true |
| `include_route_details` | boolean | Include route details | true |
| `include_parent_details` | boolean | Include parent details | true |
| `page` | integer | Page number | 1 |
| `page_size` | integer | Number of items per page | 50 |
| `ordering` | string | Ordering field (e.g., '-created_at') | '-created_at' |
| `search` | string | Search term | - |

## Response Format

### Success Response
```json
{
  "success": true,
  "data": {
    "count": 25,
    "next": "http://api.example.com/notifications/vehicle/1/?page=2",
    "previous": null,
    "results": [
      {
        "id": 1,
        "recipient": 1,
        "recipient_name": "John Doe",
        "notification_type": "student_pickup",
        "notification_type_display": "Student Picked Up",
        "priority": "normal",
        "priority_display": "Normal",
        "title": "Student Picked Up",
        "message": "Your child Sarah has been picked up by BUS-001",
        "student": {
          "id": 1,
          "student_id": "1",
          "first_name": "Kennedy",
          "last_name": "Nyachiro",
          "middle_name": "Waithaka",
          "full_name": "Kennedy Waithaka Nyachiro",
          "date_of_birth": "2025-11-10",
          "gender": "male",
          "grade": "12",
          "status": "active",
          "approval_status": "pending",
          "age": -1,
          "phone_number": "0721913384",
          "email": "kennedynyachiro@gmail.com",
          "address": "Premier Bldg Suite 1, Along Katani Rd Syokimau, Kenya",
          "city": "Nairobi",
          "state": "Nairobi",
          "postal_code": "00502",
          "country": "Kenya",
          "school_name": "bb",
          "school_address": "Box 64440-00200 Nairobi",
          "assigned_route": 1,
          "pickup_stop": 3,
          "dropoff_stop": 2,
          "has_route_assignment": true,
          "created_by": null,
          "approved_by": null,
          "approved_at": null,
          "rejection_reason": null,
          "is_pending_approval": true,
          "is_approved": false,
          "is_rejected": false,
          "needs_approval": null,
          "parents": [],
          "created_at": "2025-09-11T22:18:41.650820+03:00",
          "updated_at": "2025-09-17T12:37:01.230026+03:00"
        },
        "vehicle": {
          "id": 1,
          "license_plate": "ABC-123",
          "make": "Ford",
          "model": "Transit",
          "year": 2023,
          "vin": "1HGBH41JXMN109186",
          "vehicle_type": "bus",
          "type_display": "School Bus",
          "seating_capacity": 20,
          "status": "active",
          "status_display": "Active",
          "assigned_driver": 51,
          "driver_name": "Riley Kariuki",
          "fuel_type": "diesel",
          "fuel_capacity": 80,
          "current_latitude": null,
          "current_longitude": null,
          "last_location_update": null,
          "insurance_expiry": null,
          "registration_expiry": "2024-12-31",
          "created_at": "2025-09-12T08:44:58.836568+03:00",
          "updated_at": "2025-10-07T15:58:18.609202+03:00"
        },
        "route": {
          "id": 1,
          "name": "Morning Route B",
          "description": "Main morning route for uptown area",
          "route_type": "morning",
          "route_type_display": "Morning Route",
          "status": "active",
          "status_display": "Active",
          "estimated_duration": 45,
          "total_distance": "12.50",
          "max_capacity": 25,
          "assigned_vehicle": null,
          "assigned_driver": 50,
          "assigned_driver_name": "Florence Mwangi",
          "is_fully_assigned": null,
          "current_student_count": 0,
          "stops": [
            {
              "id": 1,
              "route": 1,
              "name": "Main Street Stop",
              "description": "Primary pickup point on Main Street",
              "stop_type": "pickup",
              "stop_type_display": "Pickup Point",
              "address": "123 Main Street, Downtown",
              "latitude": null,
              "longitude": null,
              "estimated_arrival_time": "07:30:00",
              "estimated_departure_time": "07:35:00",
              "order": 2,
              "created_at": "2025-09-13T20:46:11.525272+03:00",
              "updated_at": "2025-09-13T20:46:11.525287+03:00"
            }
          ],
          "schedules": [
            {
              "id": 1,
              "route": 1,
              "day_of_week": "monday",
              "day_of_week_display": "Monday",
              "start_time": "07:00:00",
              "end_time": "08:30:00",
              "is_active": true,
              "created_at": "2025-09-13T20:52:56.317101+03:00",
              "updated_at": "2025-09-13T20:52:56.317116+03:00"
            }
          ],
          "assignments": [
            {
              "id": 6,
              "route": 1,
              "route_name": "Morning Route B",
              "vehicle": 7,
              "vehicle_license_plate": "KGG",
              "driver": 18,
              "driver_name": "John Doe",
              "status": "pending",
              "status_display": "Pending",
              "is_active": false,
              "start_date": "2024-01-01",
              "end_date": "2024-12-31",
              "notes": "Regular assignment for morning route",
              "created_at": "2025-09-20T20:00:32.619934+03:00",
              "updated_at": "2025-09-20T20:00:32.619953+03:00"
            }
          ],
          "created_at": "2025-09-12T09:39:34.121102+03:00",
          "updated_at": "2025-10-06T12:36:36.601576+03:00"
        },
        "location": "SRID=4326;POINT (-74.0059 40.7128)",
        "location_display": "40.712800, -74.005900",
        "channels": ["push", "sms", "email"],
        "status": "pending",
        "status_display": "Pending",
        "scheduled_at": null,
        "sent_at": null,
        "delivered_at": null,
        "read_at": null,
        "metadata": {
          "trip_id": 123,
          "driver_name": "John Smith"
        },
        "is_read": false,
        "is_sent": false,
        "is_delivered": false,
        "deliveries": [],
        "created_at": "2025-10-08T11:13:22.001045+03:00",
        "updated_at": "2025-10-08T11:13:22.001060+03:00"
      }
    ]
  }
}
```

### Error Response
```json
{
  "success": false,
  "message": "Vehicle not found",
  "error": "VEHICLE_NOT_FOUND"
}
```

## Usage Examples

### Basic Usage

```javascript
import { notificationsAPI } from './api/index';

// Get all notifications for a vehicle
const result = await notificationsAPI.getNotificationsByVehicle(1);
console.log(result.data.results);
```

### Get Notifications for Specific User Types

```javascript
// Get notifications for drivers
const driverNotifications = await notificationsAPI.getNotificationsForVehicleDrivers(1);

// Get notifications for admins
const adminNotifications = await notificationsAPI.getNotificationsForVehicleAdmins(1);

// Get notifications for monitors
const monitorNotifications = await notificationsAPI.getNotificationsForVehicleMonitors(1);
```

### Filtering Notifications

```javascript
// Get pickup notifications
const pickupNotifications = await notificationsAPI.getNotificationsByVehicle(1, {
  notification_type: 'student_pickup'
});

// Get high priority notifications
const highPriorityNotifications = await notificationsAPI.getNotificationsByVehicle(1, {
  priority: 'high'
});

// Get unread notifications
const unreadNotifications = await notificationsAPI.getNotificationsByVehicle(1, {
  is_read: false
});
```

### Date Range Filtering

```javascript
// Get notifications from last 24 hours
const yesterday = new Date();
yesterday.setHours(yesterday.getHours() - 24);

const recentNotifications = await notificationsAPI.getNotificationsByVehicle(1, {
  date_from: yesterday.toISOString()
});
```

### Pagination

```javascript
// Get first page with 10 items
const firstPage = await notificationsAPI.getNotificationsByVehicle(1, {
  page: 1,
  page_size: 10
});

// Get next page
const nextPage = await notificationsAPI.getNotificationsByVehicle(1, {
  page: 2,
  page_size: 10
});
```

## Filtering and Pagination

### Available Filters

| Filter | Type | Description | Example |
|--------|------|-------------|---------|
| `notification_type` | string | Filter by notification type | `'student_pickup'` |
| `priority` | string | Filter by priority | `'high'` |
| `status` | string | Filter by status | `'sent'` |
| `is_read` | boolean | Filter by read status | `false` |
| `is_sent` | boolean | Filter by sent status | `true` |
| `is_delivered` | boolean | Filter by delivered status | `true` |
| `date_from` | string | Filter by date from | `'2025-01-01T00:00:00Z'` |
| `date_to` | string | Filter by date to | `'2025-01-31T23:59:59Z'` |
| `channels` | array | Filter by channels | `['push', 'sms']` |
| `student` | integer | Filter by student ID | `1` |
| `route` | integer | Filter by route ID | `1` |

### Pagination Parameters

| Parameter | Type | Description | Default |
|-----------|------|-------------|---------|
| `page` | integer | Page number (1-based) | 1 |
| `page_size` | integer | Number of items per page | 50 |
| `ordering` | string | Ordering field | `'-created_at'` |

### Ordering Options

- `created_at` - Order by creation date (ascending)
- `-created_at` - Order by creation date (descending)
- `updated_at` - Order by update date (ascending)
- `-updated_at` - Order by update date (descending)
- `title` - Order by title (ascending)
- `-title` - Order by title (descending)

## User Type Filtering

### Available User Types

- `driver` - Vehicle drivers
- `admin` - System administrators
- `monitor` - Vehicle monitors

### Usage Examples

```javascript
// Get notifications for drivers only
const driverNotifications = await notificationsAPI.getNotificationsForVehicleDrivers(1);

// Get notifications for admins only
const adminNotifications = await notificationsAPI.getNotificationsForVehicleAdmins(1);

// Get notifications for monitors only
const monitorNotifications = await notificationsAPI.getNotificationsForVehicleMonitors(1);

// Get notifications for specific user type
const customUserTypeNotifications = await notificationsAPI.getNotificationsByVehicleAndUserType(1, 'driver');
```

## React Component Usage

### Basic Component Usage

```jsx
import React from 'react';
import VehicleNotificationList from './components/VehicleNotificationList';

function VehicleDashboard({ vehicleId }) {
  return (
    <div>
      <h1>Vehicle Notifications</h1>
      <VehicleNotificationList
        vehicleId={vehicleId}
        userType="driver"
        onNotificationClick={(notification) => {
          console.log('Notification clicked:', notification);
        }}
      />
    </div>
  );
}
```

### Advanced Component Usage

```jsx
import React, { useState } from 'react';
import VehicleNotificationList from './components/VehicleNotificationList';

function AdvancedVehicleDashboard({ vehicleId }) {
  const [selectedUserType, setSelectedUserType] = useState('all');

  return (
    <div>
      <h1>Vehicle Notifications</h1>

      <div className="mb-4">
        <label>User Type:</label>
        <select
          value={selectedUserType}
          onChange={(e) => setSelectedUserType(e.target.value)}
        >
          <option value="all">All</option>
          <option value="driver">Drivers</option>
          <option value="admin">Admins</option>
          <option value="monitor">Monitors</option>
        </select>
      </div>

      <VehicleNotificationList
        vehicleId={vehicleId}
        userType={selectedUserType}
        onNotificationClick={(notification) => {
          // Handle notification click
          console.log('Notification clicked:', notification);
        }}
      />
    </div>
  );
}
```

## Error Handling

### Common Error Scenarios

1. **Vehicle Not Found**
   ```json
   {
     "success": false,
     "message": "Vehicle not found",
     "error": "VEHICLE_NOT_FOUND"
   }
   ```

2. **Invalid User Type**
   ```json
   {
     "success": false,
     "message": "Invalid user type",
     "error": "INVALID_USER_TYPE"
   }
   ```

3. **Invalid Parameters**
   ```json
   {
     "success": false,
     "message": "Invalid parameters",
     "error": "INVALID_PARAMETERS"
   }
   ```

### Error Handling in Code

```javascript
try {
  const result = await notificationsAPI.getNotificationsByVehicle(1);

  if (result.success) {
    console.log('Notifications:', result.data.results);
  } else {
    console.error('API Error:', result.message);
  }
} catch (error) {
  console.error('Network Error:', error.message);
}
```

## Testing

### Running Tests

```bash
# Run all vehicle notification tests
node test-vehicle-notifications.js

# Run specific test
node -e "require('./test-vehicle-notifications.js').testGetNotificationsByVehicle()"
```

### Test Coverage

The test suite covers:

- ✅ Basic vehicle notification retrieval
- ✅ User type filtering (driver, admin, monitor)
- ✅ Notification type filtering
- ✅ Priority filtering
- ✅ Status filtering
- ✅ Date range filtering
- ✅ Pagination
- ✅ Detailed information inclusion
- ✅ Error handling
- ✅ Performance testing

### Test Configuration

```javascript
const TEST_CONFIG = {
  vehicleId: 1,
  driverId: 51,
  adminId: 1,
  monitorId: 2,
  studentId: 1,
  routeId: 1
};
```

## Best Practices

### 1. Use Appropriate User Types

```javascript
// Good: Use specific user type for targeted notifications
const driverNotifications = await notificationsAPI.getNotificationsForVehicleDrivers(1);

// Avoid: Getting all notifications when you only need driver notifications
const allNotifications = await notificationsAPI.getNotificationsByVehicle(1);
```

### 2. Implement Pagination

```javascript
// Good: Use pagination for large datasets
const notifications = await notificationsAPI.getNotificationsByVehicle(1, {
  page: 1,
  page_size: 20
});

// Avoid: Loading all notifications at once
const allNotifications = await notificationsAPI.getNotificationsByVehicle(1, {
  page_size: 1000
});
```

### 3. Use Filtering for Performance

```javascript
// Good: Filter by date range for recent notifications
const recentNotifications = await notificationsAPI.getNotificationsByVehicle(1, {
  date_from: new Date(Date.now() - 24 * 60 * 60 * 1000).toISOString()
});

// Avoid: Loading all historical notifications
const allNotifications = await notificationsAPI.getNotificationsByVehicle(1);
```

### 4. Handle Errors Gracefully

```javascript
// Good: Proper error handling
try {
  const result = await notificationsAPI.getNotificationsByVehicle(1);

  if (result.success) {
    setNotifications(result.data.results);
  } else {
    setError(result.message);
  }
} catch (error) {
  setError('Network error occurred');
}
```

### 5. Use Appropriate Detail Levels

```javascript
// Good: Include only necessary details for performance
const minimalNotifications = await notificationsAPI.getNotificationsByVehicle(1, {
  include_student_details: false,
  include_vehicle_details: false,
  include_route_details: false,
  include_parent_details: false
});

// Good: Include all details when needed
const detailedNotifications = await notificationsAPI.getNotificationsByVehicle(1, {
  include_student_details: true,
  include_vehicle_details: true,
  include_route_details: true,
  include_parent_details: true
});
```

### 6. Cache Results When Appropriate

```javascript
// Good: Cache results for frequently accessed data
const cache = new Map();

async function getCachedNotifications(vehicleId) {
  if (cache.has(vehicleId)) {
    return cache.get(vehicleId);
  }

  const result = await notificationsAPI.getNotificationsByVehicle(vehicleId);
  cache.set(vehicleId, result);
  return result;
}
```

## Conclusion

The Vehicle Notification API provides comprehensive functionality for retrieving notifications by vehicle for different user types. By following the best practices outlined in this documentation, you can build efficient and user-friendly applications that leverage this API effectively.

For more information about the notification system, refer to the main [Notification API Documentation](./NOTIFICATION_API_README.md).
