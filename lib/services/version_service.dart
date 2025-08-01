import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import '../config/api_config.dart';

class VersionService {
  static const String _versionCheckEndpoint = '/version/check';
  
  // Check for app updates
  static Future<UpdateInfo?> checkForUpdates() async {
    try {
      // Get current app version
      PackageInfo packageInfo = await PackageInfo.fromPlatform();
      String version = packageInfo.version;
      String buildNumber = packageInfo.buildNumber;
      String platform = Platform.isAndroid ? 'android' : 'ios';
      
      // Make API request to check version
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}$_versionCheckEndpoint'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'version': version,
          'build_number': int.parse(buildNumber),
          'platform': platform,
        }),
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return UpdateInfo.fromJson(data);
      } else {
        print('Version check failed: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error checking for updates: $e');
      return null;
    }
  }
  
  // Show update dialog
  static Future<void> showUpdateDialog(BuildContext context, UpdateInfo updateInfo) async {
    return showDialog(
      context: context,
      barrierDismissible: !updateInfo.forceUpdate,
      builder: (BuildContext context) {
        return WillPopScope(
          onWillPop: () async => !updateInfo.forceUpdate,
          child: AlertDialog(
            title: Text(
              updateInfo.title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(updateInfo.message),
                const SizedBox(height: 16),
                if (updateInfo.updateType == UpdateType.recommended)
                  Text(
                    'Current Version: ${updateInfo.currentVersion}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                if (updateInfo.updateType == UpdateType.recommended)
                  Text(
                    'Latest Version: ${updateInfo.minimumVersion}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
              ],
            ),
            actions: [
              if (updateInfo.updateType != UpdateType.force)
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text(updateInfo.laterButtonText),
                ),
              ElevatedButton(
                onPressed: () async {
                  await _launchStore(updateInfo.storeUrl);
                  if (updateInfo.forceUpdate) {
                    // Exit app if force update
                    Navigator.of(context).pop();
                    exit(0);
                  } else {
                    Navigator.of(context).pop();
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: updateInfo.forceUpdate ? Colors.red : Colors.blue,
                ),
                child: Text(
                  updateInfo.updateButtonText,
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
  
  // Launch store URL
  static Future<void> _launchStore(String storeUrl) async {
    try {
      final Uri url = Uri.parse(storeUrl);
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        print('Could not launch store URL: $storeUrl');
      }
    } catch (e) {
      print('Error launching store: $e');
    }
  }
  
  // Check and show update dialog if needed
  static Future<void> checkAndShowUpdateDialog(BuildContext context) async {
    try {
      final updateInfo = await checkForUpdates();
      if (updateInfo != null && updateInfo.updateRequired) {
        await showUpdateDialog(context, updateInfo);
      }
    } catch (e) {
      print('Error in checkAndShowUpdateDialog: $e');
    }
  }
}

// Update information model
class UpdateInfo {
  final bool updateRequired;
  final bool forceUpdate;
  final UpdateType updateType;
  final String currentVersion;
  final String minimumVersion;
  final String storeUrl;
  final String message;
  final String title;
  final String updateButtonText;
  final String laterButtonText;
  
  UpdateInfo({
    required this.updateRequired,
    required this.forceUpdate,
    required this.updateType,
    required this.currentVersion,
    required this.minimumVersion,
    required this.storeUrl,
    required this.message,
    required this.title,
    required this.updateButtonText,
    required this.laterButtonText,
  });
  
  factory UpdateInfo.fromJson(Map<String, dynamic> json) {
    return UpdateInfo(
      updateRequired: json['update_required'] ?? false,
      forceUpdate: json['force_update'] ?? false,
      updateType: _parseUpdateType(json['update_type']),
      currentVersion: json['current_version'] ?? '',
      minimumVersion: json['minimum_version'] ?? '',
      storeUrl: json['store_url'] ?? '',
      message: json['message'] ?? '',
      title: json['title'] ?? '',
      updateButtonText: json['update_button_text'] ?? 'Update',
      laterButtonText: json['later_button_text'] ?? 'Later',
    );
  }
  
  static UpdateType _parseUpdateType(String? type) {
    switch (type) {
      case 'force':
        return UpdateType.force;
      case 'recommended':
        return UpdateType.recommended;
      case 'optional':
        return UpdateType.optional;
      default:
        return UpdateType.optional;
    }
  }
}

enum UpdateType {
  force,
  recommended,
  optional,
} 