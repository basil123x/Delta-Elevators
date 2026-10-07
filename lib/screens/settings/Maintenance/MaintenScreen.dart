import 'dart:async';

import 'package:Delta/provider/app_provider.dart';
import 'package:Delta/screens/repair/repair_screen.dart';
import 'package:Delta/screens/settings/Maintenance/MaintenanceDetails.dart';
import 'package:Delta/services/DioServiceCert.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// طلبات الصيانة — نفس قالب صفحة الحجوزات (curves / tabs / cards).
class MaintenanceScreen extends StatefulWidget {
  const MaintenanceScreen({super.key});

  @override
  State<MaintenanceScreen> createState() => _MaintenanceScreenState();
}

class _MaintenanceScreenState extends State<MaintenanceScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List myMaintenance = [];
  Timer? _timer;
  int _lastSyncedIndex = 0;

  String getTimeAgo(String date, String time) {
    if (date.trim().isEmpty) return '';
    try {
      String dateTimeString = '$date $time';
      DateTime pastDate = DateTime.parse(
        dateTimeString.replaceAll(' PM', '').replaceAll(' AM', ''),
      );

      if (time.contains('PM') || time.contains('AM')) {
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

      final now = DateTime.now();
      final diff = now.difference(pastDate);
      final seconds = diff.inSeconds;
      final minutes = diff.inMinutes;
      final hours = diff.inHours;
      final days = diff.inDays;

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
        final months = (days / 30).floor();
        if (months == 1) return 'منذ شهر';
        if (months == 2) return 'منذ شهرين';
        return 'منذ $months أشهر';
      } else {
        final years = (days / 365).floor();
        if (years == 1) return 'منذ سنة';
        if (years == 2) return 'منذ سنتين';
        return 'منذ $years سنوات';
      }
    } catch (_) {
      return date;
    }
  }

  Widget _infoRow({
    required IconData icon,
    required String label,
    required String value,
    required Color valueColor,
  }) {
    return Row(
      textDirection: TextDirection.rtl,
      children: [
        Icon(icon, size: 13, color: Colors.grey.shade600),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.left,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: valueColor,
            ),
          ),
        ),
      ],
    );
  }

  void _openDetail(dynamic row) {
    Provider.of<AppProvider>(context, listen: false).jumpToTabx(0);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MaintenanceDetailScreen(
          maintenanceId: row['id'].toString(),
        ),
      ),
    ).then((_) {
      if (mounted) getMyMaintenance();
    });
  }

  Future<void> getMyMaintenance() async {
    if (!mounted) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final uid = prefs.getString('userId') ?? '';
      final result = await getDio().post(
        'https://daltalifts.com/app2026/sql.php?k=${DateTime.now().millisecondsSinceEpoch}',
        data: {
          'action': 'getMaintenances',
          'uid': uid,
          'indexChanged': _tabController.index,
        },
      );
      if (!mounted) return;
      final raw = result.data['data'];
      setState(() {
        myMaintenance = raw is List ? List.from(raw) : <dynamic>[];
      });
    } on DioException catch (e) {
      debugPrint('Maintenance list error: ${e.message}');
    } catch (e) {
      debugPrint('Maintenance list unexpected: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    getMyMaintenance();
    _tabController.addListener(_onTabControllerTick);
    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
      getMyMaintenance();
    });
  }

  void _onTabControllerTick() {
    if (!mounted || _tabController.indexIsChanging) return;
    final index = _tabController.index;
    if (index == _lastSyncedIndex) return;
    _lastSyncedIndex = index;
    getMyMaintenance();
    setState(() {});
  }

  void _selectTab(int index) {
    if (_tabController.index == index) return;
    _lastSyncedIndex = index;
    _tabController.animateTo(
      index,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
    );
    getMyMaintenance();
    setState(() {});
  }

  void _openNewRequest() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const RepairScreen()),
    ).then((_) {
      if (mounted) getMyMaintenance();
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
                  child: myMaintenance.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SvgPicture.asset(
                                'assets/img/icons/no_address.svg',
                              ),
                              const SizedBox(height: 10),
                              const Text(
                                'لا يوجد طلبات صيانة بعد',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 10),
                              const Text('أضف طلب ثم ارجع لاحقاً'),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(14, 14, 14, 20),
                          itemCount: myMaintenance.length,
                          itemBuilder: (context, index) {
                            return _buildRequestCard(myMaintenance[index]);
                          },
                        ),
                ),
              ),
            ),
            SafeArea(
              top: false,
              child: Container(
                color: const Color(0xFFF2F3F7),
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
                child: GestureDetector(
                  onTap: _openNewRequest,
                  child: Container(
                    height: 52,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFF37021), Color(0xFFFF8C00)],
                      ),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFF37021).withValues(alpha: 0.35),
                          blurRadius: 12,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Iconsax.add_circle, color: Colors.white, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'إضافة طلب صيانة',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
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
        top: topPad + 12,
        bottom: 28,
        left: 16,
        right: 16,
      ),
      child: Column(
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.maybePop(context),
                behavior: HitTestBehavior.opaque,
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(
                    Iconsax.arrow_right_3,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
              const Expanded(
                child: Text(
                  'طلبات الصيانة',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 32),
            ],
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
                _buildTab('صيانة عادية', 1),
                _buildTab('صيانة عاجلة', 2),
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
        onTap: () => _selectTab(index),
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

  Widget _buildRequestCard(dynamic row) {
    final stx = row['stx']?.toString() ?? '0';
    final typeRaw = (row['a5']?.toString() ?? '').toLowerCase();
    final isUrgent = typeRaw.contains('urgent');
    final typeLabel = isUrgent ? 'صيانة عاجلة' : 'صيانة عادية';

    final bool isDone = stx == '2';
    final bool isProgress = stx == '1';
    final bool isWaiting = !isDone && !isProgress;

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
        ? 'مكتمل'
        : isProgress
            ? 'قيد التنفيذ'
            : 'قيد الانتظار';

    final IconData badgeIcon = isDone
        ? Icons.check_circle_rounded
        : isProgress
            ? Icons.timelapse_rounded
            : Icons.schedule_rounded;

    final String statusText = _getStatusText(stx);
    final String timeLabel = getTimeAgo(
      row['a3']?.toString() ?? '',
      row['a4']?.toString() ?? '',
    );
    final String orderLabel = 'طلب صيانة #${row['id'] ?? ''}';
    final String desc = (row['a2']?.toString() ?? '').trim();

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
            onTap: () => _openDetail(row),
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
                              : isUrgent
                                  ? const [Color(0xFFEF4444), Color(0xFFF97316)]
                                  : const [Color(0xFF3B82F6), Color(0xFF60A5FA)],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        textDirection: TextDirection.rtl,
                        children: [
                          Text(
                            orderLabel,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF1A1A2E),
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: badgeBg,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              textDirection: TextDirection.rtl,
                              children: [
                                Text(
                                  badgeText,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: badgeColor,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(badgeIcon, size: 14, color: badgeColor),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _infoRow(
                        icon: isUrgent ? Iconsax.flash_1 : Iconsax.setting_2,
                        label: 'النوع',
                        value: typeLabel,
                        valueColor: isUrgent
                            ? const Color(0xFFEF4444)
                            : const Color(0xFF1A1A2E),
                      ),
                      const SizedBox(height: 7),
                      _infoRow(
                        icon: Icons.info_outline_rounded,
                        label: 'الحالة',
                        value: statusText,
                        valueColor: stripColor,
                      ),
                      if (desc.isNotEmpty) ...[
                        const SizedBox(height: 7),
                        _infoRow(
                          icon: Iconsax.note_text,
                          label: 'الوصف',
                          value: desc,
                          valueColor: const Color(0xFF1A1A2E),
                        ),
                      ],
                    ],
                  ),
                ),
                const Divider(height: 1, color: Color(0xFFF5F5F5)),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Row(
                    textDirection: TextDirection.rtl,
                    children: [
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
                      const Spacer(),
                      GestureDetector(
                        onTap: () => _openDetail(row),
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
                            textDirection: TextDirection.rtl,
                            children: [
                              Text(
                                isProgress ? 'تابع الطلب' : 'عرض التفاصيل',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFFF37021),
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Icon(
                                Iconsax.arrow_left_2,
                                size: 12,
                                color: Color(0xFFF37021),
                              ),
                            ],
                          ),
                        ),
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
      case '1':
        return 'قيد التنفيذ';
      case '2':
        return 'مكتمل';
      default:
        return 'قيد الانتظار';
    }
  }
}
