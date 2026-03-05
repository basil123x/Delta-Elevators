import 'package:Delta/services/DioServiceCert.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List notifications = [];

  Future getNotifications() async {
    SharedPreferences prefx = await SharedPreferences.getInstance();
    var result = await getDio().post(
      "https://daltalifts.com/app2026/sql.php",
      data: {"action": "getNotify", "uid": prefx.getString("userId")},
    );
    if (result.data['success'] == true) {
      setState(() {
        notifications = result.data['data'];
      });
    }
  }

  @override
  void initState() {
    getNotifications();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          forceMaterialTransparency: true,
          backgroundColor: Colors.white,
          title: Text("الإشعارات"),
          centerTitle: true,
          actions: [
            IconButton(
              onPressed: () async {
                setState(() {
                  notifications.clear();
                });
                await getDio().post(
                  "https://daltalifts.com/app2026/sql.php?k=${DateTime.now().millisecondsSinceEpoch}",
                  data: {"action": "delNotify"},
                );
              },
              icon: Icon(Iconsax.trash, color: Colors.red),
            ),
          ],
        ),
        body: notifications.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Iconsax.notification, size: 100),
                    SizedBox(height: 40),
                    Text(
                      "لا يوجد إشعارات بعد",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              )
            : SingleChildScrollView(
                child: Column(
                  children: List.generate(notifications.length, (i) {
                    return Container(
                      margin: EdgeInsets.all(10),
                      child: Dismissible(
                        key: Key(notifications[i]['id']),
                        direction: DismissDirection.endToStart,
                        onDismissed: (direction) async {
                          if (direction == DismissDirection.endToStart) {
                            // احفظ الـ id قبل ما تحذف من الـ list
                            final deletedId = notifications[i]['id'];

                            // احذف من الـ local state أولاً
                            setState(() {
                              notifications.removeAt(i);
                            });

                            // بعدين ابعت للـ API
                            await getDio().post(
                              "https://daltalifts.com/app2026/sql.php?k=${DateTime.now().millisecondsSinceEpoch}",
                              data: {"action": "delNotify", "id": deletedId},
                            );
                          }
                        },
                        child: ListTile(
                          contentPadding: EdgeInsets.only(
                            top: 8,
                            right: 10,
                            bottom: 8,
                          ),
                          tileColor: Colors.grey.shade200,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          leading: Icon(Iconsax.notification),
                          title: Text(notifications[i]['title']),
                          subtitle: Text(notifications[i]['content']),
                        ),
                      ),
                    );
                  }),
                ),
              ),
      ),
    );
  }
}
