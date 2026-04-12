import 'dart:async';

import 'package:Delta/constants/app_colors.dart';
import 'package:Delta/provider/app_provider.dart';
import 'package:Delta/screens/booking/contract/ContractScreen.dart';
import 'package:Delta/services/DioServiceCert.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Bookingscreen extends StatefulWidget {
  const Bookingscreen({super.key});

  @override
  State<Bookingscreen> createState() => _BookingscreenState();
}

class _BookingscreenState extends State<Bookingscreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List myBookings = [];
  Timer? _timer;

  String getTimeAgo(String date, String time) {
    // دمج التاريخ والوقت
    String dateTimeString = '$date $time';
    DateTime pastDate = DateTime.parse(
      dateTimeString.replaceAll(' PM', '').replaceAll(' AM', ''),
    );

    // لو الوقت فيه AM/PM، لازم نحوله لـ 24-hour format
    if (time.contains('PM') || time.contains('AM')) {
      // تحويل من 12-hour ل 24-hour
      List<String> timeParts = time
          .replaceAll(' PM', '')
          .replaceAll(' AM', '')
          .split(':');
      int hour = int.parse(timeParts[0]);
      int minute = int.parse(timeParts[1]);

      if (time.contains('PM') && hour != 12) {
        hour += 12;
      } else if (time.contains('AM') && hour == 12) {
        hour = 0;
      }

      pastDate = DateTime.parse(
        '$date ${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}:00',
      );
    }

    DateTime now = DateTime.now();
    Duration diff = now.difference(pastDate);

    int seconds = diff.inSeconds;
    int minutes = diff.inMinutes;
    int hours = diff.inHours;
    int days = diff.inDays;

    if (seconds < 60) {
      return 'منذ أقل من دقيقة';
    } else if (minutes < 60) {
      if (minutes == 1) return 'منذ دقيقة';
      if (minutes == 2) return 'منذ دقيقتين';
      return 'منذ $minutes دقائق';
    } else if (hours < 24) {
      if (hours == 1) return 'منذ ساعة';
      if (hours == 2) return 'منذ ساعتين';
      return 'منذ $hours ساعات';
    } else if (days == 1) {
      return 'منذ يوم';
    } else if (days == 2) {
      return 'منذ يومين';
    } else if (days < 30) {
      return 'منذ $days أيام';
    } else if (days < 365) {
      int months = (days / 30).floor();
      if (months == 1) return 'منذ شهر';
      if (months == 2) return 'منذ شهرين';
      return 'منذ $months أشهر';
    } else {
      int years = (days / 365).floor();
      if (years == 1) return 'منذ سنة';
      if (years == 2) return 'منذ سنتين';
      return 'منذ $years سنوات';
    }
  }

  Future<void> getMyBookings() async {
  // ✅ لو الـ widget اتشال، وقف
  if (!mounted) return;

  try {
    SharedPreferences prefx = await SharedPreferences.getInstance();
    String uid = prefx.getString("userId") ?? "";

    var result = await getDio().post(
      "https://daltalifts.com/app2026/sql.php?k=${DateTime.now().millisecondsSinceEpoch}",
      data: {
        "action": "getMyBookings",
        "uid": uid,
        "indexChanged": _tabController.index,
      },
    );

    // ✅ تحقق تاني بعد الـ await لأن الـ widget ممكن يتشال خلال الـ request
    if (!mounted) return;

    setState(() {
      myBookings = result.data['data'] ?? [];
    });

  } on DioException catch (e) {
    if (!mounted) return;
    // ✅ مش بتعمل setState بـ error، بس توقف الـ loading
    debugPrint("Booking error: ${e.response?.statusCode} - ${e.message}");
  } catch (e) {
    if (!mounted) return;
    debugPrint("Unexpected error: $e");
  }
}

  

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    getMyBookings();
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        getMyBookings();
      }
    });
    _timer = Timer.periodic(Duration(seconds: 5), (timer) {
      getMyBookings();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text(
          "الحجوزات",
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
                Tab(text: "الكل"),
                Tab(text: "قيد التنفيذ"),
                Tab(text: "مكتملة"),
              ],
            ),
          ),
        ),
      ),
      body: myBookings.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SvgPicture.asset('assets/img/icons/no_address.svg'),
                  SizedBox(height: 10),
                  Text(
                    "لا يوجد حجوزات بعد",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 10),
                  Text("إحجز طلب ثم إرجع لاحقاً"),
                ],
              ),
            )
          : TabBarView(
              controller: _tabController,
              children: [
                _buildBookingsList(),
                _buildBookingsList(),
                _buildBookingsList(),
              ],
            ),
    );
  }

  Widget _buildBookingsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: myBookings.length,
      itemBuilder: (context, index) {
        return _buildBookingCard(index);
      },
    );
  }

  Widget _buildBookingCard(int index) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.1),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () {
              Provider.of<AppProvider>(context, listen: false).jumpToTabx(0);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ContractScreen(
                    orderId: myBookings[index]['id'].toString(),
                  ),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Icon Container with gradient
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.primary,
                              AppColors.primary.withOpacity(0.7),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Iconsax.calendar_1,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 15),
                      // Booking Info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                // Status Badge
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _getStatusColor(
                                      myBookings[index]['stl'],
                                    ).withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    _getStatusText(myBookings[index]['stl']),
                                    style: TextStyle(
                                      color: _getStatusColor(
                                        myBookings[index]['stl'],
                                      ),
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                Text(
                                  "عرض طلب #${myBookings[index]['id']}",
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Text(
                                  getTimeAgo(
                                    myBookings[index]['date'],
                                    myBookings[index]['time'],
                                  ),
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                const SizedBox(width: 5),
                                Icon(
                                  Iconsax.clock,
                                  size: 16,
                                  color: Colors.grey[600],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  // Divider
                  Container(
                    height: 1,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          Colors.grey[300]!,
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                  // Bottom Row
                  // Action Button
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primary,
                          AppColors.primary.withOpacity(0.8),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ContractScreen(
                                orderId: myBookings[index]['id'].toString(),
                              ),
                            ),
                          );
                        },
                        child: const Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 10,
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Iconsax.arrow_left_3,
                                color: Colors.white,
                                size: 18,
                              ),
                              SizedBox(width: 8),
                              Text(
                                "عرض التفاصيل",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String index) {
    switch (index) {
      case "0":
        return Colors.grey;
      case "9":
        return Colors.green;
      default:
        return Colors.orange;
    }
  }

  String _getStatusText(String index) {
    switch (index) {
      case "0":
        return "قيد الإنتظار";
      case "9":
        return "مكتمل";
      default:
        return "قيد التنفيذ";
    }
  }
}
