# Bulk Notification API

This document describes the bulk notification API for sending multiple notifications at once for admin actions in the School Transit Back Office system.

## Overview

The bulk notification API allows administrators to send multiple notifications simultaneously to different recipients. It supports various notification types, priorities, channels, and scheduling options. This is particularly useful for system-wide announcements, route changes, emergency alerts, and maintenance notifications.

## API Endpoint

```
POST /api/v1/notifications/bulk-send/
```

## Request Body Format

### Required Fields

| Field | Type | Description |
|-------|------|-------------|
| `message` | string | Summary message about the bulk operation |
| `notifications` | array | Array of notification objects |

### Notification Object Fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `recipient` | number | Yes | ID of the notification recipient |
| `notification_type` | string | Yes | Type of notification |
| `title` | string | Yes | Notification title |
| `message` | string | Yes | Notification message content |
| `priority` | string | No | Notification priority (low, normal, high, urgent) |
| `student` | number | No | Student ID (if applicable) |
| `vehicle` | number | No | Vehicle ID (if applicable) |
| `route` | number/object | No | Route ID or route object (if applicable) |
| `location` | string | No | Location in POINT format |
| `channels` | array | No | Notification channels (push, sms, email) |
| `scheduled_at` | datetime | No | When to send the notification |
| `metadata` | object | No | Additional metadata |

## Example Request

```json
{
  "message": "1 notifications created",
  "notifications": [
    {
      "id": 2,
      "recipient": 1,
      "recipient_name": "",
      "notification_type": "route_change",
      "notification_type_display": "Route Change",
      "priority": "high",
      "priority_display": "High",
      "title": "Route Change Notice",
      "message": "Route A has been temporarily changed due to road construction",
      "student": null,
      "vehicle": null,
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
      "location": null,
      "location_display": null,
      "channels": ["push", "sms", "email"],
      "status": "pending",
      "status_display": "Pending",
      "scheduled_at": null,
      "sent_at": null,
      "delivered_at": null,
      "read_at": null,
      "metadata": {
        "reason": "road_construction",
        "duration": "2_hours"
      },
      "is_read": false,
      "is_sent": false,
      "is_delivered": false,
      "deliveries": [],
      "created_at": "2025-10-08T11:15:30.030129+03:00",
      "updated_at": "2025-10-08T11:15:30.030140+03:00"
    }
  ]
}
```

## Usage Examples

### 1. Basic Usage

```javascript
import { notificationsAPI } from './src/api/index';

// Send bulk notifications
const sendBulkNotifications = async () => {
  const bulkData = {
    message: "2 notifications created",
    notifications: [
      {
        recipient: 1,
        notification_type: "system_alert",
        priority: "normal",
        title: "System Update",
        message: "The system has been updated with new features"
      },
      {
        recipient: 2,
        notification_type: "system_alert",
        priority: "normal",
        title: "System Update",
        message: "The system has been updated with new features"
      }
    ]
  };

  try {
    const result = await notificationsAPI.bulkSendNotificationsWithValidation(bulkData);
    if (result.success) {
      console.log('Bulk notifications sent:', result.data);
    }
  } catch (error) {
    console.error('Error sending bulk notifications:', error);
  }
};
```

### 2. Send to Multiple Recipients

```javascript
// Send to multiple recipients
const sendToMultipleRecipients = async (recipients, notificationTemplate) => {
  try {
    const result = await notificationsAPI.bulkSendToRecipients(recipients, notificationTemplate, {
      notification_type: 'system_alert',
      priority: 'normal',
      channels: ['push', 'email'],
      metadata: {
        source: 'admin_action',
        timestamp: new Date().toISOString()
      }
    });
    return result;
  } catch (error) {
    console.error('Error sending to multiple recipients:', error);
  }
};
```

### 3. Send by Criteria

```javascript
// Send by criteria
const sendByCriteria = async (criteria, notificationTemplate) => {
  try {
    const result = await notificationsAPI.bulkSendByCriteria(criteria, notificationTemplate, {
      notification_type: 'route_change',
      priority: 'high',
      channels: ['push', 'sms', 'email'],
      metadata: {
        admin_action: true,
        timestamp: new Date().toISOString()
      }
    });
    return result;
  } catch (error) {
    console.error('Error sending by criteria:', error);
  }
};
```

### 4. Route Change Notifications

```javascript
// Send route change notifications
const sendRouteChangeNotifications = async (routeId, reason, duration) => {
  const notificationTemplate = {
    title: "Route Change Notice",
    message: `Route has been temporarily changed due to ${reason}. Expected duration: ${duration}`
  };

  const criteria = {
    route_ids: [routeId]
  };

  try {
    const result = await notificationsAPI.bulkSendByCriteria(criteria, notificationTemplate, {
      notification_type: 'route_change',
      priority: 'high',
      channels: ['push', 'sms', 'email'],
      metadata: {
        reason: reason,
        duration: duration,
        route_id: routeId
      }
    });
    return result;
  } catch (error) {
    console.error('Error sending route change notifications:', error);
  }
};
```

