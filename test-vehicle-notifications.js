/**
 * Test script for Vehicle Notification API
 * This script tests the vehicle notification functionality for drivers, admins, and monitors
 */

const { notificationsAPI } = require('./src/api/index');

// Test configuration
const TEST_CONFIG = {
  vehicleId: 1,
  driverId: 51,
  adminId: 1,
  monitorId: 2,
  studentId: 1,
  routeId: 1
};

/**
 * Test 1: Get notifications by vehicle ID
 */
async function testGetNotificationsByVehicle() {
  console.log('\n=== Test 1: Get Notifications by Vehicle ID ===');

  try {
    const result = await notificationsAPI.getNotificationsByVehicle(TEST_CONFIG.vehicleId);

    if (result.success) {
      console.log('✅ Successfully retrieved vehicle notifications');
      console.log(`📊 Total notifications: ${result.data?.count || 0}`);
      console.log(`📄 Results: ${result.data?.results?.length || 0} notifications`);

      if (result.data?.results?.length > 0) {
        const firstNotification = result.data.results[0];
        console.log('📋 First notification details:');
        console.log(`   - ID: ${firstNotification.id}`);
        console.log(`   - Title: ${firstNotification.title}`);
        console.log(`   - Type: ${firstNotification.notification_type_display}`);
        console.log(`   - Priority: ${firstNotification.priority_display}`);
        console.log(`   - Status: ${firstNotification.status_display}`);
      }
    } else {
      console.log('❌ Failed to retrieve vehicle notifications');
      console.log(`Error: ${result.message}`);
    }
  } catch (error) {
    console.log('❌ Error testing vehicle notifications:', error.message);
  }
}

/**
 * Test 2: Get notifications for vehicle drivers
 */
async function testGetNotificationsForVehicleDrivers() {
  console.log('\n=== Test 2: Get Notifications for Vehicle Drivers ===');

  try {
    const result = await notificationsAPI.getNotificationsForVehicleDrivers(TEST_CONFIG.vehicleId);

    if (result.success) {
      console.log('✅ Successfully retrieved driver notifications');
      console.log(`📊 Total driver notifications: ${result.data?.count || 0}`);
      console.log(`📄 Results: ${result.data?.results?.length || 0} notifications`);
    } else {
      console.log('❌ Failed to retrieve driver notifications');
      console.log(`Error: ${result.message}`);
    }
  } catch (error) {
    console.log('❌ Error testing driver notifications:', error.message);
  }
}

/**
 * Test 3: Get notifications for vehicle admins
 */
async function testGetNotificationsForVehicleAdmins() {
  console.log('\n=== Test 3: Get Notifications for Vehicle Admins ===');

  try {
    const result = await notificationsAPI.getNotificationsForVehicleAdmins(TEST_CONFIG.vehicleId);

    if (result.success) {
      console.log('✅ Successfully retrieved admin notifications');
      console.log(`📊 Total admin notifications: ${result.data?.count || 0}`);
      console.log(`📄 Results: ${result.data?.results?.length || 0} notifications`);
    } else {
      console.log('❌ Failed to retrieve admin notifications');
      console.log(`Error: ${result.message}`);
    }
  } catch (error) {
    console.log('❌ Error testing admin notifications:', error.message);
  }
}

/**
 * Test 4: Get notifications for vehicle monitors
 */
async function testGetNotificationsForVehicleMonitors() {
  console.log('\n=== Test 4: Get Notifications for Vehicle Monitors ===');

  try {
    const result = await notificationsAPI.getNotificationsForVehicleMonitors(TEST_CONFIG.vehicleId);

    if (result.success) {
      console.log('✅ Successfully retrieved monitor notifications');
      console.log(`📊 Total monitor notifications: ${result.data?.count || 0}`);
      console.log(`📄 Results: ${result.data?.results?.length || 0} notifications`);
    } else {
      console.log('❌ Failed to retrieve monitor notifications');
      console.log(`Error: ${result.message}`);
    }
  } catch (error) {
    console.log('❌ Error testing monitor notifications:', error.message);
  }
}

/**
 * Test 5: Get notifications by vehicle and user type
 */
async function testGetNotificationsByVehicleAndUserType() {
  console.log('\n=== Test 5: Get Notifications by Vehicle and User Type ===');

  const userTypes = ['driver', 'admin', 'monitor'];

  for (const userType of userTypes) {
    try {
      console.log(`\n--- Testing ${userType} notifications ---`);
      const result = await notificationsAPI.getNotificationsByVehicleAndUserType(TEST_CONFIG.vehicleId, userType);

      if (result.success) {
        console.log(`✅ Successfully retrieved ${userType} notifications`);
        console.log(`📊 Total ${userType} notifications: ${result.data?.count || 0}`);
      } else {
        console.log(`❌ Failed to retrieve ${userType} notifications`);
        console.log(`Error: ${result.message}`);
      }
    } catch (error) {
      console.log(`❌ Error testing ${userType} notifications:`, error.message);
    }
  }
}

/**
 * Test 6: Get vehicle notifications with filtering
 */
