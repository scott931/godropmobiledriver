/**
 * Test script for Notification Listing API
 * This script demonstrates how to retrieve notifications with detailed response format
 */

import { notificationsAPI } from './src/api/index.js';

// Test function to get all notifications
async function testGetAllNotifications() {
  console.log('🚀 Testing Get All Notifications...');

  try {
    const result = await notificationsAPI.getAllNotifications();

    if (result.success) {
      console.log('✅ All notifications retrieved successfully!');
      console.log('📊 Response:', JSON.stringify(result.data, null, 2));
    } else {
      console.error('❌ Failed to get all notifications:', result.message);
    }
  } catch (error) {
    console.error('💥 Error getting all notifications:', error);
  }
}

// Test function to get notifications for a specific parent
async function testGetNotificationsForParent() {
  console.log('\n🚀 Testing Get Notifications for Parent...');

  try {
    const result = await notificationsAPI.getNotificationsForParent(1);

    if (result.success) {
      console.log('✅ Parent notifications retrieved successfully!');
      console.log('📊 Response:', JSON.stringify(result.data, null, 2));
    } else {
      console.error('❌ Failed to get parent notifications:', result.message);
    }
  } catch (error) {
    console.error('💥 Error getting parent notifications:', error);
  }
}

// Test function to get notifications for a specific student
async function testGetNotificationsForStudent() {
  console.log('\n🚀 Testing Get Notifications for Student...');

  try {
    const result = await notificationsAPI.getNotificationsForStudent(1);

    if (result.success) {
      console.log('✅ Student notifications retrieved successfully!');
      console.log('📊 Response:', JSON.stringify(result.data, null, 2));
    } else {
      console.error('❌ Failed to get student notifications:', result.message);
    }
  } catch (error) {
    console.error('💥 Error getting student notifications:', error);
  }
}

// Test function to get filtered notifications
async function testGetFilteredNotifications() {
  console.log('\n🚀 Testing Get Filtered Notifications...');

  const filters = {
    notification_type: 'student_pickup',
    priority: 'normal',
    is_read: false,
    page: 1,
    page_size: 10
  };

  try {
    const result = await notificationsAPI.getFilteredNotifications(filters);

    if (result.success) {
      console.log('✅ Filtered notifications retrieved successfully!');
      console.log('📊 Response:', JSON.stringify(result.data, null, 2));
    } else {
      console.error('❌ Failed to get filtered notifications:', result.message);
    }
  } catch (error) {
    console.error('💥 Error getting filtered notifications:', error);
  }
}

// Test function to get notifications by type
async function testGetNotificationsByType() {
  console.log('\n🚀 Testing Get Notifications by Type...');

  const notificationTypes = [
    'student_pickup',
    'student_dropoff',
    'route_delay',
    'emergency_alert',
    'system_maintenance'
  ];

  for (const type of notificationTypes) {
    try {
      const result = await notificationsAPI.getFilteredNotifications({
        notification_type: type,
        page_size: 5
      });

      if (result.success) {
        console.log(`✅ ${type} notifications retrieved: ${result.data.count} found`);
      } else {
        console.error(`❌ Failed to get ${type} notifications:`, result.message);
      }
    } catch (error) {
      console.error(`💥 Error getting ${type} notifications:`, error);
    }
  }
}

// Test function to get notifications by priority
async function testGetNotificationsByPriority() {
  console.log('\n🚀 Testing Get Notifications by Priority...');

  const priorities = ['low', 'normal', 'high', 'urgent'];

  for (const priority of priorities) {
    try {
      const result = await notificationsAPI.getFilteredNotifications({
        priority: priority,
        page_size: 5
      });

      if (result.success) {
        console.log(`✅ ${priority} priority notifications retrieved: ${result.data.count} found`);
      } else {
        console.error(`❌ Failed to get ${priority} priority notifications:`, result.message);
      }
    } catch (error) {
      console.error(`💥 Error getting ${priority} priority notifications:`, error);
    }
  }
}

// Test function to get unread notifications
async function testGetUnreadNotifications() {
  console.log('\n🚀 Testing Get Unread Notifications...');

  try {
    const result = await notificationsAPI.getFilteredNotifications({
      is_read: false,
      page_size: 10
    });

    if (result.success) {
      console.log('✅ Unread notifications retrieved successfully!');
      console.log(`📊 Found ${result.data.count} unread notifications`);
    } else {
      console.error('❌ Failed to get unread notifications:', result.message);
    }
  } catch (error) {
    console.error('💥 Error getting unread notifications:', error);
  }
}

// Test function to get notifications by date range
async function testGetNotificationsByDateRange() {
  console.log('\n🚀 Testing Get Notifications by Date Range...');

  const yesterday = new Date();
  yesterday.setDate(yesterday.getDate() - 1);

  const today = new Date();

  try {
    const result = await notificationsAPI.getFilteredNotifications({
      date_from: yesterday.toISOString(),
      date_to: today.toISOString(),
      page_size: 10
    });

    if (result.success) {
      console.log('✅ Date range notifications retrieved successfully!');
      console.log(`📊 Found ${result.data.count} notifications in date range`);
    } else {
      console.error('❌ Failed to get date range notifications:', result.message);
    }
  } catch (error) {
    console.error('💥 Error getting date range notifications:', error);
  }
}

