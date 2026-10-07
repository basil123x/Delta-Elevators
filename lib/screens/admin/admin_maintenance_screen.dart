import 'dart:async';

import 'package:Delta/screens/settings/Maintenance/MaintenanceDetails.dart';
import 'package:Delta/services/DioServiceCert.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Admin bottom-tab: all customer maintenance tickets with status control.
class AdminMaintenanceScreen extends StatefulWidget {
  const AdminMaintenanceScreen({super.key});

  @override
  State<AdminMaintenanceScreen> createState() => _AdminMaintenanceScreenState();
}

class _AdminMaintenanceScreenState extends State<AdminMaintenanceScreen> {
  static const _orange = Color(0xFFF37021);

  /// 0 الكل, 1 جديدة, 2 جارية, 3 مكتملة
  int _filterTab = 0;
  List _allItems = [];
  List _items = [];
  bool _loading = true;
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

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final uid = prefs.getString('userId') ?? '';
      final result = await getDio().post(
        'https://daltalifts.com/app2026/sql.php?k=${DateTime.now().millisecondsSinceEpoch}',
        data: {
          'action': 'getMaintenances',
          'uid': uid,
          'indexChanged': 0,
        },
      );
      final raw = result.data['data'];
      final tickets = raw is List ? List.from(raw) : <dynamic>[];
      // Customer service tickets only: Normal / Urgent. Never elevator
      // or maintenance-contract bookings.
      tickets.retainWhere((row) {
        final type = row['a5']?.toString() ?? '';
        return type == 'Normal' || type == 'Urgent';
      });
      tickets.sort((a, b) {
        final ia = int.tryParse(a['id']?.toString() ?? '') ?? 0;
        final ib = int.tryParse(b['id']?.toString() ?? '') ?? 0;
        return ib.compareTo(ia);
      });

      if (!mounted) return;
      setState(() {
        _allItems = tickets;
        _items = tickets.where(_matchesFilter).toList();
        _loading = false;
      });
    } on DioException catch (e) {
      debugPrint('Admin maintenance error: ${e.message}');
      if (mounted) setState(() => _loading = false);
    } catch (e) {
      debugPrint('Admin maintenance unexpected: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  bool _isTicketDone(dynamic row) {
    final stx = row['stx']?.toString() ?? '0';
    return stx == '2' || stx == '9';
  }

  bool _isTicketNew(dynamic row) {
    final stx = row['stx']?.toString() ?? '0';
    return stx == '' || stx == '0';
  }

  bool _matchesFilter(dynamic row) {
    final isDone = _isTicketDone(row);
    final isNew = _isTicketNew(row);
    switch (_filterTab) {
      case 1:
        return isNew;
      case 2:
        return !isNew && !isDone;
      case 3:
        return isDone;
      default:
        return true;
    }
  }

  void _setFilterTab(int i) {
    if (_filterTab == i) return;
    setState(() {
      _filterTab = i;
      _items = _allItems.where(_matchesFilter).toList();
    });
  }

  String _timeAgo(String date, String time) {
    try {
      var pastDate = DateTime.parse(
        '$date ${time.replaceAll(' PM', '').replaceAll(' AM', '')}',
      );
      if (time.contains('PM') || time.contains('AM')) {
        final parts =
            time.replaceAll(' PM', '').replaceAll(' AM', '').split(':');
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
    const labels = ['الكل', 'جديدة', 'جارية', 'مكتملة'];
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: _orange,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      padding: EdgeInsets.fromLTRB(16, topPad + 16, 16, 24),
      child: Column(
        children: [
          const Text(
            'الصيانة',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'طلبات صيانة العملاء',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.white.withValues(alpha: 0.85),
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
                for (var i = 0; i < labels.length; i++)
                  _pillTab(labels[i], i),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _pillTab(String label, int index) {
    final isActive = _filterTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => _setFilterTab(index),
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isActive ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
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
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Iconsax.setting_2, size: 42, color: Color(0xFFCCCCCC)),
            SizedBox(height: 12),
            Text(
              'لا توجد طلبات صيانة',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1A1A2E),
              ),
            ),
            SizedBox(height: 6),
            Text(
              'ستظهر هنا طلبات العملاء فور إرسالها',
              style: TextStyle(fontSize: 13, color: Color(0xFF888888)),
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      color: _orange,
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 20),
        itemCount: _items.length,
        itemBuilder: (context, index) => _buildCard(_items[index]),
      ),
    );
  }

  Widget _buildCard(dynamic row) {
    final subtype = row['a5']?.toString() ?? 'Normal';
    final isUrgent = subtype == 'Urgent';
    final isDone = _isTicketDone(row);
    final isNew = _isTicketNew(row);
    final isProgress = !isDone && !isNew;

    final statusText = isDone
        ? 'مكتمل'
        : isProgress
            ? 'قيد التنفيذ'
            : 'جديد';
    final stripColor = isDone
        ? const Color(0xFF22C55E)
        : isProgress
            ? _orange
            : (isUrgent ? const Color(0xFFEF4444) : const Color(0xFF3B82F6));
    final badgeBg = isDone
        ? const Color(0xFFEDFAF4)
        : isProgress
            ? const Color(0xFFFFF7ED)
            : (isUrgent ? const Color(0xFFFFF1F2) : const Color(0xFFEEF4FF));
    final badgeColor = stripColor;
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
    final desc = row['a2']?.toString() ?? '';
    final timeLabel = _timeAgo(
      row['a3']?.toString() ?? '',
      row['a4']?.toString() ?? '',
    );

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
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => MaintenanceDetailScreen(
                    maintenanceId: row['id'].toString(),
                  ),
                ),
              );
              _load();
            },
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
                                  ? const [Color(0xFFEF4444), Color(0xFFF87171)]
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
                            'طلب #${row['id'] ?? ''}',
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
                                  statusText,
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
                        icon: Iconsax.setting_2,
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
                      if (client.isNotEmpty) ...[
                        const SizedBox(height: 7),
                        _infoRow(
                          icon: Iconsax.user,
                          label: 'العميل',
                          value: client,
                          valueColor: const Color(0xFF1A1A2E),
                        ),
                      ],
                      if (location.isNotEmpty) ...[
                        const SizedBox(height: 7),
                        _infoRow(
                          icon: Iconsax.location,
                          label: 'الموقع',
                          value: location,
                          valueColor: const Color(0xFF1A1A2E),
                        ),
                      ],
                      if (desc.isNotEmpty) ...[
                        const SizedBox(height: 7),
                        _infoRow(
                          icon: Iconsax.document_text,
                          label: 'العطل',
                          value: desc,
                          valueColor: const Color(0xFF555555),
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
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF0E5),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Row(
                          textDirection: TextDirection.rtl,
                          children: [
                            Text(
                              'إدارة الطلب',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: _orange,
                              ),
                            ),
                            SizedBox(width: 6),
                            Icon(
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
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
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
}
