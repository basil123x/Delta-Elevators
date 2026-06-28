import 'dart:convert';

import 'package:Delta/screens/main/main_screen.dart';
import 'package:Delta/screens/repair/repair_theme.dart';
import 'package:Delta/services/DioServiceCert.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iconsax/iconsax.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Delta customer ("عميل دلتا") entry point: the customer types the phone
/// number registered with Delta, we verify it has an active contract, then
/// continue straight to the maintenance request screen.
class DeltaCustomerLoginScreen extends StatefulWidget {
  const DeltaCustomerLoginScreen({super.key});

  @override
  State<DeltaCustomerLoginScreen> createState() =>
      _DeltaCustomerLoginScreenState();
}

class _DeltaCustomerLoginScreenState extends State<DeltaCustomerLoginScreen> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  bool _isLoading = false;

  bool _otpSent = false;
  int? _expectedOtp;
  String? _pendingUid;
  String? _pendingContractId;
  String? _pendingAddressId;
  String? _pendingPhone;

  static const String _endpoint =
      "https://daltalifts.com/app2026/api/verify_delta_customer.php";

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: RepairTheme.cairo(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFFEF4444),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Future<void> _verify() async {
    final phone = _phoneController.text.trim();

    if (phone.isEmpty) {
      _showError("أدخل رقم الهاتف");
      return;
    }
    if (phone.length < 8) {
      _showError("رقم الهاتف يجب أن يكون 8 أرقام على الأقل");
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() => _isLoading = true);

    try {
      final response = await getDio().post(
        _endpoint,
        data: {"phone": phone},
        options: Options(
          contentType: Headers.formUrlEncodedContentType,
        ),
      );

      final data = response.data is String
          ? _tryDecode(response.data as String)
          : response.data;

      if (data is Map && data['success'] == true && data['status'] == 'otp_sent') {
        // Phone verified and an OTP was sent (e.g. via WhatsApp). Keep the
        // returned customer data and swap the UI to the OTP step.
        _pendingUid = data['uid']?.toString() ?? "";
        _pendingContractId = data['contract_id']?.toString() ?? "";
        _pendingAddressId = data['address_id']?.toString() ?? "";
        _pendingPhone = data['phone']?.toString() ?? phone;
        _expectedOtp = int.tryParse(data['otp']?.toString() ?? "");

        if (!mounted) return;
        setState(() {
          _otpSent = true;
          _isLoading = false;
        });
        return;
      } else {
        final message = (data is Map && data['message'] != null)
            ? data['message'].toString()
            : "تعذر التحقق من الرقم، حاول مرة أخرى";
        _showError(message);
      }
    } catch (e) {
      _showError("حدث خطأ، حاول مرة أخرى");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _verifyOtp() async {
    final entered = _otpController.text.trim();
    if (entered.length != 6) {
      _showError("أدخل رمز التحقق المكون من 6 أرقام");
      return;
    }
    if (entered != _expectedOtp.toString()) {
      _showError("رمز التحقق غير صحيح");
      return;
    }
    // Save to SharedPreferences and navigate
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('customer_type', 'delta');
    await prefs.setString('customer_uid', _pendingUid!);
    await prefs.setString('customer_phone', _pendingPhone!);
    await prefs.setString('contract_id', _pendingContractId!);
    await prefs.setString('userId', _pendingUid!);
    if (_pendingAddressId!.isNotEmpty) {
      await prefs.setString('addId', _pendingAddressId!);
    }
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const MainScreen()),
      (route) => false, // removes everything, fresh start
    );
  }

  dynamic _tryDecode(String raw) {
    if (raw.trim().isEmpty) return {};
    try {
      return jsonDecode(raw);
    } catch (_) {
      return {};
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: RepairTheme.bg,
        body: Column(
          children: [
            RepairTheme.orangeHeader(
              context: context,
              title: _otpSent ? "رمز التحقق" : "عميل دلتا",
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 28, 20, 20),
                child: _otpSent ? _buildOtpStep() : _buildPhoneStep(),
              ),
            ),
            SafeArea(
              top: false,
              child: _otpSent
                  ? RepairTheme.primaryButton(
                      label: "تأكيد",
                      icon: Iconsax.tick_circle,
                      onTap: _verifyOtp,
                    )
                  : RepairTheme.primaryButton(
                      label: "تحقق",
                      icon: Iconsax.verify,
                      loading: _isLoading,
                      onTap: _isLoading ? null : _verify,
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhoneStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              color: RepairTheme.orange.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Iconsax.mobile,
              color: RepairTheme.orange,
              size: 40,
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          "أدخل رقم هاتفك المسجل لدينا",
          textAlign: TextAlign.center,
          style: RepairTheme.cairo(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: RepairTheme.textSecondary,
          ),
        ),
        const SizedBox(height: 28),
        TextField(
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          textAlign: TextAlign.right,
          enabled: !_isLoading,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(8),
          ],
          style: RepairTheme.cairo(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: RepairTheme.textPrimary,
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: RepairTheme.cardBg,
            hintText: "رقم الهاتف",
            hintStyle: RepairTheme.cairo(
              fontSize: 14,
              color: RepairTheme.hint,
            ),
            prefixIcon: const Icon(
              Iconsax.call,
              color: RepairTheme.orange,
              size: 22,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 16,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: RepairTheme.border,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: RepairTheme.border,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: RepairTheme.orange,
                width: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOtpStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              color: RepairTheme.orange.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Iconsax.message,
              color: RepairTheme.orange,
              size: 40,
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          "أدخل رمز التحقق المرسل على واتساب",
          textAlign: TextAlign.center,
          style: RepairTheme.cairo(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: RepairTheme.textSecondary,
          ),
        ),
        const SizedBox(height: 28),
        TextField(
          controller: _otpController,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          maxLength: 6,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(6),
          ],
          style: RepairTheme.cairo(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: RepairTheme.textPrimary,
          ),
          decoration: InputDecoration(
            counterText: "",
            filled: true,
            fillColor: RepairTheme.cardBg,
            hintText: "------",
            hintStyle: RepairTheme.cairo(
              fontSize: 28,
              color: RepairTheme.hint,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 16,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: RepairTheme.border,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: RepairTheme.border,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: RepairTheme.orange,
                width: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