// Test function to get notifications with pagination
async function testGetNotificationsWithPagination() {
  console.log('\n🚀 Testing Get Notifications with Pagination...');

  try {
    const result = await notificationsAPI.getFilteredNotifications({
      page: 1,
      page_size: 5
    });

    if (result.success) {
      console.log('✅ Paginated notifications retrieved successfully!');
      console.log(`📊 Page 1: ${result.data.results?.length || 0} notifications`);
      console.log(`📊 Total count: ${result.data.count}`);
      console.log(`📊 Has next: ${!!result.data.next}`);
      console.log(`📊 Has previous: ${!!result.data.previous}`);
    } else {
      console.error('❌ Failed to get paginated notifications:', result.message);
    }
  } catch (error) {
    console.error('💥 Error getting paginated notifications:', error);
  }
}

// Test function to get notifications for a specific vehicle
async function testGetNotificationsForVehicle() {
  console.log('\n🚀 Testing Get Notifications for Vehicle...');

  try {
    const result = await notificationsAPI.getFilteredNotifications({
      vehicle_id: 1,
      page_size: 10
    });

    if (result.success) {
      console.log('✅ Vehicle notifications retrieved successfully!');
      console.log(`📊 Found ${result.data.count} notifications for vehicle 1`);
    } else {
      console.error('❌ Failed to get vehicle notifications:', result.message);
    }
  } catch (error) {
    console.error('💥 Error getting vehicle notifications:', error);
  }
}

// Test function to get notifications for a specific route
async function testGetNotificationsForRoute() {
  console.log('\n🚀 Testing Get Notifications for Route...');

  try {
    const result = await notificationsAPI.getFilteredNotifications({
      route_id: 1,
      page_size: 10
    });

    if (result.success) {
      console.log('✅ Route notifications retrieved successfully!');
      console.log(`📊 Found ${result.data.count} notifications for route 1`);
    } else {
      console.error('❌ Failed to get route notifications:', result.message);
    }
  } catch (error) {
    console.error('💥 Error getting route notifications:', error);
  }
}

// Test function to get sent notifications
async function testGetSentNotifications() {
  console.log('\n🚀 Testing Get Sent Notifications...');

  try {
    const result = await notificationsAPI.getFilteredNotifications({
      is_sent: true,
      page_size: 10
    });

    if (result.success) {
      console.log('✅ Sent notifications retrieved successfully!');
      console.log(`📊 Found ${result.data.count} sent notifications`);
    } else {
      console.error('❌ Failed to get sent notifications:', result.message);
    }
  } catch (error) {
    console.error('💥 Error getting sent notifications:', error);
  }
}

// Test function to get delivered notifications
async function testGetDeliveredNotifications() {
  console.log('\n🚀 Testing Get Delivered Notifications...');

  try {
    const result = await notificationsAPI.getFilteredNotifications({
      is_delivered: true,
      page_size: 10
    });

    if (result.success) {
      console.log('✅ Delivered notifications retrieved successfully!');
      console.log(`📊 Found ${result.data.count} delivered notifications`);
    } else {
      console.error('❌ Failed to get delivered notifications:', result.message);
    }
  } catch (error) {
    console.error('💥 Error getting delivered notifications:', error);
  }
}

// Test function to get notifications by status
async function testGetNotificationsByStatus() {
  console.log('\n🚀 Testing Get Notifications by Status...');

  const statuses = ['pending', 'sent', 'delivered', 'failed'];

  for (const status of statuses) {
    try {
      const result = await notificationsAPI.getFilteredNotifications({
        status: status,
        page_size: 5
      });

      if (result.success) {
        console.log(`✅ ${status} status notifications retrieved: ${result.data.count} found`);
      } else {
        console.error(`❌ Failed to get ${status} status notifications:`, result.message);
      }
    } catch (error) {
      console.error(`💥 Error getting ${status} status notifications:`, error);
    }
  }
}

// Test function to get recent notifications
async function testGetRecentNotifications() {
  console.log('\n🚀 Testing Get Recent Notifications...');

  const yesterday = new Date();
  yesterday.setDate(yesterday.getDate() - 1);

  try {
    const result = await notificationsAPI.getFilteredNotifications({
      date_from: yesterday.toISOString(),
      page_size: 10
    });

    if (result.success) {
      console.log('✅ Recent notifications retrieved successfully!');
      console.log(`📊 Found ${result.data.count} recent notifications`);
    } else {
      console.error('❌ Failed to get recent notifications:', result.message);
    }
  } catch (error) {
    console.error('💥 Error getting recent notifications:', error);
  }
}

