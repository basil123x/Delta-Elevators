import 'dart:io';
import 'dart:typed_data';

import 'package:Delta/services/DioServiceCert.dart';
import 'package:Delta/services/LocationService.dart';
import 'package:Delta/screens/repair/repair_theme.dart';
import 'package:chewie/chewie.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_player/video_player.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

/// Admin/employee issue report form.
///
/// Optional [lockedLocation]: when the technician has an active assigned job,
/// pass the site name to auto-fill and lock the location field. Also reads
/// SharedPreferences key `active_job_location` if set.
class AdminReportIssueScreen extends StatefulWidget {
  final String? lockedLocation;

  const AdminReportIssueScreen({super.key, this.lockedLocation});

  @override
  State<AdminReportIssueScreen> createState() => _AdminReportIssueScreenState();
}

class _AdminReportIssueScreenState extends State<AdminReportIssueScreen> {
  static const _green = Color(0xFF22C55E);
  static const _orange = Color(0xFFF37021);
  static const _textPrimary = Color(0xFF1A1A2E);
  static const _bg = Color(0xFFF2F3F7);
  static const _apiUrl = 'https://daltalifts.com/app2026/report_issue.php';

  static const _issueTypes = <String>[
    'عطل فني غير مخطط',
    'مشكلة أمان/خطورة بالموقع',
    'نقص أدوات أو معدات',
    'مشكلة في التطبيق (Bug)',
  ];

  final _formKey = GlobalKey<FormState>();
  final _descController = TextEditingController();
  final _locationController = TextEditingController();

  String? _issueType;
  bool _locationLocked = false;
  bool _loadingGps = false;
  bool _submitting = false;
  final List<_IssueAttachment> _attachments = [];

  @override
  void initState() {
    super.initState();
    _resolveLockedLocation();
  }

  Future<void> _resolveLockedLocation() async {
    String? locked = widget.lockedLocation?.trim();
    if (locked == null || locked.isEmpty) {
      final prefs = await SharedPreferences.getInstance();
      locked = prefs.getString('active_job_location')?.trim();
    }
    if (!mounted) return;
    if (locked != null && locked.isNotEmpty) {
      setState(() {
        _locationController.text = locked!;
        _locationLocked = true;
      });
    }
  }