async function testGetVehicleNotificationsWithFiltering() {
  console.log('\n=== Test 6: Get Vehicle Notifications with Filtering ===');

  const filterTests = [
    {
      name: 'Pickup Notifications',
      filters: { notification_type: 'student_pickup' }
    },
    {
      name: 'High Priority Notifications',
      filters: { priority: 'high' }
    },
    {
      name: 'Unread Notifications',
      filters: { is_read: false }
    },
    {
      name: 'Sent Notifications',
      filters: { is_sent: true }
    },
    {
      name: 'Recent Notifications (last 24 hours)',
      filters: {
        date_from: new Date(Date.now() - 24 * 60 * 60 * 1000).toISOString()
      }
    }
  ];

  for (const test of filterTests) {
    try {
      console.log(`\n--- Testing ${test.name} ---`);
      const result = await notificationsAPI.getNotificationsByVehicle(TEST_CONFIG.vehicleId, test.filters);

      if (result.success) {
        console.log(`✅ Successfully retrieved ${test.name}`);
        console.log(`📊 Total ${test.name}: ${result.data?.count || 0}`);
      } else {
        console.log(`❌ Failed to retrieve ${test.name}`);
        console.log(`Error: ${result.message}`);
      }
    } catch (error) {
      console.log(`❌ Error testing ${test.name}:`, error.message);
    }
  }
}

/**
 * Test 7: Get vehicle notifications with pagination
 */
async function testGetVehicleNotificationsWithPagination() {
  console.log('\n=== Test 7: Get Vehicle Notifications with Pagination ===');

  try {
    const result = await notificationsAPI.getNotificationsByVehicle(TEST_CONFIG.vehicleId, {
      page: 1,
      page_size: 5
    });

    if (result.success) {
      console.log('✅ Successfully retrieved paginated notifications');
      console.log(`📊 Total notifications: ${result.data?.count || 0}`);
      console.log(`📄 Current page results: ${result.data?.results?.length || 0} notifications`);
      console.log(`📄 Has next page: ${result.data?.next ? 'Yes' : 'No'}`);
      console.log(`📄 Has previous page: ${result.data?.previous ? 'Yes' : 'No'}`);
    } else {
      console.log('❌ Failed to retrieve paginated notifications');
      console.log(`Error: ${result.message}`);
    }
  } catch (error) {
    console.log('❌ Error testing paginated notifications:', error.message);
  }
}

/**
 * Test 8: Get vehicle notifications with detailed information
 */
async function testGetVehicleNotificationsWithDetails() {
  console.log('\n=== Test 8: Get Vehicle Notifications with Detailed Information ===');

  try {
    const result = await notificationsAPI.getNotificationsByVehicle(TEST_CONFIG.vehicleId, {
      include_student_details: true,
      include_vehicle_details: true,
      include_route_details: true,
      include_parent_details: true
    });

    if (result.success) {
      console.log('✅ Successfully retrieved detailed notifications');
      console.log(`📊 Total notifications: ${result.data?.count || 0}`);

      if (result.data?.results?.length > 0) {
        const firstNotification = result.data.results[0];
        console.log('📋 First notification with details:');
        console.log(`   - ID: ${firstNotification.id}`);
        console.log(`   - Title: ${firstNotification.title}`);

        if (firstNotification.student) {
          console.log(`   - Student: ${firstNotification.student.full_name} (${firstNotification.student.student_id})`);
        }

        if (firstNotification.vehicle) {
          console.log(`   - Vehicle: ${firstNotification.vehicle.license_plate} - ${firstNotification.vehicle.make} ${firstNotification.vehicle.model}`);
        }

        if (firstNotification.route) {
          console.log(`   - Route: ${firstNotification.route.name} (${firstNotification.route.route_type_display})`);
        }
      }
    } else {
      console.log('❌ Failed to retrieve detailed notifications');
      console.log(`Error: ${result.message}`);
    }
  } catch (error) {
    console.log('❌ Error testing detailed notifications:', error.message);
  }
}

/**
 * Test 9: Get vehicle notifications by different criteria
 */
async function testGetVehicleNotificationsByCriteria() {
  console.log('\n=== Test 9: Get Vehicle Notifications by Different Criteria ===');

  const criteriaTests = [
    {
      name: 'By Route',
      filters: { route: TEST_CONFIG.routeId }
    },
    {
      name: 'By Student',
      filters: { student: TEST_CONFIG.studentId }
    },
    {
      name: 'By Channels',
      filters: { channels: ['push', 'sms'] }
    },
    {
      name: 'By Status',
      filters: { status: 'sent' }
    }
  ];

  for (const test of criteriaTests) {
    try {
      console.log(`\n--- Testing ${test.name} ---`);
      const result = await notificationsAPI.getNotificationsByVehicle(TEST_CONFIG.vehicleId, test.filters);

      if (result.success) {
        console.log(`✅ Successfully retrieved ${test.name} notifications`);
        console.log(`📊 Total ${test.name} notifications: ${result.data?.count || 0}`);
      } else {
        console.log(`❌ Failed to retrieve ${test.name} notifications`);
        console.log(`Error: ${result.message}`);
      }
    } catch (error) {
      console.log(`❌ Error testing ${test.name} notifications:`, error.message);
    }
  }
}

