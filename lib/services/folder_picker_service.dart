import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FolderPickerService {
  static const platform = MethodChannel('com.example.smart_saver/folderPicker');
  static const _folderUriKey = 'whatsapp_status_folder_uri';

  /// Get the saved folder URI from SharedPreferences
  static Future<String?> getSavedFolderUri() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_folderUriKey);
  }

  /// Pick a folder using Android's Storage Access Framework
  static Future<String?> pickFolder() async {
    try {
      final uri = await platform.invokeMethod<String>('pickFolder');
      if (uri != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_folderUriKey, uri);
        return uri;
      }
      return null;
    } on PlatformException catch (e) {
      print("Error picking folder: ${e.message}");
      return null;
    }
  }

  /// List files in the selected folder
  static Future<List<String>> listFiles(String uri) async {
    try {
      final result = await platform.invokeMethod<List<dynamic>>(
        'listFiles',
        {'uri': uri},
      );
      return result?.cast<String>() ?? [];
    } on PlatformException catch (e) {
      print("Error listing files: ${e.message}");
      return [];
    }
  }

  /// Get file URI for a specific file in the folder
  static Future<String?> getFileUri(String folderUri, String fileName) async {
    try {
      final result = await platform.invokeMethod<String>(
        'getFileUri',
        {'folderUri': folderUri, 'fileName': fileName},
      );
      return result;
    } on PlatformException catch (e) {
      print("Error getting file URI: ${e.message}");
      return null;
    }
  }

  /// Copy file to a temporary location for sharing/saving
  static Future<String?> copyFileToTemp(String fileUri) async {
    try {
      final result = await platform.invokeMethod<String>(
        'copyFileToTemp',
        {'fileUri': fileUri},
      );
      return result;
    } on PlatformException catch (e) {
      print("Error copying file: ${e.message}");
      return null;
    }
  }

  /// Clear the saved folder URI
  static Future<void> clearSavedFolder() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_folderUriKey);
  }
}

