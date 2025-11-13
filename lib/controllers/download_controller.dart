import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';

class DownloadController {
  // Request storage permissions
  static Future<bool> requestStoragePermission() async {
    if (Platform.isAndroid) {
      if (await isAndroid13OrAbove()) {
        // Android 13+ uses granular media permissions
        var videoStatus = await Permission.videos.status;
        var imageStatus = await Permission.photos.status;
        if (videoStatus != PermissionStatus.granted) {
          videoStatus = await Permission.videos.request();
        }
        if (imageStatus != PermissionStatus.granted) {
          imageStatus = await Permission.photos.request();
        }
        return videoStatus == PermissionStatus.granted || imageStatus == PermissionStatus.granted;
      } else if (await isAndroid11OrAbove()) {
        // Android 11-12: Use app's external storage (no permission needed)
        return true;
      } else {
        // Android 10 and below: Request storage permission
        var status = await Permission.storage.status;
        if (status != PermissionStatus.granted) {
          status = await Permission.storage.request();
        }
        return status == PermissionStatus.granted;
      }
    }
    return true;
  }

  static Future<bool> isAndroid13OrAbove() async {
    if (Platform.isAndroid) {
      var androidInfo = await DeviceInfoPlugin().androidInfo;
      return androidInfo.version.sdkInt >= 33;
    }
    return false;
  }

  static Future<bool> isAndroid11OrAbove() async {
    if (Platform.isAndroid) {
      var androidInfo = await DeviceInfoPlugin().androidInfo;
      return androidInfo.version.sdkInt >= 30;
    }
    return false;
  }

  // Get the appropriate download directory
  static Future<String> getDownloadPath() async {
    String downloadPath;
    if (Platform.isAndroid) {
      // For Android 11+, use app's external storage directory (no special permission needed)
      final directory = await getExternalStorageDirectory();
      downloadPath = '${directory!.path}/SmartSaver';
    } else if (Platform.isIOS) {
      final directory = await getApplicationDocumentsDirectory();
      downloadPath = '${directory.path}/SmartSaver';
    } else {
      final directory = await getApplicationDocumentsDirectory();
      downloadPath = '${directory.path}/SmartSaver';
    }
    final dir = Directory(downloadPath);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return downloadPath;
  }

  // Download and save file
  static Future<String?> downloadAndSaveFile(String fileUrl, String fileName) async {
    final hasPermission = await requestStoragePermission();
    if (!hasPermission) return null;

    final tempDir = await getTemporaryDirectory();
    final tempFilePath = '${tempDir.path}/$fileName';

    final downloadPath = await getDownloadPath();
    final permanentFilePath = '$downloadPath/$fileName';

    // Download to temp
    await Dio().download(fileUrl, tempFilePath);

    // Copy to permanent
    final tempFile = File(tempFilePath);
    await tempFile.copy(permanentFilePath);

    return tempFilePath;
  }
}