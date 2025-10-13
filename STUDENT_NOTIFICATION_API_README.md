# Student Notification API

This document describes the student notification API for retrieving notifications by student for parents, drivers, and monitors in the School Transit Back Office system.

## Overview

The student notification API provides comprehensive functionality for retrieving notifications related to specific students. It supports filtering by user type (parents, drivers, monitors), notification type, priority, status, and other criteria. This is particularly useful for student-specific dashboards and notification management.

## API Endpoint

```
GET /api/v1/notifications/student/{student_id}/
```

## Response Format

The API returns an array of notification objects with detailed information:

```json
[
  {
    "id": 1,
    "recipient": 1,
    "recipient_name": "",
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
      "stops": [...],
      "schedules": [...],
      "assignments": [...],
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
```

## Query Parameters

### Filtering Parameters

| Parameter | Type | Description |
|-----------|------|-------------|
| `user_type` | string | Filter by user type (parent, driver, monitor) |
| `notification_type` | string | Filter by notification type |
| `priority` | string | Filter by priority (low, normal, high, urgent) |
| `status` | string | Filter by status (pending, sent, delivered, failed) |
| `date_from` | datetime | Filter from date |
| `date_to` | datetime | Filter to date |
| `is_read` | boolean | Filter by read status |
| `is_sent` | boolean | Filter by sent status |
| `is_delivered` | boolean | Filter by delivered status |
| `channels` | array | Filter by notification channels |
| `search` | string | Search in title and message |

### Pagination Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `page` | integer | 1 | Page number |
| `page_size` | integer | 50 | Number of items per page |

### Detail Inclusion Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `include_student_details` | boolean | true | Include detailed student information |
| `include_vehicle_details` | boolean | true | Include detailed vehicle information |
| `include_route_details` | boolean | true | Include detailed route information |
| `include_parent_details` | boolean | true | Include detailed parent information |

### Ordering Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `ordering` | string | '-created_at' | Order by field (prefix with - for descending) |

## Usage Examples

### 1. Basic Usage

```javascript
import { notificationsAPI } from './src/api/index';

// Get all notifications for a student
const getStudentNotifications = async (studentId) => {
  try {
    const result = await notificationsAPI.getNotificationsByStudent(studentId);
    if (result.success) {
      console.log('Student notifications:', result.data);
    }
  } catch (error) {
    console.error('Error getting student notifications:', error);
  }
};
```

### 2. Get Notifications for Student Parents

```javascript
// Get notifications for student parents
const getParentNotifications = async (studentId) => {
  try {
    const result = await notificationsAPI.getNotificationsForStudentParents(studentId);
    if (result.success) {
      console.log('Parent notifications:', result.data);
    }
  } catch (error) {
    console.error('Error getting parent notifications:', error);
  }
};
```

### 3. Get Notifications for Student Drivers

```javascript
// Get notifications for student drivers
const getDriverNotifications = async (studentId) => {
  try {
    const result = await notificationsAPI.getNotificationsForStudentDrivers(studentId);
    if (result.success) {
      console.log('Driver notifications:', result.data);
    }
  } catch (error) {
    console.error('Error getting driver notifications:', error);
  }
};
```

### 4. Get Notifications for Student Monitors

```javascript
// Get notifications for student monitors
const getMonitorNotifications = async (studentId) => {
  try {
    const result = await notificationsAPI.getNotificationsForStudentMonitors(studentId);
    if (result.success) {
      console.log('Monitor notifications:', result.data);
    }
  } catch (error) {
    console.error('Error getting monitor notifications:', error);
  }
};
```

### 5. Get Notifications by User Type

```javascript
// Get notifications by user type
const getNotificationsByUserType = async (studentId, userType) => {
  try {
    const result = await notificationsAPI.getNotificationsByStudentAndUserType(studentId, userType);
    if (result.success) {
      console.log(`${userType} notifications:`, result.data);
    }
  } catch (error) {
    console.error(`Error getting ${userType} notifications:`, error);
  }
};
```

### 6. Get Student Pickup Notifications

```javascript
// Get student pickup notifications
const getPickupNotifications = async (studentId) => {
  try {
    const result = await notificationsAPI.getNotificationsByStudent(studentId, {
      notification_type: 'student_pickup'
    });
    if (result.success) {
      console.log('Pickup notifications:', result.data);
    }
  } catch (error) {
    console.error('Error getting pickup notifications:', error);
  }
};
```

### 7. Get Student Dropoff Notifications

