import 'dart:async';

import 'package:Delta/services/DioServiceCert.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Stage gallery: same S3 path as ERP
/// `Mobile_App/Processing/{bookId}/{processType}/{n}.{ext}`
class OrderStageGallery extends StatefulWidget {
  final String bookId;
  final String processType;
  final bool isAdmin;
  /// `0` = unlimited. Use `1` for single-photo stages (e.g. installation).
  final int maxImages;

  const OrderStageGallery({
    super.key,
    required this.bookId,
    required this.processType,
    this.isAdmin = false,
    this.maxImages = 0,
  });

  @override
  State<OrderStageGallery> createState() => _OrderStageGalleryState();
}

class _OrderStageGalleryState extends State<OrderStageGallery> {
  static const _orange = Color(0xFFF37021);
  List<String> _images = [];
  bool _loading = true;
  bool _uploading = false;
  Timer? _liveTimer;
  int _reloadToken = 0;

  bool get _singlePhoto => widget.maxImages == 1;
  bool get _canAddMore =>
      widget.maxImages <= 0 || _images.length < widget.maxImages;

  @override
  void initState() {
    super.initState();
    _loadImages();
    // Customer (and admin) keep the stage media live.
    _liveTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (!_uploading) _loadImages(silent: true);
    });
  }

  @override
  void dispose() {
    _liveTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadImages({bool silent = false}) async {
    try {
      final request = await getDio().post(
        'https://daltalifts.com/app2026/sql.php?k=${DateTime.now().millisecondsSinceEpoch}',
        data: {
          'action': 'getProcessingImages',
          'bookId': widget.bookId,
          'processType': widget.processType,
        },
      );
      final raw = request.data['images'];
      final list = <String>[];
      if (raw is List) {
        for (final item in raw) {
          final url = item?.toString() ?? '';
          // Prefer image files in the gallery strip
          final lower = url.toLowerCase();
          if (url.isNotEmpty &&
              (lower.contains('.png') ||
                  lower.contains('.jpg') ||
                  lower.contains('.jpeg') ||
                  lower.contains('.webp') ||
                  lower.contains('.gif') ||
                  !lower.contains('.mp4'))) {
            if (!lower.endsWith('.mp4') &&
                !lower.endsWith('.mov') &&
                !lower.endsWith('.m4v') &&
                !lower.endsWith('.webm')) {
              list.add(url);
            }
          }
        }
      }
      if (!mounted) return;
      final changed = list.join('|') != _images.join('|');
      if (!changed && silent) return;
      if (changed) {
        for (final u in _images) {
          imageCache.evict(NetworkImage(u));
        }
      }
      setState(() {
        _images = list;
        _loading = false;
        if (changed) _reloadToken = DateTime.now().millisecondsSinceEpoch;
      });
    } catch (_) {
      if (!mounted || silent) return;
      setState(() {
        _images = [];
        _loading = false;
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
          'processType': widget.processType,
          'mediaKind': 'image',
        },
      );
    } catch (e) {
      debugPrint('notifyProcessingMedia error: $e');
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
              Text(
                _singlePhoto ? 'إضافة صورة للمرحلة' : 'إضافة صور للمرحلة',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1A1A2E),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'اختَر مصدر الصورة',
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
                  child: const Icon(Iconsax.camera, color: _orange),
                ),
                title: const Text(
                  'الكاميرا',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                ),
                subtitle: Text(
                  'التقاط صورة جديدة',
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
                  _singlePhoto
                      ? 'اختيار صورة واحدة من المعرض'
                      : 'اختيار صورة أو أكثر من المعرض',
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
    if (!_canAddMore) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('هذه المرحلة تقبل صورة واحدة فقط — احذف الحالية أولاً'),
        ),
      );
      return;
    }

    final source = await _showSourceSheet();
    if (source == null || !mounted) return;

    final picker = ImagePicker();
    final List<XFile> picked = [];
    final remaining = widget.maxImages > 0
        ? widget.maxImages - _images.length
        : 0;

    if (source == ImageSource.camera || _singlePhoto) {
      final shot = await picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 2000,
      );
      if (shot != null) picked.add(shot);
    } else {
      final multi = await picker.pickMultiImage(
        imageQuality: 85,
        maxWidth: 2000,
      );
      picked.addAll(multi);
    }
    if (picked.isEmpty) return;

    final toUpload = remaining > 0 ? picked.take(remaining).toList() : picked;
    if (toUpload.isEmpty) return;

    setState(() => _uploading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final uid = prefs.getString('userId') ?? '';
      var nextIndex = _images.length + 1;

      for (final xfile in toUpload) {
        final bytes = await xfile.readAsBytes();
        if (bytes.isEmpty) continue;
        final name = xfile.name.toLowerCase();
        var ext = 'jpg';
        var contentType = 'image/jpeg';
        if (name.endsWith('.png')) {
          ext = 'png';
          contentType = 'image/png';
        } else if (name.endsWith('.webp')) {
          ext = 'webp';
          contentType = 'image/webp';
        } else if (name.endsWith('.gif')) {
          ext = 'gif';
          contentType = 'image/gif';
        }

        final presign = await getDio().post(
          'https://daltalifts.com/app2026/sql.php?k=${DateTime.now().millisecondsSinceEpoch}',
          data: {
            'action': 'getPresignedProcessingImageUrl',
            'uid': uid,
            'bookId': widget.bookId,
            'processType': widget.processType,
            'index': nextIndex,
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
          data: bytes,
          options: Options(
            headers: {
              'Content-Type': contentType,
              'Content-Length': bytes.length,
            },
          ),
        );
        nextIndex++;
      }

      await _loadImages();
      await _notifyCustomerMedia();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _singlePhoto
                  ? 'تم رفع الصورة ✓ — العميل هيشوفها فورًا'
                  : 'تم رفع الصور ✓ — العميل هيشوفها فورًا',
            ),
            backgroundColor: const Color(0xFF22C55E),
          ),
        );
      }
    } catch (e) {
      debugPrint('Stage image upload error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e.toString().replaceFirst('Exception: ', '').isNotEmpty
                  ? e.toString().replaceFirst('Exception: ', '')
                  : 'فشل رفع الصور',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  void _openPreview(int index) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => StageImagePreview(
          images: _images,
          index: index,
        ),
      ),
    );
  }

  Future<void> _deleteImage(String imageUrl) async {
    if (!widget.isAdmin || _uploading) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'حذف الصورة',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
          ),
          content: const Text(
            'هل تريد حذف هذه الصورة؟ لن تظهر للعميل بعد الحذف.',
            style: TextStyle(height: 1.5, fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('إلغاء', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () => Navigator.pop(context, true),
              child: const Text(
                'حذف',
                style: TextStyle(color: Colors.white),
              ),
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
      final result = await getDio().post(
        'https://daltalifts.com/app2026/sql.php?k=${DateTime.now().millisecondsSinceEpoch}',
        data: {
          'action': 'deleteProcessingImage',
          'uid': uid,
          'bookId': widget.bookId,
          'processType': widget.processType,
          'imageUrl': imageUrl,
        },
      );
      final ok = result.data['success'] == true ||
          result.data['success'] == 1 ||
          result.data['success'] == 'true';
      if (!ok) {
        throw Exception(
          result.data['message']?.toString() ?? 'فشل حذف الصورة',
        );
      }
      await _loadImages();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم حذف الصورة'),
            backgroundColor: Color(0xFF22C55E),
          ),
        );
      }
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

  @override
  Widget build(BuildContext context) {
    if (_loading && !widget.isAdmin) {
      return const SizedBox.shrink();
    }
    if (!widget.isAdmin && _images.isEmpty) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      height: 48,
      child: Row(
        children: [
          if (widget.isAdmin && _canAddMore)
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
                    : const Icon(Iconsax.gallery_add, color: _orange, size: 20),
              ),
            ),
          Expanded(
            child: _images.isEmpty
                ? (widget.isAdmin
                    ? Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          _singlePhoto ? 'ارفع صورة للعميل' : 'ارفع صور للعميل',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF9A3412),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      )
                    : const SizedBox.shrink())
                : ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _images.length,
                    itemBuilder: (context, i) {
                      return Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: SizedBox(
                          width: 40,
                          height: 40,
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Positioned.fill(
                                child: GestureDetector(
                                  onTap: () => _openPreview(i),
                                  child: Container(
                                    key: ValueKey(
                                      '$_reloadToken-${_images[i]}',
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade200,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: const Color(0xFFEBEBEB),
                                      ),
                                      image: DecorationImage(
                                        image: NetworkImage(
                                          _images[i],
                                          headers: const {
                                            'Cache-Control': 'no-cache',
                                          },
                                        ),
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              if (widget.isAdmin)
                                Positioned(
                                  top: -6,
                                  left: -6,
                                  child: GestureDetector(
                                    onTap: _uploading
                                        ? null
                                        : () => _deleteImage(_images[i]),
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
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class StageImagePreview extends StatefulWidget {
  final List<String> images;
  final int index;

  const StageImagePreview({
    super.key,
    required this.images,
    required this.index,
  });

  @override
  State<StageImagePreview> createState() => _StageImagePreviewState();
}

class _StageImagePreviewState extends State<StageImagePreview> {
  late final PageController _pageController;
  late int _current;

  @override
  void initState() {
    super.initState();
    _current = widget.index;
    _pageController = PageController(initialPage: widget.index);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          '${_current + 1} / ${widget.images.length}',
          style: const TextStyle(color: Colors.white, fontSize: 16),
        ),
        centerTitle: true,
      ),
      body: PageView.builder(
        controller: _pageController,
        itemCount: widget.images.length,
        onPageChanged: (i) => setState(() => _current = i),
        itemBuilder: (context, i) {
          return InteractiveViewer(
            child: Center(
              child: Image.network(
                widget.images[i],
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.broken_image_outlined,
                  color: Colors.white54,
                  size: 48,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
