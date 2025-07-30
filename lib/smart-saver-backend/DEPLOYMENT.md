# Smart Saver Backend Deployment Guide

## Issue Fixed
The original deployment was failing because `yt-dlp` was not properly installed in the Railway environment. The error `/bin/sh: 1: yt-dlp: not found` indicated that the video downloader tool was missing.

## Changes Made

### 1. Added Dockerfile
- Created a proper Dockerfile that installs `yt-dlp` using pip3
- Uses Node.js 18 Alpine as base image for smaller size
- Installs Python3, pip3, and ffmpeg as system dependencies
- Installs yt-dlp globally using pip3

### 2. Updated Railway Configuration
- Changed from `NIXPACKS` to `DOCKERFILE` builder in `railway.json`
- This ensures Railway uses our custom Dockerfile for deployment

### 3. Improved Error Handling
- Added yt-dlp availability checks before attempting downloads
- Enhanced health check endpoint to report yt-dlp status
- Better error messages for debugging

### 4. Removed Problematic postinstall Script
- Removed the `postinstall` script from `package.json` that was trying to install yt-dlp globally
- This approach doesn't work reliably in containerized environments

## Deployment Steps

1. **Commit and Push Changes**
   ```bash
   git add .
   git commit -m "Fix yt-dlp installation with Docker deployment"
   git push
   ```

2. **Redeploy on Railway**
   - Railway will automatically detect the Dockerfile and rebuild the container
   - The new build will properly install yt-dlp

3. **Verify Deployment**
   - Check the health endpoint: `https://your-app.railway.app/health`
   - Look for `ytdlp_status: "available"` in the response

## Testing

After deployment, test with a YouTube URL:
```bash
curl -X POST https://your-app.railway.app/download/youtube \
  -H "Content-Type: application/json" \
  -d '{"url": "https://www.youtube.com/shorts/AVopN7SBY3I"}'
```

## Troubleshooting

If you still see issues:

1. **Check Railway Logs**: Look for any build errors in the Railway dashboard
2. **Verify Docker Build**: The Dockerfile should successfully install yt-dlp
3. **Health Check**: Use the `/health` endpoint to verify yt-dlp status
4. **Manual Test**: Try running `yt-dlp --version` in the Railway shell if available

## Environment Variables

No additional environment variables are required. The Dockerfile handles all necessary installations.

## File Structure

```
smart-saver-backend/
├── Dockerfile          # New: Handles yt-dlp installation
├── railway.json        # Updated: Uses Docker builder
├── package.json        # Updated: Removed postinstall script
├── server.js           # Updated: Better error handling
├── .dockerignore       # Updated: Optimized for Docker
└── DEPLOYMENT.md       # New: This guide
``` 