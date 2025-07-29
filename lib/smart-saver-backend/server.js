const express = require('express');
const cors = require('cors');
const fs = require('fs');
const path = require('path');

const app = express();
const PORT = process.env.PORT || 8080; // Railway uses 8080 by default

// Middleware
app.use(cors({
    origin: '*', // Allow all origins for now
    methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
    allowedHeaders: ['Content-Type', 'Authorization']
}));
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true }));

// Request logging middleware
app.use((req, res, next) => {
    console.log(`${new Date().toISOString()} - ${req.method} ${req.path} - Headers:`, req.headers);
    next();
});

// Create downloads directory
const DOWNLOADS_DIR = path.join(__dirname, 'downloads');
if (!fs.existsSync(DOWNLOADS_DIR)) {
    fs.mkdirSync(DOWNLOADS_DIR, { recursive: true });
}

// Serve static files
app.use('/file', express.static(DOWNLOADS_DIR));

// Root endpoint
app.get('/', (req, res) => {
    res.json({ 
        message: 'Video Downloader API',
        version: '1.0.0',
        status: 'Server is running',
        endpoints: [
            'GET /health',
            'POST /test',
            'POST /video/info',
            'POST /download/youtube',
            'POST /download/instagram'
        ]
    });
});

// Test HTML page
app.get('/test-page', (req, res) => {
    res.send(`
        <!DOCTYPE html>
        <html>
        <head>
            <title>Smart Saver API Test</title>
            <style>
                body { font-family: Arial, sans-serif; margin: 40px; }
                button { padding: 10px 20px; margin: 10px; cursor: pointer; }
                .result { margin: 20px 0; padding: 10px; border: 1px solid #ccc; }
            </style>
        </head>
        <body>
            <h1>Smart Saver API Test</h1>
            <button onclick="testHealth()">Test Health</button>
            <button onclick="testPost()">Test POST</button>
            <button onclick="testInstagram()">Test Instagram Download</button>
            <div id="result" class="result"></div>
            
            <script>
                async function testHealth() {
                    try {
                        const response = await fetch('/health');
                        const data = await response.json();
                        document.getElementById('result').innerHTML = '<h3>Health Test:</h3><pre>' + JSON.stringify(data, null, 2) + '</pre>';
                    } catch (error) {
                        document.getElementById('result').innerHTML = '<h3>Health Test Error:</h3><pre>' + error.message + '</pre>';
                    }
                }
                
                async function testPost() {
                    try {
                        const response = await fetch('/test', {
                            method: 'POST',
                            headers: { 'Content-Type': 'application/json' },
                            body: JSON.stringify({ test: 'data' })
                        });
                        const data = await response.json();
                        document.getElementById('result').innerHTML = '<h3>POST Test:</h3><pre>' + JSON.stringify(data, null, 2) + '</pre>';
                    } catch (error) {
                        document.getElementById('result').innerHTML = '<h3>POST Test Error:</h3><pre>' + error.message + '</pre>';
                    }
                }
                
                async function testInstagram() {
                    try {
                        const response = await fetch('/download/instagram', {
                            method: 'POST',
                            headers: { 'Content-Type': 'application/json' },
                            body: JSON.stringify({ url: 'https://www.instagram.com/reel/test/' })
                        });
                        const data = await response.json();
                        document.getElementById('result').innerHTML = '<h3>Instagram Test:</h3><pre>' + JSON.stringify(data, null, 2) + '</pre>';
                    } catch (error) {
                        document.getElementById('result').innerHTML = '<h3>Instagram Test Error:</h3><pre>' + error.message + '</pre>';
                    }
                }
            </script>
        </body>
        </html>
    `);
});

// Health check
app.get('/health', (req, res) => {
    res.json({ 
        status: 'healthy', 
        message: 'Video Downloader Backend is running!',
        timestamp: new Date().toISOString(),
        uptime: process.uptime(),
        port: PORT
    });
});

// Test POST endpoint
app.post('/test', (req, res) => {
    console.log('Test POST request received:', req.body);
    res.json({
        success: true,
        message: 'POST requests are working!',
        receivedData: req.body,
        timestamp: new Date().toISOString()
    });
});

// Basic video info endpoint (without yt-dlp for now)
app.post('/video/info', (req, res) => {
    res.json({
        success: true,
        message: 'Video info endpoint is working',
        note: 'yt-dlp functionality will be added back once server is stable'
    });
});

// Basic download endpoints (without yt-dlp for now)
app.post('/download/instagram', (req, res) => {
    try {
        console.log('Instagram download request received:', req.body);
        
        res.json({
            success: true,
            message: 'Instagram download endpoint is working',
            note: 'yt-dlp functionality will be added back once server is stable',
            fileUrl: `https://smartsaver-production.up.railway.app/file/test_video.mp4`,
            filename: 'test_video.mp4',
            receivedData: req.body
        });
    } catch (error) {
        console.error('Error in Instagram download endpoint:', error);
        res.status(500).json({
            success: false,
            error: error.message
        });
    }
});

app.post('/download/youtube', (req, res) => {
    try {
        console.log('YouTube download request received:', req.body);
        
        res.json({
            success: true,
            message: 'YouTube download endpoint is working',
            note: 'yt-dlp functionality will be added back once server is stable',
            fileUrl: `https://smartsaver-production.up.railway.app/file/test_video.mp4`,
            filename: 'test_video.mp4',
            receivedData: req.body
        });
    } catch (error) {
        console.error('Error in YouTube download endpoint:', error);
        res.status(500).json({
            success: false,
            error: error.message
        });
    }
});

// 404 handler
app.use('*', (req, res) => {
    res.status(404).json({ 
        error: 'API endpoint not found',
        availableEndpoints: [
            'GET /',
            'GET /health',
            'POST /video/info',
            'POST /download/youtube',
            'POST /download/instagram'
        ]
    });
});

// Start server
const server = app.listen(PORT, '0.0.0.0', () => {
    console.log(`🚀 Video Downloader Backend is running on port ${PORT}`);
    console.log(`📁 Downloads directory: ${DOWNLOADS_DIR}`);
    console.log(`🔗 Health check: http://localhost:${PORT}/health`);
    console.log(`🌐 Server bound to: 0.0.0.0:${PORT}`);
    console.log('');
    console.log('📋 Available endpoints:');
    console.log('  GET  / - API information');
    console.log('  GET  /health - Health check');
    console.log('  POST /test - Test POST endpoint');
    console.log('  POST /video/info - Get video information');
    console.log('  POST /download/youtube - Download YouTube video');
    console.log('  POST /download/instagram - Download Instagram reel');
});

// Handle server errors
server.on('error', (error) => {
    console.error('Server error:', error);
    if (error.code === 'EADDRINUSE') {
        console.error(`Port ${PORT} is already in use`);
    }
    process.exit(1);
});

// Handle uncaught exceptions
process.on('uncaughtException', (error) => {
    console.error('Uncaught Exception:', error);
    process.exit(1);
});

// Handle unhandled promise rejections
process.on('unhandledRejection', (reason, promise) => {
    console.error('Unhandled Rejection at:', promise, 'reason:', reason);
    process.exit(1);
});

// Graceful shutdown
process.on('SIGINT', () => {
    console.log('\n🛑 Shutting down gracefully...');
    server.close(() => {
        console.log('Server closed');
        process.exit(0);
    });
});

process.on('SIGTERM', () => {
    console.log('\n🛑 Received SIGTERM, shutting down gracefully...');
    server.close(() => {
        console.log('Server closed');
        process.exit(0);
    });
});