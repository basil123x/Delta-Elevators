import 'package:Delta/screens/booking/contract/ContractScreen.dart';
import 'package:Delta/screens/repair/repair_theme.dart';
import 'package:Delta/screens/settings/Maintenance/MaintenanceDetails.dart';
import 'package:Delta/services/DioServiceCert.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Completed jobs from the same sources as «مهامي», newest first.
class AdminTaskHistoryScreen extends StatefulWidget {
  const AdminTaskHistoryScreen({super.key});

  @override
  State<AdminTaskHistoryScreen> createState() => _AdminTaskHistoryScreenState();
}

class _AdminTaskHistoryScreenState extends State<AdminTaskHistoryScreen> {
  bool _loading = true;
  List<_HistoryItem> _items = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final uid = prefs.getString('userId') ?? '';
      final stamp = DateTime.now().millisecondsSinceEpoch;
      final results = await Future.wait([
        getDio().post(
          'https://daltalifts.com/app2026/sql.php?k=$stamp',
          data: {
            'action': 'getMyBookings',
            'uid': uid,
            'indexChanged': 2,
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
      final maintRaw = results[1].data['data'];
      final bookings =
          bookingsRaw is List ? List.from(bookingsRaw) : <dynamic>[];
      final maint = maintRaw is List ? List.from(maintRaw) : <dynamic>[];

      final items = <_HistoryItem>[];
      for (final b in bookings) {
        final enter = b['enter']?.toString() ?? '';
        final isMaint = enter.contains('صيانة');
        items.add(
          _HistoryItem(
            id: b['id'].toString(),
            title: isMaint ? 'عقد صيانة #${b['id']}' : 'مصعد #${b['id']}',
            kind: isMaint ? 'صيانة' : 'مصعد',
            client: b['client_name']?.toString() ?? '',
            date: b['date']?.toString() ?? '',
            time: b['time']?.toString() ?? '',
            isMaintenanceTicket: false,
            isMaintenanceBooking: isMaint,
          ),
        );
      }
      for (final m in maint) {
        final stx = m['stx']?.toString() ?? '0';
        if (stx != '2' && stx != '9') continue;
        final urgent = m['a5']?.toString() == 'Urgent';
        items.add(
          _HistoryItem(
            id: m['id'].toString(),
            title:
                '${urgent ? 'صيانة عاجلة' : 'صيانة عادية'} #${m['id']}',
            kind: urgent ? 'صيانة عاجلة' : 'صيانة عادية',
            client: m['client_name']?.toString() ?? '',
            date: m['a3']?.toString() ?? '',
            time: m['a4']?.toString() ?? '',
            isMaintenanceTicket: true,
            isMaintenanceBooking: false,
          ),
        );
      }
      items.sort((a, b) {
        final da = '${a.date} ${a.time}';
        final db = '${b.date} ${b.time}';
        return db.compareTo(da);
      });

      if (!mounted) return;
      setState(() {
        _items = items;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: RepairTheme.bg,
        body: Column(
          children: [
            RepairTheme.orangeHeader(context: context, title: 'سجل المهام'),
            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: RepairTheme.orange,
                      ),
                    )
                  : _items.isEmpty
                      ? Center(
                          child: Text(
                            'لا توجد مهام مكتملة بعد',
                            style: RepairTheme.cairo(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: RepairTheme.textSecondary,
                            ),
                          ),
                        )
                      : RefreshIndicator(
                          color: RepairTheme.orange,
                          onRefresh: () async {
                            setState(() => _loading = true);
                            await _load();
                          },
                          child: ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                            itemCount: _items.length,
                            itemBuilder: (_, i) => _card(_items[i]),
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _card(_HistoryItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: RepairTheme.cardDecoration(radius: 18),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => item.isMaintenanceTicket
                    ? MaintenanceDetailScreen(maintenanceId: item.id)
                    : ContractScreen(orderId: item.id),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEDFAF4),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.check_circle_rounded,
                    color: Color(0xFF16A34A),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: RepairTheme.cairo(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        [
                          item.kind,
                          if (item.client.isNotEmpty) item.client,
                          if (item.date.isNotEmpty) item.date,
                        ].join(' • '),
                        style: RepairTheme.cairo(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: RepairTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Iconsax.arrow_left_2,
                  size: 16,
                  color: RepairTheme.orange,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HistoryItem {
  _HistoryItem({
    required this.id,
    required this.title,
    required this.kind,
    required this.client,
    required this.date,
    required this.time,
    required this.isMaintenanceTicket,
    required this.isMaintenanceBooking,
  });

  final String id;
  final String title;
  final String kind;
  final String client;
  final String date;
  final String time;
  final bool isMaintenanceTicket;
  final bool isMaintenanceBooking;
}
