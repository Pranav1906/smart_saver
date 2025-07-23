import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
import 'dart:typed_data';
import 'package:video_player/video_player.dart';
import 'package:device_info_plus/device_info_plus.dart';

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
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      bool granted = false;
      if (Platform.isAndroid && androidInfo.version.sdkInt >= 33) {
        // Android 13+ (API 33+)
        var images = await Permission.photos.request();
        var videos = await Permission.videos.request();
        granted = images.isGranted && videos.isGranted;
      } else {
        // Android 12 and below
        var storage = await Permission.storage.request();
        granted = storage.isGranted;
      }
      if (!granted) {
        setState(() {
          _error = 'Storage/media permission denied';
          _loading = false;
        });
        return;
      }

      // 2. Locate .Statuses folder
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

      // 3. List files (no need to copy yet)
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
    print('Statuses: $_statuses, Loading: $_loading, Error: $_error');
    return Scaffold(
      appBar: AppBar(
        title: const Text('WhatsApp Statuses'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchStatuses,
          ),
        ],
      ),
      body: _loading
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
                              : Image.file(file, fit: BoxFit.cover),
                        );
                      },
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