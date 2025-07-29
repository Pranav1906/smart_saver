const express = require('express');
const cors = require('cors');
const fs = require('fs');
const path = require('path');

const app = express();

// Railway specific configuration
const PORT = process.env.PORT || 8080;
const HOST = '0.0.0.0'; // Bind to all interfaces

console.log('Starting Smart Saver Backend...');
console.log('Environment:', process.env.NODE_ENV || 'development');
console.log('Port:', PORT);
console.log('Host:', HOST);

// Middleware
app.use(cors({
    origin: '*',
    methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
    allowedHeaders: ['Content-Type', 'Authorization']
}));

app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true }));

// Simple request logging
app.use((req, res, next) => {
    console.log(`${new Date().toISOString()} - ${req.method} ${req.path} - Host: ${req.headers.host}`);
    next();
});

// Create downloads directory
const DOWNLOADS_DIR = path.join(__dirname, 'downloads');
try {
    if (!fs.existsSync(DOWNLOADS_DIR)) {
        fs.mkdirSync(DOWNLOADS_DIR, { recursive: true });
        console.log('Created downloads directory:', DOWNLOADS_DIR);
    }
} catch (error) {
    console.error('Error creating downloads directory:', error);
}

// Serve static files
app.use('/file', express.static(DOWNLOADS_DIR));

// Root endpoint
app.get('/', (req, res) => {
    try {
        res.json({ 
            message: 'Video Downloader API',
            version: '1.0.0',
            status: 'Server is running',
            timestamp: new Date().toISOString(),
            port: PORT,
            host: HOST
        });
    } catch (error) {
        console.error('Error in root endpoint:', error);
        res.status(500).json({ error: 'Internal server error' });
    }
});

// Health check - simple and reliable
app.get('/health', (req, res) => {
    try {
        res.json({ 
            status: 'healthy', 
            message: 'Video Downloader Backend is running!',
            timestamp: new Date().toISOString(),
            uptime: process.uptime(),
            port: PORT,
            host: HOST
        });
    } catch (error) {
        console.error('Error in health endpoint:', error);
        res.status(500).json({ error: 'Health check failed' });
    }
});

// Test POST endpoint
app.post('/test', (req, res) => {
    try {
        console.log('Test POST request received:', req.body);
        res.json({
            success: true,
            message: 'POST requests are working!',
            receivedData: req.body,
            timestamp: new Date().toISOString()
        });
    } catch (error) {
        console.error('Error in test endpoint:', error);
        res.status(500).json({ error: 'Test endpoint failed' });
    }
});

// Basic download endpoints
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
            'POST /test',
            'POST /download/youtube',
            'POST /download/instagram'
        ]
    });
});

// Start server with Railway-specific configuration
let server;
try {
    server = app.listen(PORT, HOST, () => {
        console.log(`🚀 Video Downloader Backend is running on ${HOST}:${PORT}`);
        console.log(`📁 Downloads directory: ${DOWNLOADS_DIR}`);
        console.log(`🔗 Health check: http://${HOST}:${PORT}/health`);
        console.log(`🌐 Server bound to: ${HOST}:${PORT}`);
        console.log('');
        console.log('📋 Available endpoints:');
        console.log('  GET  / - API information');
        console.log('  GET  /health - Health check');
        console.log('  POST /test - Test POST endpoint');
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

    // Handle connection events
    server.on('connection', (socket) => {
        console.log('New connection from:', socket.remoteAddress);
    });

} catch (error) {
    console.error('Failed to start server:', error);
    process.exit(1);
}

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
    if (server) {
        server.close(() => {
            console.log('Server closed');
            process.exit(0);
        });
    } else {
        process.exit(0);
    }
});

process.on('SIGTERM', () => {
    console.log('\n🛑 Received SIGTERM, shutting down gracefully...');
    if (server) {
        server.close(() => {
            console.log('Server closed');
            process.exit(0);
        });
    } else {
        process.exit(0);
    }
});

console.log('Server setup complete, waiting for requests...');