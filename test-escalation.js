// Simple test script to escalate an emergency alert
// Run this with: node test-escalation.js

const testEscalation = async () => {
  const API_BASE_URL = 'http://localhost:8000'; // Adjust this to your API URL
  const ALERT_ID = '1'; // Replace with actual alert ID

  const escalationData = {
    "escalation_reason": "Requires immediate medical attention",
    "escalation_level": "critical"
  };

  try {
    console.log('🚨 Escalating emergency alert...');
    console.log('📋 Alert ID:', ALERT_ID);
    console.log('📋 Escalation data:', JSON.stringify(escalationData, null, 2));

    const response = await fetch(`${API_BASE_URL}/api/v1/emergency/alerts/${ALERT_ID}/escalate/`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer YOUR_TOKEN_HERE', // Add your auth token
      },
      body: JSON.stringify(escalationData)
    });

    if (response.ok) {
      const result = await response.json();
      console.log('✅ Emergency alert escalated successfully!');
      console.log('🚨 Escalation details:', result);
      return result;
    } else {
      const error = await response.text();
      console.error('❌ Failed to escalate emergency alert:', response.status, error);
      return null;
    }
  } catch (error) {
    console.error('❌ Error escalating emergency alert:', error);
    return null;
  }
};

// Run the test
testEscalation();
