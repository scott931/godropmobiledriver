# Notification Preferences API

This document describes the notification preferences API for managing user notification settings in the School Transit Back Office system.

## Overview

The notification preferences API allows users to configure how and when they receive notifications. It supports multiple notification channels, quiet hours, timezone settings, and user-specific preferences.

## API Endpoint

```
PUT /api/v1/notifications/preferences/
```

## Request Body Format

### Required Fields

| Field | Type | Description |
|-------|------|-------------|
| `user` | number | ID of the user whose preferences to update |

### Optional Fields

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `push_enabled` | boolean | true | Enable push notifications |
| `sms_enabled` | boolean | false | Enable SMS notifications |
| `email_enabled` | boolean | true | Enable email notifications |
| `eta_update` | boolean | false | Enable ETA update notifications |
| `quiet_hours_start` | string | "22:00:00" | Start time for quiet hours (HH:MM:SS) |
| `quiet_hours_end` | string | "07:00:00" | End time for quiet hours (HH:MM:SS) |
| `timezone` | string | "UTC" | User's timezone |

## Example Request

```json
{
  "user": 5,
  "push_enabled": true,
  "sms_enabled": false,
  "email_enabled": true,
  "eta_update": false,
  "quiet_hours_start": "22:00:00",
  "quiet_hours_end": "07:00:00",
  "timezone": "Africa/Nairobi"
}
```

## Usage Examples

### 1. Basic Usage in JavaScript/React

```javascript
import { notificationsAPI } from './src/api/index';

// Update notification preferences
const updatePreferences = async () => {
  const preferencesData = {
    user: 5,
    push_enabled: true,
    sms_enabled: false,
    email_enabled: true,
    eta_update: false,
    quiet_hours_start: "22:00:00",
    quiet_hours_end: "07:00:00",
    timezone: "Africa/Nairobi"
  };

  try {
    const result = await notificationsAPI.updateNotificationPreferencesWithValidation(preferencesData);
    if (result.success) {
      console.log('Preferences updated successfully:', result.data);
    } else {
      console.error('Failed to update preferences:', result.message);
    }
  } catch (error) {
    console.error('Error updating preferences:', error);
  }
};
```

### 2. Get Current Preferences

```javascript
// Get current user preferences
const getCurrentPreferences = async () => {
  try {
    const result = await notificationsAPI.getNotificationPreferences();
    if (result.success) {
      console.log('Current preferences:', result.data);
    }
  } catch (error) {
    console.error('Error getting preferences:', error);
  }
};
```

### 3. Update Specific Settings

```javascript
// Update only notification channels
const updateChannels = async (userId) => {
  const preferences = {
    user: userId,
    push_enabled: true,
    sms_enabled: false,
    email_enabled: true
  };

  return await notificationsAPI.updateNotificationPreferencesWithValidation(preferences);
};
```

### 4. Set Quiet Hours

```javascript
// Set quiet hours for a user
const setQuietHours = async (userId, startTime, endTime) => {
  const preferences = {
    user: userId,
    quiet_hours_start: startTime,
    quiet_hours_end: endTime
  };

  return await notificationsAPI.updateNotificationPreferencesWithValidation(preferences);
};
```

### 5. Update Timezone

```javascript
// Update user timezone
const updateTimezone = async (userId, timezone) => {
  const preferences = {
    user: userId,
    timezone: timezone
  };

  return await notificationsAPI.updateNotificationPreferencesWithValidation(preferences);
};
```

### 6. Disable All Notifications

```javascript
// Disable all notifications for a user
const disableAllNotifications = async (userId) => {
  const preferences = {
    user: userId,
    push_enabled: false,
    sms_enabled: false,
    email_enabled: false,
    eta_update: false
  };

  return await notificationsAPI.updateNotificationPreferencesWithValidation(preferences);
};
```

## React Component Usage

A complete React component is available in `src/components/NotificationPreferencesForm.jsx`:

```jsx
import NotificationPreferencesForm from './components/NotificationPreferencesForm';

// Use with specific user ID
<NotificationPreferencesForm userId={5} onPreferencesUpdated={(data) => {
  console.log('Preferences updated:', data);
}} />

// Use without user ID (user can input their own ID)
<NotificationPreferencesForm />
```

## Validation

The API includes comprehensive validation:

### Required Fields
- `user` (number) - Must be provided

### Boolean Fields
- `push_enabled`, `sms_enabled`, `email_enabled`, `eta_update` must be boolean values

