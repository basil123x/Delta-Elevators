import 'dart:math';

import 'package:Delta/constants/app_colors.dart';
import 'package:Delta/screens/auth/OTP/otp_screen.dart';
import 'package:Delta/screens/auth/register/register_screen.dart';
import 'package:Delta/screens/main/main_screen.dart';
import 'package:Delta/services/DioServiceCert.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iconsax/iconsax.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  TextEditingController phoneController = TextEditingController();
  bool isValidPhone = false;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    phoneController.addListener(validatePhone);
  }

  static bool isValidQatarPhone(String phone) {
    // Remove any spaces or special characters
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

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Scaffold(
          resizeToAvoidBottomInset: true,
          backgroundColor: Colors.white,
          appBar: AppBar(
            forceMaterialTransparency: true,
            automaticallyImplyLeading: true,
          ),
          extendBodyBehindAppBar: true,
          body: Center(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Image.asset('assets/img/logo.png', width: 180),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "تسجيل",
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        " الدخول",
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 20),
                  Text(
                    "قم بإدخال رقم هاتفك لتسجيل الدخول",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                  SizedBox(height: 30),
                  Container(
                    margin: EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: TextField(
                      controller: phoneController,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(8),
                      ],
                      decoration: InputDecoration(
                        hintText: '12345678',
                        hintStyle: TextStyle(
                          color: AppColors.textHint,
                          letterSpacing: 2,
                        ),
                        prefixIcon: Container(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 34,
                                height: 36,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(9),
                                  image: DecorationImage(
                                    image: AssetImage('assets/img/qatar.png'),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '+974',
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                width: 1,
                                height: 20,
                                // color: AppColors.lightGrey,
                              ),
                            ],
                          ),
                        ),
                        suffixIcon: Container(
                          padding: isValidPhone
                              ? EdgeInsets.symmetric(horizontal: 0, vertical: 0)
                              : EdgeInsets.all(0),
                          child: IconButton(
                            onPressed: () {},
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            splashRadius: 20,
                            icon: Icon(
                              isValidPhone
                                  ? Iconsax.tick_circle5
                                  : Iconsax.close_circle5,
                              color: isValidPhone
                                  ? AppColors.success
                                  : AppColors.error,
                              size: 24,
                            ),
                          ),
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(9),
                          borderSide: BorderSide(width: 1),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(9),
                          borderSide: BorderSide(width: 1),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(9),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 20,
                        ),
                      ),
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.all(20),
                    child: Container(
                      alignment: Alignment.center,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text("ليس لديك حساب ؟"),
                          SizedBox(width: 10),
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => RegisterScreen(),
                                ),
                              );
                            },
                            child: Text("إنشاء حساب"),
                          ),
                        ],
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () async {
                      setState(() {
                        isLoading = true;
                      });
                      var result = await getDio().post(
                        "https://daltalifts.com/app2026/sql.php",
                        options: Options(
                          headers: {"Content-Type": "application/json"},
                        ),
                        data: {
                          "action": "checkUser",
                          "phone": phoneController.text.trim(),
                        },
                      );
                      if (result.data['success'] == true) {
                        setState(() {
                          isLoading = false;
                        });
                        int otp = 100000 + Random().nextInt(900000);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => OTPScreen(
                              mobile: phoneController.text.trim(),
                              otp: otp,
                              keylogin: "Login",
                            ),
                          ),
                        );
                      } else {
                        setState(() {
                          isLoading = false;
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            backgroundColor: AppColors.primary,
                            content: Text(
                              "المستخدم ليس مسجلا فقط قم بالتسجيل الأن",
                            ),
                          ),
                        );
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => RegisterScreen(),
                          ),
                        );
                      }
                    },
                    child: Container(
                      width: double.maxFinite,
                      margin: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      padding: EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        "تسجيل الدخول",
                        style: TextStyle(fontSize: 20, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
