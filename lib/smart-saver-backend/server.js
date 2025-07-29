const express = require('express');
const cors = require('cors');
const fs = require('fs');
const path = require('path');

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(cors());
app.use(express.json({ limit: '10mb' }));

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
            'POST /video/info',
            'POST /download/youtube',
            'POST /download/instagram'
        ]
    });
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
    res.json({
        success: true,
        message: 'Instagram download endpoint is working',
        note: 'yt-dlp functionality will be added back once server is stable',
        fileUrl: `https://smartsaver-production.up.railway.app/file/test_video.mp4`,
        filename: 'test_video.mp4'
    });
});

app.post('/download/youtube', (req, res) => {
    res.json({
        success: true,
        message: 'YouTube download endpoint is working',
        note: 'yt-dlp functionality will be added back once server is stable',
        fileUrl: `https://smartsaver-production.up.railway.app/file/test_video.mp4`,
        filename: 'test_video.mp4'
    });
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
    console.log('');
    console.log('📋 Available endpoints:');
    console.log('  GET  / - API information');
    console.log('  GET  /health - Health check');
    console.log('  POST /video/info - Get video information');
    console.log('  POST /download/youtube - Download YouTube video');
    console.log('  POST /download/instagram - Download Instagram reel');
});

// Handle server errors
server.on('error', (error) => {
    console.error('Server error:', error);
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
    process.exit(0);
});