  @override
  void dispose() {
    _descController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _useCurrentLocation() async {
    if (_locationLocked || _loadingGps) return;
    setState(() => _loadingGps = true);
    try {
      final service = LocationService();
      final pos = await service.getCurrentLocation();
      if (pos == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تعذر الحصول على الموقع — فعّل صلاحية الموقع')),
        );
        return;
      }
      final address = await service.getAddressFromCoordinates(
        pos.latitude,
        pos.longitude,
      );
      if (!mounted) return;
      setState(() {
        _locationController.text = address.isNotEmpty
            ? address
            : '${pos.latitude.toStringAsFixed(5)}, ${pos.longitude.toStringAsFixed(5)}';
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ في الموقع: $e')),
      );
    } finally {
      if (mounted) setState(() => _loadingGps = false);
    }
  }

  Future<String?> _showAttachmentPicker() {
    return showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        var step = 0; // 0 = media type, 1 = source
        String? mediaKind; // photo | video

        Widget optionCard({
          required IconData icon,
          required String title,
          required String subtitle,
          required VoidCallback onTap,
          Color accent = _orange,
        }) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE8ECF1)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(icon, color: accent, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: _textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              subtitle,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Iconsax.arrow_left_2,
                        size: 18,
                        color: Color(0xFFCBD5E1),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }

        return Directionality(
          textDirection: TextDirection.rtl,
          child: StatefulBuilder(
            builder: (context, setModalState) {
              final isPhoto = mediaKind == 'photo';
              return Container(
                padding: EdgeInsets.fromLTRB(
                  16,
                  10,
                  16,
                  MediaQuery.paddingOf(ctx).bottom + 18,
                ),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 42,
                        height: 4,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE5E7EB),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        if (step == 1)
                          GestureDetector(
                            onTap: () => setModalState(() {
                              step = 0;
                              mediaKind = null;
                            }),
                            child: Container(
                              width: 34,
                              height: 34,
                              margin: const EdgeInsets.only(left: 8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: const Color(0xFFE8ECF1),
                                ),
                              ),
                              child: const Icon(
                                Iconsax.arrow_right_3,
                                size: 16,
                                color: _textPrimary,
                              ),
                            ),
                          ),
                        Expanded(
                          child: Text(
                            step == 0
                                ? 'إضافة مرفق'
                                : (isPhoto ? 'مصدر الصورة' : 'مصدر الفيديو'),
                            textAlign: TextAlign.right,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: _textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      step == 0
                          ? 'اختر نوع المرفق أولاً'
                          : 'الكاميرا أو المعرض',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (step == 0) ...[
                      optionCard(
                        icon: Iconsax.camera,
                        title: 'صورة',
                        subtitle: 'التقاط أو اختيار صورة',
                        onTap: () => setModalState(() {
                          mediaKind = 'photo';
                          step = 1;
                        }),
                      ),
                      optionCard(
                        icon: Iconsax.video,
                        title: 'فيديو',
                        subtitle: 'تصوير أو اختيار فيديو',
                        accent: const Color(0xFF3B82F6),
                        onTap: () => setModalState(() {
                          mediaKind = 'video';
                          step = 1;
                        }),
                      ),
                    ] else ...[
                      optionCard(
                        icon: Iconsax.camera,
                        title: 'الكاميرا',
                        subtitle: isPhoto
                            ? 'التقاط صورة جديدة'
                            : 'تصوير فيديو جديد',
                        onTap: () => Navigator.pop(
                          ctx,
                          isPhoto ? 'photo_camera' : 'video_camera',
                        ),
                      ),
                      optionCard(
                        icon: Iconsax.gallery,
                        title: 'المعرض',
                        subtitle: isPhoto
                            ? 'اختيار صورة من المعرض'
                            : 'اختيار فيديو من المعرض',
                        accent: const Color(0xFF3B82F6),
                        onTap: () => Navigator.pop(
                          ctx,
                          isPhoto ? 'photo_gallery' : 'video_gallery',
                        ),
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  Future<void> _pickAttachment() async {
    if (_attachments.length >= 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الحد الأقصى 6 مرفقات')),
      );
      return;
    }

    final choice = await _showAttachmentPicker();
    if (choice == null || !mounted) return;

    final picker = ImagePicker();
    XFile? file;
    var isVideo = false;
    switch (choice) {
      case 'photo_camera':
        file = await picker.pickImage(
          source: ImageSource.camera,
          imageQuality: 85,
          maxWidth: 2000,
        );
        break;
      case 'photo_gallery':
        file = await picker.pickImage(
          source: ImageSource.gallery,
          imageQuality: 85,
          maxWidth: 2000,
        );
        break;
      case 'video_camera':
        file = await picker.pickVideo(
          source: ImageSource.camera,
          maxDuration: const Duration(minutes: 2),
        );
        isVideo = true;
        break;
      case 'video_gallery':
        file = await picker.pickVideo(
          source: ImageSource.gallery,
          maxDuration: const Duration(minutes: 2),
        );
        isVideo = true;
        break;
    }
    if (file == null || !mounted) return;

    Uint8List? thumb;
    if (isVideo) {
      try {
        thumb = await VideoThumbnail.thumbnailData(
          video: file.path,
          imageFormat: ImageFormat.JPEG,
          maxWidth: 160,
          quality: 70,
        );
      } catch (_) {}
    }

    setState(() {
      _attachments.add(
        _IssueAttachment(
          file: File(file!.path),
          isVideo: isVideo,
          thumbBytes: thumb,
        ),
      );
    });
  }

  Future<List<String>> _uploadAttachments(String technicianId) async {
    final urls = <String>[];
    final dio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 60),
        receiveTimeout: const Duration(minutes: 5),
        sendTimeout: const Duration(minutes: 5),
      ),
    );
    final ts = DateTime.now().millisecondsSinceEpoch;

    for (var i = 0; i < _attachments.length; i++) {
      final att = _attachments[i];
      final path = att.file.path.toLowerCase();
      var ext = 'jpg';
      var contentType = 'image/jpeg';
      if (path.endsWith('.png')) {
        ext = 'png';
        contentType = 'image/png';
      } else if (path.endsWith('.webp')) {
        ext = 'webp';
        contentType = 'image/webp';
      } else if (path.endsWith('.mp4')) {
        ext = 'mp4';
        contentType = 'video/mp4';
      } else if (path.endsWith('.mov')) {
        ext = 'mov';
        contentType = 'video/quicktime';
      } else if (path.endsWith('.m4v')) {
        ext = 'm4v';
        contentType = 'video/x-m4v';
      } else if (att.isVideo) {
        ext = 'mp4';
        contentType = 'video/mp4';
      }

      final length = await att.file.length();
      if (length <= 0) continue;

      final presign = await getDio().post(
        _apiUrl,
        data: {
          'action': 'getPresignedIssueAttachmentUrl',
          'technician_id': technicianId,
          'index': i + 1,
          'ext': ext,
          'contentType': contentType,
          'ts': ts,
        },
      );
      final body = presign.data is Map
          ? Map<String, dynamic>.from(presign.data as Map)
          : <String, dynamic>{};
      if (body['success'] != true) {
        throw Exception(body['message']?.toString() ?? 'فشل تجهيز رفع المرفق');
      }
      final data = body['data'] is Map
          ? Map<String, dynamic>.from(body['data'] as Map)
          : body;
      final uploadUrl = data['url']?.toString() ?? '';
      final publicUrl = data['publicUrl']?.toString() ?? '';
      if (uploadUrl.isEmpty) throw Exception('رابط الرفع فارغ');

      await dio.put(
        uploadUrl,
        data: att.file.openRead(),
        options: Options(
          headers: {
            'Content-Type': contentType,
            'Content-Length': length,
          },
        ),
      );
      if (publicUrl.isNotEmpty) urls.add(publicUrl);
    }
    return urls;
  }

  Future<void> _submit() async {
    if (_submitting) return;
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_issueType == null || _issueType!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('اختر نوع البلاغ')),
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final technicianId = prefs.getString('userId') ?? '';
      if (technicianId.isEmpty) {
        throw Exception('يجب تسجيل الدخول أولاً');
      }

      final attachmentUrls = _attachments.isEmpty
          ? <String>[]
          : await _uploadAttachments(technicianId);

      final result = await getDio().post(
        _apiUrl,
        data: {
          'action': 'reportIssue',
          'technician_id': technicianId,
          'issue_type': _issueType,
          'description': _descController.text.trim(),
          'location': _locationController.text.trim(),
          'attachments': attachmentUrls,
        },
      );
      final body = result.data is Map
          ? Map<String, dynamic>.from(result.data as Map)
          : <String, dynamic>{};
      final ok = body['success'] == true ||
          body['success'] == 1 ||
          body['success'] == 'true';
      if (!ok) {
        throw Exception(body['message']?.toString() ?? 'فشل إرسال البلاغ');
      }

      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (_) => Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text(
              'تم إرسال البلاغ',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
            ),
            content: const Text(
              'تم استلام بلاغك وسيتم إشعار الإدارة للمتابعة.',
              style: TextStyle(height: 1.5, fontSize: 14),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('حسناً', style: TextStyle(color: _orange)),
              ),
            ],
          ),
        ),
      );
      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceFirst('Exception: ', ''),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _pickIssueType() async {
    if (_submitting) return;
    final selected = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: Container(
          padding: EdgeInsets.fromLTRB(
            16,
            10,
            16,
            MediaQuery.paddingOf(ctx).bottom + 20,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE5E7EB),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'اختر نوع البلاغ',
                textAlign: TextAlign.right,
                style: RepairTheme.cairo(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: _textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'حدد التصنيف الأقرب للمشكلة',
                textAlign: TextAlign.right,
                style: RepairTheme.cairo(
                  fontSize: 12,
                  color: RepairTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 14),
              ..._issueTypes.map((type) {
                final active = type == _issueType;
                final icon = switch (type) {
                  'عطل فني غير مخطط' => Iconsax.setting_2,
                  'مشكلة أمان/خطورة بالموقع' => Iconsax.warning_2,
                  'نقص أدوات أو معدات' => Iconsax.box,
                  _ => Iconsax.mobile,
                };
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => Navigator.pop(ctx, type),
                      borderRadius: BorderRadius.circular(14),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 160),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: active
                              ? const Color(0xFFFFF0E5)
                              : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: active
                                ? _orange
                                : const Color(0xFFE8ECF1),
                            width: active ? 1.5 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: active
                                    ? _orange.withValues(alpha: 0.12)
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: active
                                      ? _orange.withValues(alpha: 0.25)
                                      : const Color(0xFFE8ECF1),
                                ),
                              ),
                              child: Icon(
                                icon,
                                size: 20,
                                color: active
                                    ? _orange
                                    : const Color(0xFF64748B),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                type,
                                style: RepairTheme.cairo(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: _textPrimary,
                                ),
                              ),
                            ),
                            Icon(
                              active
                                  ? Iconsax.tick_circle5
                                  : Iconsax.arrow_left_2,
                              size: 20,
                              color: active
                                  ? _orange
                                  : const Color(0xFFCBD5E1),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
    if (selected != null && mounted) {
      setState(() => _issueType = selected);
    }
  }

  Widget _issueTypeSelector({
    FormFieldState<String>? field,
    VoidCallback? onTap,
  }) {
    final hasError = field?.hasError == true;
    final selected = _issueType;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _submitting ? null : (onTap ?? _pickIssueType),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: hasError
                      ? const Color(0xFFEF4444)
                      : RepairTheme.border,
                  width: hasError ? 1.2 : 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Iconsax.category,
                    size: 20,
                    color: selected != null ? _orange : RepairTheme.hint,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      selected ?? 'اختر نوع البلاغ',
                      style: RepairTheme.cairo(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: selected != null
                            ? _textPrimary
                            : RepairTheme.hint,
                      ),
                    ),
                  ),
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Iconsax.arrow_down_1,
                      size: 16,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (hasError) ...[
          const SizedBox(height: 6),
          Text(
            field!.errorText ?? '',
            style: const TextStyle(color: Color(0xFFEF4444), fontSize: 12),
          ),
        ],
      ],
    );
  }

  Widget _label(String text, {bool required = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text(
            text,
            style: RepairTheme.cairo(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: _textPrimary,
            ),
          ),
          if (required) ...[
            const SizedBox(width: 4),
            const Text('*', style: TextStyle(color: Color(0xFFEF4444))),
          ],
        ],
      ),
    );
  }

  InputDecoration _fieldDecoration({
    String? hint,
    IconData? prefix,
    Widget? suffix,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: RepairTheme.cairo(fontSize: 13, color: RepairTheme.hint),
      filled: true,
      fillColor: Colors.white,
      prefixIcon: prefix == null
          ? null
          : Icon(prefix, color: _orange, size: 20),
      suffixIcon: suffix,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: RepairTheme.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: RepairTheme.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _orange, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFEF4444)),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: RepairTheme.border),
      ),
    );
  }

  void _openAttachmentPreview(_IssueAttachment att) {
    if (att.isVideo) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => _LocalVideoPreview(file: att.file),
        ),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => _LocalImagePreview(file: att.file),
        ),
      );
    }
  }

  Widget _attachmentsRow() {
    return SizedBox(
      height: 88,
      child: ListView(
        scrollDirection: Axis.horizontal,
        reverse: true,
        children: [
          GestureDetector(
            onTap: _submitting ? null : _pickAttachment,
            child: Container(
              width: 76,
              height: 76,
              margin: const EdgeInsets.only(left: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF0E5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _orange.withValues(alpha: 0.45)),
              ),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Iconsax.gallery_add, color: _orange, size: 22),
                  SizedBox(height: 4),
                  Text(
                    'إضافة',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: _orange,
                    ),
                  ),
                ],
              ),
            ),
          ),
          ...List.generate(_attachments.length, (i) {
            final att = _attachments[i];
            return Padding(
              padding: const EdgeInsets.only(left: 10),
              child: SizedBox(
                width: 76,
                height: 76,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned.fill(
                      child: GestureDetector(
                        onTap: () => _openAttachmentPreview(att),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: att.isVideo
                              ? (att.thumbBytes != null
                                  ? Stack(
                                      fit: StackFit.expand,
                                      children: [
                                        Image.memory(
                                          att.thumbBytes!,
                                          fit: BoxFit.cover,
                                        ),
                                        Container(
                                          color: Colors.black38,
                                          alignment: Alignment.center,
                                          child: const Icon(
                                            Iconsax.play_circle,
                                            color: Colors.white,
                                            size: 26,
                                          ),
                                        ),
                                      ],
                                    )
                                  : Container(
                                      color: Colors.black87,
                                      child: const Icon(
                                        Iconsax.video,
                                        color: Colors.white,
                                      ),
                                    ))
                              : Image.file(att.file, fit: BoxFit.cover),
                        ),
                      ),
                    ),
                    Positioned(
                      top: -6,
                      left: -6,
                      child: GestureDetector(
                        onTap: _submitting
                            ? null
                            : () => setState(() => _attachments.removeAt(i)),
                        child: Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            color: const Color(0xFFEF4444),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 1.5),
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
          }),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _bg,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          iconTheme: const IconThemeData(color: _textPrimary),
          title: const Text(
            'الإبلاغ عن مشكلة',
            style: TextStyle(
              color: _textPrimary,
              fontWeight: FontWeight.w800,
              fontSize: 17,
            ),
          ),
        ),
        body: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Existing header/icon section (kept)
                Center(
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: _green.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(
                      Iconsax.warning_2,
                      size: 34,
                      color: _green,
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'الإبلاغ عن مشكلة',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: _textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'أرسل تقرير عن عطل أو مشكلة فنية',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.black.withValues(alpha: 0.45),
                    fontWeight: FontWeight.w600,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 28),

                _label('نوع البلاغ', required: true),
                FormField<String>(
                  validator: (_) => (_issueType == null || _issueType!.isEmpty)
                      ? 'اختر نوع البلاغ'
                      : null,
                  builder: (field) => _issueTypeSelector(
                    field: field,
                    onTap: () async {
                      await _pickIssueType();
                      field.didChange(_issueType);
                    },
                  ),
                ),
                const SizedBox(height: 16),

                _label('وصف المشكلة', required: true),
                TextFormField(
                  controller: _descController,
                  maxLines: 5,
                  minLines: 4,
                  textAlign: TextAlign.right,
                  enabled: !_submitting,
                  style: RepairTheme.cairo(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  decoration: _fieldDecoration(
                    hint: 'اكتب تفاصيل المشكلة بوضوح...',
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'الرجاء كتابة وصف المشكلة';
                    }
                    if (v.trim().length < 8) {
                      return 'الوصف قصير جداً';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                _label('صورة / فيديو'),
                _attachmentsRow(),
                const SizedBox(height: 16),

                _label('الموقع', required: true),
                TextFormField(
                  controller: _locationController,
                  readOnly: _locationLocked || _submitting,
                  textAlign: TextAlign.right,
                  style: RepairTheme.cairo(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  decoration: _fieldDecoration(
                    hint: 'اسم الموقع أو العنوان',
                    prefix: Iconsax.location,
                    suffix: _locationLocked
                        ? const Icon(Iconsax.lock, size: 18, color: _green)
                        : null,
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'الموقع مطلوب';
                    }
                    return null;
                  },
                ),
                if (!_locationLocked) ...[
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: (_submitting || _loadingGps)
                          ? null
                          : _useCurrentLocation,
                      icon: _loadingGps
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: _orange,
                              ),
                            )
                          : const Icon(Iconsax.gps, size: 18, color: _orange),
                      label: Text(
                        'استخدام موقعي الحالي',
                        style: RepairTheme.cairo(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: _orange,
                        ),
                      ),
                    ),
                  ),
                ] else ...[
                  const SizedBox(height: 8),
                  Text(
                    'تم تعبئة الموقع من المهمة النشطة',
                    style: RepairTheme.cairo(
                      fontSize: 12,
                      color: _green,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
        bottomNavigationBar: SafeArea(
          child: RepairTheme.primaryButton(
            label: 'إرسال البلاغ',
            icon: Iconsax.send1,
            loading: _submitting,
            onTap: _submitting ? null : _submit,
          ),
        ),
      ),
    );
  }
}