### 5. Emergency Notifications

```javascript
// Send emergency notifications
const sendEmergencyNotifications = async (affectedRoutes, emergencyType, instructions) => {
  const notificationTemplate = {
    title: "Emergency Alert",
    message: `Emergency situation: ${emergencyType}. ${instructions}`
  };

  const criteria = {
    route_ids: affectedRoutes
  };

  try {
    const result = await notificationsAPI.bulkSendByCriteria(criteria, notificationTemplate, {
      notification_type: 'emergency_alert',
      priority: 'urgent',
      channels: ['push', 'sms', 'email'],
      metadata: {
        emergency_type: emergencyType,
        instructions: instructions,
        timestamp: new Date().toISOString()
      }
    });
    return result;
  } catch (error) {
    console.error('Error sending emergency notifications:', error);
  }
};
```

### 6. Maintenance Notifications

```javascript
// Send maintenance notifications
const sendMaintenanceNotifications = async (vehicleIds, maintenanceType, scheduledTime) => {
  const notificationTemplate = {
    title: "Vehicle Maintenance Notice",
    message: `Scheduled maintenance: ${maintenanceType} at ${scheduledTime}`
  };

  const criteria = {
    vehicle_ids: vehicleIds
  };

  try {
    const result = await notificationsAPI.bulkSendByCriteria(criteria, notificationTemplate, {
      notification_type: 'system_maintenance',
      priority: 'normal',
      channels: ['push', 'email'],
      metadata: {
        maintenance_type: maintenanceType,
        scheduled_time: scheduledTime,
        vehicle_ids: vehicleIds
      }
    });
    return result;
  } catch (error) {
    console.error('Error sending maintenance notifications:', error);
  }
};
```

### 7. Student Pickup Notifications

```javascript
// Send student pickup notifications
const sendStudentPickupNotifications = async (studentIds, busNumber, driverName) => {
  const notificationTemplate = {
    title: "Student Pickup Notification",
    message: `Your child has been picked up by ${busNumber} (Driver: ${driverName})`
  };

  const criteria = {
    student_ids: studentIds
  };

  try {
    const result = await notificationsAPI.bulkSendByCriteria(criteria, notificationTemplate, {
      notification_type: 'student_pickup',
      priority: 'normal',
      channels: ['push', 'sms', 'email'],
      metadata: {
        bus_number: busNumber,
        driver_name: driverName,
        pickup_time: new Date().toISOString()
      }
    });
    return result;
  } catch (error) {
    console.error('Error sending student pickup notifications:', error);
  }
};
```

### 8. Delay Notifications

```javascript
// Send delay notifications
const sendDelayNotifications = async (routeIds, delayMinutes, reason) => {
  const notificationTemplate = {
    title: "Route Delay Alert",
    message: `Route is running ${delayMinutes} minutes behind schedule due to ${reason}`
  };

  const criteria = {
    route_ids: routeIds
  };

  try {
    const result = await notificationsAPI.bulkSendByCriteria(criteria, notificationTemplate, {
      notification_type: 'route_delay',
      priority: 'high',
      channels: ['push', 'sms'],
      metadata: {
        delay_minutes: delayMinutes,
        reason: reason,
        estimated_arrival: new Date(Date.now() + delayMinutes * 60000).toISOString()
      }
    });
    return result;
  } catch (error) {
    console.error('Error sending delay notifications:', error);
  }
};
```

### 9. Scheduled Notifications

```javascript
// Send scheduled notifications
const sendScheduledNotifications = async (notifications, scheduledTime) => {
  const bulkData = {
    message: `${notifications.length} scheduled notifications created`,
    notifications: notifications.map(notification => ({
      ...notification,
      scheduled_at: scheduledTime
    }))
  };

  try {
    const result = await notificationsAPI.bulkSendNotificationsWithValidation(bulkData);
    return result;
  } catch (error) {
    console.error('Error sending scheduled notifications:', error);
  }
};
```

### 10. Custom Bulk Notifications

```javascript
// Send custom bulk notifications
const sendCustomBulkNotifications = async (notifications) => {
  const bulkData = {
    message: `${notifications.length} custom notifications created`,
    notifications: notifications.map(notification => ({
      recipient: notification.recipient,
      notification_type: notification.notification_type || 'system_alert',
      priority: notification.priority || 'normal',
      title: notification.title,
      message: notification.message,
      student: notification.student || null,
      vehicle: notification.vehicle || null,
      route: notification.route || null,
      location: notification.location || null,
      channels: notification.channels || ['push'],
      scheduled_at: notification.scheduled_at || null,
      metadata: notification.metadata || {}
    }))
  };

  try {
    const result = await notificationsAPI.bulkSendNotificationsWithValidation(bulkData);
    return result;
  } catch (error) {
    console.error('Error sending custom bulk notifications:', error);
  }
};
```

