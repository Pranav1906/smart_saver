# Smart Saver Backend Deployment Guide

## Railway Deployment

This backend is configured to deploy on Railway with proper system dependencies.

### Key Files

- `nixpacks.toml` - Configures system dependencies (yt-dlp, python3, ffmpeg)
- `package.json` - Node.js dependencies and scripts
- `server.js` - Main server application
- `railway.json` - Railway-specific deployment configuration

### System Dependencies

The following system packages are installed via Nixpacks:
- `yt-dlp` - YouTube/Instagram video downloader
- `python3` - Required by yt-dlp
- `ffmpeg` - Video processing (used by yt-dlp)

### Deployment Process

1. **Build Phase**: Nixpacks installs system dependencies
2. **Install Phase**: `npm install` installs Node.js dependencies
3. **Start Phase**: `npm start` runs the server

### Health Check

The `/health` endpoint now includes `ytdlp_status` to verify if yt-dlp is available:
- `available` - yt-dlp is working correctly
- `not_available` - yt-dlp is not found in PATH
- `unknown` - Could not determine status

### Troubleshooting

#### yt-dlp not found error

If you see `/bin/sh: 1: yt-dlp: not found`:

1. Check the health endpoint: `GET /health`
2. Verify the `ytdlp_status` field
3. Redeploy the application to trigger a fresh build
4. Check Railway logs for build errors

#### Common Issues

1. **Build fails**: Check if Nixpacks can access the required packages
2. **Runtime errors**: Verify all dependencies are properly installed
3. **Permission issues**: Ensure the downloads directory is writable

### Local Development

For local development, install yt-dlp manually:

```bash
# macOS
brew install yt-dlp

# Ubuntu/Debian
sudo apt update
sudo apt install yt-dlp

# Windows
# Download from https://github.com/yt-dlp/yt-dlp/releases
```

### API Endpoints

- `GET /health` - Health check with yt-dlp status
- `POST /download/youtube` - Download YouTube videos
- `POST /download/instagram` - Download Instagram reels
- `DELETE /file/:filename` - Delete downloaded files

### Environment Variables

- `PORT` - Server port (default: 8080)
- `NODE_ENV` - Environment (development/production) 