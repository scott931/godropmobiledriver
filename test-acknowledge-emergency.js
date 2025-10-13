// Test script to verify emergency alert acknowledge function
// Run this with: node test-acknowledge-emergency.js

const testAcknowledgeEmergency = async () => {
  const API_BASE_URL = 'http://localhost:8000'; // Adjust this to your API URL
  const ALERT_ID = 1; // Replace with actual alert ID

  try {
    console.log('🚨 Testing emergency alert acknowledge...');
    console.log('📋 Alert ID:', ALERT_ID);

    const acknowledgeData = {
      acknowledged_by: 'test_user',
      acknowledged_at: new Date().toISOString(),
      notes: 'Test acknowledgment'
    };

    console.log('📤 Sending acknowledge request...');
    console.log('📤 Data:', JSON.stringify(acknowledgeData, null, 2));

    const response = await fetch(`${API_BASE_URL}/api/v1/emergency/alerts/${ALERT_ID}/acknowledge/`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer YOUR_TOKEN_HERE', // Add your auth token
      },
      body: JSON.stringify(acknowledgeData)
    });

    console.log('📊 Response Status:', response.status);
    console.log('📊 Response Headers:', Object.fromEntries(response.headers.entries()));

    if (response.ok) {
      const result = await response.json();
      console.log('✅ Emergency alert acknowledged successfully!');
      console.log('🚨 Response data:', result);

      // Test the handleApiSuccess function logic
      const mockResponse = {
        data: result,
        status: response.status
      };

      const processedResult = {
        success: true,
        data: mockResponse.data,
        status: mockResponse.status,
        message: mockResponse.data?.message || 'Operation successful',
      };

      console.log('🔧 Processed result:', processedResult);
      console.log('🔧 Success check:', processedResult.success);

      // Test the specific case where API returns only message
      if (result.message && !result.id) {
        console.log('🔧 API returned message-only response');
        const enhancedResult = {
          success: true,
          data: {
            id: ALERT_ID,
            message: result.message,
            acknowledged: true,
            acknowledged_at: acknowledgeData.acknowledged_at,
            acknowledged_by: acknowledgeData.acknowledged_by
          },
          status: response.status,
          message: result.message
        };
        console.log('🔧 Enhanced result:', enhancedResult);
        return enhancedResult;
      }

      return processedResult;
    } else {
      const error = await response.text();
      console.error('❌ Failed to acknowledge emergency alert:', response.status, error);
      return null;
    }
  } catch (error) {
    console.error('❌ Error acknowledging emergency alert:', error);
    return null;
  }
};

// Run the test
testAcknowledgeEmergency();
