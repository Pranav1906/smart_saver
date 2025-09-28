import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
import 'package:video_player/video_player.dart';
import '../controllers/share_controller.dart';
import '../widgets/interstitial_ad_manager.dart';

class WhatsAppTab extends StatefulWidget {
  const WhatsAppTab({Key? key}) : super(key: key);

  @override
  State<WhatsAppTab> createState() => _WhatsAppTabState();
}

class _WhatsAppTabState extends State<WhatsAppTab> {
  List<File> _statuses = [];
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchStatuses();
  }

  Future<void> _fetchStatuses() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      // Request storage permissions
      Map<Permission, PermissionStatus> statuses = await [
        Permission.storage,
        Permission.manageExternalStorage,
        Permission.videos,
        Permission.photos,
      ].request();

      print('Permission statuses: $statuses');

      // Check if any storage permission is granted
      bool hasStoragePermission = statuses[Permission.storage]?.isGranted == true ||
          statuses[Permission.manageExternalStorage]?.isGranted == true ||
          statuses[Permission.videos]?.isGranted == true ||
          statuses[Permission.photos]?.isGranted == true;

      if (!hasStoragePermission) {
        setState(() {
          _error = 'Storage permission denied. Please grant storage access in settings.';
          _loading = false;
        });
        return;
      }

      // Multiple possible WhatsApp status paths
      List<String> possiblePaths = [
        '/storage/emulated/0/WhatsApp/Media/.Statuses',
        '/storage/emulated/0/Android/media/com.whatsapp/WhatsApp/Media/.Statuses',
        '/storage/emulated/0/Android/data/com.whatsapp/files/WhatsApp/Media/.Statuses',
        '/sdcard/WhatsApp/Media/.Statuses',
        '/sdcard/Android/media/com.whatsapp/WhatsApp/Media/.Statuses',
      ];

      Directory? statusDir;
      String foundPath = '';

      for (String path in possiblePaths) {
        Directory dir = Directory(path);
        print('Checking path: $path - exists: ${dir.existsSync()}');
        if (dir.existsSync()) {
          statusDir = dir;
          foundPath = path;
          break;
        }
      }

      if (statusDir == null) {
        setState(() {
          _error = 'WhatsApp Status folder not found.\n\nPossible reasons:\n• WhatsApp not installed\n• No statuses viewed yet\n• Different Android version\n\nTry viewing some statuses in WhatsApp first!';
          _loading = false;
        });
        return;
      }

      print('Found WhatsApp status directory: $foundPath');

      // List all files in the directory
      List<FileSystemEntity> allFiles = statusDir.listSync();
      print('Total files found: ${allFiles.length}');

      // Filter for media files
      List<File> files = allFiles
          .where((f) {
            bool isFile = f.statSync().type == FileSystemEntityType.file;
            bool isMedia = f.path.toLowerCase().endsWith('.mp4') || 
                          f.path.toLowerCase().endsWith('.jpg') ||
                          f.path.toLowerCase().endsWith('.jpeg') ||
                          f.path.toLowerCase().endsWith('.png') ||
                          f.path.toLowerCase().endsWith('.gif');
            return isFile && isMedia;
          })
          .map((f) => File(f.path))
          .toList();

      print('Media files found: ${files.length}');
      for (File file in files) {
        print('File: ${file.path}');
      }

      setState(() {
        _statuses = files;
        _loading = false;
      });
    } catch (e) {
      print('Error fetching statuses: $e');
      setState(() {
        _error = 'Error: $e';
        _loading = false;
      });
    }
  }

  Future<void> _saveToGallery(File file) async {
    final result = await ImageGallerySaverPlus.saveFile(file.path);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result['isSuccess'] == true
            ? 'Saved to gallery!'
            : 'Failed to save.'),
      ),
    );
    
    // Show interstitial ad after successful save
    if (result['isSuccess'] == true) {
      await Future.delayed(const Duration(milliseconds: 1000));
      await InterstitialAdManager.showInterstitialAd();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF43CEA2), Color(0xFF185A9D)],
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
              child: Row(
                children: [
                  Text(
                    'WhatsApp Statuses',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                          letterSpacing: 1,
                        ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.refresh, color: Color(0xFF185A9D)),
                    onPressed: _fetchStatuses,
                  ),
                ],
              ),
            ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? Center(child: Text(_error!, style: const TextStyle(color: Colors.red)))
                      : _statuses.isEmpty
                          ? const Center(child: Text('No statuses found. View some in WhatsApp first!'))
                          : GridView.builder(
                              padding: const EdgeInsets.all(12),
                                                             gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                 crossAxisCount: 3, crossAxisSpacing: 16, mainAxisSpacing: 16,
                               ),
                              itemCount: _statuses.length,
                              itemBuilder: (context, i) {
                                final file = _statuses[i];
                                final isVideo = file.path.endsWith('.mp4');
                                return GestureDetector(
                                  onTap: () async {
                                    await showDialog(
                                      context: context,
                                      builder: (_) => MediaPreviewDialog(file: file),
                                    );
                                  },
                                  child: isVideo
                                      ? ClipRRect(
                                          borderRadius: BorderRadius.circular(12),
                                          child: Container(
                                            color: Colors.black12,
                                            child: const Center(
                                              child: Icon(Icons.videocam, color: Colors.white70, size: 40),
                                            ),
                                          ),
                                        )
                                      : ClipRRect(
                                          borderRadius: BorderRadius.circular(12),
                                          child: Image.file(file, fit: BoxFit.cover),
                                        ),
                                );
                              },
                            ),
            ),
          ],
        ),
      ),
    );
  }
}

class MediaPreviewDialog extends StatefulWidget {
  final File file;
  const MediaPreviewDialog({required this.file, Key? key}) : super(key: key);

  @override
  State<MediaPreviewDialog> createState() => _MediaPreviewDialogState();
}

class _MediaPreviewDialogState extends State<MediaPreviewDialog> {
  VideoPlayerController? _controller;
  bool get isVideo => widget.file.path.toLowerCase().endsWith('.mp4');

  @override
  void initState() {
    super.initState();
    if (isVideo) {
      _controller = VideoPlayerController.file(widget.file)
        ..initialize().then((_) => setState(() {}));
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: isVideo
                  ? (_controller?.value.isInitialized ?? false)
                      ? AspectRatio(
                          aspectRatio: _controller!.value.aspectRatio,
                          child: VideoPlayer(_controller!),
                        )
                      : const SizedBox(
                          height: 200,
                          child: Center(child: CircularProgressIndicator()),
                        )
                  : Image.file(widget.file, height: 200, fit: BoxFit.contain),
            ),
            const SizedBox(height: 16),
            Text(
              widget.file.path.split('/').last,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.save_alt),
                    label: const Text('Save to Gallery'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF43CEA2),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    onPressed: () async {
                      final result = await ImageGallerySaverPlus.saveFile(widget.file.path);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(result['isSuccess'] == true
                              ? 'Saved to gallery!'
                              : 'Failed to save.'),
                        ),
                      );
                      Navigator.pop(context);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.share),
                    label: const Text('Share'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF185A9D),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    onPressed: () async {
                      await ShareController.shareFile(widget.file.path);
                      Navigator.pop(context);
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}