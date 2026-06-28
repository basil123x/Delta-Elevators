import 'package:Delta/constants/app_colors.dart';
import 'package:Delta/screens/repair/repair_theme.dart';
import 'package:Delta/services/DioServiceCert.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ComplaintScreen extends StatefulWidget {
  const ComplaintScreen({super.key});

  @override
  State<ComplaintScreen> createState() => _ComplaintScreenState();
}

class _ComplaintScreenState extends State<ComplaintScreen> {
  static const Color _orange = Color(0xFFF37021);
  static const Color _bg = Color(0xFFF2F3F7);

  TextEditingController userController = TextEditingController();
  TextEditingController mobileController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  GlobalKey<FormState> formkey = GlobalKey<FormState>();
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final uid = prefs.getString("userId") ?? "";
    if (uid.isEmpty) return;
    try {
      final result = await getDio().post(
        "https://daltalifts.com/app2026/sql.php",
        data: {"action": "profile", "uid": uid},
      );
      if (mounted) {
        setState(() {
          userController.text = result.data['data']['a1'] ?? '';
          mobileController.text = result.data['data']['a2'] ?? '';
        });
      }
    } catch (e) {
      print('Profile error: $e');
    }
  }

  String buildTelegramMessage({
    required String name,
    required String phone,
    required String message,
  }) {
    final now = DateTime.now();
    final formatted =
        '${now.day}/${now.month}/${now.year} ${now.hour}:${now.minute.toString().padLeft(2, '0')}';

    return '''
  📬 *شكوى / إقتراح جديد*

  👤 *الاسم:* $name
  📱 *رقم الهاتف:* $phone

  💬 *الرسالة:*
  $message

  ━━━━━━━━━━━━━━
  🕐 $formatted
  '''
        .trim();
  }

  Widget _floatingIconCircle() {
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFFFFF0E5),
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: const Icon(Iconsax.messages, color: _orange, size: 32),
    );
  }

  Widget _buildHeader() {
    final topPad = MediaQuery.paddingOf(context).top;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(8, topPad + 8, 8, 52),
      decoration: const BoxDecoration(
        color: _orange,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.maybePop(context),
            icon: const Icon(
              Iconsax.arrow_right_3,
              color: Colors.white,
              size: 22,
            ),
          ),
          const Expanded(
            child: Text(
              'شكاوي وإقتراحات',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Scaffold(
          backgroundColor: _orange,
          body: Form(
            key: formkey,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Column(
                  children: [
                    _buildHeader(),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(28),
                          topRight: Radius.circular(28),
                        ),
                        child: Container(
                          width: double.infinity,
                          color: _bg,
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.fromLTRB(16, 50, 16, 24),
                            child: Column(
                              children: [
                                MyInputCustom(
                                  iController: emailController,
                                  iHint: 'إكتب رسالتك هنا...',
                                  iPref: Iconsax.message_text,
                                  isTyping: TextInputType.multiline,
                                  isMultiline: true,
                                  iValid: (val) {
                                    if (val == '') {
                                      return 'الرجاء إكتب رسالتك';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),
                                Container(
                                  padding: EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Color(0xFFEBEBEB),
                                    ),
                                  ),
                                  child: Column(
                                    children: [
                                      _statusItem(
                                        icon: Iconsax.clock,
                                        color: Color(0xFFF37021),
                                        label: "شكوى جديدة",
                                        desc: "تم استلام شكواك وقيد المراجعة",
                                      ),
                                      Divider(),
                                      _statusItem(
                                        icon: Iconsax.tick_circle,
                                        color: Color(0xFF22C55E),
                                        label: "تم الحل",
                                        desc: "تمت معالجة شكواك بنجاح",
                                      ),
                                      Divider(),
                                      _statusItem(
                                        icon: Iconsax.pause_circle,
                                        color: Color(0xFFEAB308),
                                        label: "معلقة",
                                        desc: "شكواك قيد المتابعة من فريقنا",
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                Positioned(
                  top: MediaQuery.paddingOf(context).top + 72,
                  left: 0,
                  right: 0,
                  child: Center(child: _floatingIconCircle()),
                ),
              ],
            ),
          ),
          bottomNavigationBar: SafeArea(
            child: RepairTheme.primaryButton(
              label: "إرسال",
              icon: Iconsax.send1,
              loading: isLoading,
              onTap: () async {
                if (formkey.currentState!.validate()) {
                  SharedPreferences prefx =
                      await SharedPreferences.getInstance();
                  setState(() {
                    isLoading = true;
                  });
                  var result = await getDio().post(
                    "https://daltalifts.com/app2026/sql.php?k=${DateTime.now().millisecondsSinceEpoch}",
                    data: {
                      "action": "addComplaint",
                      "name": userController.text,
                      "mobile": mobileController.text,
                      "msg": emailController.text,
                      "userId": prefx.getString("userId"),
                    },
                  );
                  final text = buildTelegramMessage(
                    name: userController.text.trim(),
                    phone: mobileController.text.trim(),
                    message: emailController.text,
                  );
                  final url =
                      'https://api.telegram.org/bot8499367531:AAEnMG1yvNeAIanEgCbyYGlXWuYWImeTMyI/sendMessage';
                  await Dio().post(
                    url,
                    data: {
                      'chat_id': "-1003877690157",
                      'text': text,
                      'parse_mode': 'Markdown',
                    },
                  );
                  if (result.data['success'] == true) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          "شكرا على إقتراحاتك سيتم التواصل معك في أقرب وقت",
                        ),
                        backgroundColor: AppColors.primary,
                      ),
                    );
                    Navigator.pop(context);
                  }
                }
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _statusItem({
    required IconData icon,
    required Color color,
    required String label,
    required String desc,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: color, size: 22),
          SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: Color(0xFF1A1A2E),
                ),
              ),
              Text(desc, style: TextStyle(fontSize: 11, color: Colors.grey)),
            ],
          ),
        ],
      ),
    );
  }
}

class MyInputCustom extends StatelessWidget {
  final String iHint;
  final IconData? iPref;
  final TextEditingController? iController;
  final TextInputType? isTyping;
  final Function(String)? iChanged;
  final int? iLength;
  final int? iMax;
  final bool isMultiline;
  final bool readOnly;
  final String? Function(String?)? iValid;

  const MyInputCustom({
    super.key,
    required this.iHint,
    this.iPref,
    this.iController,
    this.isTyping,
    this.iChanged,
    this.iLength,
    this.iMax,
    this.isMultiline = false,
    this.readOnly = false,
    this.iValid,
  });

  static const Color _orange = Color(0xFFF37021);
  static const Color _hint = Color(0xFF888888);
  static const Color _border = Color(0xFFEBEBEB);

  @override
  Widget build(BuildContext context) {
    if (isMultiline) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _border),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0D000000),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          children: [
            TextFormField(
              validator: iValid,
              controller: iController,
              keyboardType: isTyping,
              onChanged: iChanged,
              maxLength: iLength,
              minLines: 5,
              maxLines: 8,
              readOnly: readOnly,
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 15, color: Color(0xFF1A1A2E)),
              decoration: InputDecoration(
                counterText: '',
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.fromLTRB(48, 16, 16, 40),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                hintText: iHint,
                hintStyle: const TextStyle(color: _hint, fontSize: 14),
                alignLabelWithHint: true,
              ),
            ),
            if (iPref != null)
              const Positioned(
                left: 12,
                bottom: 12,
                child: _FieldIconCircle(icon: Iconsax.message_text),
              ),
          ],
        ),
      );
    }

    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextFormField(
              validator: iValid,
              controller: iController,
              keyboardType: isTyping,
              onChanged: iChanged,
              maxLength: iLength,
              maxLines: 1,
              readOnly: readOnly,
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 15, color: Color(0xFF1A1A2E)),
              decoration: InputDecoration(
                counterText: '',
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                hintText: iHint,
                hintStyle: const TextStyle(color: _hint, fontSize: 14),
              ),
            ),
          ),
          if (iPref != null)
            Padding(
              padding: const EdgeInsets.only(left: 12),
              child: _FieldIconCircle(icon: iPref!),
            ),
        ],
      ),
    );
  }
}

class _FieldIconCircle extends StatelessWidget {
  final IconData icon;

  const _FieldIconCircle({required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: const Color(0xFFFFF0E5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, color: MyInputCustom._orange, size: 20),
    );
  }
}
