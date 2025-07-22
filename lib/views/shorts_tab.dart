import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:async';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';

class ShortsTab extends StatefulWidget {
  const ShortsTab({Key? key}) : super(key: key);

  @override
  State<ShortsTab> createState() => _ShortsTabState();
}

class _ShortsTabState extends State<ShortsTab> with SingleTickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeInOut);
    _animController.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    _animController.dispose();
    super.dispose();
  }

  Future<bool> _requestStoragePermission() async {
    if (Platform.isAndroid) {
      if (await _isAndroid11OrAbove()) {
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

  Future<bool> _isAndroid11OrAbove() async {
    if (Platform.isAndroid) {
      var androidInfo = await DeviceInfoPlugin().androidInfo;
      return androidInfo.version.sdkInt >= 30;
    }
    return false;
  }

  Future<String> _getDownloadPath() async {
    String downloadPath;
    if (Platform.isAndroid) {
      if (await _isAndroid11OrAbove()) {
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

  Future<void> _handleDownload() async {
    final url = _controller.text.trim();
    if (url.isEmpty) {
      _showSnackBar("Please enter a valid URL");
      return;
    }
    if (!url.contains("youtube.com") && !url.contains("youtu.be")) {
      _showSnackBar("Please enter a valid YouTube Shorts URL", isError: true);
      return;
    }

    final hasPermission = await _requestStoragePermission();
    if (!hasPermission) {
      _showSnackBar('Storage permission is required to save files', isError: true);
      return;
    }

    setState(() => _isLoading = true);
    _showSnackBar("Processing your request... Please wait", isLoading: true);

    http.Response? response;
    try {
      response = await http.post(
        Uri.parse('http://10.0.2.2:3000/download/youtube'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'url': url, 'quality': 'best', 'type': 'video'}),
      ).timeout(const Duration(seconds: 45));
    } on SocketException {
      _showSnackBar('Network error. Check your connection.', isError: true);
      setState(() => _isLoading = false);
      return;
    } on TimeoutException {
      _showSnackBar('Request timed out. Please try again.', isError: true);
      setState(() => _isLoading = false);
      return;
    } catch (e) {
      _showSnackBar('Error: ${e.toString()}', isError: true);
      setState(() => _isLoading = false);
      return;
    }

    try {
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final fileUrl = data['fileUrl'];
        final originalFileName = data['filename'] ?? fileUrl.split('/').last;

        _showSnackBar("Download complete! Saving to device...", isSuccess: true);
        _controller.clear();

        await Future.delayed(const Duration(milliseconds: 500));
        try {
          final correctedFileUrl = fileUrl.replaceAll('localhost:3000', '10.0.2.2:3000');
          final tempDir = await getTemporaryDirectory();
          final tempFilePath = '${tempDir.path}/$originalFileName';
          final downloadPath = await _getDownloadPath();
          final permanentFilePath = '$downloadPath/$originalFileName';

          _showSnackBar("Downloading file...", isLoading: true);
          await Dio().download(correctedFileUrl, tempFilePath);

          final tempFile = File(tempFilePath);
          await tempFile.copy(permanentFilePath);

          _showSnackBar("File saved to Downloads/SmartSaver folder", isSuccess: true);

          try {
            await OpenFile.open(tempFilePath);
          } catch (e) {
            _showSnackBar("File saved to: Downloads/SmartSaver/$originalFileName", isSuccess: true);
          }
        } on SocketException {
          _showSnackBar('Network error. Check your connection.', isError: true);
        } on TimeoutException {
          _showSnackBar('Request timed out. Please try again.', isError: true);
        } catch (e) {
          _showSnackBar('Download failed: ${e.toString()}', isError: true);
        }
      } else {
        final err = json.decode(response.body);
        _showSnackBar('Failed: ${err['error'] ?? 'Unknown error'}', isError: true);
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message, {bool isError = false, bool isSuccess = false, bool isLoading = false}) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            if (isLoading)
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            else if (isSuccess)
              const Icon(Icons.check_circle, color: Colors.white, size: 20)
            else if (isError)
              const Icon(Icons.error, color: Colors.white, size: 20)
            else
              const Icon(Icons.info, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        backgroundColor: isError
            ? Colors.red.shade600
            : isSuccess
                ? Colors.green.shade600
                : Colors.blue.shade600,
        duration: Duration(seconds: isLoading ? 10 : 4),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  String _getPlatformHint() => 'e.g., https://youtube.com/shorts/...';

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnim,
      child: Center(
        child: SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.10),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
              border: Border.all(color: Colors.white24, width: 1.5),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(
                    Icons.play_circle_fill,
                    size: 48,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Download Shorts',
                  style: GoogleFonts.montserrat(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Paste your YouTube Shorts link below:',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.white70,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.5,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: _controller,
                  style: const TextStyle(color: Colors.black87, fontSize: 16),
                  cursorColor: Colors.black,
                  maxLines: 3,
                  minLines: 1,
                  decoration: InputDecoration(
                    hintText: _getPlatformHint(),
                    hintStyle: const TextStyle(color: Colors.black45, fontSize: 14),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.9),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: Colors.black26, width: 1.5),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: Colors.black26, width: 1.2),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: Color(0xFF185A9D), width: 2),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                  ),
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _handleDownload,
                    icon: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF185A9D)),
                          )
                        : const Icon(Icons.download, color: Color(0xFF185A9D)),
                    label: Text(
                      _isLoading ? 'Processing...' : 'Download & Save',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        letterSpacing: 1.1,
                        color: Colors.black,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isLoading ? Colors.grey.shade300 : Colors.white,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: _isLoading ? 2 : 6,
                      shadowColor: Colors.black.withOpacity(0.15),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, color: Colors.lightBlue, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          Platform.isAndroid
                              ? 'Files will be saved to Downloads/SmartSaver folder'
                              : 'Files will be saved to app documents',
                          style: const TextStyle(
                            color: Colors.lightBlue,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}