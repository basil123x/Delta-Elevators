import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:Delta/services/DioServiceCert.dart';
import 'package:chewie/chewie.dart';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_compress/video_compress.dart';
import 'package:video_player/video_player.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

/// Stage 8 — elevator operation video. Admin uploads exactly one video.
class OrderPlaying extends StatefulWidget {
  final String bookId;
  final bool isAdmin;

  const OrderPlaying({
    super.key,
    required this.bookId,
    this.isAdmin = false,
  });

  @override
  State<OrderPlaying> createState() => _OrderPlayingState();
}

class _OrderPlayingState extends State<OrderPlaying> {
  static const _orange = Color(0xFFF37021);

  String? _videoUrl;
  Uint8List? _thumbBytes;
  bool _loading = true;
  bool _thumbLoading = false;
  bool _uploading = false;
  Timer? _liveTimer;

  @override
  void initState() {
    super.initState();
    _resolveVideoUrl();
    _liveTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (!_uploading) _resolveVideoUrl(silent: true);
    });
  }

  @override
  void dispose() {
    _liveTimer?.cancel();
    super.dispose();
  }

  Future<void> _resolveVideoUrl({bool silent = false}) async {
    try {
      final response = await getDio().post(
        'https://daltalifts.com/app2026/sql.php?k=${DateTime.now().millisecondsSinceEpoch}',
        data: {
          'action': 'getProcessingImages',
          'bookId': widget.bookId,
          'processType': 'playing',
        },
      );

      final images = response.data['images'];
      if (images is List && images.isNotEmpty) {
        final urls = images.map((e) => e.toString()).toList();
        final video = urls.firstWhere(
          (u) {
            final lower = u.toLowerCase();
            return lower.endsWith('.mp4') ||
                lower.endsWith('.mov') ||
                lower.endsWith('.m4v') ||
                lower.endsWith('.webm');
          },
          orElse: () => '',
        );
        if (video.isNotEmpty) {
          if (!mounted) return;
          if (silent && _videoUrl == video) return;
          setState(() {
            _videoUrl = video;
            _loading = false;
            _thumbLoading = true;
            _thumbBytes = null;
          });
          await _loadThumbnail(video);
          return;
        }
      }
    } catch (e) {
      debugPrint('resolve playing video error: $e');
    }

    const exts = ['mp4', 'mov', 'm4v'];
    for (final ext in exts) {
      final url =
          'https://daltaliftstech.s3.ap-south-1.amazonaws.com/Mobile_App/Processing/${widget.bookId}/playing/1.$ext';
      try {
        final head = await getDio().head(url);
        if (head.statusCode == 200) {
          if (!mounted) return;
          if (silent && _videoUrl == url) return;
          setState(() {
            _videoUrl = url;
            _loading = false;
            _thumbLoading = true;
            _thumbBytes = null;
          });
          await _loadThumbnail(url);
          return;
        }
      } catch (_) {}
    }

    if (mounted && !(silent && _videoUrl == null)) {
      setState(() {
        _videoUrl = null;
        _loading = false;
        _thumbLoading = false;
        _thumbBytes = null;
      });
    }
  }

  Future<void> _notifyCustomerMedia() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final uid = prefs.getString('userId') ?? '';
      await getDio().post(
        'https://daltalifts.com/app2026/sql.php?k=${DateTime.now().millisecondsSinceEpoch}',
        data: {
          'action': 'notifyProcessingMedia',
          'uid': uid,
          'bookId': widget.bookId,
          'processType': 'playing',
          'mediaKind': 'video',
        },
      );
    } catch (e) {
      debugPrint('notifyProcessingMedia video error: $e');
    }
  }

  Future<void> _loadThumbnail(String url) async {
    try {
      final bytes = await VideoThumbnail.thumbnailData(
        video: url,
        imageFormat: ImageFormat.JPEG,
        maxWidth: 160,
        quality: 80,
        timeMs: 800,
      );
      if (!mounted) return;
      setState(() {
        _thumbBytes = bytes;
        _thumbLoading = false;
      });
    } catch (e) {
      debugPrint('playing thumb error: $e');
      if (mounted) setState(() => _thumbLoading = false);
    }
  }

  Future<ImageSource?> _showSourceSheet() {
    return showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'رفع فيديو التشغيل',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1A1A2E),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'فيديو واحد فقط لمرحلة التشغيل',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 16),
              ListTile(
                onTap: () => Navigator.pop(ctx, ImageSource.camera),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                leading: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF0E5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Iconsax.video, color: _orange),
                ),
                title: const Text(
                  'تصوير فيديو',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                ),
                subtitle: Text(
                  'تسجيل فيديو جديد بالكاميرا',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ),
              const SizedBox(height: 6),
              ListTile(
                onTap: () => Navigator.pop(ctx, ImageSource.gallery),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                leading: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEF4FF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Iconsax.gallery, color: Color(0xFF3B82F6)),
                ),
                title: const Text(
                  'المعرض',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                ),
                subtitle: Text(
                  'اختيار فيديو واحد من المعرض',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickAndUpload() async {
    if (!widget.isAdmin || _uploading) return;
    if (_videoUrl != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('هذه المرحلة تقبل فيديو واحد فقط — احذف الحالي أولاً'),
        ),
      );
      return;
    }

    final source = await _showSourceSheet();
    if (source == null || !mounted) return;

    final picker = ImagePicker();
    final video = await picker.pickVideo(
      source: source,
      maxDuration: const Duration(minutes: 3),
    );
    if (video == null || !mounted) return;

    setState(() => _uploading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final uid = prefs.getString('userId') ?? '';

      // Compress to H.264 mp4 for iOS/Android playback compatibility.
      MediaInfo? compressed;
      try {
        compressed = await VideoCompress.compressVideo(
          video.path,
          quality: VideoQuality.MediumQuality,
          deleteOrigin: false,
          includeAudio: true,
        );
      } catch (e) {
        debugPrint('Video compress skipped: $e');
      }

      final uploadPath =
          (compressed?.path != null && compressed!.path!.isNotEmpty)
              ? compressed.path!
              : video.path;
      final file = File(uploadPath);
      final length = await file.length();
      if (length <= 0) throw Exception('الفيديو فارغ');

      const ext = 'mp4';
      const contentType = 'video/mp4';

      final presign = await getDio().post(
        'https://daltalifts.com/app2026/sql.php?k=${DateTime.now().millisecondsSinceEpoch}',
        data: {
          'action': 'getPresignedProcessingImageUrl',
          'uid': uid,
          'bookId': widget.bookId,
          'processType': 'playing',
          'index': 1,
          'ext': ext,
          'contentType': contentType,
        },
      );
      if (presign.data['success'] != true &&
          presign.data['success'] != 1 &&
          presign.data['success'] != 'true') {
        throw Exception(
          presign.data['message']?.toString() ?? 'فشل تجهيز الرفع',
        );
      }
      final uploadUrl = presign.data['url']?.toString() ?? '';
      if (uploadUrl.isEmpty) throw Exception('رابط الرفع فارغ');

      await Dio().put(
        uploadUrl,
        data: file.openRead(),
        options: Options(
          headers: {
            'Content-Type': contentType,
            'Content-Length': length,
          },
        ),
      );

      await _resolveVideoUrl();
      await _notifyCustomerMedia();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم رفع فيديو التشغيل ✓ — العميل هيشوفه فورًا'),
            backgroundColor: Color(0xFF22C55E),
          ),
        );
      }
    } catch (e) {
      debugPrint('Playing video upload error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e.toString().replaceFirst('Exception: ', '').isNotEmpty
                  ? e.toString().replaceFirst('Exception: ', '')
                  : 'فشل رفع الفيديو',
            ),
          ),
        );
      }
    } finally {
      try {
        await VideoCompress.deleteAllCache();
      } catch (_) {}
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _deleteVideo() async {
    if (!widget.isAdmin || _uploading || _videoUrl == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'حذف الفيديو',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
          ),
          content: const Text(
            'هل تريد حذف فيديو التشغيل؟ لن يظهر للعميل بعد الحذف.',
            style: TextStyle(height: 1.5, fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('إلغاء'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('حذف'),
            ),
          ],
        ),
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _uploading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final uid = prefs.getString('userId') ?? '';
      final res = await getDio().post(
        'https://daltalifts.com/app2026/sql.php?k=${DateTime.now().millisecondsSinceEpoch}',
        data: {
          'action': 'deleteProcessingImage',
          'uid': uid,
          'bookId': widget.bookId,
          'processType': 'playing',
          'imageUrl': _videoUrl,
        },
      );
      if (res.data['success'] != true &&
          res.data['success'] != 1 &&
          res.data['success'] != 'true') {
        throw Exception(res.data['message']?.toString() ?? 'فشل الحذف');
      }
      if (!mounted) return;
      setState(() {
        _videoUrl = null;
        _thumbBytes = null;
        _thumbLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم حذف الفيديو'),
          backgroundColor: Color(0xFF22C55E),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e.toString().replaceFirst('Exception: ', ''),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  void _openVideoPlayer() {
    final url = _videoUrl;
    if (url == null || url.isEmpty) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => VideoPlayerScreen(videoUrl: url),
      ),
    );
  }

  Widget _buildVideoThumb() {
    return GestureDetector(
      onTap: _openVideoPlayer,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(7),
        child: SizedBox(
          width: 40,
          height: 40,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (_thumbBytes != null)
                Image.memory(
                  _thumbBytes!,
                  fit: BoxFit.cover,
                )
              else
                Container(
                  color: Colors.black87,
                  child: _thumbLoading
                      ? const Padding(
                          padding: EdgeInsets.all(10),
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(
                          Iconsax.video,
                          color: Colors.white,
                          size: 22,
                        ),
                ),
              Container(
                color: Colors.black38,
                alignment: Alignment.center,
                child: const Icon(
                  Iconsax.play_circle,
                  color: Colors.white,
                  size: 22,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading && !widget.isAdmin) {
      return const SizedBox(
        width: 40,
        height: 40,
        child: Padding(
          padding: EdgeInsets.all(10),
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: _orange,
          ),
        ),
      );
    }

    if (!widget.isAdmin && _videoUrl == null) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      height: 48,
      child: Row(
        children: [
          if (widget.isAdmin && _videoUrl == null)
            GestureDetector(
              onTap: _uploading ? null : _pickAndUpload,
              child: Container(
                width: 40,
                height: 40,
                margin: const EdgeInsets.only(left: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF0E5),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _orange.withValues(alpha: 0.5)),
                ),
                child: _uploading
                    ? const Padding(
                        padding: EdgeInsets.all(10),
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: _orange,
                        ),
                      )
                    : const Icon(Iconsax.video_add, color: _orange, size: 20),
              ),
            ),
          if (_videoUrl != null)
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: SizedBox(
                width: 40,
                height: 40,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned.fill(child: _buildVideoThumb()),
                    if (widget.isAdmin)
                      Positioned(
                        top: -6,
                        left: -6,
                        child: GestureDetector(
                          onTap: _uploading ? null : _deleteVideo,
                          child: Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              color: const Color(0xFFEF4444),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white,
                                width: 1.5,
                              ),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x33000000),
                                  blurRadius: 3,
                                  offset: Offset(0, 1),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.close,
                              size: 12,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          if (widget.isAdmin && _videoUrl == null)
            const Expanded(
              child: Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'ارفع فيديو التشغيل للعميل',
                  style: TextStyle(
                    fontSize: 11,
                    color: Color(0xFF9A3412),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class VideoPlayerScreen extends StatefulWidget {
  final String videoUrl;
  const VideoPlayerScreen({super.key, required this.videoUrl});

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  VideoPlayerController? _videoController;
  ChewieController? _chewieController;
  String? _error;
  double? _downloadProgress;
  bool _busy = true;
  int _gen = 0;

  @override
  void initState() {
    super.initState();
    _initPlayer();
  }

  Dio _downloadDio() {
    final dio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(minutes: 15),
        sendTimeout: const Duration(minutes: 15),
      ),
    );
    (dio.httpClientAdapter as IOHttpClientAdapter).onHttpClientCreate =
        (client) {
      client.badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
      return client;
    };
    return dio;
  }

  String _cacheFileName(String url) {
    final uri = Uri.parse(url);
    final name = uri.pathSegments.isNotEmpty ? uri.pathSegments.last : 'video.bin';
    final safe = name.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
    final hash = url.hashCode.toUnsigned(32).toRadixString(16);
    return 'playing_${hash}_$safe';
  }

  Future<Directory> _cacheDir() async {
    final root = await getTemporaryDirectory();
    final dir = Directory('${root.path}/delta_video_cache');
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  Future<File?> _downloadToCache(String url, {bool force = false}) async {
    final dir = await _cacheDir();
    final local = File('${dir.path}/${_cacheFileName(url)}');
    final part = File('${local.path}.part');
    final dio = _downloadDio();

    int? remoteLen;
    try {
      final head = await dio.head(url);
      final cl = head.headers.value('content-length');
      if (cl != null) remoteLen = int.tryParse(cl);
    } catch (_) {}

    if (!force && await local.exists()) {
      final len = await local.length();
      final sizeOk = remoteLen == null
          ? len > 1024
          : len == remoteLen && len > 1024;
      if (sizeOk) return local;
      try {
        await local.delete();
      } catch (_) {}
    }

    if (await part.exists()) {
      try {
        await part.delete();
      } catch (_) {}
    }

    if (mounted) {
      setState(() {
        _downloadProgress = 0;
        _busy = true;
        _error = null;
      });
    }

    await dio.download(
      url,
      part.path,
      onReceiveProgress: (received, total) {
        if (!mounted || total <= 0) return;
        setState(() => _downloadProgress = received / total);
      },
    );

    final downloaded = await part.length();
    if (downloaded < 1024 ||
        (remoteLen != null && downloaded != remoteLen)) {
      try {
        await part.delete();
      } catch (_) {}
      throw Exception('ملف الفيديو غير مكتمل');
    }

    if (await local.exists()) {
      try {
        await local.delete();
      } catch (_) {}
    }
    await part.rename(local.path);
    return local;
  }

  Future<void> _attachController(VideoPlayerController controller) async {
    await controller.initialize();
    if (!mounted) {
      await controller.dispose();
      return;
    }
    _videoController = controller;
    _chewieController = ChewieController(
      videoPlayerController: controller,
      autoPlay: true,
      looping: false,
      allowMuting: true,
      showControls: true,
      allowFullScreen: true,
      errorBuilder: (context, errorMessage) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'تعذر تشغيل الفيديو\n$errorMessage',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70),
            ),
          ),
        );
      },
    );
    setState(() {
      _busy = false;
      _downloadProgress = null;
      _error = null;
    });
  }

  Future<void> _initPlayer() async {
    final gen = ++_gen;
    setState(() {
      _busy = true;
      _error = null;
      _downloadProgress = null;
    });

    _chewieController?.dispose();
    _chewieController = null;
    await _videoController?.dispose();
    _videoController = null;

    Object? lastError;

    // 1) Stream first — works for faststart/compatible mp4
    try {
      if (!mounted || gen != _gen) return;
      await _attachController(
        VideoPlayerController.networkUrl(
          Uri.parse(widget.videoUrl),
          httpHeaders: const {'Accept': '*/*'},
        ),
      );
      return;
    } catch (e) {
      lastError = e;
      debugPrint('Network video play failed: $e');
    }

    // 2) Download fresh (invalidate stale cache) then play local
    try {
      final local = await _downloadToCache(widget.videoUrl, force: true);
      if (!mounted || gen != _gen) return;
      if (local != null) {
        await _attachController(VideoPlayerController.file(local));
        return;
      }
    } catch (e) {
      lastError = e;
      debugPrint('Local video play failed: $e');
    }

    if (!mounted || gen != _gen) return;
    setState(() {
      _busy = false;
      _downloadProgress = null;
      _error =
          'تعذر تشغيل الفيديو${lastError != null ? '\n${lastError.toString().replaceFirst('Exception: ', '')}' : ''}';
    });
  }

  @override
  void dispose() {
    _gen++;
    _chewieController?.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: _error != null
            ? Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Iconsax.video_slash,
                    color: Colors.white54,
                    size: 42,
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: _busy ? null : _initPlayer,
                    child: const Text(
                      'إعادة المحاولة',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              )
            : _chewieController != null
                ? Chewie(controller: _chewieController!)
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(color: Colors.white),
                      const SizedBox(height: 16),
                      Text(
                        (_downloadProgress ?? 0) > 0
                            ? 'جاري تحميل الفيديو… ${((_downloadProgress ?? 0) * 100).toStringAsFixed(0)}%'
                            : 'جاري تجهيز الفيديو…',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                      if (_downloadProgress != null) ...[
                        const SizedBox(height: 12),
                        SizedBox(
                          width: 180,
                          child: LinearProgressIndicator(
                            value: _downloadProgress,
                            backgroundColor: Colors.white24,
                            color: const Color(0xFFF37021),
                          ),
                        ),
                      ],
                    ],
                  ),
      ),
    );
  }
}
