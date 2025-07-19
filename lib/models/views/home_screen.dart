import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';
import 'package:dio/dio.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:async';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        extendBodyBehindAppBar: true,
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(
            'Smart Saver',
            style: GoogleFonts.montserrat(
              fontWeight: FontWeight.w900,
              fontSize: 28,
              letterSpacing: 2,
              color: const Color(0xFF102542),
              shadows: [
                Shadow(
                  color: Colors.black.withOpacity(0.10),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
          ),
          centerTitle: true,
          backgroundColor: Colors.transparent,
          elevation: 0,
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF43CEA2), Color(0xFF185A9D)],
              ),
            ),
          ),
          bottom: const TabBar(
            indicatorColor: Colors.white,
            indicatorWeight: 4,
            labelColor: Colors.black,
            unselectedLabelColor: Colors.black54,
            labelStyle: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              letterSpacing: 1,
            ),
            tabs: [
              Tab(text: 'Reels'),
              Tab(text: 'Shorts'),
              Tab(text: 'WhatsApp'),
            ],
          ),
        ),
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF43CEA2), Color(0xFF185A9D)],
            ),
          ),
          child: const TabBarView(
            children: [
              _DownloadTab(platform: 'Reels'),
              _DownloadTab(platform: 'Shorts'),
              _DownloadTab(platform: 'WhatsApp'),
            ],
          ),
        ),
      ),
    );
  }
}

class _DownloadTab extends StatefulWidget {
  final String platform;
  const _DownloadTab({required this.platform});

  @override
  State<_DownloadTab> createState() => _DownloadTabState();
}

class _DownloadTabState extends State<_DownloadTab> with SingleTickerProviderStateMixin {
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

  Future<void> _handleDownload() async {
    final url = _controller.text.trim();

    if (url.isEmpty) {
      _showSnackBar("Please enter a valid URL");
      return;
    }

    String endpoint = '';
    String validationError = "";
    
    switch (widget.platform) {
      case 'Reels':
        if (!url.contains("instagram.com") && !url.contains("instagr.am")) {
          validationError = "Please enter a valid Instagram Reels URL";
        }
        endpoint = 'download/instagram';
        break;
      case 'Shorts':
        if (!url.contains("youtube.com") && !url.contains("youtu.be")) {
          validationError = "Please enter a valid YouTube Shorts URL";
        }
        endpoint = 'download/youtube';
        break;
      case 'WhatsApp':
        _showSnackBar('WhatsApp download is not yet implemented', isError: true);
        return;
      default:
        validationError = "Unknown platform";
    }

    if (endpoint.isEmpty) {
      _showSnackBar("Unknown platform", isError: true);
      return;
    }

    if (validationError.isNotEmpty) {
      _showSnackBar(validationError, isError: true);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    http.Response? response;
    try {
      _showSnackBar("Processing your request... Please wait", isLoading: true);

      final Map<String, dynamic> body = {'url': url};
      if (widget.platform == 'Shorts') {
        body['quality'] = 'best';
        body['type'] = 'video';
      } else if (widget.platform == 'Reels') {
        body['quality'] = 'best';
      }

      response = await http.post(
        Uri.parse('http://10.0.2.2:3000/$endpoint'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode(body),
      ).timeout(const Duration(seconds: 45));
    } on SocketException {
      _showSnackBar('Network error. Check your connection.', isError: true);
      setState(() {
        _isLoading = false;
      });
      return;
    } on TimeoutException {
      _showSnackBar('Request timed out. Please try again.', isError: true);
      setState(() {
        _isLoading = false;
      });
      return;
    } catch (e) {
      _showSnackBar('Error: ${e.toString()}', isError: true);
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final fileUrl = data['fileUrl'];

        _showSnackBar("Download complete! Opening file...", isSuccess: true);

        _controller.clear();

        await Future.delayed(const Duration(milliseconds: 500));

        final tempDir = await getTemporaryDirectory();
        final fileName = fileUrl.split('/').last;
        final filePath = '${tempDir.path}/$fileName';

        await Dio().download(fileUrl, filePath);

        try {
          await OpenFile.open(filePath);
        } catch (e) {
          _showSnackBar("File downloaded, but could not be opened.", isError: true);
        }
      } else {
        final err = json.decode(response.body);
        _showSnackBar('Failed: ${err['error'] ?? 'Unknown error'}', isError: true);
      }
    } catch (e) {
      _showSnackBar('Download failed: ${e.toString()}', isError: true);
    } finally {
      setState(() {
        _isLoading = false;
      });
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

  String _getPlatformHint() {
    switch (widget.platform) {
      case 'Reels':
        return 'e.g., https://instagram.com/reel/...';
      case 'Shorts':
        return 'e.g., https://youtube.com/shorts/...';
      case 'WhatsApp':
        return 'WhatsApp status download';
      default:
        return 'Enter link here';
    }
  }

  bool _isPlatformSupported() {
    return widget.platform != 'WhatsApp'; // WhatsApp is not fully implemented
  }

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
                    widget.platform == 'WhatsApp'
                        ? Icons.chat
                        : widget.platform == 'Reels'
                            ? Icons.video_library
                            : Icons.play_circle_fill,
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
                  'Download ${widget.platform}',
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
                  'Paste your ${widget.platform} link below:',
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
                    onPressed: _isLoading ? null : (_isPlatformSupported() ? _handleDownload : () {
                      _showSnackBar('${widget.platform} download is not yet implemented', isError: true);
                    }),
                    icon: _isLoading 
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF185A9D)),
                        )
                      : const Icon(Icons.download, color: Color(0xFF185A9D)),
                    label: Text(
                      _isLoading ? 'Processing...' : 'Download',
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
                if (!_isPlatformSupported()) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.orange.withOpacity(0.3)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.orange, size: 20),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'This feature is coming soon!',
                            style: TextStyle(
                              color: Colors.orange,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
