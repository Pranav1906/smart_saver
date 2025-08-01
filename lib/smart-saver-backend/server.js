const express = require('express');
const cors = require('cors');
const fs = require('fs');
const path = require('path');
const { exec } = require('child_process');
const { promisify } = require('util');
const { v4: uuidv4 } = require('uuid');
const { getUpdateInfo } = require('./version_config');

const execAsync = promisify(exec);

// Simple rate limiting for Instagram requests
const instagramRequests = new Map();

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

// Serve admin dashboard
app.get('/admin', (req, res) => {
    res.sendFile(path.join(__dirname, 'admin_dashboard.html'));
});

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
app.get('/health', async (req, res) => {
    try {
        // Check if yt-dlp is available
        let ytdlpStatus = 'unknown';
        let ytdlpVersion = 'unknown';
        try {
            const { stdout } = await execAsync('/opt/venv/bin/yt-dlp --version');
            ytdlpStatus = 'available';
            ytdlpVersion = stdout.trim();
        } catch (error) {
            ytdlpStatus = 'not_available';
        }

        res.json({ 
            status: 'healthy', 
            message: 'Video Downloader Backend is running!',
            timestamp: new Date().toISOString(),
            uptime: process.uptime(),
            port: PORT,
            host: HOST,
            ytdlp_status: ytdlpStatus,
            ytdlp_version: ytdlpVersion
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

// Version check endpoint for force update
app.post('/version/check', (req, res) => {
    try {
        const { version, build_number, platform } = req.body;
        
        if (!version || !build_number || !platform) {
            return res.status(400).json({
                success: false,
                error: 'Version, build_number, and platform are required'
            });
        }
        
        // Validate platform
        if (!['android', 'ios'].includes(platform)) {
            return res.status(400).json({
                success: false,
                error: 'Platform must be android or ios'
            });
        }
        
        const updateInfo = getUpdateInfo(version, build_number, platform);
        
        res.json({
            success: true,
            ...updateInfo
        });
        
    } catch (error) {
        console.error('Error in version check endpoint:', error);
        res.status(500).json({ error: 'Version check failed' });
    }
});

// Admin endpoint to update version configuration
app.post('/admin/version/update', (req, res) => {
    try {
        const { 
            current_version, 
            minimum_version, 
            force_update_enabled,
            message,
            title 
        } = req.body;
        
        // In production, add admin authentication here
        // if (!req.user || req.user.role !== 'admin') {
        //     return res.status(403).json({ error: 'Admin access required' });
        // }
        
        // Update version configuration
        const fs = require('fs');
        const path = require('path');
        
        // Read current config
        const configPath = path.join(__dirname, 'version_config.js');
        let configContent = fs.readFileSync(configPath, 'utf8');
        
        // Update values (simplified - in production, use a proper config management system)
        if (current_version) {
            configContent = configContent.replace(
                /current_version:\s*{[^}]+}/,
                `current_version: ${JSON.stringify(current_version, null, 2)}`
            );
        }
        
        if (minimum_version) {
            configContent = configContent.replace(
                /minimum_version:\s*{[^}]+}/,
                `minimum_version: ${JSON.stringify(minimum_version, null, 2)}`
            );
        }
        
        if (force_update_enabled !== undefined) {
            configContent = configContent.replace(
                /enabled:\s*(true|false)/,
                `enabled: ${force_update_enabled}`
            );
        }
        
        if (message) {
            configContent = configContent.replace(
                /message:\s*'[^']*'/,
                `message: '${message}'`
            );
        }
        
        if (title) {
            configContent = configContent.replace(
                /title:\s*'[^']*'/,
                `title: '${title}'`
            );
        }
        
        // Write updated config
        fs.writeFileSync(configPath, configContent);
        
        // Reload the config module
        delete require.cache[require.resolve('./version_config')];
        const { getUpdateInfo } = require('./version_config');
        
        res.json({
            success: true,
            message: 'Version configuration updated successfully',
            current_config: {
                current_version,
                minimum_version,
                force_update_enabled,
                message,
                title
            }
        });
        
    } catch (error) {
        console.error('Error updating version config:', error);
        res.status(500).json({ error: 'Failed to update version configuration' });
    }
});

// Test YouTube download endpoint
app.post('/test/youtube', async (req, res) => {
    try {
        console.log('Testing YouTube download...');
        
        const { url } = req.body;
        
        if (!url) {
            return res.status(400).json({
                success: false,
                error: 'URL is required for testing'
            });
        }

        // Test the download without actually saving the file
        const testCommand = `/opt/venv/bin/yt-dlp --user-agent "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36" --no-check-certificates --extractor-args "youtube:player_client=android" --add-header "Accept-Language:en-US,en;q=0.9" --add-header "Accept-Encoding:gzip, deflate, br" --add-header "DNT:1" --add-header "Connection:keep-alive" --add-header "Upgrade-Insecure-Requests:1" --get-title --get-duration "${url}"`;
        
        try {
            const { stdout, stderr } = await execAsync(testCommand, { timeout: 30000 });
            
            console.log('Test stdout:', stdout);
            if (stderr) console.log('Test stderr:', stderr);
            
            const lines = stdout.trim().split('\n');
            const title = lines[0] || 'Unknown';
            const duration = lines[1] || 'Unknown';
            
            res.json({
                success: true,
                message: 'YouTube video is accessible',
                title: title,
                duration: duration,
                url: url
            });
        } catch (testError) {
            console.error('Test failed:', testError);
            
            const errorMessage = testError.message || '';
            const stderr = testError.stderr || '';
            
            if (errorMessage.includes('Sign in to confirm you\'re not a bot') || 
                stderr.includes('Sign in to confirm you\'re not a bot')) {
                res.status(400).json({
                    success: false,
                    error: 'YouTube is requiring authentication for this video',
                    details: 'The video may be age-restricted, private, or require login to access'
                });
            } else {
                res.status(500).json({
                    success: false,
                    error: 'Failed to test YouTube video',
                    details: testError.message
                });
            }
        }
    } catch (error) {
        console.error('Error in YouTube test endpoint:', error);
        res.status(500).json({ error: 'YouTube test endpoint failed' });
    }
});

// Test Instagram error handling endpoint
app.post('/test/instagram-error', (req, res) => {
    try {
        console.log('Testing Instagram error handling...');
        
        // Simulate the "no video" error
        const mockError = new Error('Command failed: yt-dlp -o "/app/downloads/test.mp4" "https://www.instagram.com/p/test/";\nERROR: [Instagram] test: There is no video in this post');
        mockError.stderr = 'ERROR: [Instagram] test: There is no video in this post';
        mockError.stdout = '[Instagram] Extracting URL: https://www.instagram.com/p/test/\n[Instagram] test: Setting up session\n[Instagram] test: Downloading JSON metadata';
        
        // Test our error detection logic
        const errorMessage = mockError.message || '';
        const stderr = mockError.stderr || '';
        const stdout = mockError.stdout || '';
        
        console.log('Error message:', errorMessage);
        console.log('Error stderr:', stderr);
        console.log('Error stdout:', stdout);
        
        if (errorMessage.includes('There is no video in this post') || 
            stderr.includes('There is no video in this post') ||
            stdout.includes('There is no video in this post')) {
            console.log('✅ Error detection working correctly');
            res.status(400).json({
                success: false,
                error: 'This Instagram post does not contain a video. Please try with a post that has a video or reel.',
                details: 'The post appears to be an image or text-only post'
            });
        } else {
            console.log('❌ Error detection failed');
            res.status(500).json({
                success: false,
                error: 'Error detection test failed'
            });
        }
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

        // Check if yt-dlp is available
        try {
            await execAsync('/opt/venv/bin/yt-dlp --version');
            console.log('yt-dlp is available');
        } catch (ytdlpError) {
            console.error('yt-dlp is not available:', ytdlpError.message);
            return res.status(500).json({
                success: false,
                error: 'Video downloader is not properly configured. Please contact support.',
                details: 'yt-dlp not found in system'
            });
        }

        // Generate unique filename
        const filename = `youtube_${uuidv4()}.mp4`;
        const outputPath = path.join(DOWNLOADS_DIR, filename);

        console.log(`Starting download for: ${url}`);
        console.log(`Output path: ${outputPath}`);

        // yt-dlp command for YouTube Shorts with enhanced anti-bot measures
        const ytdlpCommand = `/opt/venv/bin/yt-dlp --user-agent "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36" --no-check-certificates --extractor-args "youtube:player_client=android" --add-header "Accept-Language:en-US,en;q=0.9" --add-header "Accept-Encoding:gzip, deflate, br" --add-header "DNT:1" --add-header "Connection:keep-alive" --add-header "Upgrade-Insecure-Requests:1" -f "best[height<=1080]" -o "${outputPath}" "${url}"`;

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
                const fallbackCommand = `/opt/venv/bin/yt-dlp --user-agent "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36" --no-check-certificates --extractor-args "youtube:player_client=android" --add-header "Accept-Language:en-US,en;q=0.9" --add-header "Accept-Encoding:gzip, deflate, br" --add-header "DNT:1" --add-header "Connection:keep-alive" --add-header "Upgrade-Insecure-Requests:1" -f "best" -o "${outputPath}" "${url}"`;
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
                
                // Try third fallback with different approach
                try {
                    console.log('Trying third fallback with mobile user agent...');
                    const thirdFallbackCommand = `/opt/venv/bin/yt-dlp --user-agent "Mozilla/5.0 (Linux; Android 10; SM-G975F) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36" --no-check-certificates --extractor-args "youtube:player_client=android" --add-header "Accept-Language:en-US,en;q=0.9" --add-header "Accept-Encoding:gzip, deflate, br" --add-header "DNT:1" --add-header "Connection:keep-alive" --add-header "Upgrade-Insecure-Requests:1" --format "worst" -o "${outputPath}" "${url}"`;
                    const { stdout, stderr } = await execAsync(thirdFallbackCommand, { timeout: 120000 });
                    
                    console.log('Third fallback yt-dlp stdout:', stdout);
                    if (stderr) console.log('Third fallback yt-dlp stderr:', stderr);

                    if (fs.existsSync(outputPath)) {
                        const stats = fs.statSync(outputPath);
                        const fileSize = (stats.size / (1024 * 1024)).toFixed(2);
                        
                        console.log(`Third fallback download completed: ${filename} (${fileSize} MB)`);
                        
                        const fileUrl = `${req.protocol}://${req.get('host')}/file/${filename}`;
                        
                        res.json({
                            success: true,
                            message: 'Download completed successfully (mobile fallback format)',
                            fileUrl: fileUrl,
                            filename: filename,
                            fileSize: `${fileSize} MB`,
                            originalUrl: url
                        });
                    } else {
                        throw new Error('File was not created after third fallback download');
                    }
                } catch (thirdFallbackError) {
                    console.error('Third fallback download failed:', thirdFallbackError);
                    
                    // Try fourth fallback with different approach - no format selection
                    try {
                        console.log('Trying fourth fallback with no format selection...');
                        const fourthFallbackCommand = `/opt/venv/bin/yt-dlp --user-agent "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36" --no-check-certificates --extractor-args "youtube:player_client=web" --add-header "Accept-Language:en-US,en;q=0.9" --add-header "Accept-Encoding:gzip, deflate, br" --add-header "DNT:1" --add-header "Connection:keep-alive" --add-header "Upgrade-Insecure-Requests:1" -o "${outputPath}" "${url}"`;
                        const { stdout, stderr } = await execAsync(fourthFallbackCommand, { timeout: 120000 });
                        
                        console.log('Fourth fallback yt-dlp stdout:', stdout);
                        if (stderr) console.log('Fourth fallback yt-dlp stderr:', stderr);

                        if (fs.existsSync(outputPath)) {
                            const stats = fs.statSync(outputPath);
                            const fileSize = (stats.size / (1024 * 1024)).toFixed(2);
                            
                            console.log(`Fourth fallback download completed: ${filename} (${fileSize} MB)`);
                            
                            const fileUrl = `${req.protocol}://${req.get('host')}/file/${filename}`;
                            
                            res.json({
                                success: true,
                                message: 'Download completed successfully (web client fallback)',
                                fileUrl: fileUrl,
                                filename: filename,
                                fileSize: `${fileSize} MB`,
                                originalUrl: url
                            });
                        } else {
                            throw new Error('File was not created after fourth fallback download');
                        }
                    } catch (fourthFallbackError) {
                        console.error('Fourth fallback download failed:', fourthFallbackError);
                        
                        // Try fifth fallback with minimal options and different approach
                        try {
                            console.log('Trying fifth fallback with minimal options...');
                            const fifthFallbackCommand = `/opt/venv/bin/yt-dlp --user-agent "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36" --no-check-certificates --extractor-args "youtube:player_client=web" --format "bv*[height<=720]+ba/b[height<=720]" -o "${outputPath}" "${url}"`;
                            const { stdout, stderr } = await execAsync(fifthFallbackCommand, { timeout: 120000 });
                            
                            console.log('Fifth fallback yt-dlp stdout:', stdout);
                            if (stderr) console.log('Fifth fallback yt-dlp stderr:', stderr);

                            if (fs.existsSync(outputPath)) {
                                const stats = fs.statSync(outputPath);
                                const fileSize = (stats.size / (1024 * 1024)).toFixed(2);
                                
                                console.log(`Fifth fallback download completed: ${filename} (${fileSize} MB)`);
                                
                                const fileUrl = `${req.protocol}://${req.get('host')}/file/${filename}`;
                                
                                res.json({
                                    success: true,
                                    message: 'Download completed successfully (minimal options fallback)',
                                    fileUrl: fileUrl,
                                    filename: filename,
                                    fileSize: `${fileSize} MB`,
                                    originalUrl: url
                                });
                            } else {
                                throw new Error('File was not created after fifth fallback download');
                            }
                        } catch (fifthFallbackError) {
                            console.error('Fifth fallback download failed:', fifthFallbackError);
                            
                            // Try sixth fallback with yt-dlp's default behavior
                            try {
                                console.log('Trying sixth fallback with yt-dlp defaults...');
                                const sixthFallbackCommand = `/opt/venv/bin/yt-dlp -o "${outputPath}" "${url}"`;
                                const { stdout, stderr } = await execAsync(sixthFallbackCommand, { timeout: 120000 });
                                
                                console.log('Sixth fallback yt-dlp stdout:', stdout);
                                if (stderr) console.log('Sixth fallback yt-dlp stderr:', stderr);

                                if (fs.existsSync(outputPath)) {
                                    const stats = fs.statSync(outputPath);
                                    const fileSize = (stats.size / (1024 * 1024)).toFixed(2);
                                    
                                    console.log(`Sixth fallback download completed: ${filename} (${fileSize} MB)`);
                                    
                                    const fileUrl = `${req.protocol}://${req.get('host')}/file/${filename}`;
                                    
                                    res.json({
                                        success: true,
                                        message: 'Download completed successfully (default yt-dlp behavior)',
                                        fileUrl: fileUrl,
                                        filename: filename,
                                        fileSize: `${fileSize} MB`,
                                        originalUrl: url
                                    });
                                } else {
                                    throw new Error('File was not created after sixth fallback download');
                                }
                            } catch (sixthFallbackError) {
                                console.error('Sixth fallback download failed:', sixthFallbackError);
                                
                                // Check for specific YouTube errors
                                const errorMessage = sixthFallbackError.message || '';
                                const stderr = sixthFallbackError.stderr || '';
                                
                                if (errorMessage.includes('Sign in to confirm you\'re not a bot') || 
                                    stderr.includes('Sign in to confirm you\'re not a bot')) {
                                    res.status(400).json({
                                        success: false,
                                        error: 'YouTube is requiring authentication for this video. This usually happens with age-restricted or private content.',
                                        details: 'The video may be age-restricted, private, or require login to access',
                                        suggestion: 'Try with a different YouTube video or check if the video is publicly accessible'
                                    });
                                } else if (errorMessage.includes('Failed to extract any player response') || 
                                           stderr.includes('Failed to extract any player response')) {
                                    res.status(400).json({
                                        success: false,
                                        error: 'Unable to extract video information from YouTube. This may be due to recent changes in YouTube\'s API.',
                                        details: 'The video may be unavailable, private, or YouTube has changed their API',
                                        suggestion: 'Try with a different YouTube video or check if the video is publicly accessible'
                                    });
                                } else {
                                    res.status(500).json({
                                        success: false,
                                        error: 'Failed to download video. Please check the URL and try again.',
                                        details: sixthFallbackError.message
                                    });
                                }
                            }
                        }
                    }
                }
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

        // Simple rate limiting - check if we've made too many requests recently
        const now = Date.now();
        const recentRequests = instagramRequests.get('global') || [];
        const oneMinuteAgo = now - 60000; // 1 minute ago
        
        // Remove old requests
        const filteredRequests = recentRequests.filter(timestamp => timestamp > oneMinuteAgo);
        
        // Check if we've made more than 5 requests in the last minute
        if (filteredRequests.length >= 5) {
            return res.status(429).json({
                success: false,
                error: 'Too many Instagram download requests. Please wait a minute before trying again.',
                details: 'Rate limit exceeded',
                retryAfter: 60
            });
        }
        
        // Add current request to tracking
        filteredRequests.push(now);
        instagramRequests.set('global', filteredRequests);

        // Check if yt-dlp is available
        try {
            await execAsync('/opt/venv/bin/yt-dlp --version');
            console.log('yt-dlp is available for Instagram download');
        } catch (ytdlpError) {
            console.error('yt-dlp is not available:', ytdlpError.message);
            return res.status(500).json({
                success: false,
                error: 'Video downloader is not properly configured. Please contact support.',
                details: 'yt-dlp not found in system'
            });
        }

        // Generate unique filename
        const filename = `instagram_${uuidv4()}.mp4`;
        const outputPath = path.join(DOWNLOADS_DIR, filename);

        console.log(`Starting Instagram download for: ${url}`);
        console.log(`Output path: ${outputPath}`);

        // Add a small delay to help with rate limiting
        await new Promise(resolve => setTimeout(resolve, 1000));

        // yt-dlp command for Instagram - using recommended format to avoid warnings
        // Added user-agent to help avoid rate limiting
        const ytdlpCommand = `/opt/venv/bin/yt-dlp --user-agent "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36" -o "${outputPath}" "${url}"`;

        try {
            const { stdout, stderr } = await execAsync(ytdlpCommand, { timeout: 120000 });
            
            console.log('yt-dlp stdout:', stdout);
            if (stderr) console.log('yt-dlp stderr:', stderr);

            // Check if there's an error in the output even if the command didn't throw
            if (stderr && (stderr.includes('There is no video in this post') || 
                          stderr.includes('Video unavailable') || 
                          stderr.includes('Sign in'))) {
                throw new Error(stderr);
            }

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
            
            // Check for specific Instagram errors
            const errorMessage = execError.message || '';
            const stderr = execError.stderr || '';
            const stdout = execError.stdout || '';
            
            console.log('Error message:', errorMessage);
            console.log('Error stderr:', stderr);
            console.log('Error stdout:', stdout);
            
            // Check for "no video" error in various places
            if (errorMessage.includes('There is no video in this post') || 
                stderr.includes('There is no video in this post') ||
                stdout.includes('There is no video in this post')) {
                console.log('Detected "no video" error, returning 400');
                res.status(400).json({
                    success: false,
                    error: 'This Instagram post does not contain a video. Please try with a post that has a video or reel.',
                    details: 'The post appears to be an image or text-only post'
                });
                return;
            } else if (errorMessage.includes('Video unavailable') || stderr.includes('Video unavailable')) {
                console.log('Detected "video unavailable" error, returning 400');
                res.status(400).json({
                    success: false,
                    error: 'This video is unavailable or private. Please check if the post is public.',
                    details: 'The video may be private, deleted, or restricted'
                });
                return;
            } else if (errorMessage.includes('Sign in') || stderr.includes('Sign in')) {
                console.log('Detected "sign in" error, returning 400');
                res.status(400).json({
                    success: false,
                    error: 'This post requires authentication. Please try with a public post.',
                    details: 'Private or restricted content cannot be downloaded'
                });
                return;
            } else if (errorMessage.includes('rate-limit') || stderr.includes('rate-limit') || 
                       errorMessage.includes('login required') || stderr.includes('login required') ||
                       errorMessage.includes('Requested content is not available') || stderr.includes('Requested content is not available')) {
                console.log('Detected rate-limit/authentication error, returning 429');
                res.status(429).json({
                    success: false,
                    error: 'Instagram is temporarily blocking downloads. Please try again later or use a different post.',
                    details: 'Rate limit reached or authentication required',
                    retryAfter: 60 // Suggest retry after 1 minute
                });
                return;
            } else {
                // Try fallback with different format
                try {
                    console.log('Trying fallback download for Instagram...');
                    const fallbackCommand = `/opt/venv/bin/yt-dlp --user-agent "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36" -f "best" -o "${outputPath}" "${url}"`;
                    const { stdout, stderr } = await execAsync(fallbackCommand, { timeout: 120000 });
                    
                    console.log('Fallback yt-dlp stdout:', stdout);
                    if (stderr) console.log('Fallback yt-dlp stderr:', stderr);

                    if (fs.existsSync(outputPath)) {
                        const stats = fs.statSync(outputPath);
                        const fileSize = (stats.size / (1024 * 1024)).toFixed(2);
                        
                        console.log(`Fallback Instagram download completed: ${filename} (${fileSize} MB)`);
                        
                        const fileUrl = `${req.protocol}://${req.get('host')}/file/${filename}`;
                        
                        res.json({
                            success: true,
                            message: 'Instagram download completed successfully (fallback format)',
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
                        error: 'Failed to download Instagram content. Please check the URL and try again.',
                        details: fallbackError.message
                    });
                }
            }
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
            'POST /test/youtube',
            'POST /test/instagram-error',
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
        console.log('  POST /test/youtube - Test YouTube video accessibility');
        console.log('  POST /test/instagram-error - Test Instagram error handling');
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