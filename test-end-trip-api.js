/**
 * Test script for the End Trip API
 * This script tests the end trip API endpoint with the correct data format
 */

const axios = require('axios');

// API Configuration
const BASE_URL = 'https://schooltransit-backend-staging-ixld.onrender.com/api/v1';
const END_TRIP_ENDPOINT = '/tracking/trips/end/';

// Test data matching the API specification
const testData = {
  "trip_id": "TRP_PICKUP_2_2_20251010_223751",
  "end_location": "SRID=4326;POINT (36.8065 -1.2657000000000047)",
  "latitude": -1.2921,
  "longitude": 36.8219,
  "notes": "Completed morning route successfully"
};

async function testEndTripAPI() {
  try {
    console.log('🚀 Testing End Trip API...');
    console.log('📤 Request Data:', JSON.stringify(testData, null, 2));

    const response = await axios.post(`${BASE_URL}${END_TRIP_ENDPOINT}`, testData, {
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        // Note: In a real scenario, you would need to include the Authorization header
        // 'Authorization': 'Bearer YOUR_JWT_TOKEN'
      },
      timeout: 30000
    });

    console.log('✅ API Response Status:', response.status);
    console.log('📥 Response Data:', JSON.stringify(response.data, null, 2));

    // Validate response structure
    const responseData = response.data;
    const requiredFields = [
      'id', 'trip_id', 'driver', 'driver_name', 'vehicle', 'vehicle_name',
      'route', 'route_name', 'trip_type', 'status', 'start_location',
      'end_location', 'current_location', 'scheduled_start', 'scheduled_end',
      'actual_start', 'actual_end', 'total_distance', 'average_speed',
      'max_speed', 'notes', 'delay_reason', 'created_at', 'updated_at'
    ];

    console.log('\n🔍 Validating Response Fields:');
    requiredFields.forEach(field => {
      const hasField = responseData.hasOwnProperty(field);
      console.log(`${hasField ? '✅' : '❌'} ${field}: ${hasField ? 'Present' : 'Missing'}`);
    });

    // Check if the trip was ended successfully
    if (responseData.status === 'Completed' && responseData.actual_end) {
      console.log('\n🎉 Trip ended successfully!');
      console.log(`Trip ID: ${responseData.trip_id}`);
      console.log(`Driver: ${responseData.driver_name}`);
      console.log(`Vehicle: ${responseData.vehicle_name}`);
      console.log(`Route: ${responseData.route_name}`);
      console.log(`Status: ${responseData.status}`);
      console.log(`Actual End: ${responseData.actual_end}`);

      // Check if actual_end is different from actual_start
      if (responseData.actual_start && responseData.actual_end) {
        const startTime = new Date(responseData.actual_start);
        const endTime = new Date(responseData.actual_end);
        const duration = Math.round((endTime - startTime) / 1000 / 60); // minutes
        console.log(`Trip Duration: ${duration} minutes`);
      }
    } else {
      console.log('\n⚠️ Trip may not have ended properly');
      console.log(`Status: ${responseData.status}`);
    }

  } catch (error) {
    console.error('❌ API Test Failed:');

    if (error.response) {
      // Server responded with error status
      console.error('Status:', error.response.status);
      console.error('Error Data:', JSON.stringify(error.response.data, null, 2));
    } else if (error.request) {
      // Request was made but no response received
      console.error('No response received:', error.message);
    } else {
      // Something else happened
      console.error('Error:', error.message);
    }
  }
}

// Run the test
testEndTripAPI();
