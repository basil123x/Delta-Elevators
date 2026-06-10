import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:Delta/services/DioServiceCert.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_boxicons/flutter_boxicons.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pinput/pinput.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sms_autofill/sms_autofill.dart';
import 'package:iconsax/iconsax.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with CodeAutoFill {
  static const Color _orange = Color(0xFFF37021);
  static const Color _bodyBg = Color(0xFFF2F3F7);
  static const Color _textDark = Color(0xFF1A1A2E);

  final TextEditingController userController = TextEditingController();
  final TextEditingController mobile = TextEditingController();
  final TextEditingController otpController = TextEditingController();

  int otp = 100000 + Random().nextInt(900000);
  String mobilex = '';

  bool isEditing = false;
  bool isVerify = false;
  bool isLoading = false;
  bool isOtpSent = false;
  bool isOtpVerified = false;
  bool _waSending = false;
  String? _profileImageUrl;
  bool _uploadingPhoto = false;

  String _avatarLetter() {
    final t = userController.text.trim();
    if (t.isEmpty) return 'U';
    return t.substring(0, 1);
  }

  String _phoneDisplayLine() {
    final raw = mobilex.trim();
    if (raw.isEmpty) return '—';
    final digits = raw.replaceAll(RegExp(r'\D'), '');
    if (digits.length >= 8) {
      final last8 = digits.length > 8
          ? digits.substring(digits.length - 8)
          : digits;
      return '+974 $last8';
    }
    if (raw.startsWith('+')) return raw;
    return '+974 $raw';
  }

  bool _samePhoneAsProfile(String val) {
    final a = val.replaceAll(RegExp(r'\D'), '');
    final b = mobilex.replaceAll(RegExp(r'\D'), '');
    if (a.length >= 8 && b.length >= 8) {
      return a.substring(a.length - 8) == b.substring(b.length - 8);
    }
    return val.trim() == mobilex.trim();
  }

  Future<void> _onMobileChanged(String val) async {
    setState(() {
      isOtpVerified = false;
      isOtpSent = false;
      otpController.clear();
    });
    if (val.length != 8) {
      setState(() => isVerify = false);
      return;
    }
    await _checkPhoneAvailability(val);
  }

  Future<void> _checkPhoneAvailability(String phone) async {
    if (phone == mobilex.trim()) {
      setState(() {
        isVerify = false;
        isOtpVerified = true;
      });
      return;
    }

    try {
      final result = await getDio().post(
        'https://daltalifts.com/app2026/sql.php',
        data: {'action': 'checkPhone', 'phone': phone},
      );

      if (!mounted) return;

      final exists = result.data['exists'] == true;

      if (exists) {
        setState(() => isVerify = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('هذا الرقم مسجل بالفعل في النظام'),
            backgroundColor: const Color(0xFFFF4B4B),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      } else {
        setState(() => isVerify = true);
      }
    } catch (e) {
      debugPrint('Check phone error: $e');
    }
  }

  Future<void> _sendPhoneOtpTap() async {
    if (mobile.text.trim().length != 8) return;

    try {
      final checkResult = await getDio().post(
        'https://daltalifts.com/app2026/sql.php',
        data: {'action': 'checkPhone', 'phone': mobile.text.trim()},
      );

      final exists = checkResult.data['exists'] == true;
      if (exists) {
        if (!mounted) return;
        setState(() => isVerify = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('هذا الرقم مسجل بالفعل في النظام'),
            backgroundColor: const Color(0xFFFF4B4B),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
        return;
      }
    } catch (e) {
      debugPrint('Safety check error: $e');
      return;
    }

    setState(() => _waSending = true);

    otp = 100000 + Random().nextInt(900000);

    try {
      await getDio().post(
        'https://graph.facebook.com/v22.0/1019878864550538/messages',
        options: Options(
          headers: {
            'Authorization':
                'Bearer EAAdhZCjMZCRZBABQZBhtWgeoQcYCOzXj32zhFSLi7aELSVCWDp32TaP8pd0NNbiZChZB95UwEvQw89izAsQuQEXugIMyiqZAQT8ZAxuq0CZAk8T323L6xJdxcLyG5MybKsaO4wtR9iCZBYMAHQdUg3ZAo9ApDHCld4Y6wri7JG39JBsagQa0aqqQAHWM8BfnEJsMgZDZD',
          },
        ),
        data: {
          'messaging_product': 'whatsapp',
          'to': '974${mobile.text.trim()}',
          'type': 'template',
          'template': {
            'name': 'verify_otp',
            'language': {'code': 'ar'},
            'components': [
              {
                'type': 'body',
                'parameters': [
                  {'type': 'text', 'text': otp.toString()},
                ],
              },
              {
                'type': 'button',
                'sub_type': 'url',
                'index': 0,
                'parameters': [
                  {'type': 'text', 'text': otp.toString()},
                ],
              },
            ],
          },
        },
      );

      if (!mounted) return;
      setState(() {
        _waSending = false;
        isOtpSent = true;
      });

      if (Platform.isAndroid) {
        unawaited(_startOtpListening());
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('تم إرسال رمز التحقق على واتساب'),
          backgroundColor: const Color(0xFF22C55E),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        setState(() => _waSending = false);
      }
      debugPrint('WhatsApp OTP error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('تعذر إرسال الرمز، حاول مرة أخرى'),
            backgroundColor: const Color(0xFFFF4B4B),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  Future<void> _startOtpListening() async {
    if (!Platform.isAndroid) return;
    await cancel();
    listenForCode(smsCodeRegexPattern: r'\d{6}');
  }

  @override
  void codeUpdated() {
    if (!mounted || !isOtpSent) return;
    final raw = code;
    if (raw == null || raw.isEmpty) return;
    final match = RegExp(r'\d{6}').firstMatch(raw);
    final six = match?.group(0) ?? raw.replaceAll(RegExp(r'\D'), '');
    if (six.length != 6) return;
    debugPrint('📲 Profile OTP received: $six');
    otpController.text = six;
    setState(() {});
    Future<void>.delayed(const Duration(milliseconds: 300), () async {
      if (mounted) {
        _verifyOtp(six);
      }
    });
  }

  void _verifyOtp(String pin) {
    if (pin == otp.toString()) {
      if (Platform.isAndroid) {
        unawaited(cancel());
      }
      setState(() {
        isOtpSent = false;
        isVerify = false;
        isOtpVerified = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('تم التحقق بنجاح ✓ اضغط حفظ التغييرات'),
          backgroundColor: const Color(0xFF22C55E),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    } else {
      otpController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('رمز التحقق غير صحيح، حاول مرة أخرى'),
          backgroundColor: const Color(0xFFFF4B4B),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  bool get _phoneChangedForBorder =>
      mobile.text.trim().isNotEmpty && !_samePhoneAsProfile(mobile.text.trim());

  Future<void> updateProfile(String name, String mob) async {
    setState(() {
      isLoading = true;
    });
    final SharedPreferences prefx = await SharedPreferences.getInstance();
    final String uid = prefx.getString('userId') ?? '';
    final result = await getDio().post(
      'https://daltalifts.com/app2026/sql.php?k=${DateTime.now().millisecondsSinceEpoch}',
      data: {
        'action': 'updateProfile',
        'uid': uid,
        'name': name,
        'mobile': mob,
      },
    );
    if (result.data['success'] == true) {
      await prefx.setString('userName', name.trim());
      await prefx.setString('userPhone', mob.trim());
      if (!mounted) return;
      setState(() => isLoading = false);
      Navigator.pop(context);
      return;
    }
    if (mounted) {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> getUserProfile() async {
    final SharedPreferences prefx = await SharedPreferences.getInstance();
    final String uid = prefx.getString('userId') ?? '';
    final result = await getDio().post(
      'https://daltalifts.com/app2026/sql.php?k=${DateTime.now().millisecondsSinceEpoch}',
      data: {'action': 'profile', 'uid': uid},
    );
    if (!mounted) return;
    final data = result.data['data'];
    if (data is! Map) return;
    final photo = data['a6']?.toString() ?? '';
    if (photo.isNotEmpty) {
      await prefx.setString('profilePhoto', photo);
    }
    if (!mounted) return;
    setState(() {
      userController.text = data['a1']?.toString() ?? '';
      mobile.text = data['a2']?.toString() ?? '';
      mobilex = data['a2']?.toString() ?? '';
      _profileImageUrl = photo.isEmpty ? null : photo;
      isOtpSent = false;
      isVerify = false;
      isOtpVerified = true;
      otpController.clear();
    });
  }

  Future<void> _saveProfile() async {
    if (userController.text.trim().isEmpty) return;

    final phoneReallyChanged = !_samePhoneAsProfile(mobile.text.trim());
    if (phoneReallyChanged && !isOtpVerified) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('يجب التحقق من رقم الهاتف الجديد أولاً'),
          backgroundColor: const Color(0xFFFF4B4B),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      return;
    }

    await updateProfile(userController.text.trim(), mobile.text.trim());
  }

  @override
  void initState() {
    super.initState();
    getUserProfile();
  }

  Future<String?> _uploadProfilePhotoToS3(File file) async {
    final prefs = await SharedPreferences.getInstance();
    final uid = prefs.getString('userId') ?? '';
    if (uid.isEmpty) return null;

    final rawExt = file.path.split('.').last;
    final ext =
        (rawExt.length <= 5 && RegExp(r'^[a-zA-Z0-9]+$').hasMatch(rawExt))
        ? rawExt
        : 'jpg';

    final dio = Dio();
    dio.options.connectTimeout = const Duration(seconds: 60);
    dio.options.receiveTimeout = const Duration(seconds: 60);

    final presignRes = await dio.post(
      'https://daltalifts.com/app2026/sql.php',
      data: jsonEncode({
        'action': 'getPresignedProfilePhotoUrl',
        'userId': uid,
        'ext': ext,
        'ts': DateTime.now().millisecondsSinceEpoch,
      }),
      options: Options(contentType: 'application/json'),
    );

    final presignData = presignRes.data is String
        ? jsonDecode(presignRes.data as String)
        : presignRes.data;
    if (presignData is! Map || presignData['success'] != true) return null;

    final uploadUrl = presignData['url']?.toString();
    final publicUrl = presignData['publicUrl']?.toString();
    if (uploadUrl == null || uploadUrl.isEmpty) return null;

    final bytes = await file.readAsBytes();
    final mime = ext.toLowerCase() == 'png' ? 'image/png' : 'image/jpeg';

    await dio.put(
      uploadUrl,
      data: Stream.fromIterable([bytes]),
      options: Options(
        headers: {'Content-Type': mime, 'Content-Length': bytes.length},
      ),
    );

    return publicUrl?.isNotEmpty == true ? publicUrl : null;
  }

  Future<void> _pickAndUploadPhoto() async {
    if (_uploadingPhoto) return;

    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: EdgeInsets.only(
          bottom: MediaQuery.paddingOf(ctx).bottom + 16,
          top: 8,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFE0E0E0),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            ListTile(
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
              leading: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF0E5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Iconsax.camera,
                  color: _orange,
                  size: 20,
                ),
              ),
              title: const Text(
                'التقاط صورة',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: _textDark,
                ),
              ),
              subtitle: Text(
                'افتح الكاميرا',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
              ),
            ),
            const Divider(height: 1, indent: 16, endIndent: 16),
            ListTile(
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
              leading: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF4FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Iconsax.gallery,
                  color: Color(0xFF3B82F6),
                  size: 20,
                ),
              ),
              title: const Text(
                'اختر من المعرض',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: _textDark,
                ),
              ),
              subtitle: Text(
                'اختر صورة من هاتفك',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: GestureDetector(
                onTap: () => Navigator.pop(ctx),
                child: Container(
                  width: double.infinity,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Text(
                      'إلغاء',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );

    if (source == null || !mounted) return;

    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: source,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 85,
    );

    if (image == null || !mounted) return;

    setState(() => _uploadingPhoto = true);

    try {
      final url = await _uploadProfilePhotoToS3(File(image.path));
      if (url == null || !mounted) {
        if (mounted) setState(() => _uploadingPhoto = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('فشل رفع الصورة، حاول مرة أخرى'),
              backgroundColor: const Color(0xFFFF4B4B),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }
        return;
      }

      final prefs = await SharedPreferences.getInstance();
      final uid = prefs.getString('userId') ?? '';
      final saveRes = await getDio().post(
        'https://daltalifts.com/app2026/sql.php',
        data: {'action': 'updateProfilePhoto', 'uid': uid, 'photo': url},
      );

      if (!mounted) return;

      if (saveRes.data['success'] == true) {
        await prefs.setString('profilePhoto', url);
        debugPrint('✅ profilePhoto saved: $url');
        setState(() {
          _profileImageUrl = url;
          _uploadingPhoto = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('تم تحديث الصورة بنجاح'),
            backgroundColor: const Color(0xFF22C55E),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      } else {
        setState(() => _uploadingPhoto = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('فشل حفظ رابط الصورة'),
            backgroundColor: const Color(0xFFFF4B4B),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('Photo upload error: $e');
      if (mounted) {
        setState(() => _uploadingPhoto = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('فشل رفع الصورة، حاول مرة أخرى'),
            backgroundColor: const Color(0xFFFF4B4B),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    if (Platform.isAndroid) {
      cancel();
    }
    userController.dispose();
    mobile.dispose();
    otpController.dispose();
    super.dispose();
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      color: _orange,
      padding: EdgeInsets.only(
        top: MediaQuery.paddingOf(context).top + 12,
        bottom: 24,
        left: 16,
        right: 16,
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: -20,
            right: -20,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
          ),
          Positioned(
            bottom: 10,
            left: -10,
            child: Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.06),
              ),
            ),
          ),
          Column(
            children: [
              Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        isEditing = !isEditing;
                        if (!isEditing) {
                          mobile.text = mobilex;
                          otpController.clear();
                          isVerify = false;
                          isOtpSent = false;
                          isOtpVerified = false;
                          _waSending = false;
                          if (Platform.isAndroid) {
                            unawaited(cancel());
                          }
                        }
                      });
                    },
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.20),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.30),
                        ),
                      ),
                      child: const Icon(
                        Iconsax.edit,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
                  const Expanded(
                    child: Text(
                      'ملفي الشخصي',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.maybePop(context),
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.20),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.30),
                        ),
                      ),
                      child: const Icon(
                        Iconsax.arrow_left_3,
                        color: Colors.white,
                        size: 15,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 88,
                    height: 88,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.25),
                      border: Border.all(color: Colors.white, width: 3),
                    ),
                    child: ClipOval(
                      child: _uploadingPhoto
                          ? ColoredBox(
                              color: Colors.white.withValues(alpha: 0.3),
                              child: const Center(
                                child: SizedBox(
                                  width: 28,
                                  height: 28,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            )
                          : _profileImageUrl != null &&
                                _profileImageUrl!.isNotEmpty
                          ? Image.network(
                              _profileImageUrl!,
                              fit: BoxFit.cover,
                              width: 88,
                              height: 88,
                              loadingBuilder: (ctx, child, progress) {
                                if (progress == null) return child;
                                return const Center(
                                  child: SizedBox(
                                    width: 28,
                                    height: 28,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  ),
                                );
                              },
                              errorBuilder: (_, __, ___) => Center(
                                child: Text(
                                  _avatarLetter(),
                                  style: const TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            )
                          : Center(
                              child: Text(
                                _avatarLetter(),
                                style: const TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    child: GestureDetector(
                      onTap: _uploadingPhoto ? null : _pickAndUploadPhoto,
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _textDark,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(
                          Iconsax.camera,
                          size: 13,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                userController.text.isNotEmpty ? userController.text : '—',
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _phoneDisplayLine(),
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withValues(alpha: 0.65),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNameSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8, right: 4),
          child: Text(
            'المعلومات الشخصية',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: Colors.grey.shade600,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFEBEBEB)),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            child: Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Icon(
                    Iconsax.edit,
                    size: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'الاسم الكامل',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      TextFormField(
                        controller: userController,
                        textAlign: TextAlign.right,
                        textDirection: TextDirection.rtl,
                        enabled: isEditing,
                        onChanged: (_) => setState(() {}),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: _textDark,
                        ),
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                          hintText: 'أدخل اسمك',
                          hintStyle: TextStyle(color: Colors.grey.shade400),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    color: Color(0xFFEDFAF4),
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                  ),
                  child: const Icon(
                    Iconsax.user,
                    color: Color(0xFF22C55E),
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPhoneSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8, right: 4),
          child: Text(
            'رقم الهاتف',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: Colors.grey.shade600,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _phoneChangedForBorder
                  ? const Color(0xFFFFD9BB)
                  : const Color(0xFFEBEBEB),
              width: _phoneChangedForBorder ? 1.5 : 1,
            ),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 13,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: Icon(
                        Iconsax.lock,
                        size: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'الرقم الحالي',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            mobilex.isEmpty ? '—' : mobilex,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: _textDark,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        color: Color(0xFFFFF0E5),
                        borderRadius: BorderRadius.all(Radius.circular(12)),
                      ),
                      child: const Icon(
                        Iconsax.call,
                        color: _orange,
                        size: 20,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: Color(0xFFF5F5F5)),
              Container(
                color: const Color(0xFFFFF8F4),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 9,
                ),
                child: Row(
                  children: [
                    const Icon(
                      Iconsax.info_circle,
                      size: 14,
                      color: _orange,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'تغيير الرقم يتطلب التحقق عبر واتساب',
                        style: const TextStyle(
                          fontSize: 10,
                          color: _orange,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.right,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: Color(0xFFF5F5F5)),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        children: [
                          Text('🇶🇦', style: TextStyle(fontSize: 14)),
                          SizedBox(width: 4),
                          Text(
                            '+974',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: _textDark,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                        controller: mobile,
                        enabled: isEditing,
                        keyboardType: TextInputType.phone,
                        maxLength: 8,
                        textAlign: TextAlign.right,
                        textDirection: TextDirection.rtl,
                        onChanged: _onMobileChanged,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                        decoration: InputDecoration(
                          counterText: '',
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                          hintText: 'أدخل الرقم الجديد',
                          hintStyle: TextStyle(
                            color: Colors.grey.shade400,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (isVerify && !isOtpSent)
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
                  child: GestureDetector(
                    onTap: _waSending ? null : () => _sendPhoneOtpTap(),
                    child: Container(
                      height: 44,
                      decoration: BoxDecoration(
                        color: _orange,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: _waSending
                          ? const Center(
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Boxicons.bxl_whatsapp,
                                  color: Colors.white,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  'إرسال رمز التحقق واتساب',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ),
              if (isOtpSent)
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Text(
                          'أدخل رمز التحقق المرسل على واتساب',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ),
                      AutofillGroup(
                        child: Directionality(
                          textDirection: TextDirection.ltr,
                          child: Pinput(
                            controller: otpController,
                            length: 6,
                            onCompleted: _verifyOtp,
                            autofillHints: [AutofillHints.oneTimeCode],
                            defaultPinTheme: PinTheme(
                              width: 42,
                              height: 48,
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8F8F8),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: const Color(0xFFEBEBEB),
                                ),
                              ),
                              textStyle: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: _textDark,
                              ),
                            ),
                            focusedPinTheme: PinTheme(
                              width: 42,
                              height: 48,
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFF8F4),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: _orange, width: 1.5),
                              ),
                              textStyle: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: _textDark,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      GestureDetector(
                        onTap: _waSending
                            ? null
                            : () async {
                                otpController.clear();
                                setState(() => isOtpSent = false);
                                await _sendPhoneOtpTap();
                              },
                        child: const Text(
                          'إعادة إرسال الرمز',
                          style: TextStyle(
                            fontSize: 11,
                            color: _orange,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSaveButton() {
    return Container(
      width: double.infinity,
      height: 54,
      decoration: BoxDecoration(
        color: _textDark,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: isLoading ? null : _saveProfile,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isLoading)
                const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              else ...[
                const Icon(Iconsax.save_2, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                const Text(
                  'حفظ التغييرات',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _bodyBg,
        body: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: _bodyBg,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(28),
                    topRight: Radius.circular(28),
                  ),
                ),
                clipBehavior: Clip.hardEdge,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    children: [
                      _buildNameSection(),
                      const SizedBox(height: 12),
                      _buildPhoneSection(),
                      const SizedBox(height: 16),
                      if (isEditing) _buildSaveButton(),
                      SizedBox(
                        height: MediaQuery.paddingOf(context).bottom + 30,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
