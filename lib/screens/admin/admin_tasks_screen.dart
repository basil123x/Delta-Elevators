import 'dart:async';

import 'package:Delta/screens/admin/engineer_task_scope.dart';
import 'package:Delta/screens/booking/contract/ContractScreen.dart';
import 'package:Delta/screens/settings/Maintenance/MaintenanceDetails.dart';
import 'package:Delta/services/DioServiceCert.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:iconsax/iconsax.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Admin «مهامي»: elevator bookings + maintenance tickets with nested filters.
class AdminTasksScreen extends StatefulWidget {
  const AdminTasksScreen({super.key});

  @override
  State<AdminTasksScreen> createState() => _AdminTasksScreenState();
}

class _AdminTasksScreenState extends State<AdminTasksScreen> {
  static const _orange = Color(0xFFF37021);

  /// 0 = طلب مصاعد, 1 = طلبات صيانة
  int _mainTab = 0;

  /// Elevator: 0 الكل, 1 قيد التنفيذ, 2 مكتملة
  /// Maintenance: 0 عادية, 1 عاجلة, 2 الكل
  int _filterTab = 0;

  List _items = [];
  bool _loading = true;
  bool _isEngineer = false;
  String _engineerUserId = '';
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _load();
    _timer = Timer.periodic(const Duration(seconds: 8), (_) => _load());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  List _filterForEngineer(
    List list,
    String uid, {
    bool requireAssignment = true,
  }) {
    if (!_isEngineer) return list;
    return list.where((row) {
      final hasApp =
          (row['assigned_app_uid']?.toString() ?? '').isNotEmpty;
      final hasTo = (row['assigned_to']?.toString() ?? '').isNotEmpty;
      if (!requireAssignment && !hasApp && !hasTo) return true;
      return EngineerTaskScope.isAssignedToCurrentEngineer(
        row,
        uid: uid,
        engineerUserId: _engineerUserId,
      );
    }).toList();
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final uid = prefs.getString('userId') ?? '';
      _isEngineer = prefs.getBool(EngineerTaskScope.isEngineerKey) ?? false;
      _engineerUserId =
          prefs.getString(EngineerTaskScope.engineerUserIdKey) ?? '';
      await prefs.remove(EngineerTaskScope.tasksCacheKey);
      if (_mainTab == 0) {
        await _loadElevators(uid);
      } else {
        await _loadMaintenance(uid);
      }
    } on DioException catch (e) {
      debugPrint('Admin tasks error: ${e.message}');
      if (mounted) setState(() => _loading = false);
    } catch (e) {
      debugPrint('Admin tasks unexpected: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadElevators(String uid) async {
    // Server: 0 all, 1 in-progress, 2 completed
    final result = await getDio().post(
      'https://daltalifts.com/app2026/sql.php?k=${DateTime.now().millisecondsSinceEpoch}',
      data: {
        'action': 'getMyBookings',
        'uid': uid,
        'indexChanged': _filterTab,
      },
    );
    final raw = result.data['data'];
    final list = raw is List ? List.from(raw) : <dynamic>[];
    // Elevator requests only (exclude maintenance-contract bookings).
    final elev = list.where((b) {
      final enter = b['enter']?.toString() ?? '';
      return !enter.contains('صيانة');
    }).toList();
    if (!mounted) return;
    setState(() {
      _items = _filterForEngineer(elev, uid);
      _loading = false;
    });
  }

  bool _isMaintenanceTicket(dynamic row) {
    final a5 = row['a5']?.toString() ?? '';
    return a5 == 'Normal' || a5 == 'Urgent';
  }

  bool _isUrgentBooking(dynamic booking) {
    final enter = booking['enter']?.toString() ?? '';
    final status = booking['status']?.toString() ?? '';
    return enter.contains('عاجل') || status.contains('عاجل');
  }

  Future<void> _loadMaintenance(String uid) async {
    if (_isEngineer) {
      await _loadEngineerMaintenance(uid);
      return;
    }
    // Server getMaintenances: 0 all, 1 Normal, 2 Urgent
    // UI order: 0 عادية, 1 عاجلة, 2 الكل
    final apiIndex = _filterTab == 0
        ? 1
        : _filterTab == 1
            ? 2
            : 0;
    final result = await getDio().post(
      'https://daltalifts.com/app2026/sql.php?k=${DateTime.now().millisecondsSinceEpoch}',
      data: {
        'action': 'getMaintenances',
        'uid': uid,
        'indexChanged': apiIndex,
      },
    );
    final raw = result.data['data'];
    final list = raw is List ? List.from(raw) : <dynamic>[];
    if (!mounted) return;
    setState(() {
      _items = list;
      _loading = false;
    });
  }

  Future<void> _loadEngineerMaintenance(String uid) async {
    final stamp = DateTime.now().millisecondsSinceEpoch;
    final results = await Future.wait([
      getDio().post(
        'https://daltalifts.com/app2026/sql.php?k=$stamp',
        data: {
          'action': 'getMyBookings',
          'uid': uid,
          'indexChanged': 0,
        },
      ),
      getDio().post(
        'https://daltalifts.com/app2026/sql.php?k=$stamp',
        data: {
          'action': 'getMaintenances',
          'uid': uid,
          'indexChanged': 0,
        },
      ),
    ]);

    final bookingsRaw = results[0].data['data'];
    final ticketsRaw = results[1].data['data'];
    final bookings =
        bookingsRaw is List ? List.from(bookingsRaw) : <dynamic>[];
    final tickets =
        ticketsRaw is List ? List.from(ticketsRaw) : <dynamic>[];

    final maintBookings = bookings.where((b) {
      final enter = b['enter']?.toString() ?? '';
      return enter.contains('صيانة');
    }).toList();

    var assignedBookings = _filterForEngineer(maintBookings, uid);
    var assignedTickets = _filterForEngineer(tickets, uid);

    if (_filterTab == 0) {
      assignedBookings =
          assignedBookings.where((b) => !_isUrgentBooking(b)).toList();
      assignedTickets = assignedTickets
          .where((t) => t['a5']?.toString() != 'Urgent')
          .toList();
    } else if (_filterTab == 1) {
      assignedBookings =
          assignedBookings.where(_isUrgentBooking).toList();
      assignedTickets = assignedTickets
          .where((t) => t['a5']?.toString() == 'Urgent')
          .toList();
    }

    final seenTicketIds = <String>{};
    final uniqueTickets = <dynamic>[];
    for (final t in assignedTickets) {
      final id = t['id']?.toString() ?? '';
      if (id.isEmpty || seenTicketIds.contains(id)) continue;
      seenTicketIds.add(id);
      uniqueTickets.add(t);
    }

    if (!mounted) return;
    setState(() {
      _items = [...assignedBookings, ...uniqueTickets];
      _loading = false;
    });
  }

  void _setMainTab(int i) {
    if (_mainTab == i) return;
    setState(() {
      _mainTab = i;
      _filterTab = 0;
      _loading = true;
      _items = [];
    });
    _load();
  }

  void _setFilterTab(int i) {
    if (_filterTab == i) return;
    setState(() {
      _filterTab = i;
      _loading = true;
    });
    _load();
  }

  String _timeAgo(String date, String time) {
    try {
      var pastDate = DateTime.parse(
        '$date ${time.replaceAll(' PM', '').replaceAll(' AM', '')}',
      );
      if (time.contains('PM') || time.contains('AM')) {
        final parts = time
            .replaceAll(' PM', '')
            .replaceAll(' AM', '')
            .split(':');
        var hour = int.parse(parts[0]);
        final minute = int.parse(parts[1]);
        if (time.contains('PM') && hour != 12) hour += 12;
        if (time.contains('AM') && hour == 12) hour = 0;
        pastDate = DateTime.parse(
          '$date ${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}:00',
        );
      }
      final diff = DateTime.now().difference(pastDate);
      if (diff.inSeconds < 60) return 'منذ أقل من دقيقة';
      if (diff.inMinutes < 60) return 'منذ ${diff.inMinutes} دقائق';
      if (diff.inHours < 24) return 'منذ ${diff.inHours} ساعات';
      if (diff.inDays == 1) return 'منذ يوم';
      if (diff.inDays < 30) return 'منذ ${diff.inDays} أيام';
      return 'منذ ${(diff.inDays / 30).floor()} أشهر';
    } catch (_) {
      return date.isNotEmpty ? date : '';
    }
  }

  int _progressPercent(dynamic booking) {
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

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _orange,
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
                  color: const Color(0xFFF2F3F7),
                  child: _buildBody(),
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
    final filterLabels = _mainTab == 0
        ? const ['الكل', 'قيد التنفيذ', 'مكتملة']
        : const ['عادية', 'عاجلة', 'الكل'];

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: _orange,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      padding: EdgeInsets.fromLTRB(16, topPad + 8, 16, 20),
      child: Column(
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.maybePop(context),
                child: const Icon(
                  Iconsax.arrow_right_3,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const Expanded(
                child: Text(
                  'مهامي',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 22),
            ],
          ),
          const SizedBox(height: 14),
          // Main category tabs
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.20),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                _pillTab('طلب مصاعد', 0, _mainTab, _setMainTab),
                _pillTab('طلبات صيانة', 1, _mainTab, _setMainTab),
              ],
            ),
          ),
          const SizedBox(height: 10),
          // Sub filters
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                for (var i = 0; i < filterLabels.length; i++)
                  _pillTab(
                    filterLabels[i],
                    i,
                    _filterTab,
                    _setFilterTab,
                    compact: true,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _pillTab(
    String label,
    int index,
    int active,
    ValueChanged<int> onTap, {
    bool compact = false,
  }) {
    final isActive = active == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => onTap(index),
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: EdgeInsets.symmetric(vertical: compact ? 8 : 10),
          decoration: BoxDecoration(
            color: isActive ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: compact ? 11 : 13,
              fontWeight: isActive ? FontWeight.w800 : FontWeight.w500,
              color: isActive ? _orange : Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading && _items.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: _orange),
      );
    }
    if (_items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset('assets/img/icons/no_address.svg'),
            const SizedBox(height: 10),
            Text(
              _isEngineer
                  ? 'لا توجد مهام محولة إليك'
                  : (_mainTab == 0
                      ? 'لا توجد طلبات مصاعد'
                      : 'لا توجد طلبات صيانة'),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              _isEngineer
                  ? 'ستظهر هنا المهام المعينة لك فقط'
                  : 'ستظهر المهام هنا عند توفرها',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      color: _orange,
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 24),
        itemCount: _items.length,
        itemBuilder: (context, index) {
          final item = _items[index];
          if (_mainTab == 0 || !_isMaintenanceTicket(item)) {
            return _buildElevatorCard(item);
          }
          return _buildMaintCard(item);
        },
      ),
    );
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
          style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
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

  Widget _buildElevatorCard(dynamic booking) {
    final isRejected = booking['stb']?.toString() == '4';
    final stl = booking['stl']?.toString() ?? '';
    final statusText = (booking['status']?.toString().isNotEmpty ?? false)
        ? booking['status'].toString()
        : (stl == '9'
            ? 'مكتمل'
            : (stl == '0' || stl.isEmpty ? 'قيد الانتظار' : 'قيد التنفيذ'));

    final isDone = stl == '9' || statusText.contains('مكتمل');
    final isWaiting = stl == '0' ||
        stl.isEmpty ||
        statusText.contains('انتظار') ||
        statusText.contains('إنتظار');
    final isProgress = !isDone && !isWaiting;

    final stripColor = isDone
        ? const Color(0xFF22C55E)
        : isProgress
            ? _orange
            : const Color(0xFF3B82F6);
    final badgeBg = isDone
        ? const Color(0xFFEDFAF4)
        : isProgress
            ? const Color(0xFFFFF7ED)
            : const Color(0xFFEEF4FF);
    final badgeColor = isDone
        ? const Color(0xFF16A34A)
        : isProgress
            ? _orange
            : const Color(0xFF3B82F6);
    final badgeText =
        isDone ? 'مكتمل' : (isProgress ? 'قيد التنفيذ' : 'قيد الانتظار');
    final badgeIcon = isDone
        ? Icons.check_circle_rounded
        : isProgress
            ? Icons.timelapse_rounded
            : Icons.schedule_rounded;
    final progressPct = isProgress ? _progressPercent(booking) : 0;
    final client = booking['client_name']?.toString() ?? '';
    final timeLabel = _timeAgo(
      booking['date']?.toString() ?? '',
      booking['time']?.toString() ?? '',
    );
    final orderLabel = 'طلب #${booking['id'] ?? ''}';

    return _taskCard(
      stripDone: isDone,
      stripProgress: isProgress,
      orderLabel: orderLabel,
      badgeText: badgeText,
      badgeBg: badgeBg,
      badgeColor: badgeColor,
      badgeIcon: badgeIcon,
      isRejected: isRejected,
      typeLabel: (booking['enter']?.toString() ?? '').contains('صيانة')
          ? 'صيانة'
          : 'مصعد',
      statusText: statusText,
      statusColor: stripColor,
      extraLabel: client.isNotEmpty ? 'العميل' : null,
      extraValue: client,
      progressPct: progressPct,
      timeLabel: timeLabel,
      actionLabel: isProgress ? 'تابع الطلب' : 'عرض التفاصيل',
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                ContractScreen(orderId: booking['id'].toString()),
          ),
        );
      },
    );
  }

  Widget _buildMaintCard(dynamic row) {
    final subtype = row['a5']?.toString() ?? 'Normal';
    final isUrgent = subtype == 'Urgent';
    final stx = row['stx']?.toString() ?? '0';
    final isDone = stx == '2' || stx == '9';
    final isWaiting = stx == '' || stx == '0';
    final isProgress = !isDone && !isWaiting;

    final statusText = isDone
        ? 'مكتمل'
        : isProgress
            ? 'قيد التنفيذ'
            : 'قيد الانتظار';
    final stripColor = isDone
        ? const Color(0xFF22C55E)
        : isProgress
            ? _orange
            : const Color(0xFF3B82F6);
    final badgeBg = isDone
        ? const Color(0xFFEDFAF4)
        : isProgress
            ? const Color(0xFFFFF7ED)
            : const Color(0xFFEEF4FF);
    final badgeColor = isDone
        ? const Color(0xFF16A34A)
        : isProgress
            ? _orange
            : const Color(0xFF3B82F6);
    final badgeIcon = isDone
        ? Icons.check_circle_rounded
        : isProgress
            ? Icons.timelapse_rounded
            : Icons.schedule_rounded;

    final typeLabel = isUrgent ? 'صيانة عاجلة' : 'صيانة عادية';
    final client = row['client_name']?.toString() ?? '';
    final city = row['city']?.toString() ?? '';
    final zone = row['zone']?.toString() ?? '';
    final location = [city, zone].where((e) => e.isNotEmpty).join(' - ');
    final timeLabel = _timeAgo(
      row['a3']?.toString() ?? '',
      row['a4']?.toString() ?? '',
    );

    return _taskCard(
      stripDone: isDone,
      stripProgress: isProgress,
      orderLabel: 'طلب #${row['id'] ?? ''}',
      badgeText: statusText,
      badgeBg: badgeBg,
      badgeColor: badgeColor,
      badgeIcon: badgeIcon,
      isRejected: false,
      typeLabel: typeLabel,
      statusText: statusText,
      statusColor: stripColor,
      extraLabel: client.isNotEmpty
          ? 'العميل'
          : (location.isNotEmpty ? 'الموقع' : null),
      extraValue: client.isNotEmpty ? client : location,
      progressPct: 0,
      timeLabel: timeLabel,
      actionLabel: isProgress ? 'تابع الطلب' : 'عرض التفاصيل',
      urgentAccent: isUrgent,
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => MaintenanceDetailScreen(
              maintenanceId: row['id'].toString(),
            ),
          ),
        );
      },
    );
  }

  Widget _taskCard({
    required bool stripDone,
    required bool stripProgress,
    required String orderLabel,
    required String badgeText,
    required Color badgeBg,
    required Color badgeColor,
    required IconData badgeIcon,
    required bool isRejected,
    required String typeLabel,
    required String statusText,
    required Color statusColor,
    String? extraLabel,
    String? extraValue,
    required int progressPct,
    required String timeLabel,
    required String actionLabel,
    required VoidCallback onTap,
    bool urgentAccent = false,
  }) {
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
            onTap: onTap,
            child: Column(
              children: [
                Container(
                  height: 5,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerRight,
                      end: Alignment.centerLeft,
                      colors: stripDone
                          ? const [Color(0xFF22C55E), Color(0xFF16A34A)]
                          : stripProgress
                              ? (urgentAccent
                                  ? const [Color(0xFFEF4444), Color(0xFFF87171)]
                                  : const [Color(0xFFF37021), Color(0xFFFF9A57)])
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
                          if (isRejected) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFEEEE),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: const Color(0xFFEF4444),
                                ),
                              ),
                              child: const Text(
                                'مرفوض',
                                style: TextStyle(
                                  color: Color(0xFFEF4444),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 12),
                      _infoRow(
                        icon: Iconsax.building,
                        label: 'النوع',
                        value: typeLabel,
                        valueColor: urgentAccent
                            ? const Color(0xFFEF4444)
                            : const Color(0xFF1A1A2E),
                      ),
                      const SizedBox(height: 7),
                      _infoRow(
                        icon: Icons.info_outline_rounded,
                        label: 'الحالة',
                        value: statusText,
                        valueColor: statusColor,
                      ),
                      if (extraLabel != null &&
                          (extraValue?.isNotEmpty ?? false)) ...[
                        const SizedBox(height: 7),
                        _infoRow(
                          icon: Iconsax.user,
                          label: extraLabel,
                          value: extraValue!,
                          valueColor: const Color(0xFF1A1A2E),
                        ),
                      ],
                    ],
                  ),
                ),
                if (progressPct > 0) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                    child: Column(
                      children: [
                        Row(
                          textDirection: TextDirection.rtl,
                          children: [
                            Text(
                              'نسبة الإنجاز',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              '$progressPct%',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: _orange,
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
                              _orange,
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
                      Container(
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
                              actionLabel,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: _orange,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Icon(
                              Iconsax.arrow_left_2,
                              size: 12,
                              color: _orange,
                            ),
                          ],
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
}
