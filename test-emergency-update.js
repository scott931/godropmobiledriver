// Test script to update an emergency alert using the API service
// This demonstrates how to use the emergency alerts API with PUT method

import { emergencyAlertsAPI } from './src/api/services/emergencyAlertsAPI.js';

const updateEmergencyAlert = async (alertId, updateData) => {
  try {
    console.log('🚨 Updating emergency alert...');
    console.log('📋 Alert ID:', alertId);
    console.log('📋 Update data:', JSON.stringify(updateData, null, 2));

    const response = await emergencyAlertsAPI.updateEmergencyStatus(alertId, updateData);

    if (response.success) {
      console.log('✅ Emergency alert updated successfully!');
      console.log('🚨 Updated alert details:', response.data);
      return response.data;
    } else {
      console.error('❌ Failed to update emergency alert:', response.error);
      return null;
    }
  } catch (error) {
    console.error('❌ Error updating emergency alert:', error);
    return null;
  }
};

// Test function to get all emergency alerts first
const getAllEmergencyAlerts = async () => {
  try {
    console.log('📋 Getting all emergency alerts...');
    const response = await emergencyAlertsAPI.getEmergencyAlerts();

    if (response.success) {
      console.log('✅ Emergency alerts retrieved successfully!');
      console.log('📋 Total alerts:', response.data.length);
      return response.data;
    } else {
      console.error('❌ Failed to get emergency alerts:', response.error);
      return [];
    }
  } catch (error) {
    console.error('❌ Error getting emergency alerts:', error);
    return [];
  }
};

// Main function to demonstrate emergency alert update
const main = async () => {
  try {
    // First, get all emergency alerts to find one to update
    const alerts = await getAllEmergencyAlerts();

    if (alerts.length === 0) {
      console.log('⚠️ No emergency alerts found. Creating a test alert first...');

      // Create a test emergency alert first
      const testAlertData = {
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

      const createResponse = await emergencyAlertsAPI.createEmergencyAlert(testAlertData);
      if (createResponse.success) {
        console.log('✅ Test emergency alert created!');
        const alertId = createResponse.data.id;

        // Now update this alert with the provided data
        const updateData = {
          "status": "resolved",
          "description": "Accident cleared, all students safely transferred to backup bus. Route 5 back to normal operation.",
          "estimated_resolution": "2024-01-15T15:30:00Z",
          "affected_students_count": 0,
          "estimated_delay_minutes": 0
        };

        await updateEmergencyAlert(alertId, updateData);
      } else {
        console.error('❌ Failed to create test alert:', createResponse.error);
      }
    } else {
      // Use the first available alert
      const alertId = alerts[0].id;
      console.log(`📋 Using existing alert ID: ${alertId}`);

      // Update the alert with the provided data
      const updateData = {
        "status": "resolved",
        "description": "Accident cleared, all students safely transferred to backup bus. Route 5 back to normal operation.",
        "estimated_resolution": "2024-01-15T15:30:00Z",
        "affected_students_count": 0,
        "estimated_delay_minutes": 0
      };

      await updateEmergencyAlert(alertId, updateData);
    }
  } catch (error) {
    console.error('❌ Error in main function:', error);
  }
};

// Run the main function
main();
