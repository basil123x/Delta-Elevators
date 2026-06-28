import 'package:Delta/constants/app_colors.dart';
import 'package:Delta/services/DioServiceCert.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
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
  final TextEditingController nameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();

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

  Future<void> _loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final uid = prefs.getString("userId") ?? "";
    try {
      final result = await getDio().post(
        "https://daltalifts.com/app2026/sql.php",
        data: {"action": "profile", "uid": uid},
      );
      if (mounted) {
        setState(() {
          nameController.text = result.data['data']['a1'] ?? '';
          phoneController.text = result.data['data']['a2'] ?? '';
        });
      }
    } catch (e) {
      print('Profile error: $e');
    }
  }

  Future getComplaintsData() async {
    SharedPreferences prefx = await SharedPreferences.getInstance();
    var request = await Dio().post(
      "https://daltalifts.com/app2026/sql.php?k=${DateTime.now().millisecondsSinceEpoch}",
      data: {"action": "getComplaints", "userId": prefx.getString("userId")},
    );
    setState(() {
      myComplaints = request.data['data'];
    });
  }

  @override
  void initState() {
    super.initState();
    _loadProfile();
    getComplaintsData();
  }

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    super.dispose();
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
            title: Text(
              "شكاوي وإقتراحات",
              style: TextStyle(color: Colors.white),
            ),
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
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          child: TextFormField(
                            controller: nameController,
                            readOnly: true,
                            textAlign: TextAlign.right,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: Colors.grey.shade100,
                              hintText: 'إسمك',
                              prefixIcon: Icon(
                                Iconsax.lock,
                                color: Colors.grey.shade500,
                                size: 18,
                              ),
                              suffixIcon: Icon(
                                Iconsax.user,
                                color: AppColors.primary,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: 12),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          child: TextFormField(
                            controller: phoneController,
                            readOnly: true,
                            textAlign: TextAlign.right,
                            keyboardType: TextInputType.phone,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: Colors.grey.shade100,
                              hintText: 'رقم هاتفك',
                              prefixIcon: Icon(
                                Iconsax.lock,
                                color: Colors.grey.shade500,
                                size: 18,
                              ),
                              suffixIcon: Icon(
                                Iconsax.call,
                                color: AppColors.primary,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: 16),
                        ...List.generate(myComplaints.length, (i) {
                          return Container(
                            margin: EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 14,
                            ),
                            child: Stack(
                              children: [
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 20,
                                  ),
                                  width: double.maxFinite,
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade200,
                                    borderRadius: BorderRadius.only(
                                      topLeft: Radius.circular(10),
                                      topRight: Radius.circular(10),
                                    ),
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Container(
                                        margin: EdgeInsets.symmetric(
                                          horizontal: 10,
                                        ),
                                        child: Row(
                                          children: [
                                            Text(
                                              "الإسم: ",
                                              style: TextStyle(fontSize: 18),
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
                                              style: TextStyle(fontSize: 18),
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
                                              style: TextStyle(fontSize: 18),
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
                                    child: Icon(
                                      myComplaints[i]['is_read'] == '0'
                                          ? Iconsax.tick_circle
                                          : Iconsax.message_tick,
                                      color: myComplaints[i]['is_read'] == '0'
                                          ? Colors.grey
                                          : AppColors.success,
                                    ),
                                  ),
                                ),
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
