import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/api_config.dart';

enum PlatformType {
  instagram,
  facebook,
  unknown,
}

class DownloadService {
  static PlatformType detectPlatform(String url) {
    final lowerUrl = url.toLowerCase();
    
    if (lowerUrl.contains('instagram.com') || lowerUrl.contains('instagr.am')) {
      return PlatformType.instagram;
    } else if (lowerUrl.contains('facebook.com') || lowerUrl.contains('fb.watch')) {
      return PlatformType.facebook;
    }
    
    return PlatformType.unknown;
  }

  static bool isValidReelUrl(String url, PlatformType platform) {
    final lowerUrl = url.toLowerCase();
    
    switch (platform) {
      case PlatformType.instagram:
        // Instagram reels can be /reel/ or /p/ (posts with videos)
        return lowerUrl.contains('/reel/') || lowerUrl.contains('/p/');
      
      case PlatformType.facebook:
        // Facebook videos can be various formats
        return lowerUrl.contains('/video/') || 
               lowerUrl.contains('/watch/') || 
               lowerUrl.contains('?v=') ||
               lowerUrl.contains('fb.watch');
      
      case PlatformType.unknown:
        return false;
    }
  }

  static String getApiEndpoint(PlatformType platform) {
    switch (platform) {
      case PlatformType.instagram:
        return ApiConfig.downloadInstagram;
      case PlatformType.facebook:
        return ApiConfig.downloadFacebook;
      case PlatformType.unknown:
        throw ArgumentError('Unknown platform type');
    }
  }

  static String getPlatformName(PlatformType platform) {
    switch (platform) {
      case PlatformType.instagram:
        return 'Instagram';
      case PlatformType.facebook:
        return 'Facebook';
      case PlatformType.unknown:
        return 'Unknown';
    }
  }

  static String getPlatformHint(PlatformType platform) {
    switch (platform) {
      case PlatformType.instagram:
        return 'e.g., https://instagram.com/reel/... or https://instagram.com/p/...';
      case PlatformType.facebook:
        return 'e.g., https://facebook.com/watch?v=... or https://fb.watch/...';
      case PlatformType.unknown:
        return 'Enter Instagram or Facebook video URL';
    }
  }

  static Future<Map<String, dynamic>> downloadVideo(String url, PlatformType platform) async {
    final endpoint = getApiEndpoint(platform);
    
    try {
      final response = await http.post(
        Uri.parse(endpoint),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'url': url, 'quality': 'best'}),
      ).timeout(const Duration(seconds: 45));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['error'] ?? 'Download failed');
      }
    } catch (e) {
      if (e is http.Response) {
        final errorData = json.decode(e.body);
        throw Exception(errorData['error'] ?? 'Download failed');
      }
      throw Exception(e.toString());
    }
  }

  static String getErrorMessage(String error, PlatformType platform) {
    final platformName = getPlatformName(platform);
    
    if (error.contains('does not contain a video')) {
      return 'This $platformName post has no video. Try with a reel or video post.';
    } else if (error.contains('unavailable') || error.contains('private')) {
      return 'Video is private or unavailable. Try with a public post.';
    } else if (error.contains('authentication') || error.contains('Sign in')) {
      return 'This post is private. Try with a public $platformName post.';
    } else if (error.contains('temporarily blocking') || error.contains('rate limit') || error.contains('try again later')) {
      return '$platformName is blocking downloads. Try again in a few minutes.';
    } else {
      return 'Failed: $error';
    }
  }
} 