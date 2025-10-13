// Simple script to create an emergency alert
// Run this with: node create-emergency-alert.js

const createEmergencyAlert = async () => {
  const API_BASE_URL = 'http://localhost:8000'; // Adjust this to your API URL

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

  try {
    console.log('🚨 Creating emergency alert...');
    console.log('📋 Data:', JSON.stringify(emergencyData, null, 2));

    const response = await fetch(`${API_BASE_URL}/api/v1/emergency/alerts/`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer YOUR_TOKEN_HERE', // Add your auth token
      },
      body: JSON.stringify(emergencyData)
    });

    if (response.ok) {
      const result = await response.json();
      console.log('✅ Emergency alert created successfully!');
      console.log('🚨 Alert ID:', result.id);
      console.log('🚨 Alert details:', result);
      return result;
    } else {
      const error = await response.text();
      console.error('❌ Failed to create emergency alert:', response.status, error);
      return null;
    }
  } catch (error) {
    console.error('❌ Error creating emergency alert:', error);
    return null;
  }
};

// Run the function
createEmergencyAlert();
