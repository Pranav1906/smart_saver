const express = require('express');
const cors = require('cors');
const axios = require('axios');
const fs = require('fs');
const path = require('path');
const { v4: uuidv4 } = require('uuid');
const { exec, spawn } = require('child_process');
const util = require('util');

const app = express();
const PORT = process.env.PORT || 3000;

// Convert exec to promise
const execAsync = util.promisify(exec);

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

// Video Downloader Class
class VideoDownloader {
    constructor() {
        this.userAgent = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36';
        this.ytDlpPath = null;
    }

    // Get yt-dlp executable path
    async getYtDlpPath() {
        if (this.ytDlpPath) {
            return this.ytDlpPath;
        }

        // Try multiple possible locations
        const possiblePaths = [
            'yt-dlp',
            './yt-dlp',
            '/usr/local/bin/yt-dlp',
            '/app/yt-dlp',
            '/tmp/yt-dlp',
            path.join(__dirname, 'yt-dlp', 'yt-dlp')
        ];
        
        for (const path of possiblePaths) {
            try {
                await execAsync(`${path} --version`);
                console.log(`yt-dlp found at: ${path}`);
                this.ytDlpPath = path;
                return path;
            } catch (error) {
                // Continue to next path
            }
        }
        
        throw new Error('yt-dlp not found in any location');
    }

    // Validate Instagram URL
    isValidInstagramUrl(url) {
        const instagramRegex = /^(https?:\/\/)?(www\.)?(instagram\.com|instagr\.am)\/(p|reel|reels|stories)\/[\w-]+\/?(\?.*)?$/;
        return instagramRegex.test(url);
    }

    // Validate YouTube URL
    isValidYouTubeUrl(url) {
        const youtubeRegex = /^(https?:\/\/)?(www\.)?(youtube\.com\/(watch\?v=|embed\/|v\/|shorts\/)|youtu\.be\/)[\w-]{11}(&[\w=]*)?$/;
        return youtubeRegex.test(url);
    }

    // Clean Instagram URL
    cleanInstagramUrl(url) {
        let cleanUrl = url.split('?')[0];
        if (cleanUrl.endsWith('/')) {
            cleanUrl = cleanUrl.slice(0, -1);
        }
        return cleanUrl;
    }

    // Download Instagram Reel using yt-dlp
    async downloadInstagramReel(url, filename) {
        return new Promise(async (resolve, reject) => {
            try {
                const ytDlpPath = await this.getYtDlpPath();
                const outputPath = path.join(DOWNLOADS_DIR, filename);
                const cleanUrl = this.cleanInstagramUrl(url);
                
                const args = [
                    '--no-warnings',
                    '--no-playlist',
                    '--user-agent', this.userAgent,
                    '-f', 'best[ext=mp4]/best',
                    '--merge-output-format', 'mp4',
                    '--no-check-certificate',
                    '-o', outputPath,
                    cleanUrl
                ];

                console.log('Downloading Instagram reel with yt-dlp:', cleanUrl);
                
                const process = spawn(ytDlpPath, args);
                let errorOutput = '';

                process.stdout.on('data', (data) => {
                    console.log(`yt-dlp instagram stdout: ${data}`);
                });

                process.stderr.on('data', (data) => {
                    const output = data.toString();
                    console.log(`yt-dlp instagram stderr: ${output}`);
                    errorOutput += output;
                });

                process.on('close', (code) => {
                    if (code === 0) {
                        console.log('Instagram reel downloaded successfully:', filename);
                        resolve(outputPath);
                    } else {
                        console.error('yt-dlp instagram process exited with code:', code);
                        reject(new Error(`Instagram download failed: ${errorOutput}`));
                    }
                });

                process.on('error', (error) => {
                    console.error('yt-dlp instagram process error:', error);
                    reject(error);
                });
            } catch (error) {
                reject(error);
            }
        });
    }

    // Download YouTube video
    async downloadYouTubeVideo(videoUrl, filename, quality = 'best') {
        return new Promise(async (resolve, reject) => {
            try {
                const ytDlpPath = await this.getYtDlpPath();
                const outputPath = path.join(DOWNLOADS_DIR, filename);
                
                const qualitySelector = quality === 'audio' ? 'bestaudio' : 
                                      quality === 'low' ? 'worst' : 'best';
                
                const args = [
                    '--no-warnings',
                    '--no-playlist',
                    '-f', qualitySelector,
                    '--merge-output-format', 'mp4',
                    '-o', outputPath,
                    videoUrl
                ];

                console.log('Downloading with yt-dlp:', videoUrl);
                
                const process = spawn(ytDlpPath, args);
                let errorOutput = '';

                process.stdout.on('data', (data) => {
                    console.log(`yt-dlp stdout: ${data}`);
                });

                process.stderr.on('data', (data) => {
                    const output = data.toString();
                    console.log(`yt-dlp stderr: ${output}`);
                    errorOutput += output;
                });

                process.on('close', (code) => {
                    if (code === 0) {
                        console.log('Video downloaded successfully:', filename);
                        resolve(outputPath);
                    } else {
                        console.error('yt-dlp process exited with code:', code);
                        reject(new Error(`Download failed: ${errorOutput}`));
                    }
                });

                process.on('error', (error) => {
                    console.error('yt-dlp process error:', error);
                    reject(error);
                });
            } catch (error) {
                reject(error);
            }
        });
    }

