/**
 * Test script for Notification Preferences API
 * This script demonstrates how to update notification preferences
 */

import { notificationsAPI } from './src/api/index.js';

// Example preferences data as specified in the request
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

// Test function to update notification preferences
async function testUpdateNotificationPreferences() {
  console.log('🚀 Testing Notification Preferences Update...');
  console.log('📋 Preferences Data:', JSON.stringify(preferencesData, null, 2));

  try {
    // Use the enhanced updateNotificationPreferencesWithValidation method
    const result = await notificationsAPI.updateNotificationPreferencesWithValidation(preferencesData);

    if (result.success) {
      console.log('✅ Notification preferences updated successfully!');
      console.log('📊 Response:', JSON.stringify(result.data, null, 2));
    } else {
      console.error('❌ Failed to update preferences:', result.message);
    }
  } catch (error) {
    console.error('💥 Error updating preferences:', error);
  }
}

// Test function using the standard updateNotificationPreferences method
async function testUpdateStandardPreferences() {
  console.log('\n🚀 Testing Standard Preferences Update...');

  try {
    const result = await notificationsAPI.updateNotificationPreferences(preferencesData);

    if (result.success) {
      console.log('✅ Standard preferences updated successfully!');
      console.log('📊 Response:', JSON.stringify(result.data, null, 2));
    } else {
      console.error('❌ Failed to update standard preferences:', result.message);
    }
  } catch (error) {
    console.error('💥 Error updating standard preferences:', error);
  }
}

// Test function with minimal required data
async function testMinimalPreferences() {
  console.log('\n🚀 Testing Minimal Preferences Update...');

  const minimalData = {
    user: 5
    // All other fields will use defaults
  };

  try {
    const result = await notificationsAPI.updateNotificationPreferencesWithValidation(minimalData);

    if (result.success) {
      console.log('✅ Minimal preferences updated successfully!');
      console.log('📊 Response:', JSON.stringify(result.data, null, 2));
    } else {
      console.error('❌ Failed to update minimal preferences:', result.message);
    }
  } catch (error) {
    console.error('💥 Error updating minimal preferences:', error);
  }
}

// Test function with validation error
async function testValidationError() {
  console.log('\n🚀 Testing Validation Error Handling...');

  const invalidData = {
    // Missing required user field
    push_enabled: true,
    quiet_hours_start: "invalid-time-format"
  };

  try {
    const result = await notificationsAPI.updateNotificationPreferencesWithValidation(invalidData);

    if (result.success) {
      console.log('❌ Unexpected success with invalid data!');
    } else {
      console.log('✅ Validation error handled correctly:', result.message);
    }
  } catch (error) {
    console.log('✅ Validation error caught:', error.message);
  }
}

// Test function to get current preferences
async function testGetCurrentPreferences() {
  console.log('\n🚀 Testing Get Current Preferences...');

  try {
    const result = await notificationsAPI.getNotificationPreferences();

    if (result.success) {
      console.log('✅ Current preferences retrieved successfully!');
      console.log('📊 Current Preferences:', JSON.stringify(result.data, null, 2));
    } else {
      console.error('❌ Failed to get current preferences:', result.message);
    }
  } catch (error) {
    console.error('💥 Error getting current preferences:', error);
  }
}

// Test function for different user types
async function testUserTypePreferences() {
  console.log('\n🚀 Testing User Type Preferences...');

  const userTypes = [
    { type: 'standard', userId: 1 },
    { type: 'parent', userId: 2 },
    { type: 'driver', userId: 3 },
    { type: 'admin', userId: 4 }
  ];

  for (const { type, userId } of userTypes) {
    try {
      const preferences = {
        user: userId,
        push_enabled: true,
        sms_enabled: type === 'parent' || type === 'driver',
        email_enabled: true,
        eta_update: type === 'parent' || type === 'driver',
        quiet_hours_start: type === 'driver' ? "00:00:00" : "22:00:00",
        quiet_hours_end: type === 'driver' ? "00:00:00" : "07:00:00",
        timezone: "UTC"
      };

      const result = await notificationsAPI.updateNotificationPreferencesWithValidation(preferences);

      if (result.success) {
        console.log(`✅ ${type} preferences updated for user ${userId}`);
      } else {
        console.error(`❌ Failed to update ${type} preferences:`, result.message);
      }
    } catch (error) {
      console.error(`💥 Error updating ${type} preferences:`, error.message);
    }
  }
}

// Test function for timezone validation
async function testTimezoneValidation() {
  console.log('\n🚀 Testing Timezone Validation...');

  const timezones = [
    'UTC',
    'Africa/Nairobi',
    'America/New_York',
    'Europe/London',
    'Asia/Tokyo',
    'Invalid/Timezone' // This should fail
  ];

  for (const timezone of timezones) {
    try {
      const preferences = {
        user: 5,
        timezone: timezone
      };

      const result = await notificationsAPI.updateNotificationPreferencesWithValidation(preferences);

      if (result.success) {
        console.log(`✅ Timezone ${timezone} is valid`);
      } else {
        console.log(`❌ Timezone ${timezone} is invalid:`, result.message);
      }
    } catch (error) {
      console.log(`💥 Error with timezone ${timezone}:`, error.message);
    }
  }
}

// Test function for quiet hours validation
async function testQuietHoursValidation() {
  console.log('\n🚀 Testing Quiet Hours Validation...');

  const timeFormats = [
    '22:00:00', // Valid
    '07:30:00', // Valid
    '23:59:59', // Valid
    '00:00:00', // Valid
    '25:00:00', // Invalid
    '22:60:00', // Invalid
    'invalid-time', // Invalid
    '22:00', // Invalid (missing seconds)
  ];

  for (const timeFormat of timeFormats) {
    try {
      const preferences = {
        user: 5,
        quiet_hours_start: timeFormat,
        quiet_hours_end: "07:00:00"
      };

      const result = await notificationsAPI.updateNotificationPreferencesWithValidation(preferences);

      if (result.success) {
        console.log(`✅ Time format ${timeFormat} is valid`);
      } else {
        console.log(`❌ Time format ${timeFormat} is invalid:`, result.message);
      }
    } catch (error) {
      console.log(`💥 Error with time format ${timeFormat}:`, error.message);
    }
  }
}

// Run all tests
async function runAllTests() {
  console.log('🧪 Starting Notification Preferences API Tests\n');

  await testGetCurrentPreferences();
  await testUpdateNotificationPreferences();
  await testUpdateStandardPreferences();
  await testMinimalPreferences();
  await testValidationError();
  await testUserTypePreferences();
  await testTimezoneValidation();
  await testQuietHoursValidation();

  console.log('\n🏁 All tests completed!');
}

// Export for use in other modules
export {
  testUpdateNotificationPreferences,
  testUpdateStandardPreferences,
  testMinimalPreferences,
  testValidationError,
  testGetCurrentPreferences,
  testUserTypePreferences,
  testTimezoneValidation,
  testQuietHoursValidation,
  runAllTests
};

// Run tests if this file is executed directly
if (import.meta.url === `file://${process.argv[1]}`) {
  runAllTests();
}
