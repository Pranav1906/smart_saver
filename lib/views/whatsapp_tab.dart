import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
import 'package:video_player/video_player.dart';
import '../controllers/share_controller.dart';
import '../widgets/interstitial_ad_manager.dart';
import '../services/folder_picker_service.dart';

class WhatsAppTab extends StatefulWidget {
  const WhatsAppTab({Key? key}) : super(key: key);

  @override
  State<WhatsAppTab> createState() => _WhatsAppTabState();
}

class _WhatsAppTabState extends State<WhatsAppTab> {
  List<String> _statusFileNames = [];
  String? _folderUri;
  bool _loading = false;
  String? _error;
  bool _hasFolderAccess = false;

  @override
  
  void initState() {
    super.initState();
    _loadSavedFolder();
  }

  Future<void> _loadSavedFolder() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    
    try {
      final savedUri = await FolderPickerService.getSavedFolderUri();
      if (savedUri != null) {
        setState(() {
          _folderUri = savedUri;
          _hasFolderAccess = true;
        });
        await _fetchStatuses();
      } else {
        setState(() {
          _loading = false;
          _hasFolderAccess = false;
        });
      }
    } catch (e) {
      print('Error loading saved folder: $e');
      setState(() {
        _error = 'Error loading saved folder: $e';
        _loading = false;
      });
    }
  }

  Future<void> _fetchStatuses() async {
    if (_folderUri == null) {
      setState(() {
        _error = 'No folder selected';
        _loading = false;
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final fileNames = await FolderPickerService.listFiles(_folderUri!);
      print('Found ${fileNames.length} status files');
      
      setState(() {
        _statusFileNames = fileNames;
        _loading = false;
      });
    } catch (e) {
      print('Error fetching statuses: $e');
      setState(() {
        _error = 'Error fetching statuses: $e';
        _loading = false;
      });
    }
  }

  Future<void> _pickWhatsAppFolder() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final uri = await FolderPickerService.pickFolder();
      if (uri != null) {
        setState(() {
          _folderUri = uri;
          _hasFolderAccess = true;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Folder access granted! Loading statuses..."),
            backgroundColor: Colors.green,
          ),
        );
        
        await _fetchStatuses();
      } else {
        setState(() {
          _loading = false;
        });
      }
    } catch (e) {
      print('Error picking folder: $e');
      setState(() {
        _error = 'Error selecting folder: $e';
        _loading = false;
      });
    }
  }

  Future<void> _resetFolderAccess() async {
    await FolderPickerService.clearSavedFolder();
    setState(() {
      _folderUri = null;
      _hasFolderAccess = false;
      _statusFileNames = [];
    });
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
                  if (_hasFolderAccess) ...[
                    IconButton(
                      icon: const Icon(Icons.refresh, color: Color(0xFF185A9D)),
                      onPressed: _fetchStatuses,
                      tooltip: 'Refresh',
                    ),
                    IconButton(
                      icon: const Icon(Icons.settings, color: Color(0xFF185A9D)),
                      onPressed: _resetFolderAccess,
                      tooltip: 'Change folder',
                    ),
                  ],
                ],
              ),
            ),
            Expanded(
              child: _buildContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (!_hasFolderAccess) {
      return _buildFolderPickerPrompt();
    }

    if (_loading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.white),
            SizedBox(height: 16),
            Text(
              'Loading statuses...',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                _error!,
                style: const TextStyle(color: Colors.red, fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _resetFolderAccess,
                child: const Text('Select Different Folder'),
              ),
            ],
          ),
        ),
      );
    }

    if (_statusFileNames.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.photo_library_outlined, size: 64, color: Colors.white70),
              const SizedBox(height: 16),
              const Text(
                'No statuses found',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'View some statuses in WhatsApp first!',
                style: TextStyle(color: Colors.white70, fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                icon: const Icon(Icons.refresh),
                label: const Text('Refresh'),
                onPressed: _fetchStatuses,
              ),
            ],
          ),
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: _statusFileNames.length,
      itemBuilder: (context, i) {
        final fileName = _statusFileNames[i];
        final isVideo = fileName.toLowerCase().endsWith('.mp4');
        return GestureDetector(
          onTap: () async {
            await showDialog(
              context: context,
              builder: (_) => MediaPreviewDialog(
                folderUri: _folderUri!,
                fileName: fileName,
              ),
            );
          },
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              color: Colors.black12,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (isVideo)
                    const Center(
                      child: Icon(Icons.videocam, color: Colors.white70, size: 40),
                    )
                  else
                    FutureBuilder<String?>(
                      future: _getThumbnail(fileName),
                      builder: (context, snapshot) {
                        if (snapshot.hasData && snapshot.data != null) {
                          return Image.file(
                            File(snapshot.data!),
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return const Center(
                                child: Icon(Icons.image, color: Colors.white70, size: 40),
                              );
                            },
                          );
                        }
                        return const Center(
                          child: Icon(Icons.image, color: Colors.white70, size: 40),
                        );
                      },
                    ),
                  if (isVideo)
                    Positioned(
                      bottom: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Icon(
                          Icons.play_arrow,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFolderPickerPrompt() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: const Icon(
                Icons.folder_special,
                size: 80,
                color: Color(0xFF43CEA2),
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'Select WhatsApp Status Folder',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            const Text(
              'To view WhatsApp statuses, you need to grant access to the WhatsApp Status folder.',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInstructionStep('1', 'Tap "Select Folder" button below'),
                  const SizedBox(height: 12),
                  _buildInstructionStep('2', 'The WhatsApp Status folder will open automatically'),
                  const SizedBox(height: 12),
                  _buildInstructionStep('3', 'Tap "Use this folder" at the bottom to grant access'),
                ],
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              icon: const Icon(Icons.folder_open, size: 24),
              label: const Text(
                'Select Folder',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF43CEA2),
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 8,
              ),
              onPressed: _pickWhatsAppFolder,
            ),
            const SizedBox(height: 16),
            const Text(
              '✨ You only need to do this once!',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInstructionStep(String number, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Center(
            child: Text(
              number,
              style: const TextStyle(
                color: Color(0xFF43CEA2),
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }

  Future<String?> _getThumbnail(String fileName) async {
    try {
      if (_folderUri == null) return null;
      
      final fileUri = await FolderPickerService.getFileUri(_folderUri!, fileName);
      if (fileUri != null) {
        final tempPath = await FolderPickerService.copyFileToTemp(fileUri);
        return tempPath;
      }
      return null;
    } catch (e) {
      print('Error getting thumbnail: $e');
      return null;
    }
  }
}

class MediaPreviewDialog extends StatefulWidget {
  final String folderUri;
  final String fileName;
  
  const MediaPreviewDialog({
    required this.folderUri,
    required this.fileName,
    Key? key,
  }) : super(key: key);

  @override
  State<MediaPreviewDialog> createState() => _MediaPreviewDialogState();
}

class _MediaPreviewDialogState extends State<MediaPreviewDialog> {
  VideoPlayerController? _controller;
  bool get isVideo => widget.fileName.toLowerCase().endsWith('.mp4');
  String? _tempFilePath;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadFile();
  }

  Future<void> _loadFile() async {
    try {
      final fileUri = await FolderPickerService.getFileUri(
        widget.folderUri,
        widget.fileName,
      );
      
      if (fileUri != null) {
        final tempPath = await FolderPickerService.copyFileToTemp(fileUri);
        if (tempPath != null) {
          setState(() {
            _tempFilePath = tempPath;
          });

          if (isVideo) {
            _controller = VideoPlayerController.file(File(tempPath))
              ..initialize().then((_) {
                setState(() {
                  _loading = false;
                });
              }).catchError((error) {
                print('Error initializing video: $error');
                setState(() {
                  _loading = false;
                });
              });
          } else {
            setState(() {
              _loading = false;
            });
          }
        }
      }
    } catch (e) {
      print('Error loading file: $e');
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    // Clean up temp file
    if (_tempFilePath != null) {
      try {
        File(_tempFilePath!).deleteSync();
      } catch (e) {
        print('Error deleting temp file: $e');
      }
    }
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
              child: _loading
                  ? const SizedBox(
                      height: 200,
                      child: Center(child: CircularProgressIndicator()),
                    )
                  : _tempFilePath == null
                      ? const SizedBox(
                          height: 200,
                          child: Center(
                            child: Text('Failed to load file'),
                          ),
                        )
                      : isVideo
                          ? (_controller?.value.isInitialized ?? false)
                              ? AspectRatio(
                                  aspectRatio: _controller!.value.aspectRatio,
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      VideoPlayer(_controller!),
                                      IconButton(
                                        icon: Icon(
                                          _controller!.value.isPlaying
                                              ? Icons.pause
                                              : Icons.play_arrow,
                                          color: Colors.white,
                                          size: 50,
                                        ),
                                        onPressed: () {
                                          setState(() {
                                            _controller!.value.isPlaying
                                                ? _controller!.pause()
                                                : _controller!.play();
                                          });
                                        },
                                      ),
                                    ],
                                  ),
                                )
                              : const SizedBox(
                                  height: 200,
                                  child: Center(child: Text('Failed to load video')),
                                )
                          : Image.file(
                              File(_tempFilePath!),
                              height: 200,
                              fit: BoxFit.contain,
                            ),
            ),
            const SizedBox(height: 16),
            Text(
              widget.fileName,
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
                    label: const Text('Save'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF43CEA2),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    onPressed: _tempFilePath == null
                        ? null
                        : () async {
                            final result = await ImageGallerySaverPlus.saveFile(_tempFilePath!);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(result['isSuccess'] == true
                                    ? 'Saved to gallery!'
                                    : 'Failed to save.'),
                              ),
                            );
                            
                            if (result['isSuccess'] == true) {
                              await Future.delayed(const Duration(milliseconds: 1000));
                              await InterstitialAdManager.showInterstitialAd();
                            }
                            
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
                      backgroundColor: const Color(0xFF185A9D),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    onPressed: _tempFilePath == null
                        ? null
                        : () async {
                            await ShareController.shareFile(_tempFilePath!);
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
