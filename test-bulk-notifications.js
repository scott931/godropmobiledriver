/**
 * Test script for Bulk Notification API
 * This script demonstrates how to send bulk notifications for admin actions
 */

import { notificationsAPI } from './src/api/index.js';

// Example bulk data as specified in the request
const bulkData = {
  message: "1 notifications created",
  notifications: [
    {
      id: 2,
      recipient: 1,
      recipient_name: "",
      notification_type: "route_change",
      notification_type_display: "Route Change",
      priority: "high",
      priority_display: "High",
      title: "Route Change Notice",
      message: "Route A has been temporarily changed due to road construction",
      student: null,
      vehicle: null,
      route: {
        id: 1,
        name: "Morning Route B",
        description: "Main morning route for uptown area",
        route_type: "morning",
        route_type_display: "Morning Route",
        status: "active",
        status_display: "Active",
        estimated_duration: 45,
        total_distance: "12.50",
        max_capacity: 25,
        assigned_vehicle: null,
        assigned_driver: 50,
        assigned_driver_name: "Florence Mwangi",
        is_fully_assigned: null,
        current_student_count: 0,
        stops: [
          {
            id: 1,
            route: 1,
            name: "Main Street Stop",
            description: "Primary pickup point on Main Street",
            stop_type: "pickup",
            stop_type_display: "Pickup Point",
            address: "123 Main Street, Downtown",
            latitude: null,
            longitude: null,
            estimated_arrival_time: "07:30:00",
            estimated_departure_time: "07:35:00",
            order: 2,
            created_at: "2025-09-13T20:46:11.525272+03:00",
            updated_at: "2025-09-13T20:46:11.525287+03:00"
          }
        ],
        schedules: [
          {
            id: 1,
            route: 1,
            day_of_week: "monday",
            day_of_week_display: "Monday",
            start_time: "07:00:00",
            end_time: "08:30:00",
            is_active: true,
            created_at: "2025-09-13T20:52:56.317101+03:00",
            updated_at: "2025-09-13T20:52:56.317116+03:00"
          }
        ],
        assignments: [
          {
            id: 6,
            route: 1,
            route_name: "Morning Route B",
            vehicle: 7,
            vehicle_license_plate: "KGG",
            driver: 18,
            driver_name: "John Doe",
            status: "pending",
            status_display: "Pending",
            is_active: false,
            start_date: "2024-01-01",
            end_date: "2024-12-31",
            notes: "Regular assignment for morning route",
            created_at: "2025-09-20T20:00:32.619934+03:00",
            updated_at: "2025-09-20T20:00:32.619953+03:00"
          }
        ],
        created_at: "2025-09-12T09:39:34.121102+03:00",
        updated_at: "2025-10-06T12:36:36.601576+03:00"
      },
      location: null,
      location_display: null,
      channels: ["push", "sms", "email"],
      status: "pending",
      status_display: "Pending",
      scheduled_at: null,
      sent_at: null,
      delivered_at: null,
      read_at: null,
      metadata: {
        reason: "road_construction",
        duration: "2_hours"
      },
      is_read: false,
      is_sent: false,
      is_delivered: false,
      deliveries: [],
      created_at: "2025-10-08T11:15:30.030129+03:00",
      updated_at: "2025-10-08T11:15:30.030140+03:00"
    }
  ]
};

// Test function to send bulk notifications
async function testSendBulkNotifications() {
  console.log('🚀 Testing Send Bulk Notifications...');
  console.log('📋 Bulk Data:', JSON.stringify(bulkData, null, 2));

  try {
    const result = await notificationsAPI.bulkSendNotificationsWithValidation(bulkData);

    if (result.success) {
      console.log('✅ Bulk notifications sent successfully!');
      console.log('📊 Response:', JSON.stringify(result.data, null, 2));
    } else {
      console.error('❌ Failed to send bulk notifications:', result.message);
    }
  } catch (error) {
    console.error('💥 Error sending bulk notifications:', error);
  }
}

// Test function using the standard bulkSendNotifications method
async function testSendStandardBulkNotifications() {
  console.log('\n🚀 Testing Standard Bulk Notifications...');

  try {
    const result = await notificationsAPI.bulkSendNotifications(bulkData);

    if (result.success) {
      console.log('✅ Standard bulk notifications sent successfully!');
      console.log('📊 Response:', JSON.stringify(result.data, null, 2));
    } else {
      console.error('❌ Failed to send standard bulk notifications:', result.message);
    }
  } catch (error) {
    console.error('💥 Error sending standard bulk notifications:', error);
  }
}

