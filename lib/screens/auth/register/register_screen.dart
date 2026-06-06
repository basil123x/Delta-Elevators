import 'dart:math';

import 'package:Delta/screens/auth/OTP/otp_screen.dart';
import 'package:Delta/screens/auth/login/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iconsax/iconsax.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  static const Color _orange = Color(0xFFF37021);
  static const Color _textDark = Color(0xFF1A1A2E);

  final TextEditingController nameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final FocusNode _nameFocus = FocusNode();
  final FocusNode _phoneFocus = FocusNode();

  int _nameLength = 0;
  int _phoneLength = 0;

  @override
  void initState() {
    super.initState();
    nameController.addListener(_onNameChanged);
    phoneController.addListener(_onPhoneChanged);
    _nameFocus.addListener(_onFocusChanged);
    _phoneFocus.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    nameController.removeListener(_onNameChanged);
    phoneController.removeListener(_onPhoneChanged);
    _nameFocus.removeListener(_onFocusChanged);
    _phoneFocus.removeListener(_onFocusChanged);
    nameController.dispose();
    phoneController.dispose();
    _nameFocus.dispose();
    _phoneFocus.dispose();
    super.dispose();
  }

  void _onFocusChanged() => setState(() {});

  void _onNameChanged() {
    setState(() {
      _nameLength = nameController.text.length;
    });
  }

  void _onPhoneChanged() {
    setState(() {
      _phoneLength = phoneController.text.length;
    });
  }

  Color _nameFieldBorderColor() {
    if (_nameLength == 0) return const Color(0xFFEFEFEF);
    if (_nameLength >= 3) return const Color(0xFF4CAF50);
    return const Color(0xFFFF4B4B);
  }

  Widget _buildNameValidationIcon() {
    if (nameController.text.isEmpty) {
      return const SizedBox(width: 8);
    }
    final ok = nameController.text.length >= 3;
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: ok ? const Color(0xFF4CAF50) : const Color(0xFFFF4B4B),
      ),
      child: Icon(
        ok ? Iconsax.tick_circle : Iconsax.close_circle,
        color: Colors.white,
        size: 14,
      ),
    );
  }

  Color _phoneFieldBorderColor() {
    if (_phoneLength == 0) return const Color(0xFFEFEFEF);
    if (_phoneLength == 8) return const Color(0xFF4CAF50);
    return const Color(0xFFFF4B4B);
  }

  Widget _buildPhoneValidationIcon() {
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
        isValid ? Iconsax.tick_circle : Iconsax.close_circle,
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

  void _goOtp() {
    final otp = 100000 + Random().nextInt(900000);
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (context) => OTPScreen(
          mobile: phoneController.text.trim(),
          name: nameController.text.trim(),
          otp: otp,
          keylogin: "Register",
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
              errorBuilder: (_, __, ___) =>
                  Icon(Iconsax.building, color: _orange, size: 40),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final nameFocused = _nameFocus.hasFocus;
    final phoneFocused = _phoneFocus.hasFocus;
    final screenHeight = MediaQuery.sizeOf(context).height;
    final topInset = MediaQuery.paddingOf(context).top;
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
                                text: 'أنشئ ',
                                style: TextStyle(
                                  color: _textDark,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 26,
                                ),
                              ),
                              TextSpan(
                                text: 'حسابك',
                                style: TextStyle(
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
                          'سعداء بانضمامك معنا',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 28),
                        Text(
                          'الاسم الكامل',
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
                            color: nameFocused
                                ? const Color(0xFFFFF8F4)
                                : const Color(0xFFF8F8F8),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: _nameFieldBorderColor(),
                              width: 1.5,
                            ),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Row(
                            textDirection: TextDirection.rtl,
                            children: [
                              Container(
                                width: 34,
                                height: 34,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: const Color(0xFFEEEEEE),
                                  ),
                                ),
                                child: Icon(
                                  Iconsax.user,
                                  color: _orange,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: TextFormField(
                                  controller: nameController,
                                  focusNode: _nameFocus,
                                  keyboardType: TextInputType.name,
                                  textDirection: TextDirection.rtl,
                                  textAlign: TextAlign.right,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: _textDark,
                                  ),
                                  decoration: const InputDecoration(
                                    hintText: 'قم بإدخال إسمك الشخصي',
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
                              _buildNameValidationIcon(),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
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
                              Text(
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
                                  style: TextStyle(
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
                              _buildPhoneValidationIcon(),
                            ],
                          ),
                        ),
                        const SizedBox(height: 28),
                        SizedBox(
                          height: 54,
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: _goOtp,
                            style: FilledButton.styleFrom(
                              backgroundColor: _orange,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                            ),
                            child: const Center(
                              child: Text(
                                'إنشاء الحساب',
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
                              'لدي حساب بالفعل؟',
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
                                    builder: (context) => const LoginScreen(),
                                  ),
                                );
                              },
                              child: Text(
                                ' تسجيل الدخول',
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
              Positioned(
                top: topInset + 4,
                right: 8,
                child: IconButton(
                  onPressed: () => Navigator.maybePop(context),
                  icon: const Icon(
                    Iconsax.arrow_left_3,
                    size: 18,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
