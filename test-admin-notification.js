/**
 * Test script for Admin/System Notification API
 * This script demonstrates how to create notifications using the enhanced API
 */

import { notificationsAPI } from './src/api/index.js';

// Example notification data as specified in the request
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

// Test function to create admin notification
async function testCreateAdminNotification() {
  console.log('🚀 Testing Admin Notification Creation...');
  console.log('📋 Notification Data:', JSON.stringify(notificationData, null, 2));

  try {
    // Use the new createAdminNotification method
    const result = await notificationsAPI.createAdminNotification(notificationData);

    if (result.success) {
      console.log('✅ Notification created successfully!');
      console.log('📊 Response:', JSON.stringify(result.data, null, 2));
    } else {
      console.error('❌ Failed to create notification:', result.message);
    }
  } catch (error) {
    console.error('💥 Error creating notification:', error);
  }
}

// Test function using the standard createNotification method
async function testCreateStandardNotification() {
  console.log('\n🚀 Testing Standard Notification Creation...');

  try {
    const result = await notificationsAPI.createNotification(notificationData);

    if (result.success) {
      console.log('✅ Standard notification created successfully!');
      console.log('📊 Response:', JSON.stringify(result.data, null, 2));
    } else {
      console.error('❌ Failed to create standard notification:', result.message);
    }
  } catch (error) {
    console.error('💥 Error creating standard notification:', error);
  }
}

// Test function with minimal required data
async function testMinimalNotification() {
  console.log('\n🚀 Testing Minimal Notification Creation...');

  const minimalData = {
    recipient: 1,
    notification_type: "system_alert",
    title: "System Alert",
    message: "This is a minimal notification test"
  };

  try {
    const result = await notificationsAPI.createAdminNotification(minimalData);

    if (result.success) {
      console.log('✅ Minimal notification created successfully!');
      console.log('📊 Response:', JSON.stringify(result.data, null, 2));
    } else {
      console.error('❌ Failed to create minimal notification:', result.message);
    }
  } catch (error) {
    console.error('💥 Error creating minimal notification:', error);
  }
}

// Test function with validation error
async function testValidationError() {
  console.log('\n🚀 Testing Validation Error Handling...');

  const invalidData = {
    // Missing required fields
    title: "Invalid Notification"
  };

  try {
    const result = await notificationsAPI.createAdminNotification(invalidData);

    if (result.success) {
      console.log('❌ Unexpected success with invalid data!');
    } else {
      console.log('✅ Validation error handled correctly:', result.message);
    }
  } catch (error) {
    console.log('✅ Validation error caught:', error.message);
  }
}

// Run all tests
async function runAllTests() {
  console.log('🧪 Starting Admin Notification API Tests\n');

  await testCreateAdminNotification();
  await testCreateStandardNotification();
  await testMinimalNotification();
  await testValidationError();

  console.log('\n🏁 All tests completed!');
}

// Export for use in other modules
export {
  testCreateAdminNotification,
  testCreateStandardNotification,
  testMinimalNotification,
  testValidationError,
  runAllTests
};

// Run tests if this file is executed directly
if (import.meta.url === `file://${process.argv[1]}`) {
  runAllTests();
}
