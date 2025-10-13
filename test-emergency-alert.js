// Test script to create a new emergency alert
// This demonstrates how to use the emergency alerts API

import { emergencyAlertsAPI } from './src/api/services/emergencyAlertsAPI.js';

const createTestEmergencyAlert = async () => {
  try {
    console.log('🚨 Creating new emergency alert...');

    const emergencyData = {
      emergency_type: "accident",
      severity: "high",
      title: "Bus Accident on Route 5",
      description: "Bus #1234 involved in minor accident on Main Street. All students safe, emergency services contacted.",
      vehicle: 1,
      route: 1,
      student_ids: [1, 2, 3, 4, 5],
      location: "40.7128,-74.0059",
      address: "123 Main Street, New York, NY",
      estimated_resolution: "2024-01-15T16:00:00Z",
      affected_students_count: 5,
      estimated_delay_minutes: 120,
      metadata: {
        weather_conditions: "clear",
        traffic_conditions: "heavy",
        emergency_services_contacted: true
      }
    };

    console.log('🚨 Emergency alert data:', emergencyData);

    const response = await emergencyAlertsAPI.createEmergencyAlert(emergencyData);

    if (response.success) {
      console.log('✅ Emergency alert created successfully!');
      console.log('🚨 Alert ID:', response.data.id);
      console.log('🚨 Alert details:', response.data);
      return response.data;
    } else {
      console.error('❌ Failed to create emergency alert:', response.error);
      return null;
    }
  } catch (error) {
    console.error('❌ Error creating emergency alert:', error);
    return null;
  }
};

// Test function to get all emergency alerts
const getAllEmergencyAlerts = async () => {
  try {
    console.log('🚨 Fetching all emergency alerts...');

    const response = await emergencyAlertsAPI.getEmergencyAlerts();

    if (response.success) {
      console.log('✅ Emergency alerts fetched successfully!');
      console.log('🚨 Total alerts:', response.data.count || response.data.length);
      console.log('🚨 Alerts:', response.data.results || response.data);
      return response.data;
    } else {
      console.error('❌ Failed to fetch emergency alerts:', response.error);
      return null;
    }
  } catch (error) {
    console.error('❌ Error fetching emergency alerts:', error);
    return null;
  }
};

// Test function to get active emergencies
const getActiveEmergencies = async () => {
  try {
    console.log('🚨 Fetching active emergencies...');

    const response = await emergencyAlertsAPI.getActiveEmergencies();

    if (response.success) {
      console.log('✅ Active emergencies fetched successfully!');
      console.log('🚨 Active emergencies:', response.data);
      return response.data;
    } else {
      console.error('❌ Failed to fetch active emergencies:', response.error);
      return null;
    }
  } catch (error) {
    console.error('❌ Error fetching active emergencies:', error);
    return null;
  }
};

// Test function to get emergency statistics
const getEmergencyStatistics = async () => {
  try {
    console.log('🚨 Fetching emergency statistics...');

    const response = await emergencyAlertsAPI.getEmergencyStatistics();

    if (response.success) {
      console.log('✅ Emergency statistics fetched successfully!');
      console.log('🚨 Statistics:', response.data);
      return response.data;
    } else {
      console.error('❌ Failed to fetch emergency statistics:', response.error);
      return null;
    }
  } catch (error) {
    console.error('❌ Error fetching emergency statistics:', error);
    return null;
  }
};

// Main test function
const runEmergencyTests = async () => {
  console.log('🚨 Starting Emergency API Tests...\n');

  // Test 1: Get all emergency alerts
  console.log('=== Test 1: Get All Emergency Alerts ===');
  await getAllEmergencyAlerts();
  console.log('\n');

  // Test 2: Get active emergencies
  console.log('=== Test 2: Get Active Emergencies ===');
  await getActiveEmergencies();
  console.log('\n');

  // Test 3: Get emergency statistics
  console.log('=== Test 3: Get Emergency Statistics ===');
  await getEmergencyStatistics();
  console.log('\n');

  // Test 4: Create new emergency alert
  console.log('=== Test 4: Create New Emergency Alert ===');
  const newAlert = await createTestEmergencyAlert();
  console.log('\n');

  // Test 5: Get all alerts again to see the new one
  if (newAlert) {
    console.log('=== Test 5: Verify New Alert Created ===');
    await getAllEmergencyAlerts();
  }

  console.log('🚨 Emergency API Tests Complete!');
};

// Export functions for use in other modules
export {
  createTestEmergencyAlert,
  getAllEmergencyAlerts,
  getActiveEmergencies,
  getEmergencyStatistics,
  runEmergencyTests
};

// Run tests if this file is executed directly
if (import.meta.url === `file://${process.argv[1]}`) {
  runEmergencyTests();
}
