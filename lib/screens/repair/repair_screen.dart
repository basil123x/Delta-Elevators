import 'dart:async';

import 'package:Delta/screens/repair/repair_theme.dart';
import 'package:Delta/screens/repair/requests/requestScreen.dart';
import 'package:Delta/services/DioServiceCert.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
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
    SharedPreferences prefx = await SharedPreferences.getInstance();
    String uid = prefx.getString("userId") ?? "";
    var result = await getDio().post(
      "https://daltalifts.com/app2026/sql.php?k=${DateTime.now().millisecondsSinceEpoch}",
      data: {"action": "profile", "uid": uid},
    );
    setState(() {
      name = result.data['data']['a1'];
    });
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _timer = Timer.periodic(Duration(seconds: 5), (timer) {
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
        backgroundColor: RepairTheme.bg,
        appBar: AppBar(
          backgroundColor: RepairTheme.cardBg,
          elevation: 0,
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Iconsax.arrow_right_3, color: RepairTheme.orange),
            onPressed: () => Navigator.maybePop(context),
          ),
          title: Text(
            "طلب صيانة",
            style: RepairTheme.cairo(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: RepairTheme.textPrimary,
            ),
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(48),
            child: TabBar(
              controller: _tabController,
              labelColor: RepairTheme.orange,
              unselectedLabelColor: RepairTheme.textSecondary,
              indicatorColor: RepairTheme.orange,
              indicatorWeight: 3,
              labelStyle: RepairTheme.cairo(
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
              unselectedLabelStyle: RepairTheme.cairo(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: RepairTheme.textSecondary,
              ),
              tabs: const [
                Tab(text: "طلب عادي"),
                Tab(text: "طلب عاجل"),
              ],
            ),
          ),
        ),
        body: TabBarView(
          physics: const NeverScrollableScrollPhysics(),
          controller: _tabController,
          children: const [
            RequestScreen(type: "Normal"),
            RequestScreen(type: "Urgent"),
          ],
        ),
      ),
    );
  }
}
