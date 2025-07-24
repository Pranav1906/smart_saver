import 'package:share_plus/share_plus.dart';
import 'dart:io';

class ShareController {
  static Future<void> shareFile(String filePath, {String? text}) async {
    final file = XFile(filePath);
    await Share.shareXFiles([file], text: text);
  }
}
