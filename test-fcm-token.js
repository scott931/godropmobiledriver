import notificationsAPI from './src/api/services/notificationsAPI.js';

// Test FCM Token Update
async function testFCMTokenUpdate() {
  console.log('🧪 Testing FCM Token Update API...\n');

  try {
    // Test data matching the required format
    const tokenData = {
      token: "fcm_token_123456789",
      device_type: "mobile",
      device_id: "device_unique_id"
    };

    console.log('📤 Sending FCM token update request...');
    console.log('Request data:', JSON.stringify(tokenData, null, 2));

    const response = await notificationsAPI.updateFCMToken(tokenData);

    console.log('\n✅ FCM Token Update Response:');
    console.log(JSON.stringify(response, null, 2));

    if (response.success) {
      console.log('\n🎉 FCM token updated successfully!');
      console.log('Expected response format:');
      console.log(JSON.stringify({
        message: "FCM token updated successfully"
      }, null, 2));
    } else {
      console.log('\n❌ FCM token update failed:', response.error);
    }

  } catch (error) {
    console.error('\n💥 Error testing FCM token update:', error.message);
  }
}

// Test validation with invalid data
async function testFCMTokenValidation() {
  console.log('\n🧪 Testing FCM Token Validation...\n');

  const testCases = [
    {
      name: 'Missing token field',
      data: {
        device_type: "mobile",
        device_id: "device_unique_id"
      }
    },
    {
      name: 'Invalid device type',
      data: {
        token: "fcm_token_123456789",
        device_type: "invalid_type",
        device_id: "device_unique_id"
      }
    },
    {
      name: 'Empty token',
      data: {
        token: "",
        device_type: "mobile",
        device_id: "device_unique_id"
      }
    },
    {
      name: 'Missing device_id',
      data: {
        token: "fcm_token_123456789",
        device_type: "mobile"
      }
    }
  ];

  for (const testCase of testCases) {
    try {
      console.log(`📤 Testing: ${testCase.name}`);
      console.log('Data:', JSON.stringify(testCase.data, null, 2));

      const response = await notificationsAPI.updateFCMToken(testCase.data);

      if (response.success) {
        console.log('❌ Validation should have failed but succeeded');
      } else {
        console.log('✅ Validation correctly failed:', response.error);
      }
    } catch (error) {
      console.log('✅ Validation correctly caught error:', error.message);
    }
    console.log('---\n');
  }
}

// Test different device types
async function testDeviceTypes() {
  console.log('\n🧪 Testing Different Device Types...\n');

  const deviceTypes = ['mobile', 'tablet', 'web'];

  for (const deviceType of deviceTypes) {
    try {
      const tokenData = {
        token: `fcm_token_${deviceType}_123456789`,
        device_type: deviceType,
        device_id: `device_${deviceType}_unique_id`
      };

      console.log(`📤 Testing device type: ${deviceType}`);
      console.log('Data:', JSON.stringify(tokenData, null, 2));

      const response = await notificationsAPI.updateFCMToken(tokenData);

      if (response.success) {
        console.log('✅ Device type accepted:', deviceType);
      } else {
        console.log('❌ Device type rejected:', response.error);
      }
    } catch (error) {
      console.log('❌ Error with device type:', deviceType, error.message);
    }
    console.log('---\n');
  }
}

// Run all tests
async function runAllTests() {
  console.log('🚀 Starting FCM Token Update API Tests\n');
  console.log('=' .repeat(50));

  await testFCMTokenUpdate();
  await testFCMTokenValidation();
  await testDeviceTypes();

  console.log('\n🏁 All tests completed!');
  console.log('=' .repeat(50));
}

// Execute tests
runAllTests().catch(console.error);
