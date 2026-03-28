import 'dart:math';

import 'package:Delta/constants/app_colors.dart';
import 'package:Delta/provider/app_provider.dart';
import 'package:Delta/screens/items/items_screen.dart';
import 'package:Delta/screens/order/add_address_screen.dart';
import 'package:Delta/screens/order/addresses_screen.dart';
import 'package:Delta/services/DioServiceCert.dart';
import 'package:Delta/services/OneSignalServices.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OrderScreen extends StatefulWidget {
  const OrderScreen({super.key});

  @override
  State<OrderScreen> createState() => _OrderScreenState();
}

class _OrderScreenState extends State<OrderScreen> {
  TextEditingController nameController = TextEditingController();
  TextEditingController mobileController = TextEditingController();
  List myOrders = [];
  bool isLoading = false;
  String? addId;
  List oneAddress = [];

  Future getUserProfile() async {
    SharedPreferences _prefx = await SharedPreferences.getInstance();
    String uid = _prefx.getString("userId") ?? "";
    print({"action": "profile", "uid": uid});
    var result = await getDio().post(
      "https://daltalifts.com/app2026/sql.php?k=${DateTime.now().millisecondsSinceEpoch}",
      data: {"action": "profile", "uid": uid},
    );
      setState(() {
        nameController.text = result.data['data']['a1'];
        mobileController.text = result.data['data']['a2'];
        addId = _prefx.getString("addId") ?? "";
      });
  }

  

  Future getOneAddress() async {
    SharedPreferences prefx = await SharedPreferences.getInstance();
    var result = await getDio().post(
      "https://daltalifts.com/app2026/sql.php?k=${DateTime.now().millisecondsSinceEpoch}",
      data: {"action": "getOneAddress", "id": prefx.getString("addId") ?? ''},
    );
    setState(() {
      oneAddress = result.data['data'];
    });
  }

  Future getMyOrders() async {
    SharedPreferences _prefx = await SharedPreferences.getInstance();
    String uid = _prefx.getString("userId") ?? "";
    print({"action": "getOrders", "uid": uid});
    var result = await getDio().post(
      "https://daltalifts.com/app2026/sql.php?k=${DateTime.now().millisecondsSinceEpoch}",
      data: {"action": "getOrders", "uid": uid},
    );
      setState(() {
        myOrders = result.data['data'];
      });
  }

      Future<void> sendQuotationRequestToTelegram({
        required String clientName,
        required String phone,
        required String city,
        required String zone,
        required String street,
        required String building,
        required String latitude,
        required String longitude,
        required List items,
      }) async {
        const String botToken = '8499367531:AAEnMG1yvNeAIanEgCbyYGlXWuYWImeTMyI';
        const String chatId = '-1003877690157';

        // 1. الرسالة النصية
        await Dio().post(
          'https://api.telegram.org/bot$botToken/sendMessage',
          queryParameters: {
            'chat_id': chatId,
            'text': """
      🛗 <b>طلب عرض سعر جديد</b>

      👤 <b>العميل:</b> $clientName
      📞 <b>الهاتف:</b> $phone

      📍 <b>العنوان:</b>
      🏙 المدينة: $city
      🗺 المنطقة: $zone
      🛣 الشارع: $street
      🏢 المبنى: $building

      🛒 <b>الطلبات:</b> ${items.length} منتج
      """,
            'parse_mode': 'HTML',
          },
        );

        // 2. صور المنتجات
        for (var item in items) {
          await Dio().post(
            'https://api.telegram.org/bot$botToken/sendPhoto',
            queryParameters: {
              'chat_id': chatId,
              'photo': "https://delta-lifts.s3.me-south-1.amazonaws.com/Sys/items/${item['id']}/1.jpg",
              'caption': '🛗 ${item['a1']} - ${item['a3']}',
            },
          );
        }

        // 3. الموقع
        await Dio().post(
          'https://api.telegram.org/bot$botToken/sendLocation',
          queryParameters: {
            'chat_id': chatId,
            'latitude': latitude,
            'longitude': longitude,
          },
        );
      }

