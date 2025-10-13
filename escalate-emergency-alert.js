// Test script to escalate an emergency alert
// This demonstrates how to use the emergency escalation API

import { emergencyAlertsAPI } from './src/api/services/emergencyAlertsAPI.js';

const escalateEmergencyAlert = async (alertId, escalationData) => {
  try {
    console.log('🚨 Escalating emergency alert...');
    console.log('📋 Alert ID:', alertId);
    console.log('📋 Escalation data:', JSON.stringify(escalationData, null, 2));

    const response = await emergencyAlertsAPI.escalateEmergency(alertId, escalationData);

    if (response.success) {
      console.log('✅ Emergency alert escalated successfully!');
      console.log('🚨 Escalation details:', response.data);
      return response.data;
    } else {
      console.error('❌ Failed to escalate emergency alert:', response.error);
      return null;
    }
  } catch (error) {
    console.error('❌ Error escalating emergency alert:', error);
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

// Main function to demonstrate escalation
const main = async () => {
  try {
    // First, get all emergency alerts to find one to escalate
    const alerts = await getAllEmergencyAlerts();

    if (alerts.length === 0) {
      console.log('⚠️ No emergency alerts found. Creating a test alert first...');

      // Create a test emergency alert first
      const testAlertData = {
        emergency_type: "medical",
        severity: "high",
        title: "Student Medical Emergency",
        description: "Student requires immediate medical attention on bus route 5",
        vehicle: 1,
        route: 1,
        student_ids: [1, 2, 3],
        location: "40.7128,-74.0059",
        address: "123 Main Street, New York, NY",
        estimated_resolution: "2024-01-15T16:00:00Z",
        affected_students_count: 1,
        estimated_delay_minutes: 30,
        metadata: {
          medical_condition: "severe allergic reaction",
          emergency_services_contacted: true
        }
      };

      const createResponse = await emergencyAlertsAPI.createEmergencyAlert(testAlertData);
      if (createResponse.success) {
        console.log('✅ Test emergency alert created!');
        const alertId = createResponse.data.id;

        // Now escalate this alert
        const escalationData = {
          escalation_reason: "Requires immediate medical attention",
          escalation_level: "critical",
          escalated_by: "admin_user",
          escalated_to: "emergency_medical_team",
          escalation_notes: "Student showing signs of severe allergic reaction, ambulance dispatched"
        };

        await escalateEmergencyAlert(alertId, escalationData);
      } else {
        console.error('❌ Failed to create test alert:', createResponse.error);
      }
    } else {
      // Use the first available alert
      const alertId = alerts[0].id;
      console.log(`📋 Using existing alert ID: ${alertId}`);

      // Escalate the alert with the provided data
      const escalationData = {
        escalation_reason: "Requires immediate medical attention",
        escalation_level: "critical",
        escalated_by: "admin_user",
        escalated_to: "emergency_medical_team",
        escalation_notes: "Student showing signs of severe allergic reaction, ambulance dispatched"
      };

      await escalateEmergencyAlert(alertId, escalationData);
    }
  } catch (error) {
    console.error('❌ Error in main function:', error);
  }
};

// Run the main function
main();