    // Download audio only
    async downloadAudio(videoUrl, filename) {
        return new Promise(async (resolve, reject) => {
            try {
                const ytDlpPath = await this.getYtDlpPath();
                const outputPath = path.join(DOWNLOADS_DIR, filename);
                
                const args = [
                    '--no-warnings',
                    '--no-playlist',
                    '-f', 'bestaudio',
                    '--extract-audio',
                    '--audio-format', 'mp3',
                    '--audio-quality', '192K',
                    '-o', outputPath,
                    videoUrl
                ];

                const process = spawn(ytDlpPath, args);
                let errorOutput = '';

                process.stdout.on('data', (data) => {
                    console.log(`yt-dlp audio stdout: ${data}`);
                });

                process.stderr.on('data', (data) => {
                    const output = data.toString();
                    console.log(`yt-dlp audio stderr: ${output}`);
                    errorOutput += output;
                });

                process.on('close', (code) => {
                    if (code === 0) {
                        console.log('Audio downloaded successfully:', filename);
                        resolve(outputPath);
                    } else {
                        console.error('yt-dlp audio process exited with code:', code);
                        reject(new Error(`Audio download failed: ${errorOutput}`));
                    }
                });

                process.on('error', (error) => {
                    console.error('yt-dlp audio process error:', error);
                    reject(error);
                });
            } catch (error) {
                reject(error);
            }
        });
    }

    // Get video info
    async getVideoInfo(videoUrl) {
        try {
            const ytDlpPath = await this.getYtDlpPath();
            let command;
            if (this.isValidInstagramUrl(videoUrl)) {
                const cleanUrl = this.cleanInstagramUrl(videoUrl);
                command = `"${ytDlpPath}" --dump-json --user-agent "${this.userAgent}" --no-check-certificate "${cleanUrl}"`;
            } else {
                command = `"${ytDlpPath}" --dump-json "${videoUrl}"`;
            }
            
            const { stdout } = await execAsync(command);
            const info = JSON.parse(stdout.trim());
            
            return {
                title: info.title || 'Video',
                duration: info.duration,
                uploader: info.uploader || info.uploader_id || 'Unknown',
                thumbnail: info.thumbnail,
                id: info.id,
                description: info.description || '',
                upload_date: info.upload_date,
                view_count: info.view_count,
                like_count: info.like_count
            };
        } catch (error) {
            console.error('Error getting video info:', error.message);
            return null;
        }
    }

    // Check if yt-dlp is available
    async checkYtDlp() {
        try {
            await this.getYtDlpPath();
            return true;
        } catch (error) {
            console.log('yt-dlp not found');
            return false;
        }
    }

    // Install yt-dlp
    async installYtDlp() {
        try {
            console.log('Installing yt-dlp...');
            
            // Create yt-dlp directory in app folder
            const ytDlpDir = path.join(__dirname, 'yt-dlp');
            if (!fs.existsSync(ytDlpDir)) {
                fs.mkdirSync(ytDlpDir, { recursive: true });
            }
            
            const ytDlpPath = path.join(ytDlpDir, 'yt-dlp');
            
            // Try multiple installation methods
            const methods = [
                // Method 1: Using curl to download binary to app directory
                async () => {
                    console.log('Trying curl method...');
                    await execAsync(`curl -L https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp -o ${ytDlpPath}`);
                    await execAsync(`chmod +x ${ytDlpPath}`);
                    console.log(`yt-dlp installed to: ${ytDlpPath}`);
                },
                // Method 2: Using wget to download binary to app directory
                async () => {
                    console.log('Trying wget method...');
                    await execAsync(`wget https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp -O ${ytDlpPath}`);
                    await execAsync(`chmod +x ${ytDlpPath}`);
                    console.log(`yt-dlp installed to: ${ytDlpPath}`);
                },
                // Method 3: Using npm package (fallback)
                async () => {
                    console.log('Trying npm method...');
                    await execAsync('npm install -g yt-dlp');
                },
                // Method 4: Using pip (original method)
                async () => {
                    console.log('Trying pip method...');
                    await execAsync('pip install --upgrade yt-dlp');
                }
            ];

            let installed = false;
            for (const method of methods) {
                try {
                    await method();
                    console.log('yt-dlp installed successfully');
                    installed = true;
                    break;
                } catch (error) {
                    console.log(`Installation method failed: ${error.message}`);
                    continue;
                }
            }

            if (!installed) {
                throw new Error('All installation methods failed');
            }

            return true;
        } catch (error) {
            console.error('Failed to install yt-dlp:', error.message);
            return false;
        }
    }
}

