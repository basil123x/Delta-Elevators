import 'dart:async';

import 'package:Delta/screens/admin/engineer_task_scope.dart';
import 'package:Delta/screens/booking/contract/ContractScreen.dart';
import 'package:Delta/screens/settings/Maintenance/MaintenanceDetails.dart';
import 'package:Delta/services/DioServiceCert.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:iconsax/iconsax.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  static const Color _orange = Color(0xFFF37021);
  static const Color _bodyBg = Color(0xFFF2F3F7);
  static const Color _textDark = Color(0xFF1A1A2E);

  List notifications = [];
  String _filter = 'all';
  Set<String> _readIds = {};
  Timer? _refreshTimer;

  Future<void> getNotifications() async {
    try {
      final SharedPreferences prefx = await SharedPreferences.getInstance();
      final result = await getDio().post(
        "https://daltalifts.com/app2026/sql.php?k=${DateTime.now().millisecondsSinceEpoch}",
        data: {"action": "getNotify", "uid": prefx.getString("userId")},
      );
      if (!mounted) return;
      if (result.data['success'] == true) {
        setState(() {
          notifications = result.data['data'];
        });
      }
    } catch (_) {}
  }

  Future<void> _deleteAll() async {
    setState(() {
      notifications.clear();
      _readIds.clear();
    });
    final SharedPreferences prefx = await SharedPreferences.getInstance();
    await prefx.remove('read_notification_ids');
    await getDio().post(
      "https://daltalifts.com/app2026/sql.php?k=${DateTime.now().millisecondsSinceEpoch}",
      data: {"action": "delNotify", "uid": prefx.getString("userId")},
    );
  }

  Future<void> _loadReadIds() async {
    final prefs = await SharedPreferences.getInstance();
    final ids = prefs.getStringList('read_notification_ids') ?? [];
    if (!mounted) return;
    setState(() => _readIds = ids.toSet());
  }

  Future<void> _markAsRead(String notifId) async {
    if (notifId.isEmpty) return;
    if (_readIds.contains(notifId)) return;
    setState(() => _readIds.add(notifId));
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('read_notification_ids', _readIds.toList());
  }

  void _openNotification(Map<dynamic, dynamic> n, String idStr) {
    _markAsRead(idStr);
    final type = _typeStr(n);
    final bookingId = n['booking_id']?.toString() ??
        n['bookingId']?.toString() ??
        '';
    if (type == 'task_assigned' && bookingId.isNotEmpty) {
      EngineerTaskScope.clearTasksCache();
      Navigator.push(
        context,
        MaterialPageRoute<void>(
          builder: (_) => ContractScreen(orderId: bookingId),
        ),
      );
      return;
    }
    final title = n['title']?.toString() ?? '';
    final body = n['content']?.toString() ?? '';
    final combined = '$title $body';
    final match = RegExp(r'#\s*(\d+)').firstMatch(combined);
    final isMaintenance = title.contains('فني') ||
        title.contains('صيانة') ||
        body.contains('صيانة');
    if (match != null && isMaintenance) {
      Navigator.push(
        context,
        MaterialPageRoute<void>(
          builder: (_) =>
              MaintenanceDetailScreen(maintenanceId: match.group(1)!),
        ),
      );
    }
  }

  bool _isRead(dynamic notif) {
    if (notif is! Map) return false;
    final id = notif['id']?.toString() ?? '';
    return id.isNotEmpty && _readIds.contains(id);
  }

  String _typeStr(Map<dynamic, dynamic> n) {
    final t = n['type'] ?? n['notify_type'] ?? n['category'];
    return t?.toString() ?? '';
  }

  String _timeAgo(Map<dynamic, dynamic> n) {
    final raw = n['date'] ?? n['created_at'] ?? n['time'] ?? n['timestamp'] ?? n['sent_at'];
    if (raw == null || raw.toString().isEmpty) return '';
    return raw.toString();
  }

  List<Map<dynamic, dynamic>> _filteredNotifications() {
    final List<Map<dynamic, dynamic>> out = [];
    for (final raw in notifications) {
      if (raw is! Map) continue;
      final map = Map<dynamic, dynamic>.from(raw);
      switch (_filter) {
        case 'unread':
          if (!_isRead(map)) out.add(map);
          break;
        case 'read':
          if (_isRead(map)) out.add(map);
          break;
        default:
          out.add(map);
      }
    }
    return out;
  }

  DateTime? _tryParseNotificationDate(Map<dynamic, dynamic> notif) {
    final dateStr = notif['created_at']?.toString() ??
        notif['date']?.toString() ??
        notif['time']?.toString() ??
        notif['timestamp']?.toString() ??
        notif['sent_at']?.toString() ??
        '';
    if (dateStr.trim().isEmpty) return null;
    var parsed = DateTime.tryParse(dateStr.trim());
    if (parsed != null) return parsed;
    final spaced = dateStr.trim();
    if (RegExp(r'^\d{4}-\d{2}-\d{2} \d').hasMatch(spaced)) {
      parsed = DateTime.tryParse(spaced.replaceFirst(' ', 'T'));
    }
    return parsed;
  }

  void _addToGroup(Map<String, List<Map<dynamic, dynamic>>> groups, String key, Map<dynamic, dynamic> item) {
    groups.putIfAbsent(key, () => []).add(item);
  }

  Map<String, List<Map<dynamic, dynamic>>> _groupByDate(List<Map<dynamic, dynamic>> items) {
    final groups = <String, List<Map<dynamic, dynamic>>>{};
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    for (final notif in items) {
      final date = _tryParseNotificationDate(notif);

      if (date == null) {
        _addToGroup(groups, 'أخرى', notif);
        continue;
      }

      final notifDay = DateTime(date.year, date.month, date.day);
      final diffHours = now.difference(date).inHours;
      final diffDays = today.difference(notifDay).inDays;

      String label;
      if (diffHours < 1) {
        label = 'الجديدة';
      } else if (notifDay == today) {
        label = 'اليوم';
      } else if (notifDay == yesterday) {
        label = 'أمس';
      } else if (diffDays >= 0 && diffDays < 7) {
        const days = ['الاثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة', 'السبت', 'الأحد'];
        label = days[date.weekday - 1];
      } else if (diffDays < 0) {
        label = 'أخرى';
      } else {
        label = '${date.day}/${date.month}/${date.year}';
      }

      _addToGroup(groups, label, notif);
    }

    return groups;
  }

  List<Object> _buildFlatEntries() {
    final filtered = _filteredNotifications();
    if (filtered.isEmpty) return [];

    final grouped = _groupByDate(filtered);
    const orderedKeys = ['الجديدة', 'اليوم', 'أمس'];
    final otherKeys = grouped.keys.where((k) => !orderedKeys.contains(k)).toList();
    final allKeys = <String>[
      ...orderedKeys.where((k) => grouped.containsKey(k)),
      ...otherKeys,
    ];

    final entries = <Object>[];
    for (final key in allKeys) {
      final items = grouped[key]!;
      if (items.isEmpty) continue;
      entries.add(_SectionHeaderEntry(key, items.length));
      for (final n in items) {
        entries.add(n);
      }
    }
    return entries;
  }

  Future<void> _deleteOneById(dynamic deletedId) async {
    await getDio().post(
      "https://daltalifts.com/app2026/sql.php?k=${DateTime.now().millisecondsSinceEpoch}",
      data: {"action": "delNotify", "id": deletedId},
    );
  }

  Color _getIconBg(String type) {
    switch (type) {
      case 'success':
        return const Color(0xFFEDFAF4);
      case 'warning':
        return const Color(0xFFFFF8ED);
      case 'info':
        return const Color(0xFFEEF4FF);
      case 'install':
        return const Color(0xFFF3EEFF);
      default:
        return const Color(0xFFFFF0E5);
    }
  }

  IconData _getIcon(String type) {
    switch (type) {
      case 'success':
        return Iconsax.tick_circle;
      case 'warning':
        return Iconsax.flash;
      case 'info':
        return Iconsax.clock;
      case 'install':
        return Iconsax.setting;
      default:
        return Iconsax.notification;
    }
  }

  Color _getIconColor(String type) {
    switch (type) {
      case 'success':
        return const Color(0xFF22C55E);
      case 'warning':
        return const Color(0xFFF59E0B);
      case 'info':
        return const Color(0xFF3B82F6);
      case 'install':
        return const Color(0xFF8B5CF6);
      default:
        return const Color(0xFFF37021);
    }
  }

  @override
  void initState() {
    super.initState();
    _loadReadIds().then((_) {
      if (mounted) getNotifications();
    });
    _refreshTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      getNotifications();
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Widget _filterTab(String label, String value) {
    final bool isActive = _filter == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _filter = value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: isActive ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: isActive ? _orange : Colors.white.withValues(alpha: 0.75),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOrangeHeader() {
    return Container(
      width: double.infinity,
      color: _orange,
      padding: EdgeInsets.only(
        top: MediaQuery.paddingOf(context).top + 8,
        bottom: 16,
        left: 16,
        right: 16,
      ),
      child: Column(
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: _deleteAll,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.20),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.30)),
                  ),
                  child: const Icon(
                    Iconsax.trash,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
              const Expanded(
                child: Text(
                  'الإشعارات',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () => Navigator.maybePop(context),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.20),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.30)),
                  ),
                  child: const Icon(
                    Iconsax.arrow_left_3,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
            ),
            child: Row(
              children: [
                _filterTab('الكل', 'all'),
                _filterTab('غير مقروء', 'unread'),
                _filterTab('مقروء', 'read'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyAllNotifications() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: const BoxDecoration(
              color: Color(0xFFFFF0E5),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Iconsax.notification,
              color: _orange,
              size: 40,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'لا يوجد إشعارات بعد',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: _textDark,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'ستظهر إشعاراتك هنا عند وصولها',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, int count) {
    final isNewSection = title == 'الجديدة';
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 4, right: 4, left: 4),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: isNewSection ? _orange : const Color(0xFFEEEEEE),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$count',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: isNewSection ? Colors.white : Colors.grey.shade700,
              ),
            ),
          ),
          const SizedBox(width: 6),
          const Expanded(
            child: Divider(color: Color(0xFFEEEEEE), height: 1),
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: isNewSection ? _orange : const Color(0xFF888888),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotifList() {
    if (notifications.isEmpty) {
      return _buildEmptyAllNotifications();
    }

    final entries = _buildFlatEntries();
    if (entries.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            _filter == 'read' ? 'لا توجد إشعارات مقروءة' : 'لا توجد إشعارات غير مقروءة',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF888888),
            ),
          ),
        ),
      );
    }

    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return ListView.builder(
      padding: EdgeInsets.fromLTRB(12, 16, 12, 20 + bottomInset),
      itemCount: entries.length,
      itemBuilder: (context, index) {
        final item = entries[index];
        if (item is _SectionHeaderEntry) {
          return _buildSectionHeader(item.title, item.count);
        }
        final n = item as Map<dynamic, dynamic>;
        final isUnread = !_isRead(n);
        final id = n['id'];
        final idStr = id?.toString() ?? '';
        return Dismissible(
          key: Key('notif_${idStr}_$index'),
          direction: DismissDirection.startToEnd,
          background: Container(
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFFF4B4B),
              borderRadius: BorderRadius.circular(16),
            ),
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Iconsax.trash, color: Colors.white, size: 24),
                SizedBox(height: 4),
                Text(
                  'حذف',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          onDismissed: (_) async {
            HapticFeedback.mediumImpact();
            final deletedId = id;
            setState(() {
              if (idStr.isNotEmpty) {
                _readIds.remove(idStr);
              }
              notifications.removeWhere((e) {
                if (e is! Map) return false;
                return e['id'].toString() == deletedId.toString();
              });
            });
            final prefs = await SharedPreferences.getInstance();
            await prefs.setStringList('read_notification_ids', _readIds.toList());
            await _deleteOneById(deletedId);
          },
          child: GestureDetector(
            behavior: HitTestBehavior.deferToChild,
            onTap: () => _openNotification(n, idStr),
            child: _NotifCard(
              title: n['title']?.toString() ?? '',
              body: n['content']?.toString() ?? '',
              timeAgo: _timeAgo(n),
              type: _typeStr(n),
              isUnread: isUnread,
              getIconBg: _getIconBg,
              getIcon: _getIcon,
              getIconColor: _getIconColor,
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _orange,
        body: Column(
          children: [
            _buildOrangeHeader(),
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: _bodyBg,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(28),
                    topRight: Radius.circular(28),
                  ),
                ),
                clipBehavior: Clip.hardEdge,
                child: _buildNotifList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeaderEntry {
  const _SectionHeaderEntry(this.title, this.count);
  final String title;
  final int count;
}

class _NotifCard extends StatelessWidget {
  const _NotifCard({
    required this.title,
    required this.body,
    required this.timeAgo,
    required this.type,
    required this.isUnread,
    required this.getIconBg,
    required this.getIcon,
    required this.getIconColor,
  });

  final String title;
  final String body;
  final String timeAgo;
  final String type;
  final bool isUnread;
  final Color Function(String type) getIconBg;
  final IconData Function(String type) getIcon;
  final Color Function(String type) getIconColor;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isUnread ? const Color(0xFFFFFAF7) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isUnread ? const Color(0xFFFFD9BB) : const Color(0xFFEBEBEB),
        ),
      ),
      child: Stack(
        children: [
          if (isUnread)
            Positioned(
              right: 0,
              top: 0,
              bottom: 0,
              child: Container(
                width: 4,
                decoration: const BoxDecoration(
                  color: Color(0xFFF37021),
                  borderRadius: BorderRadius.only(
                    topRight: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                  ),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                if (isUnread)
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFFF37021),
                    ),
                  )
                else
                  const SizedBox(width: 8),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1A1A2E),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        body,
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF888888),
                          height: 1.45,
                        ),
                      ),
                      if (timeAgo.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          timeAgo,
                          style: const TextStyle(
                            fontSize: 10,
                            color: Color(0xFFCCCCCC),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: getIconBg(type),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Icon(
                    getIcon(type),
                    color: getIconColor(type),
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
