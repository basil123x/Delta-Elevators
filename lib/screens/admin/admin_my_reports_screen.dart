import 'package:Delta/screens/repair/repair_theme.dart';
import 'package:Delta/services/DioServiceCert.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AdminMyReportsScreen extends StatefulWidget {
  const AdminMyReportsScreen({super.key});

  @override
  State<AdminMyReportsScreen> createState() => _AdminMyReportsScreenState();
}

class _AdminMyReportsScreenState extends State<AdminMyReportsScreen> {
  static const _apiUrl = 'https://daltalifts.com/app2026/report_issue.php';

  bool _loading = true;
  List _items = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final uid = prefs.getString('userId') ?? '';
      final result = await getDio().post(
        '$_apiUrl?k=${DateTime.now().millisecondsSinceEpoch}',
        data: {
          'action': 'getMyIssueReports',
          'technician_id': uid,
          'uid': uid,
        },
      );
      final raw = result.data['data'];
      if (!mounted) return;
      setState(() {
        _items = raw is List ? List.from(raw) : [];
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  ({String label, Color color, Color bg}) _status(String raw) {
    final s = raw.trim().toLowerCase();
    if (s == 'resolved' ||
        s == 'done' ||
        s == 'closed' ||
        s == 'solved' ||
        s == 'تم الحل') {
      return (
        label: 'تم الحل',
        color: const Color(0xFF16A34A),
        bg: const Color(0xFFEDFAF4),
      );
    }
    if (s == 'reviewing' ||
        s == 'review' ||
        s == 'pending' ||
        s == 'in_review' ||
        s == 'قيد المراجعة') {
      return (
        label: 'قيد المراجعة',
        color: const Color(0xFFF37021),
        bg: const Color(0xFFFFF7ED),
      );
    }
    return (
      label: 'جديد',
      color: const Color(0xFF3B82F6),
      bg: const Color(0xFFEEF4FF),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: RepairTheme.bg,
        body: Column(
          children: [
            RepairTheme.orangeHeader(context: context, title: 'بلاغاتي'),
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
                            'لا توجد بلاغات بعد',
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

  Widget _card(dynamic row) {
    final st = _status(row['status']?.toString() ?? 'new');
    final desc = row['description']?.toString() ?? '';
    final type = row['issue_type']?.toString() ?? '';
    final loc = row['location']?.toString() ?? '';
    final created = row['created_at']?.toString() ?? '';
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: RepairTheme.cardDecoration(radius: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  type.isEmpty ? 'بلاغ #${row['id']}' : type,
                  style: RepairTheme.cairo(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: st.bg,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  st.label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: st.color,
                  ),
                ),
              ),
            ],
          ),
          if (desc.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              desc,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: RepairTheme.cairo(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: RepairTheme.textSecondary,
                height: 1.5,
              ),
            ),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              if (loc.isNotEmpty) ...[
                const Icon(Iconsax.location, size: 13, color: Color(0xFFAAAAAA)),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    loc,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: RepairTheme.cairo(
                      fontSize: 12,
                      color: RepairTheme.hint,
                    ),
                  ),
                ),
              ] else
                const Spacer(),
              if (created.isNotEmpty)
                Text(
                  created,
                  style: RepairTheme.cairo(
                    fontSize: 11,
                    color: RepairTheme.hint,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
