const axios = require('axios');

// Test the Instagram download endpoint with the problematic URL
async function testInstagramDownload() {
    const testUrl = 'https://www.instagram.com/p/DMrtXHcxu9V/?igsh=emIwamNhcmFjeGM0';
    
    try {
        console.log('Testing Instagram download with URL:', testUrl);
        
        const response = await axios.post('http://localhost:8080/download/instagram', {
            url: testUrl
        }, {
            timeout: 30000
        });
        
        console.log('Success:', response.data);
    } catch (error) {
        if (error.response) {
            console.log('Error Status:', error.response.status);
            console.log('Error Data:', error.response.data);
        } else {
            console.log('Network Error:', error.message);
        }
    }
}

// Test with a valid reel URL (you can replace this with a working reel URL)
async function testValidReel() {
    const testUrl = 'https://www.instagram.com/reel/example/'; // Replace with actual reel URL
    
    try {
        console.log('Testing with valid reel URL:', testUrl);
        
        const response = await axios.post('http://localhost:8080/download/instagram', {
            url: testUrl
        }, {
            timeout: 30000
        });
        
        console.log('Success:', response.data);
    } catch (error) {
        if (error.response) {
            console.log('Error Status:', error.response.status);
            console.log('Error Data:', error.response.data);
        } else {
            console.log('Network Error:', error.message);
        }
    }
}

// Run tests
async function runTests() {
    console.log('=== Testing Instagram Download Endpoint ===\n');
    
    console.log('1. Testing with image-only post (should fail with specific error):');
    await testInstagramDownload();
    
    console.log('\n2. Testing with valid reel (if you have a working URL):');
    // await testValidReel(); // Uncomment when you have a valid reel URL
}

runTests().catch(console.error); 