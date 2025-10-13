# Admin/System Notification API

This document describes the enhanced notification API for creating admin/system notifications in the School Transit Back Office system.

## Overview

The notification API provides a comprehensive system for creating and managing notifications for various admin and system actions. It supports multiple notification types, channels, and scheduling options.

## API Endpoint

```
POST /api/v1/notifications/
```

## Request Body Format

### Required Fields

| Field | Type | Description |
|-------|------|-------------|
| `recipient` | number | ID of the notification recipient |
| `notification_type` | string | Type of notification (see types below) |
| `title` | string | Notification title |
| `message` | string | Notification message content |

### Optional Fields

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `priority` | string | "normal" | Notification priority (low, normal, high, urgent) |
| `student` | number | null | Student ID (if applicable) |
| `vehicle` | number | null | Vehicle ID (if applicable) |
| `route` | number | null | Route ID (if applicable) |
| `location` | string | null | Location in POINT format |
| `channels` | array | ["push"] | Notification channels (push, sms, email) |
| `scheduled_at` | datetime | null | When to send the notification |
| `metadata` | object | {} | Additional metadata |

## Notification Types

- `student_pickup` - Student has been picked up
- `student_dropoff` - Student has been dropped off
- `route_delay` - Route is delayed
- `emergency_alert` - Emergency situation
- `system_maintenance` - System maintenance notification
- `system_alert` - General system alert

## Example Request

```json
{
  "recipient": 1,
  "notification_type": "student_pickup",
  "priority": "normal",
  "title": "Student Picked Up",
  "message": "Your child Sarah has been picked up by BUS-001",
  "student": 1,
  "vehicle": 1,
  "route": 1,
  "location": "POINT(-74.0059 40.7128)",
  "channels": ["push", "sms", "email"],
  "scheduled_at": null,
  "metadata": {
    "trip_id": 123,
    "driver_name": "John Smith"
  }
}
```

## Usage Examples

### 1. Basic Usage in JavaScript/React

```javascript
import { notificationsAPI } from './src/api/index';

// Create a student pickup notification
const createStudentPickupNotification = async () => {
  const notificationData = {
    recipient: 1,
    notification_type: "student_pickup",
    priority: "normal",
    title: "Student Picked Up",
    message: "Your child Sarah has been picked up by BUS-001",
    student: 1,
    vehicle: 1,
    route: 1,
    location: "POINT(-74.0059 40.7128)",
    channels: ["push", "sms", "email"],
    scheduled_at: null,
    metadata: {
      trip_id: 123,
      driver_name: "John Smith"
    }
  };

  try {
    const result = await notificationsAPI.createAdminNotification(notificationData);
    if (result.success) {
      console.log('Notification created successfully:', result.data);
    } else {
      console.error('Failed to create notification:', result.message);
    }
  } catch (error) {
    console.error('Error creating notification:', error);
  }
};
```

### 2. Using the Enhanced API Method

The `createAdminNotification` method provides additional validation and default values:

```javascript
// Minimal notification (only required fields)
const minimalNotification = {
  recipient: 1,
  notification_type: "system_alert",
  title: "System Update",
  message: "The system has been updated with new features."
};

const result = await notificationsAPI.createAdminNotification(minimalNotification);
```

### 3. Bulk Notifications

```javascript
const createBulkNotifications = async (recipientIds, notificationData) => {
  const results = [];

  for (const recipientId of recipientIds) {
    try {
      const result = await notificationsAPI.createAdminNotification({
        ...notificationData,
        recipient: recipientId
      });
      results.push({ recipientId, success: true, data: result.data });
    } catch (error) {
      results.push({ recipientId, success: false, error: error.message });
    }
  }

  return results;
};
```

### 4. Scheduled Notifications

```javascript
const createScheduledNotification = async (notificationData, scheduledTime) => {
  const scheduledNotification = {
    ...notificationData,
    scheduled_at: scheduledTime
  };

  return await notificationsAPI.createAdminNotification(scheduledNotification);
};
```

## React Component Example

A complete React component example is available in `src/components/AdminNotificationExample.jsx` that demonstrates:

- Form-based notification creation
- Validation handling
- Multiple notification types
- Channel selection
- Metadata management

## Validation

The API includes built-in validation for:

- Required fields (recipient, notification_type, title, message)
- Valid notification types
- Valid priority levels
- Valid notification channels
- Data type validation

## Error Handling

The API returns structured error responses:

```javascript
{
  success: false,
  message: "Missing required fields: recipient, title",
  status: 400,
  data: { /* detailed error information */ }
}
```

## Response Format

### Success Response

```javascript
{
  success: true,
  data: {
    id: 123,
    recipient: 1,
    notification_type: "student_pickup",
    title: "Student Picked Up",
    message: "Your child Sarah has been picked up by BUS-001",
    status: "sent",
    created_at: "2024-01-15T10:30:00Z",
    // ... other notification fields
  },
  status: 201,
  message: "Operation successful"
}
```

### Error Response

```javascript
{
  success: false,
  message: "Missing required fields: recipient, title",
  status: 400,
  data: { /* detailed error information */ }
}
```

## Testing

Run the test script to verify the API functionality:

```bash
node test-admin-notification.js
```

## Files Created/Modified

1. **Enhanced API Service**: `src/api/services/notificationsAPI.js`
   - Added `createAdminNotification` method with validation
   - Enhanced error handling and default values

2. **React Component**: `src/components/AdminNotificationExample.jsx`
   - Complete UI for creating notifications
   - Form validation and error handling
   - Multiple notification type examples

3. **Usage Examples**: `src/examples/notificationExamples.js`
   - Comprehensive examples for different notification types
   - Utility functions for validation and bulk operations
   - Ready-to-use code snippets

4. **Test Script**: `test-admin-notification.js`
   - Automated testing of the notification API
   - Validation error testing
   - Success scenario testing

## Integration

To use this API in your application:

1. Import the notification API:
   ```javascript
   import { notificationsAPI } from './src/api/index';
   ```

2. Use the enhanced method for admin notifications:
   ```javascript
   const result = await notificationsAPI.createAdminNotification(notificationData);
   ```

3. Handle the response appropriately:
   ```javascript
   if (result.success) {
     // Handle success
   } else {
     // Handle error
   }
   ```

## Security Considerations

- All notifications require proper authentication
- Recipient validation ensures notifications are sent to valid users
- Channel validation prevents invalid notification channels
- Input sanitization prevents injection attacks

## Performance Considerations

- Use bulk operations for multiple recipients when possible
- Schedule notifications for off-peak hours when appropriate
- Consider rate limiting for high-volume notification scenarios
- Monitor API response times and error rates

## Support

For questions or issues with the notification API, please refer to the main API documentation or contact the development team.
