import 'dart:math';

import 'package:Delta/constants/app_colors.dart';
import 'package:Delta/screens/settings/About/contact_menu.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_boxicons/flutter_boxicons.dart';
import 'package:iconsax/iconsax.dart';
import 'package:pinput/pinput.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SalesScreen extends StatefulWidget {
  const SalesScreen({super.key});

  @override
  State<SalesScreen> createState() => _SalesScreenState();
}

class _SalesScreenState extends State<SalesScreen> {
  TextEditingController userController = TextEditingController();
  TextEditingController mobileController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  GlobalKey<FormState> formkey = GlobalKey<FormState>();
  List<Map<String, dynamic>> salesMan = [
    {"name": "محمد رأفت", "mobile": "30006374"},
    {"name": "خالد", "mobile": "33856188"},
    {"name": "نور", "mobile": "30006532"},
  ];

  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.primary,
        appBar: AppBar(
          title: Text("قسم المبيعات", style: TextStyle(color: Colors.white)),
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
                              children: List.generate(salesMan.length, (i) {
                                return Column(
                                  children: [
                                    Container(
                                      width: double.maxFinite,
                                      height: 130,
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade200,
                                        borderRadius: BorderRadius.only(
                                          topLeft: Radius.circular(10),
                                          topRight: Radius.circular(10),
                                        ),
                                      ),
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Container(
                                            margin: EdgeInsets.symmetric(
                                              horizontal: 10,
                                            ),
                                            child: Row(
                                              children: [
                                                Text(
                                                  "الإسم: ",
                                                  style: TextStyle(
                                                    fontSize: 18,
                                                  ),
                                                ),
                                                SizedBox(width: 2),
                                                Text(
                                                  salesMan[i]['name'],
                                                  style: TextStyle(
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          SizedBox(height: 5),
                                          Container(
                                            margin: EdgeInsets.symmetric(
                                              horizontal: 10,
                                            ),
                                            child: Row(
                                              children: [
                                                Text(
                                                  "رقم الهاتف: ",
                                                  style: TextStyle(
                                                    fontSize: 18,
                                                  ),
                                                ),
                                                SizedBox(width: 2),
                                                Text(
                                                  salesMan[i]['mobile'],
                                                  style: TextStyle(
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.only(
                                          bottomLeft: Radius.circular(10),
                                          bottomRight: Radius.circular(10),
                                        ),
                                        border: Border.all(
                                          color: AppColors.primary,
                                          width: 2,
                                        ),
                                        color: Colors.white,
                                      ),
                                      height: 40,
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: GestureDetector(
                                              onTap: () {
                                                UrlHelper.openPhone(
                                                  salesMan[i]['mobile'],
                                                );
                                              },
                                              child: Container(
                                                decoration: BoxDecoration(
                                                  border: Border(
                                                    left: BorderSide(
                                                      color: AppColors.primary,
                                                    ),
                                                  ),
                                                ),
                                                child: Icon(
                                                  Iconsax.call,
                                                  size: 25,
                                                ),
                                              ),
                                            ),
                                          ),
                                          Expanded(
                                            child: GestureDetector(
                                              onTap: () {
                                                UrlHelper.openWhatsApp(
                                                  salesMan[i]['mobile']
                                                      .toString()
                                                      .trim(),
                                                  "مرحبا قسم المبيعات",
                                                );
                                              },
                                              child: Container(
                                                child: Icon(
                                                  Boxicons.bxl_whatsapp,
                                                  size: 30,
                                                  color: Color(0xFF1FA015),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    SizedBox(height: 40),
                                  ],
                                );
                              }),
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
                            Iconsax.trend_up,
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
