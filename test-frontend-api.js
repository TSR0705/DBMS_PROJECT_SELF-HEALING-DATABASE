// Test script to verify frontend API integration
const API_BASE = 'http://localhost:8000';

async function testAPI() {
    console.log('Testing DBMS API endpoints...');
    
    try {
        // Test health endpoint
        console.log('\n1. Testing health endpoint...');
        const healthResponse = await fetch(`${API_BASE}/health`);
        const healthData = await healthResponse.json();
        console.log('✓ Health:', healthData);
        
        // Test issues endpoint
        console.log('\n2. Testing issues endpoint...');
        const issuesResponse = await fetch(`${API_BASE}/issues/`);
        const issuesData = await issuesResponse.json();
        console.log('✓ Issues count:', issuesData.length);
        console.log('✓ Sample issue:', issuesData[0]);
        
        // Test actions endpoint
        console.log('\n3. Testing actions endpoint...');
        const actionsResponse = await fetch(`${API_BASE}/actions/`);
        const actionsData = await actionsResponse.json();
        console.log('✓ Actions count:', actionsData.length);
        
        console.log('\n✅ All API tests passed!');
        
    } catch (error) {
        console.error('❌ API test failed:', error);
    }
}

// Run the test
testAPI();