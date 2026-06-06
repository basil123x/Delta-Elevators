import 'dart:async';

import 'package:Delta/provider/app_provider.dart';
import 'package:Delta/screens/booking/contract/ContractScreen.dart';
import 'package:Delta/services/DioServiceCert.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:iconsax/iconsax.dart';

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

  int _progressPercentFromBooking(dynamic booking) {
    final parsed = int.tryParse(booking['progress']?.toString() ?? '');
    if (parsed != null && parsed >= 0 && parsed <= 100) return parsed;
    final stl = booking['stl']?.toString() ?? '0';
    if (stl == '9') return 100;
    if (stl == '0') return 0;
    final step = int.tryParse(stl);
    if (step != null && step >= 1 && step <= 8) {
      return (step * 100 ~/ 9).clamp(5, 95);
    }
    return 65;
  }

  String _elevatorTypeLabel(dynamic booking) {
    final v =
        booking['elevator_type'] ??
        booking['type'] ??
        booking['service_type'] ??
        booking['stt'];
    if (v == null || v.toString().isEmpty) return 'مصعد';
    return v.toString();
  }

  void _openBookingDetail(dynamic booking) {
    Provider.of<AppProvider>(context, listen: false).jumpToTabx(0);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ContractScreen(orderId: booking['id'].toString()),
      ),
    );
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
      setState(() {});
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
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF37021),
        body: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(28),
                  topRight: Radius.circular(28),
                ),
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Color(0xFFF2F3F7),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(28),
                      topRight: Radius.circular(28),
                    ),
                  ),
                  child: myBookings.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SvgPicture.asset(
                                'assets/img/icons/no_address.svg',
                              ),
                              const SizedBox(height: 10),
                              const Text(
                                'لا يوجد حجوزات بعد',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 10),
                              const Text('إحجز طلب ثم إرجع لاحقاً'),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(14, 14, 14, 20),
                          itemCount: myBookings.length,
                          itemBuilder: (context, index) {
                            return _buildBookingCard(myBookings[index]);
                          },
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final topPad = MediaQuery.paddingOf(context).top;
    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: const BoxDecoration(
        color: Color(0xFFF37021),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      padding: EdgeInsets.only(
        top: topPad + 16,
        bottom: 28,
        left: 16,
        right: 16,
      ),
      child: Column(
        children: [
          const Text(
            'حجوزاتي',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.20),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                _buildTab('الكل', 0),
                _buildTab('قيد التنفيذ', 1),
                _buildTab('مكتملة', 2),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTab(String label, int index) {
    final bool isActive = _tabController.index == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (_tabController.index != index) {
            _tabController.animateTo(
              index,
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
            );
          }
        },
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isActive ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
              color: isActive ? const Color(0xFFF37021) : Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBookingCard(dynamic booking) {
    final stl = booking['stl']?.toString() ?? '';
    final String statusText =
        (booking['status']?.toString().isNotEmpty ?? false)
        ? booking['status'].toString()
        : _getStatusText(stl);

    final bool isDone =
        stl == '9' ||
        statusText.contains('مكتمل') ||
        statusText.toLowerCase().contains('complete');
    final bool isWaiting =
        stl == '0' ||
        statusText.contains('انتظار') ||
        statusText.contains('إنتظار') ||
        statusText.toLowerCase().contains('wait');
    final bool isProgress = !isDone && !isWaiting;

    final Color stripColor = isDone
        ? const Color(0xFF22C55E)
        : isProgress
        ? const Color(0xFFF37021)
        : const Color(0xFF3B82F6);

    final Color badgeBg = isDone
        ? const Color(0xFFEDFAF4)
        : isProgress
        ? const Color(0xFFFFF7ED)
        : const Color(0xFFEEF4FF);

    final Color badgeColor = isDone
        ? const Color(0xFF16A34A)
        : isProgress
        ? const Color(0xFFF37021)
        : const Color(0xFF3B82F6);

    final String badgeText = isDone
        ? '✓ مكتمل'
        : isProgress
        ? '⏳ قيد التنفيذ'
        : '🕐 قيد الانتظار';

    final int progressPct = isProgress
        ? _progressPercentFromBooking(booking)
        : 0;

    final String timeLabel = getTimeAgo(
      booking['date']?.toString() ?? '',
      booking['time']?.toString() ?? '',
    );

    final String orderLabel =
        'طلب #${booking['id'] ?? booking['order_id'] ?? booking['orderId'] ?? ''}';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFEBEBEB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _openBookingDetail(booking),
            child: Column(
              children: [
                Container(
                  height: 5,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerRight,
                      end: Alignment.centerLeft,
                      colors: isDone
                          ? const [Color(0xFF22C55E), Color(0xFF16A34A)]
                          : isProgress
                          ? const [Color(0xFFF37021), Color(0xFFFF9A57)]
                          : const [Color(0xFF3B82F6), Color(0xFF60A5FA)],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: badgeBg,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              badgeText,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: badgeColor,
                              ),
                            ),
                          ),
                          Text(
                            orderLabel,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF1A1A2E),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _elevatorTypeLabel(booking),
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1A1A2E),
                            ),
                          ),
                          Row(
                            children: [
                              Icon(
                                Iconsax.building,
                                size: 13,
                                color: Colors.grey.shade600,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'النوع',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 7),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            statusText,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: stripColor,
                            ),
                          ),
                          Row(
                            children: [
                              Icon(
                                Iconsax.chart_2,
                                size: 13,
                                color: Colors.grey.shade600,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'الحالة',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (isProgress) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '$progressPct%',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFFF37021),
                              ),
                            ),
                            Text(
                              'نسبة الإنجاز',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(3),
                          child: LinearProgressIndicator(
                            value: progressPct / 100,
                            minHeight: 6,
                            backgroundColor: const Color(0xFFF5F5F5),
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              Color(0xFFF37021),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const Divider(height: 1, color: Color(0xFFF5F5F5)),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onTap: () => _openBookingDetail(booking),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF0E5),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Iconsax.arrow_right_3,
                                size: 12,
                                color: Color(0xFFF37021),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                isProgress ? 'تابع الطلب' : 'عرض التفاصيل',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFFF37021),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          Icon(
                            Iconsax.clock,
                            size: 12,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            timeLabel,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade400,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
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
