import routesAPI from './src/api/services/routesAPI.js';

// Test Assignment Stats API
async function testAssignmentStats() {
  console.log('📊 Testing Assignment Stats API...\n');

  try {
    console.log('📤 Fetching assignment statistics...');
    console.log('📤 Endpoint: /api/v1/routes/assignments/stats/');

    const response = await routesAPI.getAssignmentStats();

    console.log('\n✅ Assignment Stats Response:');
    console.log(JSON.stringify(response, null, 2));

    if (response.success) {
      console.log('\n🎉 Assignment stats retrieved successfully!');
      console.log('\n📊 Expected Response Format:');
      console.log(JSON.stringify({
        "total_assignments": 9,
        "active_assignments": 0,
        "pending_assignments": 9,
        "completed_assignments": 0,
        "current_active_assignments": 0,
        "recent_assignments": 9,
        "assignments_by_status": [
          {
            "status": "pending",
            "count": 9
          }
        ]
      }, null, 2));

      // Validate response structure
      const data = response.data;
      if (data) {
        console.log('\n🔍 Response Analysis:');
        console.log(`📈 Total Assignments: ${data.total_assignments || 'N/A'}`);
        console.log(`🟢 Active Assignments: ${data.active_assignments || 'N/A'}`);
        console.log(`🟡 Pending Assignments: ${data.pending_assignments || 'N/A'}`);
        console.log(`✅ Completed Assignments: ${data.completed_assignments || 'N/A'}`);
        console.log(`🔄 Current Active: ${data.current_active_assignments || 'N/A'}`);
        console.log(`📅 Recent Assignments: ${data.recent_assignments || 'N/A'}`);

        if (data.assignments_by_status && Array.isArray(data.assignments_by_status)) {
          console.log('\n📊 Assignments by Status:');
          data.assignments_by_status.forEach((statusItem, index) => {
            console.log(`  ${index + 1}. ${statusItem.status}: ${statusItem.count}`);
          });
        }
      }
    } else {
      console.log('\n❌ Assignment stats fetch failed:', response.error);
    }

  } catch (error) {
    console.error('\n💥 Error testing assignment stats:', error.message);
  }
}

// Test assignment stats with different scenarios
async function testAssignmentStatsScenarios() {
  console.log('\n🧪 Testing Assignment Stats Scenarios...\n');

  const scenarios = [
    {
      name: 'Basic Stats Request',
      description: 'Fetch basic assignment statistics'
    },
    {
      name: 'Stats with Date Range',
      description: 'Fetch stats for specific date range (if supported)'
    }
  ];

  for (const scenario of scenarios) {
    try {
      console.log(`📤 Testing: ${scenario.name}`);
      console.log(`📝 Description: ${scenario.description}`);

      const response = await routesAPI.getAssignmentStats();

      if (response.success) {
        console.log('✅ Scenario successful');
        console.log('📊 Response data keys:', Object.keys(response.data || {}));
      } else {
        console.log('❌ Scenario failed:', response.error);
      }
    } catch (error) {
      console.log('❌ Scenario error:', error.message);
    }
    console.log('---\n');
  }
}

// Test assignment stats data structure validation
async function validateAssignmentStatsStructure() {
  console.log('\n🔍 Validating Assignment Stats Structure...\n');

  try {
    const response = await routesAPI.getAssignmentStats();

    if (response.success && response.data) {
      const data = response.data;
      const requiredFields = [
        'total_assignments',
        'active_assignments',
        'pending_assignments',
        'completed_assignments',
        'current_active_assignments',
        'recent_assignments',
        'assignments_by_status'
      ];

      console.log('📋 Checking required fields:');
      requiredFields.forEach(field => {
        const exists = data.hasOwnProperty(field);
        const value = data[field];
        console.log(`  ${exists ? '✅' : '❌'} ${field}: ${exists ? (typeof value) : 'MISSING'}`);
      });

      // Validate assignments_by_status structure
      if (data.assignments_by_status && Array.isArray(data.assignments_by_status)) {
        console.log('\n📊 Validating assignments_by_status structure:');
        data.assignments_by_status.forEach((item, index) => {
          const hasStatus = item.hasOwnProperty('status');
          const hasCount = item.hasOwnProperty('count');
          console.log(`  Item ${index + 1}: ${hasStatus ? '✅' : '❌'} status, ${hasCount ? '✅' : '❌'} count`);
          if (hasStatus && hasCount) {
            console.log(`    Status: "${item.status}", Count: ${item.count}`);
          }
        });
      } else {
        console.log('❌ assignments_by_status is missing or not an array');
      }

    } else {
      console.log('❌ Cannot validate structure - no data received');
    }

  } catch (error) {
    console.error('💥 Error validating structure:', error.message);
  }
}

// Test assignment stats with error handling
async function testAssignmentStatsErrorHandling() {
  console.log('\n🛡️ Testing Assignment Stats Error Handling...\n');

  try {
    // This should work normally
    console.log('📤 Testing normal request...');
    const response = await routesAPI.getAssignmentStats();

    if (response.success) {
      console.log('✅ Normal request successful');
    } else {
      console.log('❌ Normal request failed:', response.error);
    }

    // Test with potential edge cases
    console.log('\n📤 Testing with various parameters...');

    // Test if the API supports any query parameters
    const testParams = [
      { date_from: '2024-01-01', date_to: '2024-12-31' },
      { status: 'active' },
      { limit: 10 }
    ];

    for (const params of testParams) {
      try {
        console.log(`📤 Testing with params:`, params);
        // Note: The current implementation doesn't support params, but we can test the error handling
        const response = await routesAPI.getAssignmentStats();
        console.log('✅ Request completed (params ignored)');
      } catch (error) {
        console.log('❌ Request failed:', error.message);
      }
    }

  } catch (error) {
    console.error('💥 Error in error handling test:', error.message);
  }
}

// Run all tests
async function runAllAssignmentStatsTests() {
  console.log('🚀 Starting Assignment Stats API Tests\n');
  console.log('=' .repeat(60));

  await testAssignmentStats();
  await testAssignmentStatsScenarios();
  await validateAssignmentStatsStructure();
  await testAssignmentStatsErrorHandling();

  console.log('\n🏁 All assignment stats tests completed!');
  console.log('=' .repeat(60));
}

// Execute tests
runAllAssignmentStatsTests().catch(console.error);
