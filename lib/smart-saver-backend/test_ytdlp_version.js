const axios = require('axios');
const { exec } = require('child_process');
const { promisify } = require('util');

const execAsync = promisify(exec);

// Configuration
const BASE_URL = process.env.BASE_URL || 'http://localhost:8080';
const TEST_URL = process.env.TEST_URL || 'https://www.youtube.com/watch?v=dQw4w9WgXcQ'; // Rick Roll - should work

async function testYtdlpVersion() {
    console.log('🔍 Testing yt-dlp Version and Functionality');
    console.log('==========================================');
    console.log(`Base URL: ${BASE_URL}`);
    console.log(`Test URL: ${TEST_URL}`);
    console.log('');

    try {
        // Check yt-dlp version locally
        console.log('1. Checking yt-dlp version...');
        try {
            const { stdout } = await execAsync('/opt/venv/bin/yt-dlp --version');
            console.log('✅ yt-dlp version:', stdout.trim());
        } catch (error) {
            console.log('❌ yt-dlp not available locally:', error.message);
        }
        console.log('');

        // Check server health
        console.log('2. Checking server health...');
        const healthResponse = await axios.get(`${BASE_URL}/health`);
        console.log('✅ Server health:', healthResponse.data);
        console.log('');

        // Test with a regular YouTube video (not shorts)
        console.log('3. Testing with regular YouTube video...');
        const testResponse = await axios.post(`${BASE_URL}/test/youtube`, {
            url: TEST_URL
        });
        console.log('✅ YouTube test passed:', testResponse.data);
        console.log('');

        // Test actual download
        console.log('4. Testing YouTube download...');
        const downloadResponse = await axios.post(`${BASE_URL}/download/youtube`, {
            url: TEST_URL,
            quality: 'best',
            type: 'video'
        });
        console.log('✅ Download successful:', downloadResponse.data);
        console.log('');

        console.log('🎉 All tests passed!');
        console.log('');
        console.log('💡 The issue might be specific to YouTube Shorts or certain videos.');
        console.log('   Regular YouTube videos should work fine.');
        
    } catch (error) {
        console.error('❌ Test failed:', error.response?.data || error.message);
        
        if (error.response?.status === 400) {
            console.log('\n💡 This video requires authentication or is unavailable.');
            console.log('   Try with a different public YouTube video.');
        }
    }
}

// Run the test
testYtdlpVersion(); 