// Test script to update an emergency alert using PUT method
// Run this with: node update-emergency-alert.js

const updateEmergencyAlert = async () => {
  const API_BASE_URL = 'http://localhost:8000'; // Adjust this to your API URL
  const ALERT_ID = '1'; // Replace with actual alert ID

  const updateData = {
    "status": "resolved",
    "description": "Accident cleared, all students safely transferred to backup bus. Route 5 back to normal operation.",
    "estimated_resolution": "2024-01-15T15:30:00Z",
    "affected_students_count": 0,
    "estimated_delay_minutes": 0
  };

  try {
    console.log('🚨 Updating emergency alert...');
    console.log('📋 Alert ID:', ALERT_ID);
    console.log('📋 Update data:', JSON.stringify(updateData, null, 2));

    const response = await fetch(`${API_BASE_URL}/api/v1/emergency/alerts/${ALERT_ID}/`, {
      method: 'PUT',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer YOUR_TOKEN_HERE', // Add your auth token
      },
      body: JSON.stringify(updateData)
    });

    if (response.ok) {
      const result = await response.json();
      console.log('✅ Emergency alert updated successfully!');
      console.log('🚨 Updated alert details:', result);
      return result;
    } else {
      const error = await response.text();
      console.error('❌ Failed to update emergency alert:', response.status, error);
      return null;
    }
  } catch (error) {
    console.error('❌ Error updating emergency alert:', error);
    return null;
  }
};

// Run the test
updateEmergencyAlert();