## React Component Usage

A complete React component is available in `src/components/BulkNotificationForm.jsx`:

```jsx
import BulkNotificationForm from './components/BulkNotificationForm';

// Basic usage
<BulkNotificationForm />

// With callback
<BulkNotificationForm
  onBulkSent={(data) => {
    console.log('Bulk notifications sent:', data);
  }}
/>
```

## Notification Types

- `system_alert` - General system alert
- `route_change` - Route has been changed
- `emergency_alert` - Emergency situation
- `system_maintenance` - System maintenance notification
- `student_pickup` - Student has been picked up
- `student_dropoff` - Student has been dropped off
- `route_delay` - Route is delayed

## Priority Levels

- `low` - Low priority
- `normal` - Normal priority
- `high` - High priority
- `urgent` - Urgent priority

## Notification Channels

- `push` - Push notifications
- `sms` - SMS notifications
- `email` - Email notifications

## Validation

The API includes comprehensive validation:

### Required Fields
- `message` (string) - Summary message
- `notifications` (array) - Array of notifications
- Each notification must have: `recipient`, `notification_type`, `title`, `message`

### Optional Fields
- `priority` (string) - Default: "normal"
- `student` (number) - Student ID
- `vehicle` (number) - Vehicle ID
- `route` (number/object) - Route ID or route object
- `location` (string) - Location in POINT format
- `channels` (array) - Default: ["push"]
- `scheduled_at` (datetime) - When to send
- `metadata` (object) - Additional data

## Error Handling

The API returns structured error responses:

```javascript
{
  success: false,
  message: "Validation error message",
  status: 400,
  data: { /* detailed error information */ }
}
```

### Common Error Scenarios

1. **Empty notifications array**: "notifications array cannot be empty"
2. **Missing required fields**: "Notification X is missing required fields: field1, field2"
3. **Invalid notification type**: "Invalid notification_type"
4. **Invalid priority**: "Invalid priority level"
5. **Invalid channels**: "Invalid notification channels"

## Response Format

### Success Response

```javascript
{
  success: true,
  data: {
    message: "5 notifications created",
    notifications: [
      {
        id: 1,
        recipient: 1,
        notification_type: "system_alert",
        title: "System Update",
        message: "The system has been updated",
        status: "pending",
        created_at: "2024-01-15T10:30:00Z",
        // ... other notification fields
      }
      // ... more notifications
    ]
  },
  status: 201,
  message: "Operation successful"
}
```

## Performance Considerations

- Use appropriate batch sizes (50-100 notifications per request)
- Consider rate limiting for large batches
- Use scheduling for non-urgent notifications
- Monitor API response times and error rates
- Consider using background processing for very large batches

## Testing

Run the test script to verify the API functionality:

```bash
node test-bulk-notifications.js
```

The test script includes:
- Basic bulk notification sending
- Validation error testing
- Multiple notification types
- Different priorities and channels
- Scheduled notifications
- Error handling scenarios

## Files Created/Modified

1. **Enhanced API Service**: `src/api/services/notificationsAPI.js`
   - Added `bulkSendNotificationsWithValidation` method
   - Added `bulkSendToRecipients` method
   - Added `bulkSendByCriteria` method
   - Enhanced validation and error handling

2. **React Component**: `src/components/BulkNotificationForm.jsx`
   - Complete UI for bulk notification management
   - Form validation and error handling
   - Support for all notification types and channels
   - Real-time preview and JSON export

3. **Usage Examples**: `src/examples/bulkNotificationExamples.js`
   - Comprehensive examples for different scenarios
   - Utility functions for common operations
   - Ready-to-use code snippets

4. **Test Script**: `test-bulk-notifications.js`
   - Automated testing of bulk notification API
   - Validation error testing
   - Success scenario testing

## Integration

To use this API in your application:

1. Import the notification API:
   ```javascript
   import { notificationsAPI } from './src/api/index';
   ```

2. Use the appropriate method for your needs:
   ```javascript
   // Send bulk notifications with validation
   const result = await notificationsAPI.bulkSendNotificationsWithValidation(bulkData);

   // Send to multiple recipients
   const result = await notificationsAPI.bulkSendToRecipients(recipients, template, options);

   // Send by criteria
   const result = await notificationsAPI.bulkSendByCriteria(criteria, template, options);
   ```

3. Handle the response appropriately:
   ```javascript
   if (result.success) {
     // Handle success
     console.log('Bulk notifications sent:', result.data);
   } else {
     // Handle error
     console.error('Error:', result.message);
   }
   ```

## Security Considerations

- All bulk operations require proper authentication
- Recipient validation ensures notifications are sent to valid users
- Input sanitization prevents injection attacks
- Rate limiting prevents abuse
- Audit logging for bulk operations

## Support

For questions or issues with the bulk notification API, please refer to the main API documentation or contact the development team.
