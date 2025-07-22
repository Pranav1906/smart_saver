import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';

class DownloadController {
  // Request storage permissions
  static Future<bool> requestStoragePermission() async {
    if (Platform.isAndroid) {
      if (await isAndroid11OrAbove()) {
        var manageStatus = await Permission.manageExternalStorage.status;
        if (manageStatus != PermissionStatus.granted) {
          manageStatus = await Permission.manageExternalStorage.request();
        }
        return manageStatus == PermissionStatus.granted;
      } else {
        var status = await Permission.storage.status;
        if (status != PermissionStatus.granted) {
          status = await Permission.storage.request();
        }
        return status == PermissionStatus.granted;
      }
    }
    return true;
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
      if (await isAndroid11OrAbove()) {
        try {
          downloadPath = '/storage/emulated/0/Download/SmartSaver';
          final testDir = Directory(downloadPath);
          if (!await testDir.exists()) {
            await testDir.create(recursive: true);
          }
        } catch (e) {
          final directory = await getExternalStorageDirectory();
          downloadPath = '${directory!.path}/SmartSaver';
        }
      } else {
        try {
          downloadPath = '/storage/emulated/0/Download/SmartSaver';
        } catch (e) {
          final directory = await getExternalStorageDirectory();
          downloadPath = '${directory!.path}/SmartSaver';
        }
      }
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