```javascript
// Get student dropoff notifications
const getDropoffNotifications = async (studentId) => {
  try {
    const result = await notificationsAPI.getNotificationsByStudent(studentId, {
      notification_type: 'student_dropoff'
    });
    if (result.success) {
      console.log('Dropoff notifications:', result.data);
    }
  } catch (error) {
    console.error('Error getting dropoff notifications:', error);
  }
};
```

### 8. Get Unread Notifications

```javascript
// Get unread notifications
const getUnreadNotifications = async (studentId) => {
  try {
    const result = await notificationsAPI.getNotificationsByStudent(studentId, {
      is_read: false
    });
    if (result.success) {
      console.log('Unread notifications:', result.data);
    }
  } catch (error) {
    console.error('Error getting unread notifications:', error);
  }
};
```

### 9. Get Recent Notifications

```javascript
// Get recent notifications (last 24 hours)
const getRecentNotifications = async (studentId) => {
  const yesterday = new Date();
  yesterday.setDate(yesterday.getDate() - 1);

  try {
    const result = await notificationsAPI.getNotificationsByStudent(studentId, {
      date_from: yesterday.toISOString()
    });
    if (result.success) {
      console.log('Recent notifications:', result.data);
    }
  } catch (error) {
    console.error('Error getting recent notifications:', error);
  }
};
```

### 10. Get Notifications with Pagination

```javascript
// Get notifications with pagination
const getNotificationsWithPagination = async (studentId, page = 1, pageSize = 20) => {
  try {
    const result = await notificationsAPI.getNotificationsByStudent(studentId, {
      page: page,
      page_size: pageSize
    });

    if (result.success) {
      console.log('Page:', page);
      console.log('Total pages:', Math.ceil(result.data.count / pageSize));
      console.log('Has next:', !!result.data.next);
      console.log('Has previous:', !!result.data.previous);
    }
  } catch (error) {
    console.error('Error getting paginated notifications:', error);
  }
};
```

### 11. Get Notifications by Priority

```javascript
// Get notifications by priority
const getNotificationsByPriority = async (studentId, priority) => {
  try {
    const result = await notificationsAPI.getNotificationsByStudent(studentId, {
      priority: priority
    });
    if (result.success) {
      console.log(`${priority} priority notifications:`, result.data);
    }
  } catch (error) {
    console.error(`Error getting ${priority} priority notifications:`, error);
  }
};
```

### 12. Get Notifications by Date Range

```javascript
// Get notifications by date range
const getNotificationsByDateRange = async (studentId, dateFrom, dateTo) => {
  try {
    const result = await notificationsAPI.getNotificationsByStudent(studentId, {
      date_from: dateFrom,
      date_to: dateTo
    });
    if (result.success) {
      console.log('Date range notifications:', result.data);
    }
  } catch (error) {
    console.error('Error getting date range notifications:', error);
  }
};
```

### 13. Get Notifications with Advanced Filtering

```javascript
// Get notifications with advanced filtering
const getNotificationsWithAdvancedFiltering = async (studentId, filters) => {
  try {
    const result = await notificationsAPI.getNotificationsByStudent(studentId, {
      user_type: filters.userType,
      notification_type: filters.notificationType,
      priority: filters.priority,
      status: filters.status,
      date_from: filters.dateFrom,
      date_to: filters.dateTo,
      is_read: filters.isRead,
      is_sent: filters.isSent,
      is_delivered: filters.isDelivered,
      channels: filters.channels,
      page: filters.page || 1,
      page_size: filters.pageSize || 20,
      ordering: filters.ordering || '-created_at'
    });

    if (result.success) {
      console.log('Filtered notifications:', result.data);
    }
  } catch (error) {
    console.error('Error getting filtered notifications:', error);
  }
};
```

### 14. Get Notification Statistics

```javascript
// Get notification statistics
const getNotificationStatistics = async (studentId) => {
  try {
    // Get total count
    const totalResult = await notificationsAPI.getNotificationsByStudent(studentId, {
      page_size: 1
    });

    // Get unread count
    const unreadResult = await notificationsAPI.getNotificationsByStudent(studentId, {
      is_read: false,
      page_size: 1
    });

    // Get pickup count
    const pickupResult = await notificationsAPI.getNotificationsByStudent(studentId, {
      notification_type: 'student_pickup',
      page_size: 1
    });

    // Get dropoff count
    const dropoffResult = await notificationsAPI.getNotificationsByStudent(studentId, {
      notification_type: 'student_dropoff',
      page_size: 1
    });

    const stats = {
      total: totalResult.data?.count || 0,
      unread: unreadResult.data?.count || 0,
      pickup: pickupResult.data?.count || 0,
      dropoff: dropoffResult.data?.count || 0
    };

    console.log('Notification statistics:', stats);
  } catch (error) {
    console.error('Error getting notification statistics:', error);
  }
};
```