// Test function to get notifications with custom ordering
async function testGetNotificationsWithOrdering() {
  console.log('\n🚀 Testing Get Notifications with Custom Ordering...');

  const orderings = ['-created_at', 'created_at', '-priority', 'priority'];

  for (const ordering of orderings) {
    try {
      const result = await notificationsAPI.getFilteredNotifications({
        ordering: ordering,
        page_size: 5
      });

      if (result.success) {
        console.log(`✅ Notifications with ${ordering} ordering retrieved: ${result.data.count} found`);
      } else {
        console.error(`❌ Failed to get notifications with ${ordering} ordering:`, result.message);
      }
    } catch (error) {
      console.error(`💥 Error getting notifications with ${ordering} ordering:`, error);
    }
  }
}

// Test function to get notifications with minimal details
async function testGetNotificationsMinimal() {
  console.log('\n🚀 Testing Get Notifications with Minimal Details...');

  try {
    const result = await notificationsAPI.getFilteredNotifications({
      include_student_details: false,
      include_vehicle_details: false,
      include_route_details: false,
      include_parent_details: false,
      page_size: 5
    });

    if (result.success) {
      console.log('✅ Minimal notifications retrieved successfully!');
      console.log(`📊 Found ${result.data.count} notifications with minimal details`);
    } else {
      console.error('❌ Failed to get minimal notifications:', result.message);
    }
  } catch (error) {
    console.error('💥 Error getting minimal notifications:', error);
  }
}

// Test function to get notifications with comprehensive details
async function testGetNotificationsComprehensive() {
  console.log('\n🚀 Testing Get Notifications with Comprehensive Details...');

  try {
    const result = await notificationsAPI.getFilteredNotifications({
      include_student_details: true,
      include_vehicle_details: true,
      include_route_details: true,
      include_parent_details: true,
      page_size: 5
    });

    if (result.success) {
      console.log('✅ Comprehensive notifications retrieved successfully!');
      console.log(`📊 Found ${result.data.count} notifications with comprehensive details`);
    } else {
      console.error('❌ Failed to get comprehensive notifications:', result.message);
    }
  } catch (error) {
    console.error('💥 Error getting comprehensive notifications:', error);
  }
}

// Test function to search notifications
async function testSearchNotifications() {
  console.log('\n🚀 Testing Search Notifications...');

  const searchTerms = ['student', 'pickup', 'bus', 'route'];

  for (const term of searchTerms) {
    try {
      const result = await notificationsAPI.getFilteredNotifications({
        search: term,
        page_size: 5
      });

      if (result.success) {
        console.log(`✅ Search for "${term}" retrieved: ${result.data.count} found`);
      } else {
        console.error(`❌ Failed to search for "${term}":`, result.message);
      }
    } catch (error) {
      console.error(`💥 Error searching for "${term}":`, error);
    }
  }
}

// Test function to get notification statistics
async function testGetNotificationStatistics() {
  console.log('\n🚀 Testing Get Notification Statistics...');

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

    if (totalResult.success && unreadResult.success && sentResult.success && deliveredResult.success) {
      console.log('✅ Notification statistics retrieved successfully!');
      console.log(`📊 Total notifications: ${totalResult.data.count || 0}`);
      console.log(`📊 Unread notifications: ${unreadResult.data.count || 0}`);
      console.log(`📊 Sent notifications: ${sentResult.data.count || 0}`);
      console.log(`📊 Delivered notifications: ${deliveredResult.data.count || 0}`);
    } else {
      console.error('❌ Failed to get notification statistics');
    }
  } catch (error) {
    console.error('💥 Error getting notification statistics:', error);
  }
}

// Run all tests
async function runAllTests() {
  console.log('🧪 Starting Notification Listing API Tests\n');

  await testGetAllNotifications();
  await testGetNotificationsForParent();
  await testGetNotificationsForStudent();
  await testGetFilteredNotifications();
  await testGetNotificationsByType();
  await testGetNotificationsByPriority();
  await testGetUnreadNotifications();
  await testGetNotificationsByDateRange();
  await testGetNotificationsWithPagination();
  await testGetNotificationsForVehicle();
  await testGetNotificationsForRoute();
  await testGetSentNotifications();
  await testGetDeliveredNotifications();
  await testGetNotificationsByStatus();
  await testGetRecentNotifications();
  await testGetNotificationsWithOrdering();
  await testGetNotificationsMinimal();
  await testGetNotificationsComprehensive();
  await testSearchNotifications();
  await testGetNotificationStatistics();

  console.log('\n🏁 All tests completed!');
}

// Export for use in other modules
export {
  testGetAllNotifications,
  testGetNotificationsForParent,
  testGetNotificationsForStudent,
  testGetFilteredNotifications,
  testGetNotificationsByType,
  testGetNotificationsByPriority,
  testGetUnreadNotifications,
  testGetNotificationsByDateRange,
  testGetNotificationsWithPagination,
  testGetNotificationsForVehicle,
  testGetNotificationsForRoute,
  testGetSentNotifications,
  testGetDeliveredNotifications,
  testGetNotificationsByStatus,
  testGetRecentNotifications,
  testGetNotificationsWithOrdering,
  testGetNotificationsMinimal,
  testGetNotificationsComprehensive,
  testSearchNotifications,
  testGetNotificationStatistics,
  runAllTests
};

// Run tests if this file is executed directly
if (import.meta.url === `file://${process.argv[1]}`) {
  runAllTests();
}