const downloader = new VideoDownloader();

// Initialize yt-dlp on startup
(async () => {
    const isInstalled = await downloader.checkYtDlp();
    if (!isInstalled) {
        await downloader.installYtDlp();
    }
})();

// Root endpoint
app.get('/', (req, res) => {
    res.json({ 
        message: 'Video Downloader API',
        version: '1.0.0',
        endpoints: [
            'POST /video/info',
            'POST /download/youtube',
            'POST /download/instagram',
            'POST /download/auto',
            'GET /health'
        ]
    });
});

// Health check
app.get('/health', async (req, res) => {
    const ytDlpStatus = await downloader.checkYtDlp();
    
    res.json({ 
        status: 'healthy', 
        message: 'Video Downloader Backend is running!',
        timestamp: new Date().toISOString(),
        uptime: process.uptime(),
        ytDlpInstalled: ytDlpStatus,
        supportedPlatforms: ['YouTube', 'Instagram']
    });
});

// Get video information
app.post('/video/info', async (req, res) => {
    try {
        const { url } = req.body;

        if (!url) {
            return res.status(400).json({ error: 'URL is required' });
        }

        if (!downloader.isValidYouTubeUrl(url) && !downloader.isValidInstagramUrl(url)) {
            return res.status(400).json({ error: 'Invalid YouTube or Instagram URL' });
        }

        console.log('Getting video info for:', url);

        const info = await downloader.getVideoInfo(url);

        if (!info) {
            return res.status(400).json({ 
                error: 'Could not get video information. The video might be private or unavailable.' 
            });
        }

        res.json({
            success: true,
            info: {
                title: info.title,
                duration: info.duration,
                uploader: info.uploader,
                thumbnail: info.thumbnail,
                id: info.id,
                upload_date: info.upload_date,
                description: info.description ? info.description.substring(0, 200) + '...' : '',
                view_count: info.view_count,
                like_count: info.like_count
            }
        });

    } catch (error) {
        console.error('Video info error:', error);
        res.status(500).json({ error: `Server error: ${error.message}` });
    }
});

// Download Instagram Reel
app.post('/download/instagram', async (req, res) => {
    try {
        const { url, quality = 'best' } = req.body;

        if (!url) {
            return res.status(400).json({ error: 'URL is required' });
        }

        if (!downloader.isValidInstagramUrl(url)) {
            return res.status(400).json({ error: 'Invalid Instagram URL' });
        }

        console.log('Processing Instagram URL:', url);

        // Get video info first
        const info = await downloader.getVideoInfo(url);
        const title = info?.title || 'Instagram_Reel';

        // Generate filename
        const sanitizedTitle = title.replace(/[^a-zA-Z0-9]/g, '_').substring(0, 50);
        const filename = `${sanitizedTitle}_${uuidv4().slice(0, 8)}.mp4`;

        // Download Instagram reel
        const filePath = await downloader.downloadInstagramReel(url, filename);

        if (filePath && fs.existsSync(filePath)) {
            const stats = fs.statSync(filePath);
            const fileUrl = `http://localhost:${PORT}/file/${filename}`;
            
            res.json({
                success: true,
                fileUrl: fileUrl,
                filename: filename,
                title: title,
                duration: info?.duration,
                uploader: info?.uploader,
                type: 'video',
                quality: quality,
                size: stats.size,
                message: 'Instagram reel downloaded successfully'
            });
        } else {
            res.status(500).json({ error: 'Failed to download Instagram reel. Please try again.' });
        }

    } catch (error) {
        console.error('Instagram download error:', error);
        res.status(500).json({ error: `Server error: ${error.message}` });
    }
});

