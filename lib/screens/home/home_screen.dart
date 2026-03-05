import 'package:Delta/constants/app_colors.dart';
import 'package:Delta/screens/home/notifications_screen.dart';
import 'package:Delta/screens/home/search_screen.dart';
import 'package:Delta/screens/items/items_screen.dart';
import 'package:Delta/screens/repair/repair_screen.dart';
import 'package:Delta/screens/settings/About/about_screen.dart';
import 'package:Delta/screens/settings/Complaints/Complaints_screen.dart';
import 'package:Delta/screens/settings/Sales/SalesScreen.dart';
import 'package:Delta/services/DioServiceCert.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  TextEditingController searchController = TextEditingController();
  int currentIndex = 0;
  bool isSearch = false;
  List searchItemsList = [];
  List promosImages = [];
  List<Map<dynamic, dynamic>> services = [
    {"icon": Iconsax.box, "txt": "المنتجات", "onTap": ItemsScreen()},
    {"icon": Iconsax.briefcase, "txt": "صيانة", "onTap": RepairScreen()},
    {"icon": Iconsax.trend_up, "txt": "قسم المبيعات", "onTap": SalesScreen()},
    {
      "icon": Iconsax.note_2,
      "txt": "شكاوي و اقتراحات",
      "onTap": ComplaintScreen(),
    },
    {"icon": Iconsax.info_circle, "txt": "حول الشركة", "onTap": AboutScreen()},
  ];
  String userName = "";

  Future getUserProfile() async {
    SharedPreferences _prefx = await SharedPreferences.getInstance();
    String uid = _prefx.getString("userId") ?? "";
    String oid = _prefx.getString("orderId") ?? "";
    var result = await getDio().post(
      "https://daltalifts.com/app2026/sql.php",
      data: {"action": "profile", "uid": uid},
    );
    setState(() {
      userName = result.data['data']['a1'];
    });
  }

  Future searchItems(kval) async {
    var result = await getDio().post(
      "https://daltalifts.com/app2026/sql.php?k=${DateTime.now().millisecondsSinceEpoch}",
      data: {"action": "search", "kval": kval},
    );
    setState(() {
      searchItemsList = result.data['data'];
    });
  }

  Future getPromos() async {
    var result = await getDio().post(
      "https://daltalifts.com/app2026/sql.php?k=${DateTime.now().millisecondsSinceEpoch}",
      data: {"action": "promos"},
    );
    setState(() {
      promosImages = result.data['data'];
    });
  }

  @override
  void initState() {
    getUserProfile();
    getPromos();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Image.asset('assets/img/logo.png', width: 100),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [Text("أهلا بك"), Text(userName)],
                    ),
                  ],
                ),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => NotificationsScreen(),
                      ),
                    );
                  },
                  child: Container(
                    margin: EdgeInsets.symmetric(horizontal: 10),
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: Colors.grey.shade200,
                    ),
                    child: Icon(Iconsax.notification),
                  ),
                ),
              ],
            ),
            Container(
              margin: EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
              ),
              child: TextField(
                onChanged: (val) {
                  setState(() {
                    if (val.isEmpty) {
                      isSearch = false;
                    } else {
                      isSearch = true;
                      searchItems(val);
                    }
                  });
                },
                controller: searchController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  hintText: 'ابحث هنا...',
                  hintStyle: TextStyle(color: AppColors.textHint),
                  prefixIcon: Container(
                    child: IconButton(
                      onPressed: () {},
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      splashRadius: 20,
                      icon: Icon(Iconsax.search_normal, size: 24),
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
            if (isSearch != true)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (promosImages.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.all(15),
                      child: Text(
                        "أحدث العروض",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                    ),
                  if (promosImages.isNotEmpty)
                    Container(
                      height: 200,
                      margin: EdgeInsets.symmetric(horizontal: 10),
                      child: PageView(
                        onPageChanged: (val) {
                          setState(() {
                            currentIndex = val;
                          });
                        },
                        children: List.generate(promosImages.length, (i) {
                          return ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              width: double.maxFinite,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                color: Colors.grey.shade200,
                                image: DecorationImage(
                                  image: NetworkImage(promosImages[i]),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                    ),
                  if (promosImages.isNotEmpty) SizedBox(height: 10),
                  if (promosImages.isNotEmpty)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(promosImages.length, (i) {
                        return AnimatedContainer(
                          duration: Duration(milliseconds: 300),
                          margin: EdgeInsets.symmetric(horizontal: 5),
                          width: currentIndex == i ? 20 : 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: currentIndex == i
                                ? AppColors.primary
                                : Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(10),
                          ),
                        );
                      }),
                    ),
                  Padding(
                    padding: const EdgeInsets.all(15),
                    child: Text(
                      "خدماتنا",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                  ),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: 1,
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 10),
                    itemCount: services.length,
                    itemBuilder: (context, i) {
                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => services[i]['onTap'],
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
                                child: Icon(services[i]['icon'], size: 40),
                              ),
                              Positioned(
                                bottom: 10,
                                left: 0,
                                right: 0,
                                child: Text(
                                  services[i]['txt'],
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
                    },
                  ),
                ],
              ),
            if (isSearch == true)
              SearchScreen(searchItemsList: searchItemsList),
          ],
        ),
      ),
    );
  }
}
