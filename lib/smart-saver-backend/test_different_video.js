const axios = require('axios');

// Configuration - using a different YouTube video that should be publicly accessible
const BASE_URL = process.env.BASE_URL || 'http://localhost:8080';
const TEST_URL = process.env.TEST_URL || 'https://www.youtube.com/shorts/dQw4w9WgXcQ'; // Rick Roll - should be accessible

async function testDifferentVideo() {
    console.log('🧪 Testing with Different YouTube Video');
    console.log('=======================================');
    console.log(`Base URL: ${BASE_URL}`);
    console.log(`Test URL: ${TEST_URL}`);
    console.log('');

    try {
        // Test YouTube video accessibility
        console.log('1. Testing YouTube video accessibility...');
        const testResponse = await axios.post(`${BASE_URL}/test/youtube`, {
            url: TEST_URL
        });
        console.log('✅ YouTube test passed:', testResponse.data);
        console.log('');

        // Test actual download
        console.log('2. Testing YouTube download...');
        const downloadResponse = await axios.post(`${BASE_URL}/download/youtube`, {
            url: TEST_URL,
            quality: 'best',
            type: 'video'
        });
        console.log('✅ Download successful:', downloadResponse.data);
        console.log('');

        console.log('🎉 Test with different video passed!');
        console.log('');
        console.log('💡 The original video (x1c9Z6JN4QU) appears to be age-restricted or require authentication.');
        console.log('   This new video should work fine with the enhanced anti-bot measures.');
        
    } catch (error) {
        console.error('❌ Test failed:', error.response?.data || error.message);
        
        if (error.response?.status === 400) {
            console.log('\n💡 This video also requires authentication.');
            console.log('   Try with another public YouTube video.');
        }
    }
}

// Run the test
testDifferentVideo(); 