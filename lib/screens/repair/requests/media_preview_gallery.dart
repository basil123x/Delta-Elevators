import 'dart:io';
import 'dart:typed_data';

import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:video_player/video_player.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

bool isMaintenanceMediaVideo(String path) {
  final p = path.toLowerCase().split('?').first;
  return p.endsWith('.mp4') ||
      p.endsWith('.mov') ||
      p.endsWith('.m4v') ||
      p.endsWith('.avi') ||
      p.endsWith('.webm') ||
      p.contains('video_') ||
      p.contains('/video') ||
      p.contains('\\video');
}

Future<Uint8List?> maintenanceVideoThumb(String path) async {
  try {
    return await VideoThumbnail.thumbnailData(
      video: path,
      imageFormat: ImageFormat.JPEG,
      maxWidth: 320,
      quality: 75,
    );
  } catch (_) {
    return null;
  }
}

/// Full-screen gallery: swipe between media, zoom images, play videos, delete.
class MaintenanceMediaPreviewGallery extends StatefulWidget {
  const MaintenanceMediaPreviewGallery({
    super.key,
    required this.paths,
    required this.initialIndex,
    this.onDelete,
  });

  final List<String> paths;
  final int initialIndex;
  final void Function(int index)? onDelete;

  @override
  State<MaintenanceMediaPreviewGallery> createState() =>
      _MaintenanceMediaPreviewGalleryState();
}

class _MaintenanceMediaPreviewGalleryState
    extends State<MaintenanceMediaPreviewGallery> {
  late PageController _pageController;
  late List<String> _paths;
  late int _index;

  @override
  void initState() {
    super.initState();
    _paths = List<String>.from(widget.paths);
    _index = widget.initialIndex.clamp(0, _paths.isEmpty ? 0 : _paths.length - 1);
    _pageController = PageController(initialPage: _index);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _deleteCurrent() async {
    if (_paths.isEmpty) return;
    final removeAt = _index;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('حذف الملف؟'),
          content: const Text('هل تريد حذف هذه الصورة/الفيديو؟'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('إلغاء'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text(
                'حذف',
                style: TextStyle(color: Color(0xFFEF4444)),
              ),
            ),
          ],
        ),
      ),
    );
    if (confirmed != true || !mounted) return;

    widget.onDelete?.call(removeAt);
    setState(() {
      _paths.removeAt(removeAt);
      if (_paths.isEmpty) {
        Navigator.pop(context);
        return;
      }
      _index = _index.clamp(0, _paths.length - 1);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_pageController.hasClients) return;
      _pageController.jumpToPage(_index);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_paths.isEmpty) {
      return const SizedBox.shrink();
    }
    final path = _paths[_index];
    final isVideo = isMaintenanceMediaVideo(path);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.white),
          title: Text(
            '${_index + 1} / ${_paths.length}  •  ${isVideo ? 'فيديو' : 'صورة'}',
            style: const TextStyle(color: Colors.white, fontSize: 15),
          ),
          actions: [
            if (widget.onDelete != null)
              IconButton(
                tooltip: 'حذف',
                onPressed: _deleteCurrent,
                icon: const Icon(Iconsax.trash, color: Color(0xFFEF4444)),
              ),
          ],
        ),
        body: PageView.builder(
          controller: _pageController,
          itemCount: _paths.length,
          onPageChanged: (i) => setState(() => _index = i),
          itemBuilder: (context, i) {
            final p = _paths[i];
            if (isMaintenanceMediaVideo(p)) {
              return _GalleryVideoPage(key: ValueKey('v_$p'), path: p);
            }
            return _GalleryImagePage(key: ValueKey('i_$p'), path: p);
          },
        ),
      ),
    );
  }
}

bool _isNetworkMediaPath(String path) {
  final p = path.toLowerCase();
  return p.startsWith('http://') || p.startsWith('https://');
}

class _GalleryImagePage extends StatelessWidget {
  const _GalleryImagePage({super.key, required this.path});
  final String path;

  @override
  Widget build(BuildContext context) {
    final Widget image = _isNetworkMediaPath(path)
        ? Image.network(
            path,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => const Icon(
              Iconsax.gallery_slash,
              color: Colors.white54,
              size: 48,
            ),
          )
        : Image.file(
            File(path),
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => const Icon(
              Iconsax.gallery_slash,
              color: Colors.white54,
              size: 48,
            ),
          );

    return InteractiveViewer(
      minScale: 1,
      maxScale: 5,
      child: Center(child: image),
    );
  }
}

class _GalleryVideoPage extends StatefulWidget {
  const _GalleryVideoPage({super.key, required this.path});
  final String path;

  @override
  State<_GalleryVideoPage> createState() => _GalleryVideoPageState();
}

