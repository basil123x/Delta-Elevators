import 'dart:math';

import 'package:Delta/constants/app_colors.dart';
import 'package:Delta/services/DioServiceCert.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:pinput/pinput.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ComplaintScreen extends StatefulWidget {
  const ComplaintScreen({super.key});

  @override
  State<ComplaintScreen> createState() => _ComplaintScreenState();
}

class _ComplaintScreenState extends State<ComplaintScreen> {
  TextEditingController userController = TextEditingController();
  TextEditingController mobileController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  GlobalKey<FormState> formkey = GlobalKey<FormState>();
  bool isLoading = false;

  String buildTelegramMessage({
    required String name,
    required String phone,
    required String message,
  }) {
    final now = DateTime.now();
    final formatted = '${now.day}/${now.month}/${now.year} ${now.hour}:${now.minute.toString().padLeft(2, '0')}';

    return '''
  📬 *شكوى / إقتراح جديد*

  👤 *الاسم:* $name
  📱 *رقم الهاتف:* $phone

  💬 *الرسالة:*
  $message

  ━━━━━━━━━━━━━━
  🕐 $formatted
  '''.trim();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    return Directionality(
      textDirection: TextDirection.rtl,
      child: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Scaffold(
          backgroundColor: AppColors.primary,
          appBar: AppBar(
            title: Text("شكاوي وإقتراحات", style: TextStyle(color: Colors.white)),
            centerTitle: true,
            forceMaterialTransparency: true,
            backgroundColor: AppColors.primary,
            iconTheme: IconThemeData(color: Colors.white),
          ),
          body: Form(
            key: formkey,
            child: Stack(
              children: [
                Positioned(
                  top: screenHeight * 0.18,
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(25),
                        topRight: Radius.circular(25),
                      ),
                    ),
                    child: Column(
                      children: [
                        SizedBox(height: 50),
        
                        Expanded(
                          child: Container(
                            margin: EdgeInsets.all(15),
                            child: SingleChildScrollView(
                              child: Column(
                                children: [
                                  MyInputCustom(
                                    iController: userController,
                                    iHint: "إسمك",
                                    iPref: Iconsax.user,
                                    isTyping: TextInputType.name,
                                    iValid: (val) {
                                      if (val == '') {
                                        return 'الرجاء إكتب إسمك';
                                      }
                                      return null;
                                    },
                                  ),
                                  SizedBox(height: 20),
                                  MyInputCustom(
                                    iController: mobileController,
                                    iHint: "رقم هاتفك",
                                    iPref: Iconsax.mobile,
                                    isTyping: TextInputType.phone,
                                    iValid: (val) {
                                      if (val == '') {
                                        return 'الرجاء إكتب رقم هاتفك';
                                      }
                                      return null;
                                    },
                                  ),
                                  SizedBox(height: 20),
                                  MyInputCustom(
                                    iController: emailController,
                                    iHint: "إكتب رسالتك هنا...",
                                    iPref: Iconsax.sms,
                                    isTyping: TextInputType.emailAddress,
                                    iMax: 6,
                                    iValid: (val) {
                                      if (val == '') {
                                        return 'الرجاء إكتب رسالتك';
                                      }
                                      return null;
                                    },
                                  ),
                                  SizedBox(height: 20),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
        
                // ===== صورة البروفايل في المنتصف =====
                Positioned(
                  top: screenHeight * 0.11,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 40,
                          backgroundColor: Colors.white,
                          child: CircleAvatar(
                            radius: 36,
                            backgroundColor: AppColors.primary.withOpacity(0.2),
                            child: Icon(
                              Iconsax.note_2,
                              size: 30,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
          floatingActionButton: GestureDetector(
            onTap: () async {
              if (formkey.currentState!.validate()) {
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
                  },
                );
                final text = buildTelegramMessage(name: userController.text.trim(),phone: mobileController.text.trim(),message: emailController.text);
                final url = 'https://api.telegram.org/bot8499367531:AAEnMG1yvNeAIanEgCbyYGlXWuYWImeTMyI/sendMessage';
                await Dio().post(url, data: {
                  'chat_id': "-1003877690157",
                  'text': text,
                  'parse_mode': 'Markdown',
                });
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
            child: Container(
              width: double.maxFinite,
              height: 60,
              margin: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              padding: EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(8),
              ),
              alignment: Alignment.center,
              child: isLoading
                  ? Center(child: CircularProgressIndicator(color: Colors.white))
                  : Text(
                      "إرسال",
                      style: TextStyle(fontSize: 20, color: Colors.white),
                    ),
            ),
          ),
        ),
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
    this.iValid,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      validator: iValid,
      controller: iController,
      keyboardType: isTyping,
      onChanged: iChanged,
      maxLength: iLength,
      maxLines: iMax,
      decoration: InputDecoration(
        counterText: "",
        filled: true,
        fillColor: Colors.grey.shade200,
        border: OutlineInputBorder(
          borderSide: BorderSide.none,
          borderRadius: BorderRadius.circular(10),
        ),
        hintText: iHint,
        prefixIcon: Icon(iPref),
      ),
    );
  }
}
