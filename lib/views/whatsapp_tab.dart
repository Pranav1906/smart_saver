import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
import 'package:video_player/video_player.dart';

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
      if (!await Permission.videos.request().isGranted ||
          !await Permission.photos.request().isGranted) {
        setState(() {
          _error = 'Storage permission denied';
          _loading = false;
        });
        return;
      }
      const legacy = '/storage/emulated/0/WhatsApp/Media/.Statuses';
      const scoped = '/storage/emulated/0/Android/media/com.whatsapp/WhatsApp/Media/.Statuses';
      Directory statusDir = Directory(legacy);
      if (!statusDir.existsSync()) statusDir = Directory(scoped);
      if (!statusDir.existsSync()) {
        setState(() {
          _error = 'WhatsApp Status folder not found. View a status in WhatsApp first!';
          _loading = false;
        });
        return;
      }
      final files = statusDir
          .listSync()
          .where((f) =>
              f.statSync().type == FileSystemEntityType.file &&
              (f.path.endsWith('.mp4') || f.path.endsWith('.jpg')))
          .map((f) => File(f.path))
          .toList();
      setState(() {
        _statuses = files;
        _loading = false;
      });
    } catch (e) {
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
                                crossAxisCount: 3, crossAxisSpacing: 8, mainAxisSpacing: 8,
                              ),
                              itemCount: _statuses.length,
                              itemBuilder: (context, i) {
                                final file = _statuses[i];
                                final isVideo = file.path.endsWith('.mp4');
                                return GestureDetector(
                                  onTap: () async {
                                    await showDialog(
                                      context: context,
                                      builder: (_) => Dialog(
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            isVideo
                                                ? SizedBox(
                                                    height: 300,
                                                    child: VideoPreview(file: file),
                                                  )
                                                : Image.file(file, fit: BoxFit.contain),
                                            const SizedBox(height: 12),
                                            ElevatedButton.icon(
                                              icon: const Icon(Icons.save_alt),
                                              label: const Text('Save to Gallery'),
                                              onPressed: () async {
                                                await _saveToGallery(file);
                                                Navigator.pop(context);
                                              },
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                  child: isVideo
                                      ? Stack(
                                          fit: StackFit.expand,
                                          children: [
                                            Container(color: Colors.black12),
                                            const Icon(Icons.videocam, color: Colors.white70, size: 40),
                                          ],
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

class VideoPreview extends StatefulWidget {
  final File file;
  const VideoPreview({required this.file, Key? key}) : super(key: key);

  @override
  State<VideoPreview> createState() => _VideoPreviewState();
}

class _VideoPreviewState extends State<VideoPreview> {
  late VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.file(widget.file)
      ..initialize().then((_) {
        setState(() {});
        _controller.play();
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _controller.value.isInitialized
        ? AspectRatio(
            aspectRatio: _controller.value.aspectRatio,
            child: VideoPlayer(_controller),
          )
        : const Center(child: CircularProgressIndicator());
  }
}