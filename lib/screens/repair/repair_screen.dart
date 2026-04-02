import 'dart:async';

import 'package:Delta/constants/app_colors.dart';
import 'package:Delta/provider/app_provider.dart';
import 'package:Delta/screens/repair/repair_contract.dart';
import 'package:Delta/screens/repair/requests/requestScreen.dart';
import 'package:Delta/services/DioServiceCert.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RepairScreen extends StatefulWidget {
  const RepairScreen({super.key});

  @override
  State<RepairScreen> createState() => _RepairScreenState();
}

class _RepairScreenState extends State<RepairScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Timer? _timer;
  String stx = "";
  String name = '';

  Future getUserProfile() async {
    SharedPreferences _prefx = await SharedPreferences.getInstance();
    String uid = _prefx.getString("userId") ?? "";
    var result = await getDio().post(
      "https://daltalifts.com/app2026/sql.php?k=${DateTime.now().millisecondsSinceEpoch}",
      data: {"action": "profile", "uid": uid},
    );
    setState(() {
      name = result.data['data']['a1'];
    });
  }

  Future getContractStatus() async {
    if (!mounted) return;
    SharedPreferences _prefx = await SharedPreferences.getInstance();
    String uid = _prefx.getString("userId") ?? "";
    var result = await getDio().post(
      "https://daltalifts.com/app2026/sql.php?k=${DateTime.now().millisecondsSinceEpoch}",
      data: {"action": "getContract", "contractUserId": uid.toString()},
    );
    if (!mounted) return;
    setState(() {
      stx = result.data['data'][0]['stx'].toString();
      if (stx != '0') {
        _timer?.cancel();
      }
    });
  }

  @override
  void initState() {
    getContractStatus();
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _timer = Timer.periodic(Duration(seconds: 5), (timer) {
      getContractStatus();
      print("SSSSSSSSS $stx");
    });
  }
  

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          title: Text(
            stx == '1' ? "طلب صيانة" : "عقد الصيانة",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          centerTitle: true,
          backgroundColor: Colors.white,
          elevation: 0,
          bottom: stx == '1' ? PreferredSize(
            preferredSize: const Size.fromHeight(60),
            child: Container(
              color: Colors.white,
              child: TabBar(
                controller: _tabController,
                labelColor: AppColors.primary,
                unselectedLabelColor: Colors.grey,
                indicatorColor: AppColors.primary,
                indicatorWeight: 3,
                labelStyle: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  fontFamily: GoogleFonts.cairo().fontFamily,
                ),
                unselectedLabelStyle: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  fontFamily: GoogleFonts.cairo().fontFamily,
                ),
                tabs: const [
                  Tab(text: "طلب عادي"),
                  Tab(text: "طلب عاجل"),
                ],
              ),
            ),
          ) : null,
        ),
        body: stx == '1' ? TabBarView(
          physics: NeverScrollableScrollPhysics(),
          controller: _tabController,
          children: [
            RequestScreen(type: "Normal"),
            RequestScreen(type: "Urgent"),
          ],
        ) : RepairContract(),
      ),
    );
  }
}