  @override
  void initState() {
    getUserProfile();
    getMyOrders();
    getOneAddress();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final currentTab = Provider.of<AppProvider>(context);
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        forceMaterialTransparency: true,
        backgroundColor: Colors.white,
        title: Text("طلب عرض"),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 300, child: AddressesDisplayWidget()),
            SizedBox(height: 10),
            Container(
              margin: EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
              ),
              child: TextField(
                controller: nameController,
                keyboardType: TextInputType.name,
                decoration: InputDecoration(
                  hintText: 'قم بإدخال إسمك الشخصي',
                  hintStyle: TextStyle(color: AppColors.textHint),
                  prefixIcon: Container(
                    padding: EdgeInsets.all(0),
                    child: IconButton(
                      onPressed: () {},
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      splashRadius: 20,
                      icon: Icon(Iconsax.user, size: 24),
                    ),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(9),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(9),
                    borderSide: BorderSide.none,
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
            SizedBox(height: 10),
            Container(
              margin: EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
              ),
              child: TextField(
                controller: mobileController,
                keyboardType: TextInputType.name,
                decoration: InputDecoration(
                  hintText: 'قم بإدخال رقمك الشخصي',
                  hintStyle: TextStyle(color: AppColors.textHint),
                  prefixIcon: Container(
                    padding: EdgeInsets.all(0),
                    child: IconButton(
                      onPressed: () {},
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      splashRadius: 20,
                      icon: Icon(Iconsax.mobile, size: 24),
                    ),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(9),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(9),
                    borderSide: BorderSide.none,
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
            SizedBox(height: 10),
            if (myOrders.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 13,
                  vertical: 8,
                ),
                child: Text("طلباتك"),
              ),
            ...List.generate(myOrders.length, (i) {
              return Column(
                children: [
                  Container(
                    margin: EdgeInsets.symmetric(horizontal: 13),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(10),
                                image: DecorationImage(
                                  image: NetworkImage(
                                    "https://delta-lifts.s3.me-south-1.amazonaws.com/Sys/items/${myOrders[i]['id']}/1.jpg",
                                  ),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            SizedBox(width: 10),
                            Text(myOrders[i]['a1']),
                          ],
                        ),
                        GestureDetector(
                          onTap: () async {
                            await getDio().post(
                              "https://daltalifts.com/app2026/sql.php?k=${DateTime.now().millisecondsSinceEpoch}",
                              data: {
                                "action": "deleteMyOrders",
                                "id": myOrders[i]['oid'],
                              },
                            );
                            getMyOrders();
                            setState(() {});
                          },
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(5),
                              border: Border.all(color: AppColors.primary),
                            ),
                            child: Icon(
                              Iconsax.trash,
                              color: Colors.red,
                              size: 19,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // إضافة Divider بعد كل عنصر ماعدا الأخير
                  if (i < myOrders.length - 1)
                    Divider(
                      height: 20,
                      thickness: 1,
                      indent: 13,
                      endIndent: 13,
                      color: Colors.grey.shade300,
                    ),
                ],
              );
            }),
            SizedBox(height: 20),
            GestureDetector(
              onTap: () async {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ItemsScreen()),
                );
              },
              child: Container(
                width: double.maxFinite,
                margin: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                padding: EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.primary, width: 2),
                ),
                alignment: Alignment.center,
                child: Text(
                  "إضافة منتج",
                  style: TextStyle(fontSize: 20, color: AppColors.primary),
                ),
              ),
            ),
            GestureDetector(
              onTap: () async {
                if (addId != '' &&
                    (nameController.text.trim() != '' &&
                        mobileController.text.trim() != '') &&
                    myOrders.isNotEmpty) {
                  setState(() {
                    isLoading = true;
                  });
                  SharedPreferences prefx =
                      await SharedPreferences.getInstance();
                  String? addId = prefx.getString("addId");
                  String? uid = prefx.getString("userId");
                  String? oid = prefx.getString("orderId");

                  var result = await getDio().post(
                    "https://daltalifts.com/app2026/sql.php?k=${DateTime.now().millisecondsSinceEpoch}",
                    data: {
                      "action": "addMyBookings",
                      "addId": addId,
                      "uid": uid,
                      "oid": oid,
                    },
                  );

                  if (result.data['success'] == true) {
                    setState(() {
                      isLoading = false;
                    });
                    sendQuotationRequestToTelegram(clientName: nameController.text.trim(), phone: mobileController.text.trim(), city: oneAddress[0]['city'], zone: oneAddress[0]['zone'], street: oneAddress[0]['street'], building: oneAddress[0]['building'], latitude: oneAddress[0]['latitude'], longitude: oneAddress[0]['longitude'], items: myOrders);
                    currentTab.jumpToPagex(1);
                    showModalBottomSheet(
                      context: context,
                      backgroundColor: Colors.transparent,
                      isScrollControlled: true,
                      builder: (context) {
                        return Container(
                          width: double.maxFinite,
                          padding: EdgeInsets.only(
                            top: 20,
                            left: 20,
                            right: 20,
                            bottom:
                                MediaQuery.of(context).viewInsets.bottom +
                                20, // عشان الكيبورد
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(20),
                              topRight: Radius.circular(20),
                            ),
                          ),
                          child: SingleChildScrollView(
                            // أضف scroll
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  "عرض الطلب",
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 10),
                                Divider(color: Colors.grey.shade300),
                                SizedBox(height: 20),
                                // أيقونة النجاح
                                Container(
                                  width: 100,
                                  height: 100,
                                  decoration: BoxDecoration(
                                    color: Colors.green.withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.check_circle,
                                    color: Colors.green,
                                    size: 60,
                                  ),
                                ),
                                SizedBox(height: 20),
                                Text(
                                  "تم عرض الطلب بنجاح",
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 15),
                                Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 10),
                                  child: Text(
                                    "يمكنك متابعة حالة الطلب في سجل الحجوزات لديك وشكرا لاستخدامك تطبيق دلتا",
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey.shade700,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                SizedBox(height: 25),
                                // زر سجل الحجوزات
                                _buildButton(
                                  text: "سجل الحجوزات",
                                  color: AppColors.primary,
                                  onTap: () {
                                    Navigator.pop(context);
                                  },
                                ),
                                SizedBox(height: 12),
                                // زر الرئيسية
                                _buildOutlineButton(
                                  text: "الرئيسية",
                                  color: AppColors.primary,
                                  onTap: () {
                                    Navigator.pop(context);
                                    currentTab.jumpToPagex(0);
                                  },
                                ),
                                SizedBox(height: 10),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  }
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("من فضلك أكمل المطلوب")),
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
                child: isLoading
                    ? CircularProgressIndicator(color: Colors.white)
                    : Text(
                        "تقديم الطلب",
                        style: TextStyle(fontSize: 20, color: Colors.white),
                      ),
              ),
            ),
            SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}

Widget _buildButton({
  required String text,
  required Color color,
  required VoidCallback onTap,
}) {
  return GestureDetector(
    onTap: onTap,
    child: Container(
      width: double.maxFinite,
      padding: EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      alignment: Alignment.center,
      child: Text(
        text,
        style: TextStyle(
          fontSize: 18,
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
  );
}

// زر Outline
Widget _buildOutlineButton({
  required String text,
  required Color color,
  required VoidCallback onTap,
}) {
  return GestureDetector(
    onTap: onTap,
    child: Container(
      width: double.maxFinite,
      padding: EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color, width: 2),
      ),
      alignment: Alignment.center,
      child: Text(
        text,
        style: TextStyle(
          fontSize: 18,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
  );
}