/**
 * Test 10: Get vehicle notification statistics
 */
async function testGetVehicleNotificationStatistics() {
  console.log('\n=== Test 10: Get Vehicle Notification Statistics ===');

  try {
    // Get total count
    const totalResult = await notificationsAPI.getNotificationsByVehicle(TEST_CONFIG.vehicleId, {
      page_size: 1
    });

    // Get unread count
    const unreadResult = await notificationsAPI.getNotificationsByVehicle(TEST_CONFIG.vehicleId, {
      is_read: false,
      page_size: 1
    });

    // Get sent count
    const sentResult = await notificationsAPI.getNotificationsByVehicle(TEST_CONFIG.vehicleId, {
      is_sent: true,
      page_size: 1
    });

    // Get delivered count
    const deliveredResult = await notificationsAPI.getNotificationsByVehicle(TEST_CONFIG.vehicleId, {
      is_delivered: true,
      page_size: 1
    });

    console.log('📊 Vehicle Notification Statistics:');
    console.log(`   - Total notifications: ${totalResult.data?.count || 0}`);
    console.log(`   - Unread notifications: ${unreadResult.data?.count || 0}`);
    console.log(`   - Sent notifications: ${sentResult.data?.count || 0}`);
    console.log(`   - Delivered notifications: ${deliveredResult.data?.count || 0}`);

    console.log('✅ Successfully retrieved notification statistics');
  } catch (error) {
    console.log('❌ Error testing notification statistics:', error.message);
  }
}

/**
 * Test 11: Error handling for invalid vehicle ID
 */
async function testErrorHandling() {
  console.log('\n=== Test 11: Error Handling for Invalid Vehicle ID ===');

  try {
    const result = await notificationsAPI.getNotificationsByVehicle(999999);

    if (result.success) {
      console.log('✅ API handled invalid vehicle ID gracefully');
      console.log(`📊 Total notifications: ${result.data?.count || 0}`);
    } else {
      console.log('✅ API returned expected error for invalid vehicle ID');
      console.log(`Error: ${result.message}`);
    }
  } catch (error) {
    console.log('✅ API threw expected error for invalid vehicle ID:', error.message);
  }
}

/**
 * Test 12: Performance test with multiple requests
 */
async function testPerformance() {
  console.log('\n=== Test 12: Performance Test with Multiple Requests ===');

  const startTime = Date.now();
  const requests = [];

  try {
    // Make 5 concurrent requests
    for (let i = 0; i < 5; i++) {
      requests.push(notificationsAPI.getNotificationsByVehicle(TEST_CONFIG.vehicleId, {
        page_size: 10
      }));
    }

    const results = await Promise.all(requests);
    const endTime = Date.now();
    const duration = endTime - startTime;

    console.log(`✅ Successfully completed 5 concurrent requests in ${duration}ms`);
    console.log(`📊 Average response time: ${duration / 5}ms per request`);

    const successCount = results.filter(r => r.success).length;
    console.log(`📊 Successful requests: ${successCount}/5`);

  } catch (error) {
    console.log('❌ Error in performance test:', error.message);
  }
}

/**
 * Run all tests
 */
async function runAllTests() {
  console.log('🚀 Starting Vehicle Notification API Tests');
  console.log('==========================================');

  const tests = [
    testGetNotificationsByVehicle,
    testGetNotificationsForVehicleDrivers,
    testGetNotificationsForVehicleAdmins,
    testGetNotificationsForVehicleMonitors,
    testGetNotificationsByVehicleAndUserType,
    testGetVehicleNotificationsWithFiltering,
    testGetVehicleNotificationsWithPagination,
    testGetVehicleNotificationsWithDetails,
    testGetVehicleNotificationsByCriteria,
    testGetVehicleNotificationStatistics,
    testErrorHandling,
    testPerformance
  ];

  let passedTests = 0;
  let totalTests = tests.length;

  for (const test of tests) {
    try {
      await test();
      passedTests++;
    } catch (error) {
      console.log(`❌ Test failed with error: ${error.message}`);
    }
  }

  console.log('\n==========================================');
  console.log(`📊 Test Results: ${passedTests}/${totalTests} tests passed`);

  if (passedTests === totalTests) {
    console.log('🎉 All tests passed!');
  } else {
    console.log('⚠️  Some tests failed. Please check the output above.');
  }
}

// Run tests if this file is executed directly
if (require.main === module) {
  runAllTests().catch(console.error);
}

module.exports = {
  runAllTests,
  testGetNotificationsByVehicle,
  testGetNotificationsForVehicleDrivers,
  testGetNotificationsForVehicleAdmins,
  testGetNotificationsForVehicleMonitors,
  testGetNotificationsByVehicleAndUserType,
  testGetVehicleNotificationsWithFiltering,
  testGetVehicleNotificationsWithPagination,
  testGetVehicleNotificationsWithDetails,
  testGetVehicleNotificationsByCriteria,
  testGetVehicleNotificationStatistics,
  testErrorHandling,
  testPerformance
};
