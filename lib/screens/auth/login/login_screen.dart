import 'dart:math';

import 'package:Delta/screens/auth/OTP/otp_screen.dart';
import 'package:Delta/screens/auth/auth_design.dart';
import 'package:Delta/screens/auth/register/register_screen.dart';
import 'package:Delta/services/DioServiceCert.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  static const Color _orange = Color(0xFFF37021);
  static const Color _textDark = Color(0xFF1A1A2E);

  final TextEditingController phoneController = TextEditingController();
  final FocusNode _phoneFocus = FocusNode();
  bool isValidPhone = false;
  bool isLoading = false;
  int _phoneLength = 0;

  @override
  void initState() {
    super.initState();
    phoneController.addListener(_onPhoneChanged);
    _phoneFocus.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    phoneController.removeListener(_onPhoneChanged);
    _phoneFocus.removeListener(_onFocusChanged);
    _phoneFocus.dispose();
    phoneController.dispose();
    super.dispose();
  }

  void _onFocusChanged() => setState(() {});

  void _onPhoneChanged() {
    setState(() {
      _phoneLength = phoneController.text.length;
    });
    validatePhone();
  }

  static bool isValidQatarPhone(String phone) {
    final cleanPhone = phone.replaceAll(RegExp(r'[^\d]'), '');
    return cleanPhone.length == 8 && RegExp(r'^\d{8}$').hasMatch(cleanPhone);
  }

  void validatePhone() {
    final isValid = isValidQatarPhone(phoneController.text);
    if (isValidPhone != isValid) {
      setState(() {
        isValidPhone = isValid;
      });
    }
  }

  Future<void> _submit() async {
    setState(() => isLoading = true);
    try {
      final result = await getDio().post(
        "https://daltalifts.com/app2026/sql.php",
        options: Options(
          headers: {"Content-Type": "application/json"},
        ),
        data: {
          "action": "checkUser",
          "phone": phoneController.text.trim(),
        },
      );

      final response = authResponseAsMap(result.data);
      // API may return `id` as String; never use it as a List index without parsing.
      // ignore: unused_local_variable
      final safeRowIndex =
          int.tryParse(response['id']?.toString() ?? '') ?? 0;

      final success = response['success'] == true ||
          response['success'] == 1 ||
          response['success'] == 'true';

      if (!mounted) return;
      if (success) {
        setState(() => isLoading = false);
        final otp = 100000 + Random().nextInt(900000);
        Navigator.push(
          context,
          MaterialPageRoute<void>(
            builder: (context) => OTPScreen(
              mobile: phoneController.text.trim(),
              otp: otp,
              keylogin: "Login",
            ),
          ),
        );
      } else {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AuthDesign.orange,
            content: const Text(
              "المستخدم ليس مسجلا فقط قم بالتسجيل الأن",
            ),
          ),
        );
        Navigator.push(
          context,
          MaterialPageRoute<void>(
            builder: (context) => const RegisterScreen(),
          ),
        );
      }
    } catch (_) {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Color _phoneFieldBorderColor() {
    if (_phoneLength == 0) return const Color(0xFFEFEFEF);
    if (_phoneLength == 8) return const Color(0xFF4CAF50);
    return const Color(0xFFFF4B4B);
  }

  Widget _buildValidationIcon() {
    if (phoneController.text.isEmpty) {
      return const SizedBox(width: 8);
    }
    final isValid = phoneController.text.length == 8;
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isValid ? const Color(0xFF4CAF50) : const Color(0xFFFF4B4B),
      ),
      child: Icon(
        isValid ? Icons.check : Icons.close,
        color: Colors.white,
        size: 14,
      ),
    );
  }

  Widget _qatarFlagBadge() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(2),
      child: Image.asset(
        'assets/img/qatar.png',
        width: 24,
        height: 16,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          width: 24,
          height: 16,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(2),
            border: Border.all(color: const Color(0xFFE0E0E0)),
          ),
          child: Row(
            children: [
              Container(width: 8, color: const Color(0xFF8D1B3D)),
              Expanded(child: Container(color: Colors.white)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _authOverlapLogo() {
    return CircleAvatar(
      radius: 40,
      backgroundColor: Colors.white,
      child: CircleAvatar(
        radius: 36,
        backgroundColor: _orange.withOpacity(0.2),
        child: ClipOval(
          child: Image.asset(
            'assets/images/logo.png',
            width: 50,
            height: 50,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Image.asset(
              'assets/img/logo.png',
              width: 50,
              height: 50,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Icon(
                Icons.apartment_rounded,
                color: _orange,
                size: 40,
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final phoneFocused = _phoneFocus.hasFocus;
    final screenHeight = MediaQuery.sizeOf(context).height;
    final whiteCardTop = screenHeight * 0.18;
    final logoTop = screenHeight * 0.11;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _orange,
        resizeToAvoidBottomInset: false,
        body: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                top: whiteCardTop,
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  clipBehavior: Clip.antiAlias,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(25),
                      topRight: Radius.circular(25),
                    ),
                  ),
                  child: SingleChildScrollView(
                    physics: const ClampingScrollPhysics(),
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: EdgeInsets.only(
                      left: 24,
                      right: 24,
                      top: 56,
                      bottom: MediaQuery.viewInsetsOf(context).bottom + 24,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                          Text(
                            'DELTA ELEVATORS',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey.shade600,
                              letterSpacing: 2,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(
                                  text: 'أهلاً بك ',
                                  style: TextStyle(
                                    color: _textDark,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 26,
                                  ),
                                ),
                                TextSpan(
                                  text: 'مجدداً',
                                  style: const TextStyle(
                                    color: _orange,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 26,
                                  ),
                                ),
                              ],
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'سجل دخولك للمتابعة',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 28),
                          Text(
                            'رقم الهاتف',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF555555),
                            ),
                          ),
                          const SizedBox(height: 6),
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            curve: Curves.easeOut,
                            height: 54,
                            decoration: BoxDecoration(
                              color: phoneFocused
                                  ? const Color(0xFFFFF8F4)
                                  : const Color(0xFFF8F8F8),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: _phoneFieldBorderColor(),
                                width: 1.5,
                              ),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Row(
                              textDirection: TextDirection.rtl,
                              children: [
                                _qatarFlagBadge(),
                                const SizedBox(width: 8),
                                const Text(
                                  '+974',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: _textDark,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Container(
                                  width: 1,
                                  height: 28,
                                  color: const Color(0xFFE8E8E8),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: TextFormField(
                                    controller: phoneController,
                                    focusNode: _phoneFocus,
                                    keyboardType: TextInputType.number,
                                    textDirection: TextDirection.rtl,
                                    textAlign: TextAlign.right,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: _textDark,
                                    ),
                                    inputFormatters: [
                                      FilteringTextInputFormatter.digitsOnly,
                                      LengthLimitingTextInputFormatter(8),
                                    ],
                                    decoration: const InputDecoration(
                                      hintText: '12345678',
                                      border: InputBorder.none,
                                      isDense: true,
                                      contentPadding: EdgeInsets.zero,
                                      hintStyle: TextStyle(
                                        color: Color(0xFF9E9E9E),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                _buildValidationIcon(),
                              ],
                            ),
                          ),
                          const SizedBox(height: 28),
                          SizedBox(
                            height: 54,
                            width: double.infinity,
                            child: FilledButton(
                              onPressed: isLoading ? null : _submit,
                              style: FilledButton.styleFrom(
                                backgroundColor: _orange,
                                foregroundColor: Colors.white,
                                disabledBackgroundColor:
                                    _orange.withValues(alpha: 0.65),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                              ),
                              child: isLoading
                                  ? const Center(
                                      child: SizedBox(
                                        height: 24,
                                        width: 24,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.5,
                                          color: Colors.white,
                                        ),
                                      ),
                                    )
                                  : const Center(
                                      child: Text(
                                        'تسجيل الدخول',
                                        textDirection: TextDirection.rtl,
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 28),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            textDirection: TextDirection.rtl,
                            children: [
                              Text(
                                'ليس لديك حساب؟',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute<void>(
                                      builder: (context) => const RegisterScreen(),
                                    ),
                                  );
                                },
                                child: const Text(
                                  ' أنشئ حساباً الآن',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: _orange,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(
                            height: MediaQuery.sizeOf(context).height * 0.08,
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                top: logoTop,
                left: 0,
                right: 0,
                child: Center(child: _authOverlapLogo()),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
