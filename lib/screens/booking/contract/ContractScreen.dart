import 'dart:async';

import 'package:Delta/constants/app_colors.dart';
import 'package:Delta/provider/app_provider.dart';
import 'package:Delta/screens/booking/contract/Contract.dart';
import 'package:Delta/screens/booking/contract/ContractScreen.dart';
import 'package:Delta/screens/booking/contract/ContractWait.dart';
import 'package:Delta/screens/booking/contract/Processing.dart';
import 'package:Delta/services/DioServiceCert.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
      "https://daltalifts.com/app2026/sql.php",
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
      if (myBooking.isNotEmpty && myBooking[0]['stx'] != "0" && myBooking[0]['stt'] != "0") {
        _timer?.cancel();
      }
    });
  }


  @override
  Widget build(BuildContext context) {
    print(myBooking);
    return Directionality(
      textDirection: TextDirection.rtl,
      child: myBooking.isEmpty
          ? Scaffold(backgroundColor: Colors.grey[50])
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
                return Scaffold(
                  backgroundColor: Colors.grey[50],
                  appBar: AppBar(
                    title: Text(
                      "طلب رقم ${widget.orderId}",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    centerTitle: true,
                    backgroundColor: Colors.white,
                    elevation: 0,
                    bottom: PreferredSize(
                      preferredSize: const Size.fromHeight(60),
                      child: Container(
                        color: Colors.white,
                        child: TabBar(
                          onTap: (index) {
                            if (index == 1 && myBooking[0]['stt'] == "0") {
                              _tabController.animateTo(0);
                            }
                          },
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
                          tabs:  [
                            Tab(text: "توقيع العقد"),
                            Tab(
                              child: Opacity(
                                opacity: myBooking[0]['stt'] == "0" ? 0.3 : 1.0,
                                child: Text("مراحل التنفيذ"),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  body: TabBarView(
                    physics: NeverScrollableScrollPhysics(),
                    controller: _tabController,
                    children: [
                      myBooking[0]['stx'] == "0"
                          ? ContractWait()
                          : Contract(bookDets: bookDet),
                      myBooking[0]['stx'] == "0"
                          ? ContractWait()
                          : Processing(bookDets: bookDet),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
