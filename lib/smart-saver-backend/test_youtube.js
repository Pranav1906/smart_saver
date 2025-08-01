const axios = require('axios');

// Configuration
const BASE_URL = process.env.BASE_URL || 'http://localhost:8080';
const TEST_URL = process.env.TEST_URL || 'https://www.youtube.com/shorts/x1c9Z6JN4QU';

async function testYouTubeDownload() {
    console.log('🧪 Testing YouTube Download Functionality');
    console.log('==========================================');
    console.log(`Base URL: ${BASE_URL}`);
    console.log(`Test URL: ${TEST_URL}`);
    console.log('');

    try {
        // First, test the health endpoint
        console.log('1. Testing health endpoint...');
        const healthResponse = await axios.get(`${BASE_URL}/health`);
        console.log('✅ Health check passed:', healthResponse.data);
        console.log('');

        // Test YouTube video accessibility
        console.log('2. Testing YouTube video accessibility...');
        const testResponse = await axios.post(`${BASE_URL}/test/youtube`, {
            url: TEST_URL
        });
        console.log('✅ YouTube test passed:', testResponse.data);
        console.log('');

        // Test actual download
        console.log('3. Testing YouTube download...');
        const downloadResponse = await axios.post(`${BASE_URL}/download/youtube`, {
            url: TEST_URL,
            quality: 'best',
            type: 'video'
        });
        console.log('✅ Download successful:', downloadResponse.data);
        console.log('');

        console.log('🎉 All tests passed!');
        
    } catch (error) {
        console.error('❌ Test failed:', error.response?.data || error.message);
        
        if (error.response?.status === 400) {
            console.log('\n💡 This appears to be an authentication issue with YouTube.');
            console.log('   The video may be age-restricted or require login.');
            console.log('   Try with a different YouTube video.');
        }
    }
}

// Run the test
testYouTubeDownload(); 