class _IssueAttachment {
  final File file;
  final bool isVideo;
  final Uint8List? thumbBytes;

  _IssueAttachment({
    required this.file,
    required this.isVideo,
    this.thumbBytes,
  });
}

class _LocalImagePreview extends StatelessWidget {
  final File file;
  const _LocalImagePreview({required this.file});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          iconTheme: const IconThemeData(color: Colors.white),
          title: const Text(
            'معاينة الصورة',
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
        ),
        body: Center(
          child: InteractiveViewer(
            minScale: 1,
            maxScale: 4,
            child: Image.file(file, fit: BoxFit.contain),
          ),
        ),
      ),
    );
  }
}

class _LocalVideoPreview extends StatefulWidget {
  final File file;
  const _LocalVideoPreview({required this.file});

  @override
  State<_LocalVideoPreview> createState() => _LocalVideoPreviewState();
}

class _LocalVideoPreviewState extends State<_LocalVideoPreview> {
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
      final c = VideoPlayerController.file(widget.file);
      await c.initialize();
      if (!mounted) {
        await c.dispose();
        return;
      }
      _controller = c;
      _chewie = ChewieController(
        videoPlayerController: c,
        autoPlay: true,
        looping: false,
        allowMuting: true,
        showControls: true,
      );
      setState(() {});
    } catch (e) {
      if (mounted) {
        setState(() => _error = 'تعذر تشغيل الفيديو');
      }
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
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          iconTheme: const IconThemeData(color: Colors.white),
          title: const Text(
            'معاينة الفيديو',
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
        ),
        body: Center(
          child: _error != null
              ? Text(
                  _error!,
                  style: const TextStyle(color: Colors.white70),
                )
              : _chewie != null
                  ? Chewie(controller: _chewie!)
                  : const CircularProgressIndicator(color: Colors.white),
        ),
      ),
    );
  }
}