### Time Format
- `quiet_hours_start` and `quiet_hours_end` must be in HH:MM:SS format
- Valid examples: "22:00:00", "07:30:00", "23:59:59"
- Invalid examples: "25:00:00", "22:60:00", "invalid-time"

### Timezone
- Must be a valid IANA timezone identifier
- Valid examples: "UTC", "Africa/Nairobi", "America/New_York"
- Invalid examples: "Invalid/Timezone", "GMT+1"

## Default Configurations

### Standard User
```json
{
  "push_enabled": true,
  "sms_enabled": false,
  "email_enabled": true,
  "eta_update": false,
  "quiet_hours_start": "22:00:00",
  "quiet_hours_end": "07:00:00",
  "timezone": "UTC"
}
```

### Parent User
```json
{
  "push_enabled": true,
  "sms_enabled": true,
  "email_enabled": true,
  "eta_update": true,
  "quiet_hours_start": "23:00:00",
  "quiet_hours_end": "06:00:00",
  "timezone": "UTC"
}
```

### Driver User
```json
{
  "push_enabled": true,
  "sms_enabled": true,
  "email_enabled": false,
  "eta_update": true,
  "quiet_hours_start": "00:00:00",
  "quiet_hours_end": "00:00:00",
  "timezone": "UTC"
}
```

## Common Timezones

| Timezone | Description |
|----------|-------------|
| `UTC` | Coordinated Universal Time |
| `Africa/Nairobi` | East Africa Time |
| `Africa/Lagos` | West Africa Time |
| `America/New_York` | Eastern Time |
| `America/Los_Angeles` | Pacific Time |
| `Europe/London` | Greenwich Mean Time |
| `Asia/Tokyo` | Japan Standard Time |
| `Asia/Shanghai` | China Standard Time |
| `Australia/Sydney` | Australian Eastern Time |

## Error Handling

### Validation Errors
```javascript
{
  success: false,
  message: "Missing required fields: user",
  status: 400,
  data: { /* detailed error information */ }
}
```

### Invalid Time Format
```javascript
{
  success: false,
  message: "quiet_hours_start must be in HH:MM:SS format",
  status: 400,
  data: { /* detailed error information */ }
}
```

### Invalid Timezone
```javascript
{
  success: false,
  message: "Invalid timezone format",
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
    user: 5,
    push_enabled: true,
    sms_enabled: false,
    email_enabled: true,
    eta_update: false,
    quiet_hours_start: "22:00:00",
    quiet_hours_end: "07:00:00",
    timezone: "Africa/Nairobi",
    updated_at: "2024-01-15T10:30:00Z"
  },
  status: 200,
  message: "Operation successful"
}
```

## Testing

Run the test script to verify the API functionality:

```bash
node test-notification-preferences.js
```

The test script includes:
- Basic preferences update
- Validation error testing
- Timezone validation
- Time format validation
- User type configurations
- Error handling scenarios

## Files Created/Modified

1. **Enhanced API Service**: `src/api/services/notificationsAPI.js`
   - Added `updateNotificationPreferencesWithValidation` method
   - Added validation helper functions
   - Enhanced error handling

2. **React Component**: `src/components/NotificationPreferencesForm.jsx`
   - Complete UI for managing preferences
   - Form validation and error handling
   - Support for all preference types
   - Default configurations

3. **Usage Examples**: `src/examples/notificationPreferencesExamples.js`
   - Comprehensive examples for different scenarios
   - Utility functions for validation
   - Ready-to-use code snippets

4. **Test Script**: `test-notification-preferences.js`
   - Automated testing of the preferences API
   - Validation error testing
   - Success scenario testing

## Integration

To use this API in your application:

1. Import the notification API:
   ```javascript
   import { notificationsAPI } from './src/api/index';
   ```

2. Use the enhanced method for preferences:
   ```javascript
   const result = await notificationsAPI.updateNotificationPreferencesWithValidation(preferencesData);
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

- All preference updates require proper authentication
- User validation ensures preferences are updated for valid users
- Input sanitization prevents injection attacks
- Timezone validation prevents invalid timezone settings

## Performance Considerations

- Use bulk operations for multiple users when possible
- Validate data client-side before sending to reduce server load
- Cache user preferences when appropriate
- Monitor API response times and error rates

## Support

For questions or issues with the notification preferences API, please refer to the main API documentation or contact the development team.
