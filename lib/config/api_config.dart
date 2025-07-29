class ApiConfig {
  // Development URL (for Android emulator)
  static const String devBaseUrl = 'http://10.0.2.2:3000';
  
  // Production URL (set to your deployed Railway domain)
  static const String prodBaseUrl = 'https://smartsaver-production.up.railway.app';
  
  // Set environment to 'production' for live deployment
  static const String environment = 'production';
  
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
Production API is now set to:
https://smartsaver-production.up.railway.app

To switch back to development, change 'environment' to 'development'.
*/