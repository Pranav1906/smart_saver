const express = require('express');
const cors = require('cors');
const fs = require('fs');
const path = require('path');
const { exec } = require('child_process');
const { promisify } = require('util');
const { v4: uuidv4 } = require('uuid');

const execAsync = promisify(exec);

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

// YouTube download endpoint with yt-dlp
app.post('/download/youtube', async (req, res) => {
    try {
        console.log('YouTube download request received:', req.body);
        
        const { url, quality = 'best', type = 'video' } = req.body;
        
        if (!url) {
            return res.status(400).json({
                success: false,
                error: 'URL is required'
            });
        }

        // Validate YouTube URL
        if (!url.includes('youtube.com') && !url.includes('youtu.be')) {
            return res.status(400).json({
                success: false,
                error: 'Invalid YouTube URL'
            });
        }

        // Generate unique filename
        const filename = `youtube_${uuidv4()}.mp4`;
        const outputPath = path.join(DOWNLOADS_DIR, filename);

        console.log(`Starting download for: ${url}`);
        console.log(`Output path: ${outputPath}`);

        // yt-dlp command for YouTube Shorts
        const ytdlpCommand = `yt-dlp -f "best[height<=1080]" -o "${outputPath}" "${url}"`;

        try {
            const { stdout, stderr } = await execAsync(ytdlpCommand, { timeout: 120000 }); // 2 minutes timeout
            
            console.log('yt-dlp stdout:', stdout);
            if (stderr) console.log('yt-dlp stderr:', stderr);

            // Check if file was created
            if (fs.existsSync(outputPath)) {
                const stats = fs.statSync(outputPath);
                const fileSize = (stats.size / (1024 * 1024)).toFixed(2); // MB
                
                console.log(`Download completed: ${filename} (${fileSize} MB)`);
                
                const fileUrl = `${req.protocol}://${req.get('host')}/file/${filename}`;
                
                res.json({
                    success: true,
                    message: 'Download completed successfully',
                    fileUrl: fileUrl,
                    filename: filename,
                    fileSize: `${fileSize} MB`,
                    originalUrl: url
                });
            } else {
                throw new Error('File was not created after download');
            }
            
        } catch (execError) {
            console.error('yt-dlp execution error:', execError);
            
            // Try alternative format if best fails
            try {
                const fallbackCommand = `yt-dlp -f "best" -o "${outputPath}" "${url}"`;
                const { stdout, stderr } = await execAsync(fallbackCommand, { timeout: 120000 });
                
                console.log('Fallback yt-dlp stdout:', stdout);
                if (stderr) console.log('Fallback yt-dlp stderr:', stderr);

                if (fs.existsSync(outputPath)) {
                    const stats = fs.statSync(outputPath);
                    const fileSize = (stats.size / (1024 * 1024)).toFixed(2);
                    
                    console.log(`Fallback download completed: ${filename} (${fileSize} MB)`);
                    
                    const fileUrl = `${req.protocol}://${req.get('host')}/file/${filename}`;
                    
                    res.json({
                        success: true,
                        message: 'Download completed successfully (fallback format)',
                        fileUrl: fileUrl,
                        filename: filename,
                        fileSize: `${fileSize} MB`,
                        originalUrl: url
                    });
                } else {
                    throw new Error('File was not created after fallback download');
                }
            } catch (fallbackError) {
                console.error('Fallback download failed:', fallbackError);
                res.status(500).json({
                    success: false,
                    error: 'Failed to download video. Please check the URL and try again.',
                    details: fallbackError.message
                });
            }
        }
        
    } catch (error) {
        console.error('Error in YouTube download endpoint:', error);
        res.status(500).json({
            success: false,
            error: error.message || 'Internal server error'
        });
    }
});

// Instagram download endpoint
app.post('/download/instagram', async (req, res) => {
    try {
        console.log('Instagram download request received:', req.body);
        
        const { url } = req.body;
        
        if (!url) {
            return res.status(400).json({
                success: false,
                error: 'URL is required'
            });
        }

        // Validate Instagram URL
        if (!url.includes('instagram.com')) {
            return res.status(400).json({
                success: false,
                error: 'Invalid Instagram URL'
            });
        }

        // Generate unique filename
        const filename = `instagram_${uuidv4()}.mp4`;
        const outputPath = path.join(DOWNLOADS_DIR, filename);

        console.log(`Starting Instagram download for: ${url}`);
        console.log(`Output path: ${outputPath}`);

        // yt-dlp command for Instagram
        const ytdlpCommand = `yt-dlp -f "best" -o "${outputPath}" "${url}"`;

        try {
            const { stdout, stderr } = await execAsync(ytdlpCommand, { timeout: 120000 });
            
            console.log('yt-dlp stdout:', stdout);
            if (stderr) console.log('yt-dlp stderr:', stderr);

            if (fs.existsSync(outputPath)) {
                const stats = fs.statSync(outputPath);
                const fileSize = (stats.size / (1024 * 1024)).toFixed(2);
                
                console.log(`Instagram download completed: ${filename} (${fileSize} MB)`);
                
                const fileUrl = `${req.protocol}://${req.get('host')}/file/${filename}`;
                
                res.json({
                    success: true,
                    message: 'Instagram download completed successfully',
                    fileUrl: fileUrl,
                    filename: filename,
                    fileSize: `${fileSize} MB`,
                    originalUrl: url
                });
            } else {
                throw new Error('File was not created after download');
            }
            
        } catch (execError) {
            console.error('yt-dlp execution error:', execError);
            res.status(500).json({
                success: false,
                error: 'Failed to download Instagram content. Please check the URL and try again.',
                details: execError.message
            });
        }
        
    } catch (error) {
        console.error('Error in Instagram download endpoint:', error);
        res.status(500).json({
            success: false,
            error: error.message || 'Internal server error'
        });
    }
});

// File cleanup endpoint (optional)
app.delete('/file/:filename', (req, res) => {
    try {
        const filename = req.params.filename;
        const filePath = path.join(DOWNLOADS_DIR, filename);
        
        if (fs.existsSync(filePath)) {
            fs.unlinkSync(filePath);
            res.json({
                success: true,
                message: `File ${filename} deleted successfully`
            });
        } else {
            res.status(404).json({
                success: false,
                error: 'File not found'
            });
        }
    } catch (error) {
        console.error('Error deleting file:', error);
        res.status(500).json({
            success: false,
            error: 'Failed to delete file'
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
            'POST /download/instagram',
            'DELETE /file/:filename'
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
        console.log('  DELETE /file/:filename - Delete downloaded file');
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