// Test function with minimal bulk data
async function testSendMinimalBulkNotifications() {
  console.log('\n🚀 Testing Minimal Bulk Notifications...');

  const minimalBulkData = {
    message: "2 minimal notifications created",
    notifications: [
      {
        recipient: 1,
        notification_type: "system_alert",
        title: "System Alert",
        message: "This is a minimal notification test"
      },
      {
        recipient: 2,
        notification_type: "system_alert",
        title: "System Alert",
        message: "This is another minimal notification test"
      }
    ]
  };

  try {
    const result = await notificationsAPI.bulkSendNotificationsWithValidation(minimalBulkData);

    if (result.success) {
      console.log('✅ Minimal bulk notifications sent successfully!');
      console.log('📊 Response:', JSON.stringify(result.data, null, 2));
    } else {
      console.error('❌ Failed to send minimal bulk notifications:', result.message);
    }
  } catch (error) {
    console.error('💥 Error sending minimal bulk notifications:', error);
  }
}

// Test function with validation error
async function testValidationError() {
  console.log('\n🚀 Testing Validation Error Handling...');

  const invalidBulkData = {
    message: "Invalid bulk data",
    notifications: [
      {
        // Missing required fields
        title: "Invalid Notification"
      }
    ]
  };

  try {
    const result = await notificationsAPI.bulkSendNotificationsWithValidation(invalidBulkData);

    if (result.success) {
      console.log('❌ Unexpected success with invalid data!');
    } else {
      console.log('✅ Validation error handled correctly:', result.message);
    }
  } catch (error) {
    console.log('✅ Validation error caught:', error.message);
  }
}

// Test function with empty notifications array
async function testEmptyNotificationsArray() {
  console.log('\n🚀 Testing Empty Notifications Array...');

  const emptyBulkData = {
    message: "Empty notifications",
    notifications: []
  };

  try {
    const result = await notificationsAPI.bulkSendNotificationsWithValidation(emptyBulkData);

    if (result.success) {
      console.log('❌ Unexpected success with empty array!');
    } else {
      console.log('✅ Empty array error handled correctly:', result.message);
    }
  } catch (error) {
    console.log('✅ Empty array error caught:', error.message);
  }
}

// Test function with multiple notifications
async function testMultipleNotifications() {
  console.log('\n🚀 Testing Multiple Notifications...');

  const multipleBulkData = {
    message: "5 notifications created",
    notifications: [
      {
        recipient: 1,
        notification_type: "system_alert",
        priority: "normal",
        title: "System Alert 1",
        message: "This is the first notification"
      },
      {
        recipient: 2,
        notification_type: "route_change",
        priority: "high",
        title: "Route Change 1",
        message: "Route A has been changed"
      },
      {
        recipient: 3,
        notification_type: "emergency_alert",
        priority: "urgent",
        title: "Emergency Alert 1",
        message: "Emergency situation detected"
      },
      {
        recipient: 4,
        notification_type: "system_maintenance",
        priority: "normal",
        title: "Maintenance Notice 1",
        message: "System maintenance scheduled"
      },
      {
        recipient: 5,
        notification_type: "student_pickup",
        priority: "normal",
        title: "Student Pickup 1",
        message: "Student has been picked up"
      }
    ]
  };

  try {
    const result = await notificationsAPI.bulkSendNotificationsWithValidation(multipleBulkData);

    if (result.success) {
      console.log('✅ Multiple notifications sent successfully!');
      console.log('📊 Response:', JSON.stringify(result.data, null, 2));
    } else {
      console.error('❌ Failed to send multiple notifications:', result.message);
    }
  } catch (error) {
    console.error('💥 Error sending multiple notifications:', error);
  }
}

// Test function with different notification types
async function testDifferentNotificationTypes() {
  console.log('\n🚀 Testing Different Notification Types...');

  const notificationTypes = [
    'system_alert',
    'route_change',
    'emergency_alert',
    'system_maintenance',
    'student_pickup',
    'student_dropoff',
    'route_delay'
  ];

  for (const type of notificationTypes) {
    try {
      const bulkData = {
        message: `1 ${type} notification created`,
        notifications: [
          {
            recipient: 1,
            notification_type: type,
            priority: "normal",
            title: `${type.replace('_', ' ').toUpperCase()} Notification`,
            message: `This is a ${type} notification test`
          }
        ]
      };

      const result = await notificationsAPI.bulkSendNotificationsWithValidation(bulkData);

      if (result.success) {
        console.log(`✅ ${type} notification sent successfully`);
      } else {
        console.error(`❌ Failed to send ${type} notification:`, result.message);
      }
    } catch (error) {
      console.error(`💥 Error sending ${type} notification:`, error);
    }
  }
}