class _GalleryVideoPageState extends State<_GalleryVideoPage> {
  VideoPlayerController? _controller;
  ChewieController? _chewie;
  String? _error;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      final VideoPlayerController c;
      if (_isNetworkMediaPath(widget.path)) {
        c = VideoPlayerController.networkUrl(Uri.parse(widget.path));
      } else {
        final file = File(widget.path);
        if (!await file.exists()) {
          if (mounted) setState(() => _error = 'الملف غير موجود');
          return;
        }
        c = VideoPlayerController.file(file);
      }
      await c.initialize();
      if (!mounted) {
        await c.dispose();
        return;
      }
      _controller = c;
      _chewie = ChewieController(
        videoPlayerController: c,
        autoPlay: false,
        looping: false,
        allowMuting: true,
        showControls: true,
        materialProgressColors: ChewieProgressColors(
          playedColor: const Color(0xFFF37021),
          handleColor: const Color(0xFFF37021),
          bufferedColor: Colors.white24,
          backgroundColor: Colors.white12,
        ),
      );
      setState(() {});
    } catch (_) {
      if (mounted) setState(() => _error = 'تعذر تشغيل الفيديو');
    }
  }

  @override
  void dispose() {
    _chewie?.dispose();
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Center(
        child: Text(_error!, style: const TextStyle(color: Colors.white70)),
      );
    }
    if (_chewie == null) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFFF37021)),
      );
    }
    return Center(child: Chewie(controller: _chewie!));
  }
}

/// Thumbnail tile for the horizontal strip on the request form.
class MaintenanceMediaThumb extends StatefulWidget {
  const MaintenanceMediaThumb({
    super.key,
    required this.path,
    required this.onTap,
    required this.onDelete,
  });

  final String path;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  State<MaintenanceMediaThumb> createState() => _MaintenanceMediaThumbState();
}

class _MaintenanceMediaThumbState extends State<MaintenanceMediaThumb> {
  Uint8List? _thumb;
  bool _loadingThumb = false;

  bool get _isVideo => isMaintenanceMediaVideo(widget.path);

  @override
  void initState() {
    super.initState();
    if (_isVideo) _loadThumb();
  }

  @override
  void didUpdateWidget(covariant MaintenanceMediaThumb oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.path != widget.path && _isVideo) {
      _thumb = null;
      _loadThumb();
    }
  }

  Future<void> _loadThumb() async {
    setState(() => _loadingThumb = true);
    final bytes = await maintenanceVideoThumb(widget.path);
    if (!mounted) return;
    setState(() {
      _thumb = bytes;
      _loadingThumb = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        GestureDetector(
          onTap: widget.onTap,
          child: Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFEBEBEB)),
              color: Colors.black87,
            ),
            clipBehavior: Clip.antiAlias,
            child: _isVideo
                ? Stack(
                    fit: StackFit.expand,
                    children: [
                      if (_thumb != null)
                        Image.memory(_thumb!, fit: BoxFit.cover)
                      else if (_loadingThumb)
                        const Center(
                          child: SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white70,
                            ),
                          ),
                        )
                      else
                        const ColoredBox(color: Colors.black87),
                      Container(
                        color: Colors.black38,
                        alignment: Alignment.center,
                        child: const Icon(
                          Iconsax.play_circle,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                    ],
                  )
                : Image.file(
                    File(widget.path),
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Icon(
                      Iconsax.gallery,
                      color: Colors.white54,
                    ),
                  ),
          ),
        ),
        Positioned(
          top: -6,
          right: -6,
          child: GestureDetector(
            onTap: widget.onDelete,
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: const Icon(
                Iconsax.close_circle,
                color: Colors.white,
                size: 14,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Network thumbnail for admin/customer maintenance detail media strip.
class MaintenanceNetworkMediaThumb extends StatefulWidget {
  const MaintenanceNetworkMediaThumb({
    super.key,
    required this.url,
    required this.onTap,
    this.size = 110,
  });

  final String url;
  final VoidCallback onTap;
  final double size;

  @override
  State<MaintenanceNetworkMediaThumb> createState() =>
      _MaintenanceNetworkMediaThumbState();
}

class _MaintenanceNetworkMediaThumbState
    extends State<MaintenanceNetworkMediaThumb> {
  Uint8List? _thumb;
  bool _loadingThumb = false;

  bool get _isVideo => isMaintenanceMediaVideo(widget.url);

  @override
  void initState() {
    super.initState();
    if (_isVideo) _loadThumb();
  }

  @override
  void didUpdateWidget(covariant MaintenanceNetworkMediaThumb oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url && _isVideo) {
      _thumb = null;
      _loadThumb();
    }
  }

  Future<void> _loadThumb() async {
    setState(() => _loadingThumb = true);
    final bytes = await maintenanceVideoThumb(widget.url);
    if (!mounted) return;
    setState(() {
      _thumb = bytes;
      _loadingThumb = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE8E8EC)),
          color: const Color(0xFFF0F0F3),
        ),
        clipBehavior: Clip.antiAlias,
        child: _isVideo
            ? Stack(
                fit: StackFit.expand,
                children: [
                  if (_thumb != null)
                    Image.memory(_thumb!, fit: BoxFit.cover)
                  else if (_loadingThumb)
                    const Center(
                      child: SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Color(0xFFF37021),
                        ),
                      ),
                    )
                  else
                    Container(color: Colors.black87),
                  Container(color: Colors.black38),
                  const Center(
                    child: Icon(
                      Iconsax.play_circle,
                      color: Colors.white,
                      size: 36,
                    ),
                  ),
                ],
              )
            : Image.network(
                widget.url,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Icon(
                  Iconsax.gallery,
                  color: Color(0xFFBBBBBB),
                ),
              ),
      ),
    );
  }
}
