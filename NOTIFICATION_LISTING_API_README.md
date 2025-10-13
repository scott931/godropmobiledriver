# Notification Listing API

This document describes the notification listing API for retrieving notifications with detailed response format in the School Transit Back Office system.

## Overview

The notification listing API provides comprehensive functionality for retrieving notifications with detailed information including student details, vehicle information, route details, and parent relationships. It supports advanced filtering, pagination, and various query parameters.

## API Endpoint

```
GET /api/v1/notifications/
```

## Response Format

The API returns a paginated response with detailed notification information:

```json
{
  "count": 1,
  "next": null,
  "previous": null,
  "results": [
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
}
```

## Query Parameters

### Pagination Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `page` | integer | 1 | Page number |
| `page_size` | integer | 20 | Number of items per page |

### Filtering Parameters

| Parameter | Type | Description |
|-----------|------|-------------|
| `recipient` | integer | Filter by recipient ID |
| `notification_type` | string | Filter by notification type |
| `priority` | string | Filter by priority (low, normal, high, urgent) |
| `status` | string | Filter by status (pending, sent, delivered, failed) |
| `date_from` | datetime | Filter from date |
| `date_to` | datetime | Filter to date |
| `is_read` | boolean | Filter by read status |
| `is_sent` | boolean | Filter by sent status |
| `is_delivered` | boolean | Filter by delivered status |
| `student_id` | integer | Filter by student ID |
| `vehicle_id` | integer | Filter by vehicle ID |
| `route_id` | integer | Filter by route ID |
| `search` | string | Search in title and message |

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