// Test function with different priorities
async function testDifferentPriorities() {
  console.log('\n🚀 Testing Different Priorities...');

  const priorities = ['low', 'normal', 'high', 'urgent'];

  for (const priority of priorities) {
    try {
      const bulkData = {
        message: `1 ${priority} priority notification created`,
        notifications: [
          {
            recipient: 1,
            notification_type: "system_alert",
            priority: priority,
            title: `${priority.toUpperCase()} Priority Notification`,
            message: `This is a ${priority} priority notification test`
          }
        ]
      };

      const result = await notificationsAPI.bulkSendNotificationsWithValidation(bulkData);

      if (result.success) {
        console.log(`✅ ${priority} priority notification sent successfully`);
      } else {
        console.error(`❌ Failed to send ${priority} priority notification:`, result.message);
      }
    } catch (error) {
      console.error(`💥 Error sending ${priority} priority notification:`, error);
    }
  }
}

// Test function with different channels
async function testDifferentChannels() {
  console.log('\n🚀 Testing Different Channels...');

  const channelCombinations = [
    ['push'],
    ['sms'],
    ['email'],
    ['push', 'sms'],
    ['push', 'email'],
    ['sms', 'email'],
    ['push', 'sms', 'email']
  ];

  for (const channels of channelCombinations) {
    try {
      const bulkData = {
        message: `1 notification with ${channels.join(', ')} channels created`,
        notifications: [
          {
            recipient: 1,
            notification_type: "system_alert",
            priority: "normal",
            title: "Multi-Channel Notification",
            message: `This notification will be sent via ${channels.join(', ')}`,
            channels: channels
          }
        ]
      };

      const result = await notificationsAPI.bulkSendNotificationsWithValidation(bulkData);

      if (result.success) {
        console.log(`✅ Notification with ${channels.join(', ')} channels sent successfully`);
      } else {
        console.error(`❌ Failed to send notification with ${channels.join(', ')} channels:`, result.message);
      }
    } catch (error) {
      console.error(`💥 Error sending notification with ${channels.join(', ')} channels:`, error);
    }
  }
}

// Test function with scheduled notifications
async function testScheduledNotifications() {
  console.log('\n🚀 Testing Scheduled Notifications...');

  const futureTime = new Date();
  futureTime.setHours(futureTime.getHours() + 1);

  const scheduledBulkData = {
    message: "1 scheduled notification created",
    notifications: [
      {
        recipient: 1,
        notification_type: "system_alert",
        priority: "normal",
        title: "Scheduled Notification",
        message: "This notification is scheduled for the future",
        scheduled_at: futureTime.toISOString()
      }
    ]
  };

  try {
    const result = await notificationsAPI.bulkSendNotificationsWithValidation(scheduledBulkData);

    if (result.success) {
      console.log('✅ Scheduled notification sent successfully!');
      console.log('📊 Response:', JSON.stringify(result.data, null, 2));
    } else {
      console.error('❌ Failed to send scheduled notification:', result.message);
    }
  } catch (error) {
    console.error('💥 Error sending scheduled notification:', error);
  }
}

// Test function with metadata
async function testNotificationsWithMetadata() {
  console.log('\n🚀 Testing Notifications with Metadata...');

  const metadataBulkData = {
    message: "1 notification with metadata created",
    notifications: [
      {
        recipient: 1,
        notification_type: "route_change",
        priority: "high",
        title: "Route Change with Metadata",
        message: "Route has been changed with additional information",
        metadata: {
          reason: "road_construction",
          duration: "2_hours",
          alternative_route: "Route B",
          contact_person: "John Doe",
          phone: "123-456-7890"
        }
      }
    ]
  };

  try {
    const result = await notificationsAPI.bulkSendNotificationsWithValidation(metadataBulkData);

    if (result.success) {
      console.log('✅ Notification with metadata sent successfully!');
      console.log('📊 Response:', JSON.stringify(result.data, null, 2));
    } else {
      console.error('❌ Failed to send notification with metadata:', result.message);
    }
  } catch (error) {
    console.error('💥 Error sending notification with metadata:', error);
  }
}

// Run all tests
async function runAllTests() {
  console.log('🧪 Starting Bulk Notification API Tests\n');

  await testSendBulkNotifications();
  await testSendStandardBulkNotifications();
  await testSendMinimalBulkNotifications();
  await testValidationError();
  await testEmptyNotificationsArray();
  await testMultipleNotifications();
  await testDifferentNotificationTypes();
  await testDifferentPriorities();
  await testDifferentChannels();
  await testScheduledNotifications();
  await testNotificationsWithMetadata();

  console.log('\n🏁 All tests completed!');
}

// Export for use in other modules
export {
  testSendBulkNotifications,
  testSendStandardBulkNotifications,
  testSendMinimalBulkNotifications,
  testValidationError,
  testEmptyNotificationsArray,
  testMultipleNotifications,
  testDifferentNotificationTypes,
  testDifferentPriorities,
  testDifferentChannels,
  testScheduledNotifications,
  testNotificationsWithMetadata,
  runAllTests
};

// Run tests if this file is executed directly
if (import.meta.url === `file://${process.argv[1]}`) {
  runAllTests();
}
