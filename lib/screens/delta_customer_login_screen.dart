import 'dart:convert';

import 'package:Delta/screens/repair/repair_first.dart';
import 'package:Delta/screens/repair/repair_screen.dart';
import 'package:Delta/screens/repair/repair_theme.dart';
import 'package:Delta/services/DioServiceCert.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iconsax/iconsax.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Delta customer ("عميل دلتا") entry: verify the phone has a registered
/// contract, then continue to the maintenance request screen.
/// No OTP — the user already authenticated when logging into the app.
class DeltaCustomerLoginScreen extends StatefulWidget {
  const DeltaCustomerLoginScreen({super.key});

  @override
  State<DeltaCustomerLoginScreen> createState() =>
      _DeltaCustomerLoginScreenState();
}

class _DeltaCustomerLoginScreenState extends State<DeltaCustomerLoginScreen> {
  final TextEditingController _phoneController = TextEditingController();
  bool _isLoading = false;

  static const String _endpoint =
      "https://daltalifts.com/app2026/api/verify_delta_customer.php";

  @override
  void initState() {
    super.initState();
    _prefillLoggedInPhone();
  }

  Future<void> _prefillLoggedInPhone() async {
    final prefs = await SharedPreferences.getInstance();
    final phone = prefs.getString('userPhone') ??
        prefs.getString('phone') ??
        prefs.getString('customer_phone') ??
        '';
    if (phone.isNotEmpty && mounted) {
      final digits = phone.replaceAll(RegExp(r'\D'), '');
      final last8 =
          digits.length >= 8 ? digits.substring(digits.length - 8) : digits;
      _phoneController.text = last8;
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
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

  /// الرقم مش في العقود → امسح اختيار "عملاء دلتا" وارجع لشاشة الاختيار فورًا.
  Future<void> _returnToCustomerChoice(
    String message, {
    bool showMessage = true,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(MaintFlowPrefs.typeKey);
    await prefs.remove(MaintFlowPrefs.deltaVerifiedKey);
    await prefs.remove(MaintFlowPrefs.erpContractIdKey);
    await prefs.remove('currentCard');
    await prefs.remove('customer_type');
    await prefs.remove('customer_phone');
    // Do not clear elevator `contract_id` — maintenance uses erpContractIdKey only.
    await prefs.remove('customer_uid');

    if (!mounted) return;
    if (showMessage && message.trim().isNotEmpty) {
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
          duration: const Duration(seconds: 3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const RepairFirst()),
    );
  }

  Future<void> _continueWithVerified({
    required String uid,
    required String contractId,
    required String addressId,
    required String phone,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final loggedInUid = prefs.getString('userId') ?? '';
    // App account for the request = logged-in user. ERP contract is proof only.
    final resolvedUid = loggedInUid.isNotEmpty ? loggedInUid : uid;
    if (resolvedUid.isEmpty || contractId.isEmpty) {
      await _returnToCustomerChoice(
        "تعذر ربط الحساب بعقد فيزيائي. جرّب مرة أخرى أو اختر «عميل جديد».",
      );
      return;
    }

    await prefs.setString('customer_type', 'delta');
    await prefs.setString(MaintFlowPrefs.typeKey, 'delta');
    await prefs.setInt('currentCard', 1);
    await prefs.setBool(MaintFlowPrefs.deltaVerifiedKey, true);
    await prefs.setString('customer_phone', phone);
    // Separate from elevator booking contract_id.
    await prefs.setString(MaintFlowPrefs.erpContractIdKey, contractId);
    await prefs.setString('customer_uid', resolvedUid);
    if (addressId.isNotEmpty) {
      await prefs.setString('addId', addressId);
    }
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const RepairScreen()),
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

      if (data is Map && data['success'] == true) {
        final uid = data['uid']?.toString() ?? '';
        final contractId = data['contract_id']?.toString() ?? '';
        final addressId = data['address_id']?.toString() ?? '';
        final verifiedPhone = data['phone']?.toString() ?? phone;
        final prefs = await SharedPreferences.getInstance();
        final loggedInUid = prefs.getString('userId') ?? '';

        // Need an ERP physical contract_id. App uid may be empty for ERP-only phones.
        if (contractId.isEmpty ||
            (uid.isEmpty && loggedInUid.isEmpty)) {
          await _returnToCustomerChoice(
            "لا يوجد عقد فيزيائي لهذا الرقم في السيستم. اختر «عميل جديد» للمتابعة.",
          );
          return;
        }

        await _continueWithVerified(
          uid: uid,
          contractId: contractId,
          addressId: addressId,
          phone: verifiedPhone,
        );
        return;
      }

      final message = (data is Map && data['message'] != null)
          ? data['message'].toString()
          : "تعذر التحقق من الرقم، حاول مرة أخرى";
      await _returnToCustomerChoice(
        "$message\nيمكنك اختيار «عميل جديد» من الشاشة التالية.",
      );
    } catch (e) {
      _showError("حدث خطأ، حاول مرة أخرى");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
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
              title: "عميل دلتا",
              onBack: () => _returnToCustomerChoice('', showMessage: false),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 28, 20, 20),
                child: Column(
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
                      "أدخل رقم هاتفك المسجل لدينا للتحقق من وجود عقد",
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
                ),
              ),
            ),
            SafeArea(
              top: false,
              child: RepairTheme.primaryButton(
                label: "تحقق من العقد",
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
}