// Get all notifications with default settings
const getAllNotifications = async () => {
  try {
    const result = await notificationsAPI.getAllNotifications();
    if (result.success) {
      console.log('Notifications:', result.data.results);
      console.log('Total count:', result.data.count);
    }
  } catch (error) {
    console.error('Error getting notifications:', error);
  }
};
```

### 2. Get Notifications for a Specific Parent

```javascript
// Get notifications for a specific parent
const getParentNotifications = async (parentId) => {
  try {
    const result = await notificationsAPI.getNotificationsForParent(parentId);
    if (result.success) {
      console.log('Parent notifications:', result.data.results);
    }
  } catch (error) {
    console.error('Error getting parent notifications:', error);
  }
};
```

### 3. Get Notifications for a Specific Student

```javascript
// Get notifications for a specific student
const getStudentNotifications = async (studentId) => {
  try {
    const result = await notificationsAPI.getNotificationsForStudent(studentId);
    if (result.success) {
      console.log('Student notifications:', result.data.results);
    }
  } catch (error) {
    console.error('Error getting student notifications:', error);
  }
};
```

### 4. Advanced Filtering

```javascript
// Get filtered notifications
const getFilteredNotifications = async () => {
  const filters = {
    notification_type: 'student_pickup',
    priority: 'normal',
    is_read: false,
    date_from: '2024-01-01',
    date_to: '2024-12-31',
    page: 1,
    page_size: 20
  };

  try {
    const result = await notificationsAPI.getFilteredNotifications(filters);
    if (result.success) {
      console.log('Filtered notifications:', result.data.results);
    }
  } catch (error) {
    console.error('Error getting filtered notifications:', error);
  }
};
```

### 5. Pagination

```javascript
// Get notifications with pagination
const getNotificationsWithPagination = async (page = 1, pageSize = 20) => {
  try {
    const result = await notificationsAPI.getFilteredNotifications({
      page,
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

### 6. Get Unread Notifications

```javascript
// Get unread notifications
const getUnreadNotifications = async () => {
  try {
    const result = await notificationsAPI.getFilteredNotifications({
      is_read: false
    });

    if (result.success) {
      console.log('Unread notifications:', result.data.results);
    }
  } catch (error) {
    console.error('Error getting unread notifications:', error);
  }
};
```

### 7. Get Notifications by Type

```javascript
// Get notifications by type
const getNotificationsByType = async (type) => {
  try {
    const result = await notificationsAPI.getFilteredNotifications({
      notification_type: type
    });

    if (result.success) {
      console.log(`${type} notifications:`, result.data.results);
    }
  } catch (error) {
    console.error(`Error getting ${type} notifications:`, error);
  }
};
```

### 8. Get Recent Notifications

```javascript
// Get recent notifications (last 24 hours)
const getRecentNotifications = async () => {
  const yesterday = new Date();
  yesterday.setDate(yesterday.getDate() - 1);

  try {
    const result = await notificationsAPI.getFilteredNotifications({
      date_from: yesterday.toISOString()
    });

    if (result.success) {
      console.log('Recent notifications:', result.data.results);
    }
  } catch (error) {
    console.error('Error getting recent notifications:', error);
  }
};
```

### 9. Search Notifications

```javascript
// Search notifications
const searchNotifications = async (searchTerm) => {
  try {
    const result = await notificationsAPI.getFilteredNotifications({
      search: searchTerm
    });

    if (result.success) {
      console.log('Search results:', result.data.results);
    }
  } catch (error) {
    console.error('Error searching notifications:', error);
  }
};
```

### 10. Get Notification Statistics

```javascript
// Get notification statistics
const getNotificationStatistics = async () => {
  try {
    // Get total count
    const totalResult = await notificationsAPI.getFilteredNotifications({
      page_size: 1
    });

    // Get unread count
    const unreadResult = await notificationsAPI.getFilteredNotifications({
      is_read: false,
      page_size: 1
    });

    // Get sent count
    const sentResult = await notificationsAPI.getFilteredNotifications({
      is_sent: true,
      page_size: 1
    });

    // Get delivered count
    const deliveredResult = await notificationsAPI.getFilteredNotifications({
      is_delivered: true,
      page_size: 1
    });

    const stats = {
      total: totalResult.data?.count || 0,
      unread: unreadResult.data?.count || 0,
      sent: sentResult.data?.count || 0,
      delivered: deliveredResult.data?.count || 0
    };

    console.log('Notification statistics:', stats);
  } catch (error) {
    console.error('Error getting notification statistics:', error);
  }
};
```

## React Component Usage

A complete React component is available in `src/components/NotificationList.jsx`:

```jsx
import NotificationList from './components/NotificationList';

// Basic usage
<NotificationList />

// With parent ID
<NotificationList parentId={1} />

// With student ID
<NotificationList studentId={1} />

// With custom settings
<NotificationList
  parentId={1}
  showFilters={true}
  showPagination={true}
  pageSize={20}
  onNotificationClick={(notification) => {
    console.log('Notification clicked:', notification);
  }}
/>
```

## Notification Types

- `student_pickup` - Student has been picked up
- `student_dropoff` - Student has been dropped off
- `route_delay` - Route is delayed
- `emergency_alert` - Emergency situation
- `system_maintenance` - System maintenance notification
- `system_alert` - General system alert

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
node test-notification-listing.js
```

The test script includes:
- Basic notification retrieval
- Filtering and pagination testing
- Error handling scenarios
- Performance testing
- Comprehensive functionality testing

## Files Created/Modified

1. **Enhanced API Service**: `src/api/services/notificationsAPI.js`
   - Added `getAllNotifications` method with detailed response
   - Added `getNotificationsForParent` method
   - Added `getNotificationsForStudent` method
   - Added `getFilteredNotifications` method with advanced filtering

2. **React Component**: `src/components/NotificationList.jsx`
   - Complete UI for displaying notifications
   - Advanced filtering and search functionality
   - Pagination support
   - Real-time updates

3. **Usage Examples**: `src/examples/notificationListingExamples.js`
   - Comprehensive examples for different scenarios
   - Utility functions for common operations
   - Ready-to-use code snippets

4. **Test Script**: `test-notification-listing.js`
   - Automated testing of the listing API
   - Filtering and pagination testing
   - Success scenario testing

## Integration

To use this API in your application:

1. Import the notification API:
   ```javascript
   import { notificationsAPI } from './src/api/index';
   ```

2. Use the appropriate method for your needs:
   ```javascript
   // Get all notifications
   const result = await notificationsAPI.getAllNotifications();

   // Get filtered notifications
   const result = await notificationsAPI.getFilteredNotifications(filters);

   // Get parent notifications
   const result = await notificationsAPI.getNotificationsForParent(parentId);
   ```

3. Handle the response appropriately:
   ```javascript
   if (result.success) {
     // Handle success
     console.log('Notifications:', result.data.results);
     console.log('Total count:', result.data.count);
   } else {
     // Handle error
     console.error('Error:', result.message);
   }
   ```

## Security Considerations

- All requests require proper authentication
- User validation ensures data access is authorized
- Input sanitization prevents injection attacks
- Rate limiting prevents abuse

## Support

For questions or issues with the notification listing API, please refer to the main API documentation or contact the development team.
