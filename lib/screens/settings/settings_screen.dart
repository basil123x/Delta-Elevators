import 'package:Delta/constants/app_colors.dart';
import 'package:Delta/provider/app_provider.dart';
import 'package:Delta/screens/home/home_screen.dart';
import 'package:Delta/screens/settings/About/about_screen.dart';
import 'package:Delta/screens/settings/Addresses/Addresses_Screen.dart';
import 'package:Delta/screens/settings/Complaints/Complaints_Details.dart';
import 'package:Delta/screens/settings/Complaints/Complaints_screen.dart';
import 'package:Delta/screens/settings/Maintenance/maintenScreen.dart';
import 'package:Delta/screens/settings/Profile/profile_screen.dart';
import 'package:Delta/screens/splash_screen.dart';
import 'package:Delta/services/DioServiceCert.dart';
import 'package:Delta/services/OneSignalServices.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  int isLoading = -1;
  int isNotify = -2;
  List<Map<dynamic, dynamic>> listTileItems = [
    {"text": "الملف الشخصي", "icon": Iconsax.user, "onTap": ProfileScreen()},
    {
      "text": "عقود الصيانة",
      "icon": Iconsax.stickynote,
      "onTap": MaintenanceScreen(),
    },
    {"text": "العناوين", "icon": Iconsax.location, "onTap": AddressesScreen()},
    {"text": "حول الشركة", "icon": Iconsax.info_circle, "onTap": AboutScreen()},
    {"text": "الإشعارات", "icon": Iconsax.notification, "onTap": HomeScreen()},
    {"text": "شكاوي", "icon": Iconsax.note_2, "onTap": ComplaintDetails()},
    {"text": "تسجيل الخروج", "icon": Iconsax.logout, "onTap": HomeScreen()},
    {"text": "حذف الحساب", "icon": Iconsax.trash, "onTap": HomeScreen()},
  ];
  String name = "";

  Future getUserProfile({String? playId}) async {
    SharedPreferences prefx = await SharedPreferences.getInstance();
    String uid = prefx.getString("userId") ?? "";
    var result = await getDio().post(
      "https://daltalifts.com/app2026/sql.php?k=${DateTime.now().millisecondsSinceEpoch}",
      data: {"action": "profile", "uid": uid, "playId": playId},
    );
    setState(() {
      name = result.data['data']['a1'];
    });
  }

  Future logoutAccount(i) async {
    setState(() {
      isLoading = i;
    });
    final currentTab = Provider.of<AppProvider>(context, listen: false);
    SharedPreferences prefx = await SharedPreferences.getInstance();
    prefx.remove("userId");
    prefx.remove("orderId");
    currentTab.jumpToPagex(0);
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => SplashScreen()),
    );
  }

  Future deleteAccount(i) async {
    setState(() {
      isLoading = i;
    });
    final currentTab = Provider.of<AppProvider>(context, listen: false);
    SharedPreferences prefx = await SharedPreferences.getInstance();
    var uid = prefx.get("userId");
    await getDio().post(
      "https://daltalifts.com/app2026/sql.php?k=${DateTime.now().millisecondsSinceEpoch}",
      data: {"action": "deleteAccount", "userId": uid},
    );
    prefx.remove("userId");
    prefx.remove("orderId");
    currentTab.jumpToPagex(0);
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => SplashScreen()),
    );
  }

  Future getNotifyStatus() async {
    SharedPreferences prefx = await SharedPreferences.getInstance();
    isNotify = prefx.getInt('isNotify') ?? 0;
    setState(() {});
  }

  @override
  void initState() {
    getUserProfile();
    getNotifyStatus();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    return Scaffold(
      backgroundColor: AppColors.primary,
      appBar: AppBar(
        title: Text("الإعدادات", style: TextStyle(color: Colors.white)),
        centerTitle: true,
        forceMaterialTransparency: true,
        backgroundColor: AppColors.primary,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: Stack(
        children: [
          // ===== الكارد الأبيض =====
          Positioned(
            top: screenHeight * 0.18, // يبدأ قبل نهاية الجزء الملون بشوية
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
                  SizedBox(height: 70),
                  // ===== Grid الأيقونات =====
                  Expanded(
                    child: GridView.builder(
                      padding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      itemCount: listTileItems.length,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 4, // 4 في الصف زي مطراش
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 20,
                        childAspectRatio: 0.85,
                      ),
                      itemBuilder: (context, i) {
                        return GestureDetector(
                          onTap: () async {
                            SharedPreferences prefx =
                                await SharedPreferences.getInstance();
                            switch (i) {
                              case 4:
                                if (isNotify == 4) {
                                  isNotify = -1;
                                  prefx.setInt('isNotify', isNotify);
                                  getUserProfile(playId: "");
                                  getNotifyStatus();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text("تم إلغاء الإشعارات"),
                                      backgroundColor: AppColors.primary,
                                    ),
                                  );
                                  setState(() {});
                                } else {
                                  isNotify = 4;
                                  prefx.setInt('isNotify', isNotify);
                                  final playerId =
                                      OneSignal.User.pushSubscription.id;
                                  getUserProfile(playId: playerId);
                                  getNotifyStatus();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text("تم تفعيل الإشعارات"),
                                      backgroundColor: AppColors.primary,
                                    ),
                                  );
                                  setState(() {});
                                }
                                break;
                              case 6:
                                logoutAccount(6);
                                break;
                              case 7:
                                deleteAccount(7);
                                break;
                              default:
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        listTileItems[i]['onTap'],
                                  ),
                                );
                                break;
                            }
                          },
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  color: i == 6 || i == 7
                                      ? Colors.red.withOpacity(0.12)
                                      : isNotify == i
                                      ? AppColors.primary
                                      : AppColors.primary.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(50),
                                ),
                                child: isLoading == i
                                    ? Center(
                                        child: CircularProgressIndicator(
                                          color: i == 6 || i == 7
                                              ? Colors.red
                                              : AppColors.primary,
                                        ),
                                      )
                                    : Icon(
                                        listTileItems[i]['icon'],
                                        color: i == 6 || i == 7
                                            ? Colors.red
                                            : isNotify == i
                                            ? Colors.white
                                            : AppColors.primary,
                                        size: 26,
                                      ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                listTileItems[i]['text'],
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        );
                      },
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
                  SizedBox(height: 8),
                  Text(
                    name,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
