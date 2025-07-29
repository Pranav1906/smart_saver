class ApiConfig {
  // Development URL (for Android emulator)
  static const String devBaseUrl = 'http://10.0.2.2:3000';
  
  // Production URL (replace with your Railway URL after deployment)
  // Example: https://smart-saver-backend.up.railway.app
  // Get this URL from your Railway dashboard after deployment
  // Your app is running on port 8080, so the URL will be like:
  // https://your-app-name.up.railway.app
  static const String prodBaseUrl = 'https://your-app-name.up.railway.app';
  
  // Current environment - change this to 'production' after deployment
  static const String environment = 'development';
  
  // Get the current base URL based on environment
  static String get baseUrl {
    return environment == 'production' ? prodBaseUrl : devBaseUrl;
  }
  
  // API endpoints
  static String get healthCheck => '$baseUrl/health';
  static String get videoInfo => '$baseUrl/video/info';
  static String get downloadYoutube => '$baseUrl/download/youtube';
  static String get downloadInstagram => '$baseUrl/download/instagram';
  static String get downloadAuto => '$baseUrl/download/auto';
  static String get files => '$baseUrl/files';
  static String deleteFile(String filename) => '$baseUrl/file/$filename';
  static String getFile(String filename) => '$baseUrl/file/$filename';
}

/*
RAILWAY DEPLOYMENT STATUS:
✅ Server deployed successfully on Railway
✅ Running on port 8080
✅ Health endpoint working
❌ yt-dlp installation needs fix (updated code provided)

NEXT STEPS:
1. Redeploy with updated yt-dlp installation code
2. Get your Railway URL from dashboard
3. Replace 'your-app-name.up.railway.app' with your actual Railway URL
4. Change environment from 'development' to 'production'
5. Test the complete setup

CURRENT RAILWAY URL FORMAT:
https://your-app-name.up.railway.app

TEST HEALTH ENDPOINT:
https://your-app-name.up.railway.app/health
*/