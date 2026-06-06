import 'dart:async';

import 'package:Delta/provider/app_provider.dart';
import 'package:Delta/screens/booking/contract/Contract.dart';
import 'package:Delta/screens/booking/contract/ContractWait.dart';
import 'package:Delta/screens/booking/contract/Processing.dart';
import 'package:Delta/screens/booking/contract/Quotation.dart';
import 'package:Delta/screens/booking/contract/contract_theme.dart';
import 'package:Delta/services/DioServiceCert.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';

class ContractScreen extends StatefulWidget {
  final String orderId;
  const ContractScreen({super.key, required this.orderId});

  @override
  State<ContractScreen> createState() => _ContractScreenState();
}

class _ContractScreenState extends State<ContractScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int currentPage = 0;
  Timer? _timer;

  List bookDet = [];
  List myBooking = [];

  @override
  void initState() {
    super.initState();
    getMyBookings();
    getBookingDet();
    _tabController = TabController(length: 2, vsync: this);
    _timer = Timer.periodic(Duration(seconds: 5), (timer) {
      getMyBookings();
      getBookingDet();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  Future getBookingDet() async {
    var response = await getDio().post(
      "https://daltalifts.com/app2026/sql.php?k=${DateTime.now().millisecondsSinceEpoch}",
      data: {"action": "getMyBookingDet", "bookId": widget.orderId},
    );
    setState(() {
      bookDet = response.data['data'];
    });
  }

  Future getMyBookings() async {
    var result = await getDio().post(
      "https://daltalifts.com/app2026/sql.php?k=${DateTime.now().millisecondsSinceEpoch}",
      data: {"action": "getMyBookingOne", "bookid": widget.orderId},
    );
    setState(() {
      myBooking = result.data['data'];
      if (myBooking.isNotEmpty &&
          myBooking[0]['stx'] != "0" &&
          myBooking[0]['stt'] != "0") {
        _timer?.cancel();
      }
    });
  }

  Widget getSwitchPage1() {
    switch (myBooking[0]['stx']) {
      case "0":
        return ContractWait();
      case "1":
        return QuotationScreen(bookDets: bookDet);
      case "2":
        return Contract(bookDets: bookDet);
      default:
        return Contract(bookDets: bookDet);
    }
  }

  Widget getSwitchPage2() {
    switch (myBooking[0]['stx']) {
      case "0":
        return ContractWait();
      default:
        return Processing(bookDets: bookDet);
    }
  }

  @override
  Widget build(BuildContext context) {
    print(widget.orderId);
    return Directionality(
      textDirection: TextDirection.rtl,
      child: myBooking.isEmpty
          ? Scaffold(backgroundColor: ContractTheme.bg)
          : Consumer<AppProvider>(
              builder: (context, app, child) {
                if (app.currentTab1 >= 0 && app.currentTab1 < 2) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (_tabController.index != app.currentTab1) {
                      _tabController.animateTo(
                        app.currentTab1,
                        duration: Duration(milliseconds: 200),
                        curve: Curves.easeInOut,
                      );
                    }
                  });
                }
                return GestureDetector(
                  onTap: () => FocusScope.of(context).unfocus(),
                  child: Scaffold(
                    backgroundColor: ContractTheme.bg,
                    appBar: AppBar(
                      leading: IconButton(
                        icon: const Icon(
                          Iconsax.arrow_right_3,
                          color: ContractTheme.orange,
                        ),
                        onPressed: () => Navigator.maybePop(context),
                      ),
                      title: Text(
                        myBooking[0]['stx'] == "1" ||
                                myBooking[0]['stx'] == "0"
                            ? "طلب عرض سعر"
                            : "طلب رقم ${widget.orderId}",
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: ContractTheme.textPrimary,
                        ),
                      ),
                      centerTitle: true,
                      backgroundColor: Colors.white,
                      elevation: 0,
                      bottom: myBooking[0]['stx'] == "1" ||
                              myBooking[0]['stx'] == "0"
                          ? null
                          : PreferredSize(
                              preferredSize: const Size.fromHeight(49),
                              child: Column(
                                children: [
                                  TabBar(
                                    onTap: (index) {
                                      if (index == 1 &&
                                          myBooking[0]['stt'] == "0") {
                                        _tabController.animateTo(0);
                                      }
                                    },
                                    controller: _tabController,
                                    labelColor: ContractTheme.orange,
                                    unselectedLabelColor:
                                        ContractTheme.textSecondary,
                                    indicatorColor: ContractTheme.orange,
                                    indicatorWeight: 3,
                                    dividerColor: ContractTheme.border,
                                    dividerHeight: 1,
                                    labelStyle: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                    ),
                                    unselectedLabelStyle: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    tabs: [
                                      const Tab(text: "توقيع العقد"),
                                      Tab(
                                        child: Opacity(
                                          opacity: myBooking[0]['stt'] == "0"
                                              ? 0.3
                                              : 1.0,
                                          child: const Text("مراحل التنفيذ"),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                    ),
                    body: TabBarView(
                      physics: const NeverScrollableScrollPhysics(),
                      controller: _tabController,
                      children: [
                        getSwitchPage1(),
                        getSwitchPage2(),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
