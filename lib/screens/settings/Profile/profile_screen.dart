import 'dart:math';

import 'package:Delta/constants/app_colors.dart';
import 'package:Delta/services/DioServiceCert.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:pinput/pinput.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  TextEditingController userController = TextEditingController();
  TextEditingController mobile = TextEditingController();
  TextEditingController otpController = TextEditingController();
  int otp = 100000 + Random().nextInt(900000);
  String mobilex = "";

  bool isEditing = false;
  bool isVerify = false;
  bool isLoading = false;

  Future updateProfile(name, mob) async {
    setState(() {
      isLoading = true;
    });
    SharedPreferences _prefx = await SharedPreferences.getInstance();
    String uid = _prefx.getString("userId") ?? "";
    var result = await getDio().post(
      "https://daltalifts.com/app2026/sql.php?k=${DateTime.now().millisecondsSinceEpoch}",
      data: {
        "action": "updateProfile",
        "uid": uid,
        "name": name,
        "mobile": mob,
      },
    );
    if (result.data['success'] == true) {
      Navigator.pop(context);
    }
  }

  Future getUserProfile() async {
    SharedPreferences _prefx = await SharedPreferences.getInstance();
    String uid = _prefx.getString("userId") ?? "";
    var result = await getDio().post(
      "https://daltalifts.com/app2026/sql.php?k=${DateTime.now().millisecondsSinceEpoch}",
      data: {"action": "profile", "uid": uid},
    );
    setState(() {
      userController.text = result.data['data']['a1'];
      mobile.text = result.data['data']['a2'];
      mobilex = result.data['data']['a2'];
    });
  }

  @override
  void initState() {
    getUserProfile();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.primary,
        appBar: AppBar(
          title: Text("ملفي الشخصي", style: TextStyle(color: Colors.white)),
          centerTitle: true,
          forceMaterialTransparency: true,
          backgroundColor: AppColors.primary,
          iconTheme: IconThemeData(color: Colors.white),
          actions: [
            IconButton(
              onPressed: () {
                setState(() {
                  isEditing = !isEditing;
                });
              },
              icon: Icon(Iconsax.edit),
            ),
          ],
        ),
        body: Stack(
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
                    // ===== Grid الأيقونات =====
                    Expanded(
                      child: Container(
                        margin: EdgeInsets.all(15),
                        child: SingleChildScrollView(
                          child: Column(
                            children: [
                              MyInputCustom(
                                iController: userController,
                                iHint: "إسم المستخدم",
                                iPref: Iconsax.user,
                                isEditingArea: isEditing,
                                isTyping: TextInputType.name,
                              ),
                              SizedBox(height: 20),
                              MyInputCustom(
                                iController: mobile,
                                iHint: "رقم الهاتف",
                                iPref: Iconsax.mobile,
                                isEditingArea: isEditing,
                                isTyping: TextInputType.phone,
                                iLength: 8,
                                iChanged: (val) {
                                  if ((mobilex.toString() != val) &&
                                      val.length == 8) {
                                    setState(() {
                                      isVerify = true;
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          backgroundColor: AppColors.primary,
                                          content: Text(
                                            "Your Verification Code is $otp",
                                          ),
                                        ),
                                      );
                                    });
                                  } else {
                                    setState(() {
                                      isVerify = false;
                                    });
                                  }
                                },
                              ),
                              SizedBox(height: 20),
                              Visibility(
                                visible: isVerify ? true : false,
                                child: Directionality(
                                  textDirection: TextDirection.ltr,
                                  child: Pinput(
                                    controller: otpController,
                                    length: 6,
                                  ),
                                ),
                              ),
                              SizedBox(height: 100),
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
                        child: Image.asset(
                          'assets/img/brand_logo_big.png',
                          width: 50,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
        floatingActionButton: GestureDetector(
          onTap: () async {
            if (mobile.text.trim().toString() != mobilex.toString()) {
              if (otp.toString() != otpController.text.trim().toString()) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: AppColors.primary,
                    content: Text("Your OTP Is Invalid"),
                  ),
                );
              } else {
                updateProfile(userController.text.trim(), mobile.text.trim());
              }
            } else {
              updateProfile(userController.text.trim(), mobile.text.trim());
            }
          },
          child: Visibility(
            visible: isEditing,
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
                  ? Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    )
                  : Text(
                      "تحديث البيانات",
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
  final bool? isEditingArea;
  final TextInputType? isTyping;
  final Function(String)? iChanged;
  final int? iLength;
  const MyInputCustom({
    super.key,
    required this.iHint,
    this.iPref,
    this.iController,
    this.isEditingArea,
    this.isTyping,
    this.iChanged,
    this.iLength,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: iController,
      keyboardType: isTyping,
      onChanged: iChanged,
      maxLength: iLength,

      decoration: InputDecoration(
        counterText: "",
        enabled: isEditingArea ?? false,
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