// Download YouTube video
app.post('/download/youtube', async (req, res) => {
    try {
        const { url, quality = 'best', type = 'video' } = req.body;

        if (!url) {
            return res.status(400).json({ error: 'URL is required' });
        }

        if (!downloader.isValidYouTubeUrl(url)) {
            return res.status(400).json({ error: 'Invalid YouTube URL' });
        }

        console.log('Processing YouTube URL:', url, 'Quality:', quality, 'Type:', type);

        // Get video info first
        const info = await downloader.getVideoInfo(url);
        if (!info) {
            return res.status(400).json({ 
                error: 'Could not get video information. The video might be private or unavailable.' 
            });
        }

        // Generate filename
        const sanitizedTitle = info.title.replace(/[^a-zA-Z0-9]/g, '_').substring(0, 50);
        const extension = type === 'audio' ? 'mp3' : 'mp4';
        const filename = `${sanitizedTitle}_${uuidv4().slice(0, 8)}.${extension}`;

        // Download video or audio
        let filePath;
        if (type === 'audio') {
            filePath = await downloader.downloadAudio(url, filename);
        } else {
            filePath = await downloader.downloadYouTubeVideo(url, filename, quality);
        }

        if (filePath && fs.existsSync(filePath)) {
            const stats = fs.statSync(filePath);
            const fileUrl = `http://localhost:${PORT}/file/${filename}`;
            
            res.json({
                success: true,
                fileUrl: fileUrl,
                filename: filename,
                title: info.title,
                duration: info.duration,
                uploader: info.uploader,
                type: type,
                quality: quality,
                size: stats.size,
                message: `YouTube ${type} downloaded successfully`
            });
        } else {
            res.status(500).json({ error: 'Failed to download video. Please try again.' });
        }

    } catch (error) {
        console.error('YouTube download error:', error);
        res.status(500).json({ error: `Server error: ${error.message}` });
    }
});

// Auto-detect platform and download
app.post('/download/auto', async (req, res) => {
    try {
        const { url, quality = 'best', type = 'video' } = req.body;

        if (!url) {
            return res.status(400).json({ error: 'URL is required' });
        }

        if (downloader.isValidYouTubeUrl(url)) {
            // Handle YouTube download
            req.body = { url, quality, type };
            return app.handle({ ...req, url: '/download/youtube', method: 'POST' }, res);
        } else if (downloader.isValidInstagramUrl(url)) {
            // Handle Instagram download
            req.body = { url, quality };
            return app.handle({ ...req, url: '/download/instagram', method: 'POST' }, res);
        } else {
            return res.status(400).json({ error: 'Unsupported URL. Please provide a valid YouTube or Instagram URL.' });
        }

    } catch (error) {
        console.error('Auto download error:', error);
        res.status(500).json({ error: `Server error: ${error.message}` });
    }
});

// List files
app.get('/files', (req, res) => {
    try {
        const files = fs.readdirSync(DOWNLOADS_DIR);
        const fileList = files.map(filename => {
            const filePath = path.join(DOWNLOADS_DIR, filename);
            const stats = fs.statSync(filePath);
            return {
                filename: filename,
                size: stats.size,
                created: stats.birthtime,
                downloadUrl: `http://localhost:${PORT}/file/${filename}`
            };
        });
        
        res.json({ files: fileList, count: fileList.length });
    } catch (error) {
        res.status(500).json({ error: `Error listing files: ${error.message}` });
    }
});

// Delete file
app.delete('/file/:filename', (req, res) => {
    try {
        const filename = req.params.filename;
        const filePath = path.join(DOWNLOADS_DIR, filename);
        
        if (fs.existsSync(filePath)) {
            fs.unlinkSync(filePath);
            res.json({ message: 'File deleted successfully' });
        } else {
            res.status(404).json({ error: 'File not found' });
        }
    } catch (error) {
        res.status(500).json({ error: `Error deleting file: ${error.message}` });
    }
});

// 404 handler - MUST be last
app.use('*', (req, res) => {
    console.log(`404 - Route not found: ${req.method} ${req.originalUrl}`);
    res.status(404).json({ 
        error: 'API endpoint not found',
        availableEndpoints: [
            'GET /',
            'GET /health',
            'POST /video/info',
            'POST /download/youtube',
            'POST /download/instagram',
            'POST /download/auto',
            'GET /files',
            'DELETE /file/:filename'
        ]
    });
});

// Start server
app.listen(PORT, '0.0.0.0', () => {
    console.log(`🚀 Video Downloader Backend is running on port ${PORT}`);
    console.log('DOWNLOADS_DIR:', DOWNLOADS_DIR);
    console.log(`📁 Downloads directory: ${DOWNLOADS_DIR}`);
    console.log(`🔗 Health check: http://localhost:${PORT}/health`);
    console.log('\n📋 Available endpoints:');
    console.log('  GET  / - API information');
    console.log('  GET  /health - Health check');
    console.log('  POST /video/info - Get video information');
    console.log('  POST /download/youtube - Download YouTube video/audio');
    console.log('  POST /download/instagram - Download Instagram reel');
    console.log('  POST /download/auto - Auto-detect and download');
    console.log('  GET  /files - List downloaded files');
    console.log('  DELETE /file/:filename - Delete file');
});

// Graceful shutdown
process.on('SIGINT', () => {
    console.log('\n🛑 Shutting down gracefully...');
    process.exit(0);
});