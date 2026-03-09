import 'package:Delta/constants/app_colors.dart';
import 'package:Delta/provider/app_provider.dart';
import 'package:Delta/screens/items/item_preview.dart';
import 'package:Delta/screens/main/main_screen.dart';
import 'package:Delta/services/DioServiceCert.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ItemsDetailsScreen extends StatefulWidget {
  final String itmid;
  const ItemsDetailsScreen({super.key, required this.itmid});

  @override
  State<ItemsDetailsScreen> createState() => _ItemsDetailsScreenState();
}

class _ItemsDetailsScreenState extends State<ItemsDetailsScreen> {
  List itemDetails = [];
  List itemLabelsDet = [];
  List itemSela = [];
  List itemLiftsDet = [];
  bool isLoading = false;

  Future getItems() async {
    var request = await getDio().post(
      "https://daltalifts.com/app2026/sql.php?k=${DateTime.now().millisecondsSinceEpoch}",
      data: {"action": "oneItemDetails", "itmid": widget.itmid},
    );
    setState(() {
      itemDetails = request.data['data'];
    });
  }

  Future getLabelsLifts() async {
    var request = await getDio().post(
      "https://daltalifts.com/app2026/sql.php?k=${DateTime.now().millisecondsSinceEpoch}",
      data: {"action": "getLabelsLifts"},
    );
    setState(() {
      itemLabelsDet = request.data['data'];
    });
  }

  Future getItemSela() async {
    // var request = await getDio().post(
    //   "https://daltalifts.com/app2026/sql.php?k=${DateTime.now().millisecondsSinceEpoch}",
    //   data: {
    //     "action": "items",
    //     "grp": itemDetails[0]['a2'],
    //     "notId": widget.itmid,
    //   },
    // );
    // setState(() {
    //   itemSela = request.data['data'];
    // });
  }

  Future getLiftsDet() async {
    var request = await getDio().post(
      "https://daltalifts.com/app2026/sql.php?k=${DateTime.now().millisecondsSinceEpoch}",
      data: {"action": "getLiftsDet", "idlift": itemDetails[0]['liftid']},
    );
    setState(() {
      itemLiftsDet = request.data['data'];
    });
  }

  Future<void> _loadAllData() async {
    await getItems(); // الأول لازم يخلص
    await getItemSela(); // دلوقتي itemDetails جاهزة
    await getLabelsLifts(); // بعدين
    await getLiftsDet(); // دي كمان محتاجة itemDetails
  }

  @override
  void initState() {
    _loadAllData();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final currentTab = Provider.of<AppProvider>(context);
    return Directionality(
      textDirection: TextDirection.rtl,
      child:
          itemDetails.isEmpty || itemLabelsDet.isEmpty || itemLiftsDet.isEmpty
          ? Scaffold(
              body: Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            )
          : Scaffold(
              backgroundColor: Colors.white,
              appBar: AppBar(
                title: Text(itemDetails[0]['a1'] ?? ""),
                centerTitle: true,
                backgroundColor: Colors.white,
              ),
              body: Container(
                margin: EdgeInsets.all(20),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GestureDetector(
                        onTap: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ItemPreviewScreen(
                                id: itemDetails[0]['id'].toString(),
                              ),
                            ),
                          );
                        },
                        child: Container(
                          width: double.maxFinite,
                          height: 200,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            image: DecorationImage(
                              image: NetworkImage(
                                "https://daltalifts.com/erp2026/assets/items/${itemDetails[0]['id'] ?? ""}/images/1.jpg",
                              ),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 10),
                      Text(
                        itemDetails[0]['a1'],
                        style: TextStyle(fontSize: 20),
                        textAlign: TextAlign.end,
                      ),
                      SizedBox(height: 10),
                      Text(
                        "الوصف",
                        style: TextStyle(fontSize: 20),
                        textAlign: TextAlign.end,
                      ),
                      SizedBox(height: 10),
                      Text(
                        itemDetails[0]['a3'] ?? "",
                        style: TextStyle(
                          fontSize: 20,
                          color: Colors.grey.shade400,
                        ),
                        textAlign: TextAlign.end,
                      ),
                      SizedBox(height: 10),
                      Visibility(
                        visible: itemSela.isNotEmpty ? true : false,
                        child: Text(
                          "منتجات ذات صلة",
                          style: TextStyle(fontSize: 20),
                          textAlign: TextAlign.end,
                        ),
                      ),
                      Visibility(
                        visible: itemSela.isNotEmpty ? true : false,
                        child: Container(
                          height: 150,
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            children: List.generate(itemSela.length, (i) {
                              return GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ItemsDetailsScreen(
                                        itmid: itemSela[i]['id'],
                                      ),
                                    ),
                                  );
                                },
                                child: Container(
                                  width: 150,
                                  height: 150,
                                  margin: EdgeInsets.only(left: 10),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade200,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Stack(
                                    children: [
                                      Center(
                                        child: Container(
                                          width: 80,
                                          height: 80,
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                            image: DecorationImage(
                                              image: NetworkImage(
                                                "https://daltalifts.com/erp2026/assets/items/${itemSela[i]['id']}/images/1.jpg",
                                              ),
                                              fit: BoxFit.cover,
                                            ),
                                            color: Colors.red,
                                          ),
                                        ),
                                      ),
                                      Positioned(
                                        bottom: 5,
                                        left: 0,
                                        right: 0,
                                        child: Text(
                                          itemSela[i]['a1'],
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }),
                          ),
                        ),
                      ),
                      SizedBox(height: 10),
                      ...List.generate(itemLabelsDet.length, (i) {
                        return Visibility(
                          visible: itemLiftsDet[0]['a${i + 1}'] != null
                              ? true
                              : false,
                          child: Column(
                            children: [
                              ListTile(
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 10,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                tileColor: Colors.grey.shade100,
                                title: Text(itemLabelsDet[i]['arb']),
                                subtitle: Text(
                                  itemLiftsDet[0]['a${i + 1}'].toString(),
                                ),
                              ),
                              SizedBox(height: 10),
                            ],
                          ),
                        );
                      }),
                      SizedBox(height: 105),
                    ],
                  ),
                ),
              ),
              floatingActionButtonLocation:
                  FloatingActionButtonLocation.centerFloat,
              floatingActionButton: GestureDetector(
                onTap: () async {
                  setState(() {
                    isLoading = true;
                  });
                  SharedPreferences prefx =
                      await SharedPreferences.getInstance();
                      print({
                      "action": "addOneItem",
                      "itmid": itemDetails[0]['id'],
                      "uid": prefx.getString("userId"),
                      "oid": prefx.getString("orderId"),
                    });
                  var result = await getDio().post(
                    "https://daltalifts.com/app2026/sql.php?k=${DateTime.now().millisecondsSinceEpoch}",
                    data: {
                      "action": "addOneItem",
                      "itmid": itemDetails[0]['id'],
                      "uid": prefx.getString("userId"),
                      "oid": prefx.getString("orderId"),
                    },
                  );
                  if (result.data['success'] == true) {
                    setState(() {
                      isLoading = false;
                    });
                    currentTab.jumpToPagex(2);
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => MainScreen()),
                    );
                  } else {
                    setState(() {
                      isLoading = true;
                    });
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
                      ? CircularProgressIndicator(color: Colors.white)
                      : Text(
                          "طلب العرض",
                          style: TextStyle(fontSize: 20, color: Colors.white),
                        ),
                ),
              ),
            ),
    );
  }
}
