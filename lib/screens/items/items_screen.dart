import 'package:Delta/constants/app_colors.dart';
import 'package:Delta/screens/items/items_details_screen.dart';
import 'package:Delta/services/DioServiceCert.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

class ItemsScreen extends StatefulWidget {
  const ItemsScreen({super.key});

  @override
  State<ItemsScreen> createState() => _ItemsScreenState();
}

class _ItemsScreenState extends State<ItemsScreen> {
  int currentGroup = -1;
  List groups = [];
  List items = [];
  String currentGrpname = "الكل";
  Future getGroups() async {
    var request = await getDio().post(
      "https://daltalifts.com/app2026/sql.php?k=${DateTime.now().millisecondsSinceEpoch}",
      data: {"action": "groups"},
    );
    setState(() {
      groups = request.data['data'];
    });
  }

  Future getItems({String? grpx}) async {
    var request = await getDio().post(
      "https://daltalifts.com/app2026/sql.php?k=${DateTime.now().millisecondsSinceEpoch}",
      data: {"action": "items", "grp": grpx},
    );
    setState(() {
      items = request.data['data'];
    });
  }

  @override
  void initState() {
    getGroups();
    getItems();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: Text("منتجاتنا"),
          centerTitle: true,
          backgroundColor: Colors.white,
          forceMaterialTransparency: true,
        ),
        body: Container(
          margin: EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 5,
                children: [
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        currentGroup = -1;
                        currentGrpname = "الكل";
                        getItems();
                      });
                    },
                    child: Chip(
                      backgroundColor: currentGroup == -1
                          ? AppColors.primary
                          : Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide.none,
                      ),
                      side: currentGroup == -1
                          ? BorderSide.none
                          : BorderSide(color: AppColors.primary),
                      label: Text(
                        "الكل",
                        style: TextStyle(
                          color: currentGroup == -1
                              ? Colors.white
                              : Colors.black,
                        ),
                      ),
                    ),
                  ),
                  ...List.generate(groups.length, (i) {
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          currentGroup = i;
                          currentGrpname = groups[i]['a2'];
                          getItems(grpx: currentGrpname);
                        });
                      },
                      child: Chip(
                        backgroundColor: currentGroup == i
                            ? AppColors.primary
                            : Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: BorderSide.none,
                        ),
                        side: currentGroup == i
                            ? BorderSide.none
                            : BorderSide(color: AppColors.primary),
                        label: Text(
                          groups[i]['a2'],
                          style: TextStyle(
                            color: currentGroup == i
                                ? Colors.white
                                : Colors.black,
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Text(
                  "المنتجات - $currentGrpname",
                  style: TextStyle(fontSize: 18),
                ),
              ),
              Expanded(
                child: GridView(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 3,
                    crossAxisSpacing: 3,
                  ),
                  children: List.generate(items.length, (i) {
                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                ItemsDetailsScreen(itmid: items[i]['id']),
                          ),
                        );
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Stack(
                          children: [
                            Center(
                              child: Container(
                                width: 100,
                                height: 100,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  image: DecorationImage(
                                    image: NetworkImage(
                                      "https://delta-lifts.s3.me-south-1.amazonaws.com/Sys/items/${items[i]['id']}/1.jpg",
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
                                items[i]['a1'],
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
            ],
          ),
        ),
      ),
    );
  }
}
