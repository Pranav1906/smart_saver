# Smart Saver Backend

Backend API for Smart Saver video downloader app supporting YouTube and Instagram video downloads.

## Features

- YouTube video downloads (video and audio)
- Instagram reel downloads
- Video information extraction
- Health check endpoint
- CORS enabled for cross-origin requests

## Railway Deployment

### Prerequisites
- Railway account
- Git repository with this backend code
- Node.js 18+ (specified in package.json)

### Deployment Steps

1. **Connect to Railway**
   - Go to [railway.app](https://railway.app)
   - Sign in with GitHub/GitLab
   - Create new project → "Deploy from GitHub repo"
   - Select your repository

2. **Configure Project**
   - Set **Root Directory** to `lib/smart-saver-backend`
   - This tells Railway where your backend code is located

3. **Environment Variables**
   - Go to your project's "Variables" tab
   - Add the following environment variables:

   ```
   PORT=3000
   NODE_ENV=production
   ```

4. **Deploy**
   - Railway will automatically detect your Node.js app
   - It will install dependencies from `package.json`
   - Start the app using `npm start` (as defined in Procfile)

### Configuration Details

Your `railway.json` is already configured with:
- **Builder**: NIXPACKS (auto-detects Node.js)
- **Start Command**: `npm start`
- **Health Check**: `/health` endpoint
- **Restart Policy**: ON_FAILURE with max 10 retries

### Health Check

The app includes a health check endpoint at `/health` that returns:
```json
{
  "status": "healthy",
  "message": "Video Downloader Backend is running!",
  "timestamp": "2024-01-01T00:00:00.000Z",
  "uptime": 123.456,
  "ytDlpInstalled": true,
  "supportedPlatforms": ["YouTube", "Instagram"]
}
```

### API Endpoints

- `GET /health` - Health check
- `POST /video/info` - Get video information
- `POST /download/instagram` - Download Instagram reel
- `POST /download/youtube` - Download YouTube video
- `POST /download/audio` - Download audio only

### Dependencies

The app automatically installs:
- `yt-dlp` for video downloading
- All Node.js dependencies from `package.json`

### Monitoring

- Railway provides built-in logs and monitoring
- Check the "Deployments" tab for deployment status
- Use "Logs" tab to monitor application logs

### Custom Domain (Optional)

1. Go to your project's "Settings" tab
2. Click "Generate Domain" or add custom domain
3. Update your Flutter app's API configuration with the new domain

## Local Development

```bash
cd lib/smart-saver-backend
npm install
npm run dev
```

The server will start on `http://localhost:3000`