## React Component Usage

A complete React component is available in `src/components/StudentNotificationList.jsx`:

```jsx
import StudentNotificationList from './components/StudentNotificationList';

// Basic usage
<StudentNotificationList studentId={1} />

// With user type filtering
<StudentNotificationList
  studentId={1}
  userType="parent"
/>

// With custom settings
<StudentNotificationList
  studentId={1}
  userType="all"
  showFilters={true}
  showPagination={true}
  pageSize={20}
  onNotificationClick={(notification) => {
    console.log('Notification clicked:', notification);
  }}
/>
```

## User Types

- `parent` - Student parents
- `driver` - Student drivers
- `monitor` - Student monitors
- `all` - All user types

## Notification Types

- `student_pickup` - Student has been picked up
- `student_dropoff` - Student has been dropped off
- `route_change` - Route has been changed
- `route_delay` - Route is delayed
- `emergency_alert` - Emergency situation
- `system_maintenance` - System maintenance notification

## Priority Levels

- `low` - Low priority
- `normal` - Normal priority
- `high` - High priority
- `urgent` - Urgent priority

## Status Values

- `pending` - Notification is pending
- `sent` - Notification has been sent
- `delivered` - Notification has been delivered
- `failed` - Notification failed to send

## Ordering Options

- `created_at` - Order by creation date (ascending)
- `-created_at` - Order by creation date (descending)
- `priority` - Order by priority (ascending)
- `-priority` - Order by priority (descending)
- `title` - Order by title (ascending)
- `-title` - Order by title (descending)

## Error Handling

The API returns structured error responses:

```javascript
{
  success: false,
  message: "Error message",
  status: 400,
  data: { /* detailed error information */ }
}
```

## Performance Considerations

- Use appropriate page sizes (20-50 items per page)
- Use filtering to reduce data transfer
- Disable unnecessary detail inclusion for better performance
- Use pagination for large datasets
- Consider caching for frequently accessed data

## Testing

Run the test script to verify the API functionality:

```bash
node test-student-notifications.js
```

The test script includes:
- Basic student notification retrieval
- User type filtering testing
- Notification type filtering
- Priority and status filtering
- Pagination testing
- Error handling scenarios

## Files Created/Modified

1. **Enhanced API Service**: `src/api/services/notificationsAPI.js`
   - Added `getNotificationsByStudent` method
   - Added `getNotificationsForStudentParents` method
   - Added `getNotificationsForStudentDrivers` method
   - Added `getNotificationsForStudentMonitors` method
   - Added `getNotificationsByStudentAndUserType` method

2. **React Component**: `src/components/StudentNotificationList.jsx`
   - Complete UI for student notification management
   - User type filtering with tabs
   - Advanced filtering and search functionality
   - Statistics display
   - Pagination support

3. **Usage Examples**: `src/examples/studentNotificationExamples.js`
   - Comprehensive examples for different scenarios
   - User type specific examples
   - Filtering and pagination examples
   - Statistics and analytics examples

4. **Test Script**: `test-student-notifications.js`
   - Automated testing of student notification API
   - User type filtering testing
   - Notification type filtering testing
   - Success scenario testing

## Integration

To use this API in your application:

1. Import the notification API:
   ```javascript
   import { notificationsAPI } from './src/api/index';
   ```

2. Use the appropriate method for your needs:
   ```javascript
   // Get all notifications for a student
   const result = await notificationsAPI.getNotificationsByStudent(studentId);

   // Get notifications for parents
   const result = await notificationsAPI.getNotificationsForStudentParents(studentId);

   // Get notifications by user type
   const result = await notificationsAPI.getNotificationsByStudentAndUserType(studentId, userType);
   ```

3. Handle the response appropriately:
   ```javascript
   if (result.success) {
     // Handle success
     console.log('Notifications:', result.data);
   } else {
     // Handle error
     console.error('Error:', result.message);
   }
   ```

## Security Considerations

- All requests require proper authentication
- User validation ensures data access is authorized
- Student validation ensures notifications are for valid students
- Input sanitization prevents injection attacks
- Rate limiting prevents abuse

## Support

For questions or issues with the student notification API, please refer to the main API documentation or contact the development team.
