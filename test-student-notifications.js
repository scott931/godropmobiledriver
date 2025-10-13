/**
 * Test script for Student Notification API
 * This script demonstrates how to retrieve notifications by student for parents, drivers, and monitors
 */

import { notificationsAPI } from './src/api/index.js';

// Test function to get notifications by student ID
async function testGetNotificationsByStudent() {
  console.log('🚀 Testing Get Notifications by Student...');

  try {
    const result = await notificationsAPI.getNotificationsByStudent(1);

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

// Test function to get notifications for student parents
async function testGetNotificationsForStudentParents() {
  console.log('\n🚀 Testing Get Notifications for Student Parents...');

  try {
    const result = await notificationsAPI.getNotificationsForStudentParents(1);

    if (result.success) {
      console.log('✅ Student parent notifications retrieved successfully!');
      console.log('📊 Response:', JSON.stringify(result.data, null, 2));
    } else {
      console.error('❌ Failed to get student parent notifications:', result.message);
    }
  } catch (error) {
    console.error('💥 Error getting student parent notifications:', error);
  }
}

// Test function to get notifications for student drivers
async function testGetNotificationsForStudentDrivers() {
  console.log('\n🚀 Testing Get Notifications for Student Drivers...');

  try {
    const result = await notificationsAPI.getNotificationsForStudentDrivers(1);

    if (result.success) {
      console.log('✅ Student driver notifications retrieved successfully!');
      console.log('📊 Response:', JSON.stringify(result.data, null, 2));
    } else {
      console.error('❌ Failed to get student driver notifications:', result.message);
    }
  } catch (error) {
    console.error('💥 Error getting student driver notifications:', error);
  }
}

// Test function to get notifications for student monitors
async function testGetNotificationsForStudentMonitors() {
  console.log('\n🚀 Testing Get Notifications for Student Monitors...');

  try {
    const result = await notificationsAPI.getNotificationsForStudentMonitors(1);

    if (result.success) {
      console.log('✅ Student monitor notifications retrieved successfully!');
      console.log('📊 Response:', JSON.stringify(result.data, null, 2));
    } else {
      console.error('❌ Failed to get student monitor notifications:', result.message);
    }
  } catch (error) {
    console.error('💥 Error getting student monitor notifications:', error);
  }
}

// Test function to get notifications by student and user type
async function testGetNotificationsByStudentAndUserType() {
  console.log('\n🚀 Testing Get Notifications by Student and User Type...');

  const userTypes = ['parent', 'driver', 'monitor'];

  for (const userType of userTypes) {
    try {
      const result = await notificationsAPI.getNotificationsByStudentAndUserType(1, userType);

      if (result.success) {
        console.log(`✅ ${userType} notifications retrieved successfully!`);
        console.log(`📊 ${userType} Response:`, JSON.stringify(result.data, null, 2));
      } else {
        console.error(`❌ Failed to get ${userType} notifications:`, result.message);
      }
    } catch (error) {
      console.error(`💥 Error getting ${userType} notifications:`, error);
    }
  }
}

// Test function to get student pickup notifications
async function testGetStudentPickupNotifications() {
  console.log('\n🚀 Testing Get Student Pickup Notifications...');

  try {
    const result = await notificationsAPI.getNotificationsByStudent(1, {
      notification_type: 'student_pickup'
    });

    if (result.success) {
      console.log('✅ Student pickup notifications retrieved successfully!');
      console.log('📊 Response:', JSON.stringify(result.data, null, 2));
    } else {
      console.error('❌ Failed to get student pickup notifications:', result.message);
    }
  } catch (error) {
    console.error('💥 Error getting student pickup notifications:', error);
  }
}

// Test function to get student dropoff notifications
async function testGetStudentDropoffNotifications() {
  console.log('\n🚀 Testing Get Student Dropoff Notifications...');

  try {
    const result = await notificationsAPI.getNotificationsByStudent(1, {
      notification_type: 'student_dropoff'
    });

    if (result.success) {
      console.log('✅ Student dropoff notifications retrieved successfully!');
      console.log('📊 Response:', JSON.stringify(result.data, null, 2));
    } else {
      console.error('❌ Failed to get student dropoff notifications:', result.message);
    }
  } catch (error) {
    console.error('💥 Error getting student dropoff notifications:', error);
  }
}

// Test function to get student route change notifications
async function testGetStudentRouteChangeNotifications() {
  console.log('\n🚀 Testing Get Student Route Change Notifications...');

  try {
    const result = await notificationsAPI.getNotificationsByStudent(1, {
      notification_type: 'route_change'
    });

    if (result.success) {
      console.log('✅ Student route change notifications retrieved successfully!');
      console.log('📊 Response:', JSON.stringify(result.data, null, 2));
    } else {
      console.error('❌ Failed to get student route change notifications:', result.message);
    }
  } catch (error) {
    console.error('💥 Error getting student route change notifications:', error);
  }
}

// Test function to get student emergency notifications
async function testGetStudentEmergencyNotifications() {
  console.log('\n🚀 Testing Get Student Emergency Notifications...');

  try {
    const result = await notificationsAPI.getNotificationsByStudent(1, {
      notification_type: 'emergency_alert'
    });

    if (result.success) {
      console.log('✅ Student emergency notifications retrieved successfully!');
      console.log('📊 Response:', JSON.stringify(result.data, null, 2));
    } else {
      console.error('❌ Failed to get student emergency notifications:', result.message);
    }
  } catch (error) {
    console.error('💥 Error getting student emergency notifications:', error);
  }
}

// Test function to get student notifications by priority
async function testGetStudentNotificationsByPriority() {
  console.log('\n🚀 Testing Get Student Notifications by Priority...');

  const priorities = ['low', 'normal', 'high', 'urgent'];

  for (const priority of priorities) {
    try {
      const result = await notificationsAPI.getNotificationsByStudent(1, {
        priority: priority
      });

      if (result.success) {
        console.log(`✅ ${priority} priority notifications retrieved: ${result.data.count || result.data.length || 0} found`);
      } else {
        console.error(`❌ Failed to get ${priority} priority notifications:`, result.message);
      }
    } catch (error) {
      console.error(`💥 Error getting ${priority} priority notifications:`, error);
    }
  }
}

// Test function to get unread student notifications
async function testGetUnreadStudentNotifications() {
  console.log('\n🚀 Testing Get Unread Student Notifications...');

  try {
    const result = await notificationsAPI.getNotificationsByStudent(1, {
      is_read: false
    });

    if (result.success) {
      console.log('✅ Unread student notifications retrieved successfully!');
      console.log(`📊 Found ${result.data.count || result.data.length || 0} unread notifications`);
    } else {
      console.error('❌ Failed to get unread student notifications:', result.message);
    }
  } catch (error) {
    console.error('💥 Error getting unread student notifications:', error);
  }
}

// Test function to get student notifications by date range
async function testGetStudentNotificationsByDateRange() {
  console.log('\n🚀 Testing Get Student Notifications by Date Range...');

  const yesterday = new Date();
  yesterday.setDate(yesterday.getDate() - 1);

  const today = new Date();

  try {
    const result = await notificationsAPI.getNotificationsByStudent(1, {
      date_from: yesterday.toISOString(),
      date_to: today.toISOString()
    });

    if (result.success) {
      console.log('✅ Date range student notifications retrieved successfully!');
      console.log(`📊 Found ${result.data.count || result.data.length || 0} notifications in date range`);
    } else {
      console.error('❌ Failed to get date range student notifications:', result.message);
    }
  } catch (error) {
    console.error('💥 Error getting date range student notifications:', error);
  }
}

// Test function to get recent student notifications
async function testGetRecentStudentNotifications() {
  console.log('\n🚀 Testing Get Recent Student Notifications...');

  const yesterday = new Date();
  yesterday.setDate(yesterday.getDate() - 1);

  try {
    const result = await notificationsAPI.getNotificationsByStudent(1, {
      date_from: yesterday.toISOString()
    });

    if (result.success) {
      console.log('✅ Recent student notifications retrieved successfully!');
      console.log(`📊 Found ${result.data.count || result.data.length || 0} recent notifications`);
    } else {
      console.error('❌ Failed to get recent student notifications:', result.message);
    }
  } catch (error) {
    console.error('💥 Error getting recent student notifications:', error);
  }
}

// Test function to get student notifications with pagination
async function testGetStudentNotificationsWithPagination() {
  console.log('\n🚀 Testing Get Student Notifications with Pagination...');

  try {
    const result = await notificationsAPI.getNotificationsByStudent(1, {
      page: 1,
      page_size: 5
    });

    if (result.success) {
      console.log('✅ Paginated student notifications retrieved successfully!');
      console.log(`📊 Page 1: ${result.data.results?.length || result.data.length || 0} notifications`);
      console.log(`📊 Total count: ${result.data.count || result.data.length || 0}`);
      console.log(`📊 Has next: ${!!result.data.next}`);
      console.log(`📊 Has previous: ${!!result.data.previous}`);
    } else {
      console.error('❌ Failed to get paginated student notifications:', result.message);
    }
  } catch (error) {
    console.error('💥 Error getting paginated student notifications:', error);
  }
}

// Test function to get student notifications by status
async function testGetStudentNotificationsByStatus() {
  console.log('\n🚀 Testing Get Student Notifications by Status...');

  const statuses = ['pending', 'sent', 'delivered', 'failed'];

  for (const status of statuses) {
    try {
      const result = await notificationsAPI.getNotificationsByStudent(1, {
        status: status
      });

      if (result.success) {
        console.log(`✅ ${status} status notifications retrieved: ${result.data.count || result.data.length || 0} found`);
      } else {
        console.error(`❌ Failed to get ${status} status notifications:`, result.message);
      }
    } catch (error) {
      console.error(`💥 Error getting ${status} status notifications:`, error);
    }
  }
}

// Test function to get student notifications with custom ordering
async function testGetStudentNotificationsWithOrdering() {
  console.log('\n🚀 Testing Get Student Notifications with Custom Ordering...');

  const orderings = ['-created_at', 'created_at', '-priority', 'priority'];

  for (const ordering of orderings) {
    try {
      const result = await notificationsAPI.getNotificationsByStudent(1, {
        ordering: ordering
      });

      if (result.success) {
        console.log(`✅ Notifications with ${ordering} ordering retrieved: ${result.data.count || result.data.length || 0} found`);
      } else {
        console.error(`❌ Failed to get notifications with ${ordering} ordering:`, result.message);
      }
    } catch (error) {
      console.error(`💥 Error getting notifications with ${ordering} ordering:`, error);
    }
  }
}

// Test function to get student notifications with minimal details
async function testGetStudentNotificationsMinimal() {
  console.log('\n🚀 Testing Get Student Notifications with Minimal Details...');

  try {
    const result = await notificationsAPI.getNotificationsByStudent(1, {
      include_student_details: false,
      include_vehicle_details: false,
      include_route_details: false,
      include_parent_details: false
    });

    if (result.success) {
      console.log('✅ Minimal student notifications retrieved successfully!');
      console.log(`📊 Found ${result.data.count || result.data.length || 0} notifications with minimal details`);
    } else {
      console.error('❌ Failed to get minimal student notifications:', result.message);
    }
  } catch (error) {
    console.error('💥 Error getting minimal student notifications:', error);
  }
}

// Test function to get student notifications with comprehensive details
async function testGetStudentNotificationsComprehensive() {
  console.log('\n🚀 Testing Get Student Notifications with Comprehensive Details...');

  try {
    const result = await notificationsAPI.getNotificationsByStudent(1, {
      include_student_details: true,
      include_vehicle_details: true,
      include_route_details: true,
      include_parent_details: true
    });

    if (result.success) {
      console.log('✅ Comprehensive student notifications retrieved successfully!');
      console.log(`📊 Found ${result.data.count || result.data.length || 0} notifications with comprehensive details`);
    } else {
      console.error('❌ Failed to get comprehensive student notifications:', result.message);
    }
  } catch (error) {
    console.error('💥 Error getting comprehensive student notifications:', error);
  }
}

// Test function to get student notifications for different students
async function testGetStudentNotificationsForDifferentStudents() {
  console.log('\n🚀 Testing Get Student Notifications for Different Students...');

  const studentIds = [1, 2, 3, 4, 5];

  for (const studentId of studentIds) {
    try {
      const result = await notificationsAPI.getNotificationsByStudent(studentId);

      if (result.success) {
        console.log(`✅ Student ${studentId} notifications retrieved: ${result.data.count || result.data.length || 0} found`);
      } else {
        console.error(`❌ Failed to get student ${studentId} notifications:`, result.message);
      }
    } catch (error) {
      console.error(`💥 Error getting student ${studentId} notifications:`, error);
    }
  }
}

// Test function to get student notifications with advanced filtering
async function testGetStudentNotificationsWithAdvancedFiltering() {
  console.log('\n🚀 Testing Get Student Notifications with Advanced Filtering...');

  const filters = [
    { notification_type: 'student_pickup', priority: 'normal' },
    { notification_type: 'student_dropoff', priority: 'high' },
    { notification_type: 'route_change', priority: 'urgent' },
    { is_read: false, status: 'pending' },
    { is_read: true, status: 'sent' }
  ];

  for (const filter of filters) {
    try {
      const result = await notificationsAPI.getNotificationsByStudent(1, filter);

      if (result.success) {
        console.log(`✅ Filtered notifications retrieved: ${result.data.count || result.data.length || 0} found`);
        console.log(`📊 Filter:`, filter);
      } else {
        console.error(`❌ Failed to get filtered notifications:`, result.message);
      }
    } catch (error) {
      console.error(`💥 Error getting filtered notifications:`, error);
    }
  }
}

// Run all tests
async function runAllTests() {
  console.log('🧪 Starting Student Notification API Tests\n');

  await testGetNotificationsByStudent();
  await testGetNotificationsForStudentParents();
  await testGetNotificationsForStudentDrivers();
  await testGetNotificationsForStudentMonitors();
  await testGetNotificationsByStudentAndUserType();
  await testGetStudentPickupNotifications();
  await testGetStudentDropoffNotifications();
  await testGetStudentRouteChangeNotifications();
  await testGetStudentEmergencyNotifications();
  await testGetStudentNotificationsByPriority();
  await testGetUnreadStudentNotifications();
  await testGetStudentNotificationsByDateRange();
  await testGetRecentStudentNotifications();
  await testGetStudentNotificationsWithPagination();
  await testGetStudentNotificationsByStatus();
  await testGetStudentNotificationsWithOrdering();
  await testGetStudentNotificationsMinimal();
  await testGetStudentNotificationsComprehensive();
  await testGetStudentNotificationsForDifferentStudents();
  await testGetStudentNotificationsWithAdvancedFiltering();

  console.log('\n🏁 All tests completed!');
}

// Export for use in other modules
export {
  testGetNotificationsByStudent,
  testGetNotificationsForStudentParents,
  testGetNotificationsForStudentDrivers,
  testGetNotificationsForStudentMonitors,
  testGetNotificationsByStudentAndUserType,
  testGetStudentPickupNotifications,
  testGetStudentDropoffNotifications,
  testGetStudentRouteChangeNotifications,
  testGetStudentEmergencyNotifications,
  testGetStudentNotificationsByPriority,
  testGetUnreadStudentNotifications,
  testGetStudentNotificationsByDateRange,
  testGetRecentStudentNotifications,
  testGetStudentNotificationsWithPagination,
  testGetStudentNotificationsByStatus,
  testGetStudentNotificationsWithOrdering,
  testGetStudentNotificationsMinimal,
  testGetStudentNotificationsComprehensive,
  testGetStudentNotificationsForDifferentStudents,
  testGetStudentNotificationsWithAdvancedFiltering,
  runAllTests
};

// Run tests if this file is executed directly
if (import.meta.url === `file://${process.argv[1]}`) {
  runAllTests();
}
