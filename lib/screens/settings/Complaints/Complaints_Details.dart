import 'dart:math';

import 'package:Delta/constants/app_colors.dart';
import 'package:Delta/services/DioServiceCert.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:pinput/pinput.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ComplaintDetails extends StatefulWidget {
  const ComplaintDetails({super.key});

  @override
  State<ComplaintDetails> createState() => _ComplaintDetailsState();
}

class _ComplaintDetailsState extends State<ComplaintDetails> {
  GlobalKey<FormState> formkey = GlobalKey<FormState>();
  bool isLoading = false;
  List myComplaints = [];

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

  Future getComplaintsData() async {
    SharedPreferences prefx = await SharedPreferences.getInstance();
    var request = await Dio().post("https://daltalifts.com/app2026/sql.php?k=${DateTime.now().millisecondsSinceEpoch}", data: {
      "action": "getComplaints",
      "userId": prefx.getString("userId")
    });
    setState(() {
      myComplaints = request.data['data'];
    });
  }

  @override
  void initState() {
    getComplaintsData();
    super.initState();
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
                        ...List.generate(myComplaints.length, (i) {
                          return Container(
                            margin: EdgeInsets.symmetric(horizontal: 10, vertical: 14),
                            child:  Stack(
                              children: [
                                Container(
                                      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 20),
                                      width: double.maxFinite,
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
                                                  myComplaints[i]['name'],
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
                                                  myComplaints[i]['mobile'],
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
                                                  "رسالة الشكوى: ",
                                                  style: TextStyle(
                                                    fontSize: 18,
                                                  ),
                                                ),
                                                SizedBox(width: 2),
                                                Text(
                                                  myComplaints[i]['msg'],
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
                                    Positioned(
                                      bottom: 10,
                                      left: 10,
                                      child: Container(
                                        child: Icon(myComplaints[i]['is_read'] == '0' ? Icons.done : Icons.done_all, color: myComplaints[i]['is_read'] == '0' ? Colors.grey : AppColors.success,),
                                      ),
                                    )
                              ],
                            ),
                          );
                        }),
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

        ),
      ),
    );
  }
}
