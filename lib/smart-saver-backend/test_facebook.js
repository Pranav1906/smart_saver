const axios = require('axios');

// Test the Facebook download endpoint
async function testFacebookDownload() {
    const testUrl = 'https://www.facebook.com/watch?v=example'; // Replace with actual Facebook video URL
    
    try {
        console.log('Testing Facebook download with URL:', testUrl);
        
        const response = await axios.post('http://localhost:8080/download/facebook', {
            url: testUrl,
            quality: 'best'
        });
        
        console.log('✅ Facebook download successful!');
        console.log('Response:', response.data);
        
    } catch (error) {
        console.log('❌ Facebook download failed');
        if (error.response) {
            console.log('Error status:', error.response.status);
            console.log('Error data:', error.response.data);
        } else {
            console.log('Error:', error.message);
        }
    }
}

// Test Facebook URL validation
async function testFacebookUrlValidation() {
    const invalidUrl = 'https://www.youtube.com/watch?v=example';
    
    try {
        console.log('Testing Facebook URL validation with invalid URL:', invalidUrl);
        
        const response = await axios.post('http://localhost:8080/download/facebook', {
            url: invalidUrl,
            quality: 'best'
        });
        
        console.log('❌ URL validation failed - should have rejected invalid URL');
        console.log('Response:', response.data);
        
    } catch (error) {
        if (error.response && error.response.status === 400) {
            console.log('✅ URL validation working correctly');
            console.log('Error message:', error.response.data.error);
        } else {
            console.log('❌ Unexpected error:', error.message);
        }
    }
}

// Main test function
async function runFacebookTests() {
    console.log('=== Testing Facebook Download Endpoint ===\n');
    
    await testFacebookUrlValidation();
    console.log('');
    await testFacebookDownload();
}

// Run tests if this file is executed directly
if (require.main === module) {
    runFacebookTests().catch(console.error);
}

module.exports = { testFacebookDownload, testFacebookUrlValidation }; 