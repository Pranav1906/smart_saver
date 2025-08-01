class ApiConfig {
  // Railway backend URL
  static const String baseUrl = 'https://smartsaver-production.up.railway.app';
  
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
Railway Backend API: https://smartsaver-production.up.railway.app

All API requests will go directly to the Railway backend.
*/