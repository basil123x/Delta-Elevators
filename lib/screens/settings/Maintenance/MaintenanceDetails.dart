import 'dart:async';

import 'package:Delta/screens/repair/requests/media_preview_gallery.dart';
import 'package:Delta/screens/settings/About/contact_menu.dart';
import 'package:Delta/services/DioServiceCert.dart';
import 'package:Delta/services/OneSignalServices.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iconsax/iconsax.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

// ─── Model ────────────────────────────────────────────────────────────────────
class MaintenanceRequest {
  final int id;
  final String type;
  final String elevatorType;
  final String location;
  final String address;
  final String contractNumber;
  final String description;
  final DateTime date;
  final String status; // 'pending' | 'assigned' | 'in_progress' | 'done'
  final TechnicianInfo? technician;
  final List<TimelineEvent> timeline;

  const MaintenanceRequest({
    required this.id,
    required this.type,
    required this.elevatorType,
    required this.location,
    required this.address,
    required this.contractNumber,
    required this.description,
    required this.date,
    required this.status,
    this.technician,
    required this.timeline,
  });
}

class TechnicianInfo {
  final String name;
  final String role;
  final String initials;
  final String phone;

  const TechnicianInfo({
    required this.name,
    required this.role,
    required this.initials,
    required this.phone,
  });
}

class TimelineEvent {
  final String title;
  final String? time;
  final TimelineStatus status;

  const TimelineEvent({required this.title, this.time, required this.status});
}

enum TimelineStatus { done, active, pending }

// ─── Colors (Light Theme) ─────────────────────────────────────────────────────
class AppColors {
  static const background = Color(0xFFF5F5F7);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceHigher = Color(0xFFF0F0F3);
  static const orangePrimary = Color(0xFFF97316);
  static const orangeDark = Color(0xFFE8520A);
  static const textPrimary = Color(0xFF1A1A1A);
  static const textSecondary = Color(0xFF888888);
  static const textHint = Color(0xFFBBBBBB);
  static const green = Color(0xFF16A34A);
  static const greenBg = Color(0xFFDCFCE7);
  static const greenBorder = Color(0xFFBBF7D0);
  static const border = Color(0xFFE8E8EC);
}

// ─── Screen ───────────────────────────────────────────────────────────────────
class MaintenanceDetailScreen extends StatefulWidget {
  final String maintenanceId;
  const MaintenanceDetailScreen({super.key, required this.maintenanceId});

  @override
  State<MaintenanceDetailScreen> createState() =>
      _MaintenanceDetailScreenState();
}

class _MaintenanceDetailScreenState extends State<MaintenanceDetailScreen> {
  List mainList = [];
  bool _isAdmin = false;
  bool _busy = false;
  List<String> _images = [];
  List<Map<String, dynamic>> _techs = [];
  String? _selectedHrId;
  bool _techsLoading = false;
  Timer? _liveTimer;
  String _lastHrName = '';
  bool _readyForLiveUpdates = false;

  Map get _row => mainList.isEmpty ? {} : mainList[0];

  String get _stx => _row['stx']?.toString() ?? '0';
  bool get _isDone => _stx == '2' || _stx == '9';
  bool get _isNew => _stx == '' || _stx == '0';

  Future getMaintenanceDetails() async {
    try {
      var request = await getDio().post(
        "https://daltalifts.com/app2026/sql.php?k=${DateTime.now().millisecondsSinceEpoch}",
        data: {
          "action": "getMaintenanceDetails",
          "maintenanceId": widget.maintenanceId,
        },
      );
      if (!mounted) return;
      final data = request.data['data'];
      final rows = data is List ? data : [];
      final nextRow = rows.isEmpty ? {} : rows[0];
      final assignedName = nextRow['hr_name']?.toString().trim() ?? '';
      final prevName = _lastHrName;
      setState(() {
        mainList = rows;
        _lastHrName = assignedName;
        final current = nextRow['a7']?.toString();
        if (current != null && current.isNotEmpty && current != '0') {
          _selectedHrId = current;
        }
      });
      if (_readyForLiveUpdates &&
          !_isAdmin &&
          prevName.isEmpty &&
          assignedName.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تم تعيين الفني $assignedName لمتابعة طلبك'),
            backgroundColor: AppColors.green,
          ),
        );
      }
      if (_images.isEmpty) _loadImages();
    } catch (e) {
      debugPrint('Maintenance details error: $e');
    }
  }

  Future<void> _loadImages() async {
    if (mainList.isEmpty) return;
    try {
      final result = await getDio().post(
        "https://daltalifts.com/app2026/sql.php?k=${DateTime.now().millisecondsSinceEpoch}",
        data: {
          "action": "getMaintenanceImages",
          "maintenance_id": widget.maintenanceId,
          "user_id": _row['a6']?.toString() ?? '',
          "type": _row['a5']?.toString() ?? 'Normal',
        },
      );
      final raw = result.data['images'];
      if (!mounted) return;
      setState(() {
        _images = raw is List
            ? raw.map((e) => e.toString()).where((e) => e.isNotEmpty).toList()
            : [];
      });
    } catch (_) {}
  }

  @override
  void initState() {
    super.initState();
    _loadAdmin();
    getMaintenanceDetails().then((_) {
      if (!mounted) return;
      _readyForLiveUpdates = true;
      _liveTimer = Timer.periodic(const Duration(seconds: 5), (_) {
        getMaintenanceDetails();
      });
    });
  }

  @override
  void dispose() {
    _liveTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadAdmin() async {
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getBool('is_app_manager') ?? false;
    if (!mounted) return;
    setState(() => _isAdmin = cached);
    if (cached) _loadTechnicians();
  }

  Future<void> _loadTechnicians() async {
    setState(() => _techsLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final uid = prefs.getString('userId') ?? '';
      final result = await getDio().post(
        "https://daltalifts.com/app2026/sql.php?k=${DateTime.now().millisecondsSinceEpoch}",
        data: {"action": "getHrTechnicians", "uid": uid},
      );
      final raw = result.data['data'];
      final list = <Map<String, dynamic>>[];
      if (raw is List) {
        for (final t in raw) {
          if (t is! Map) continue;
          final name = t['a1']?.toString().trim() ?? '';
          if (name.isEmpty) continue;
          list.add(Map<String, dynamic>.from(t));
        }
      }
      if (!mounted) return;
      setState(() {
        _techs = list;
        final current = _row['a7']?.toString();
        if (current != null &&
            current.isNotEmpty &&
            current != '0' &&
            list.any((t) => t['id'].toString() == current)) {
          _selectedHrId = current;
        }
      });
    } catch (_) {
    } finally {
      if (mounted) setState(() => _techsLoading = false);
    }
  }

  Future<void> _setStatus(String stx) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final uid = prefs.getString('userId') ?? '';
      final result = await getDio().post(
        "https://daltalifts.com/app2026/sql.php?k=${DateTime.now().millisecondsSinceEpoch}",
        data: {
          "action": "updateMaintenanceStatus",
          "uid": uid,
          "maintenanceId": widget.maintenanceId,
          "stx": stx,
        },
      );
      final ok = result.data['success'] == true ||
          result.data['success'] == 1 ||
          result.data['success'] == 'true';
      if (!mounted) return;
      if (!ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.data['message']?.toString() ?? 'فشل التحديث'),
          ),
        );
        return;
      }
      await getMaintenanceDetails();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            stx == '2' ? 'تم إكمال طلب الصيانة' : 'تم بدء تنفيذ الصيانة',
          ),
          backgroundColor: AppColors.green,
        ),
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('حدث خطأ أثناء تحديث الحالة')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _assignTech(String hrId) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final uid = prefs.getString('userId') ?? '';
      final result = await getDio().post(
        "https://daltalifts.com/app2026/sql.php?k=${DateTime.now().millisecondsSinceEpoch}",
        data: {
          "action": "assignMaintenanceTech",
          "uid": uid,
          "maintenanceId": widget.maintenanceId,
          "hrId": hrId,
        },
      );
      final ok = result.data['success'] == true ||
          result.data['success'] == 1 ||
          result.data['success'] == 'true';
      if (!mounted) return;
      if (!ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.data['message']?.toString() ?? 'فشل التعيين'),
          ),
        );
        return;
      }
      await getMaintenanceDetails();
      if (!mounted) return;
      setState(() => _selectedHrId = hrId);
      try {
        final payload = result.data['data'];
        final pushAttempted = payload is Map &&
            (payload['pushAttempted'] == 1 ||
                payload['pushAttempted'] == true ||
                payload['pushAttempted'] == '1');
        if (!pushAttempted) {
          final players = payload is Map ? payload['playerIds'] : null;
          final customerUid = payload is Map
              ? (payload['customerUid']?.toString() ?? '')
              : '';
          final title = payload is Map
              ? (payload['title']?.toString() ?? 'تعيين فني الصيانة')
              : 'تعيين فني الصيانة';
          final body = payload is Map
              ? (payload['content']?.toString() ??
                  'تم تعيين فني لمتابعة طلب الصيانة')
              : 'تم تعيين فني لمتابعة طلب الصيانة';
          final extra = {
            'headings': {'en': title, 'ar': title},
            'contents': {'en': body, 'ar': body},
            'data': {
              'type': 'maintenance_tech',
              'maintenanceId': widget.maintenanceId,
            },
          };
          var sent = false;
          if (players is List) {
            for (final p in players) {
              final id = p?.toString() ?? '';
              if (id.isEmpty) continue;
              sent = true;
              await OneSignalNotification.sendToUser(
                subscriptionId: id,
                title: title,
                message: body,
                extra: extra,
              );
            }
          }
          if (!sent && customerUid.isNotEmpty) {
            await OneSignalNotification.sendToExternalId(
              externalUserId: customerUid,
              title: title,
              message: body,
              extra: extra,
            );
          }
        }
      } catch (e) {
        debugPrint('Maintenance tech push backup error: $e');
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم تعيين الفني وإشعار العميل'),
          backgroundColor: AppColors.green,
        ),
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('حدث خطأ أثناء تعيين الفني')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _confirmAssignSelected() async {
    final hrId = _selectedHrId;
    if (hrId == null || hrId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('اختر الفني أولاً من القائمة')),
      );
      return;
    }
    await _assignTech(hrId);
  }

  void _openMediaPreview(int index) {
    if (_images.isEmpty) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MaintenanceMediaPreviewGallery(
          paths: _images,
          initialIndex: index,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.dark,
        child: mainList.isEmpty
            ? Scaffold(backgroundColor: AppColors.background)
            : Scaffold(
                backgroundColor: AppColors.background,
                body: Column(
                  children: [
                    _buildHeader(context),
                    Expanded(
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildHeroCard(),
                            _buildSection('معلومات الطلب', _buildInfoCard()),
                            _buildSection('وصف المشكلة', _buildDescCard()),
                            if (_images.isNotEmpty)
                              _buildSection('وسائط العطل', _buildImages()),
                            _buildSection('الفني المسؤول', _buildTechCard()),
                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
                    ),
                    if (_isAdmin) _buildAdminBar(),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildImages() {
    return SizedBox(
      height: 110,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _images.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, i) {
          return MaintenanceNetworkMediaThumb(
            url: _images[i],
            onTap: () => _openMediaPreview(i),
          );
        },
      ),
    );
  }

  Widget _buildAdminBar() {
    final clientPhone = _row['client_phone']?.toString() ?? '';
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _busy ? null : _confirmAssignSelected,
                    icon: const Icon(Iconsax.user_add, size: 16),
                    label: Text(
                      (_row['hr_name']?.toString().isNotEmpty ?? false)
                          ? 'تأكيد تعيين الفني'
                          : 'تعيين فني',
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.orangePrimary,
                      side: const BorderSide(color: Color(0xFFFFE0C2)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                if (clientPhone.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: () => UrlHelper.openPhone(clientPhone),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.orangePrimary,
                      side: const BorderSide(color: Color(0xFFFFE0C2)),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                    ),
                    child: const Icon(Iconsax.call, size: 18),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 8),
            if (_isDone)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.greenBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: const Text(
                  'الطلب مكتمل',
                  style: TextStyle(
                    color: AppColors.green,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              )
            else
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _busy
                      ? null
                      : () => _setStatus(_isNew ? '1' : '2'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.orangePrimary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _busy
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          _isNew ? 'بدء التنفيذ' : 'إكمال الطلب',
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ── Header ─────────────────────────────────────────────────────────────────
  Widget _buildHeader(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            _iconButton(
              onTap: () => Navigator.pop(context),
              child: const Icon(
                Iconsax.arrow_right_3,
                size: 17,
                color: AppColors.orangePrimary,
              ),
            ),
            const Expanded(
              child: Text(
                'تفاصيل الطلب',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Opacity(
              opacity: 0,
              child: _iconButton(
                onTap: () {},
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    3,
                    (_) => Container(
                      width: 4,
                      height: 4,
                      margin: const EdgeInsets.symmetric(vertical: 1.5),
                      decoration: const BoxDecoration(
                        color: AppColors.textSecondary,
                        shape: BoxShape.circle,
                      ),
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

  Widget _iconButton({required VoidCallback onTap, required Widget child}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: child,
      ),
    );
  }

  // ── Hero Card ──────────────────────────────────────────────────────────────
  Widget _buildHeroCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.orangeDark, AppColors.orangePrimary],
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: AppColors.orangePrimary.withOpacity(0.35),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              top: -30,
              left: -30,
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Positioned(
              bottom: -40,
              right: -20,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Positioned(top: 20, left: 20, child: _statusPill()),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.25),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'طلب صيانة',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'طلب رقم # ${mainList[0]['id']?.toString() ?? ''}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    (mainList[0]['a5']?.toString() ?? '') == 'Urgent'
                        ? "صيانة عاجلة"
                        : "صيانة عادية",
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.85),
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _metaChip(
                        icon: Iconsax.calendar,
                        label: 'التاريخ',
                        value: mainList[0]['a3']?.toString() ?? '',
                      ),
                      const SizedBox(width: 8),
                      _metaChip(
                        icon: Iconsax.clock,
                        label: 'الوقت',
                        value: mainList[0]['a4']?.toString() ?? '',
                      ),
                      const SizedBox(width: 8),
                      _metaChip(
                        icon: Iconsax.location,
                        label: 'الموقع',
                        value:
                            "مبنى رقم ${mainList[0]['building']?.toString() ?? ''}",
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusPill() {
    final colors = {
      'in_progress': [AppColors.orangePrimary, 'قيد التنفيذ'],
      'done': [AppColors.green, 'مكتمل'],
      'pending': [const Color(0xFF3B82F6), 'جديد'],
    };
    final key = _isDone ? 'done' : (_isNew ? 'pending' : 'in_progress');
    final data = colors[key] ?? [AppColors.green, 'غير معروف'];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: data[0] as Color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            data[1] as String,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _metaChip({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(icon, size: 14, color: Colors.white.withOpacity(0.9)),
            const SizedBox(width: 6),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.white.withOpacity(0.75),
                    ),
                  ),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Section Wrapper ────────────────────────────────────────────────────────
  Widget _buildSection(String title, Widget child) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w600,

              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  // ── Info Card ──────────────────────────────────────────────────────────────
  Widget _buildInfoCard() {
    final clientName = mainList[0]['client_name']?.toString() ?? '';
    final clientPhone = mainList[0]['client_phone']?.toString() ?? '';
    final rows = [
      if (clientName.isNotEmpty)
        (Iconsax.user, 'العميل', clientName, false),
      if (clientPhone.isNotEmpty)
        (Iconsax.call, 'الهاتف', clientPhone, false),
      (
        Iconsax.star,
        'نوع الصيانة',
        (mainList[0]['a5']?.toString() ?? '') == 'Urgent'
            ? "صيانة عاجلة"
            : "صيانة عادية",
        true,
      ),
      (
        Iconsax.location,
        'العنوان',
        "المدينة: ${mainList[0]['city']?.toString() ?? ''}, المنطقة: ${mainList[0]['zone']?.toString() ?? ''}, الشارع: ${mainList[0]['street']?.toString() ?? ''}",
        false,
      ),
      // (Iconsax.building, 'نوع المصعد',  "", false),
      (
        Iconsax.document_text,
        'رقم العقد',
        mainList[0]['contract_id']?.toString() ?? '',
        false,
      ),
    ];

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: rows.asMap().entries.map((entry) {
          final isLast = entry.key == rows.length - 1;
          final row = entry.value;
          return _infoRow(
            icon: row.$1,
            label: row.$2,
            value: row.$3,
            isOrange: row.$4,
            showDivider: !isLast,
          );
        }).toList(),
      ),
    );
  }

  Widget _infoRow({
    required IconData icon,
    required String label,
    required String value,
    bool isOrange = false,
    bool showDivider = true,
  }) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  value,
                  textAlign: TextAlign.start,
                  style: TextStyle(
                    color: isOrange
                        ? AppColors.orangePrimary
                        : AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    height: 1.45,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                ),
              ),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Icon(icon, size: 14, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
        if (showDivider)
          const Divider(height: 1, color: AppColors.border, thickness: 1),
      ],
    );
  }

  // ── Desc Card ──────────────────────────────────────────────────────────────
  Widget _buildDescCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Text(
        mainList[0]['a2']?.toString() ?? '',
        style: const TextStyle(
          color: Color(0xFF555555),
          fontSize: 13,
          height: 1.7,
        ),
        textAlign: TextAlign.right,
      ),
    );
  }

  // ── Tech Card ──────────────────────────────────────────────────────────────
  Widget _buildTechCard() {
    final assignedName = _row['hr_name']?.toString().trim() ?? '';
    final assignedPhone = _row['hr_phone']?.toString().trim() ?? '';
    final hasAssigned = assignedName.isNotEmpty;

    if (_isAdmin) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_techsLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 18),
                child: Center(
                  child: SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      color: AppColors.orangePrimary,
                    ),
                  ),
                ),
              )
            else
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.surfaceHigher,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFFFE0C2)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedHrId != null &&
                            _techs.any((t) => t['id'].toString() == _selectedHrId)
                        ? _selectedHrId
                        : null,
                    isExpanded: true,
                    itemHeight: 64,
                    hint: Text(
                      hasAssigned ? assignedName : 'اختر الفني المسؤول',
                      style: TextStyle(
                        color: hasAssigned
                            ? AppColors.textPrimary
                            : AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    icon: const Icon(
                      Iconsax.arrow_down_1,
                      size: 18,
                      color: AppColors.orangePrimary,
                    ),
                    borderRadius: BorderRadius.circular(14),
                    dropdownColor: Colors.white,
                    items: _techs.map((t) {
                      final id = t['id'].toString();
                      final name = t['a1']?.toString() ?? '';
                      final phone = t['a3']?.toString() ?? '';
                      return DropdownMenuItem<String>(
                        value: id,
                        child: Row(
                          children: [
                            Container(
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    AppColors.orangeDark,
                                    AppColors.orangePrimary,
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                _getInitials(name),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  if (phone.isNotEmpty)
                                    Text(
                                      phone,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: _busy
                        ? null
                        : (v) {
                            setState(() => _selectedHrId = v);
                          },
                    selectedItemBuilder: (context) {
                      return _techs.map((t) {
                        final name = t['a1']?.toString() ?? '';
                        final phone = t['a3']?.toString() ?? '';
                        return Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            phone.isEmpty ? name : '$name  •  $phone',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        );
                      }).toList();
                    },
                  ),
                ),
              ),
            if (_techs.isEmpty && !_techsLoading)
              const Padding(
                padding: EdgeInsets.only(top: 10),
                child: Text(
                  'لا يوجد فنيون مسجّلون في قاعدة البيانات حالياً',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ),
            if (hasAssigned) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  _techActionBtn(
                    icon: Iconsax.call,
                    onTap: assignedPhone.isEmpty
                        ? null
                        : () async {
                            final uri = Uri.parse('tel:$assignedPhone');
                            if (await canLaunchUrl(uri)) launchUrl(uri);
                          },
                  ),
                  const SizedBox(width: 8),
                  _techActionBtn(
                    icon: Iconsax.message,
                    onTap: assignedPhone.isEmpty
                        ? null
                        : () async {
                            final uri =
                                Uri.parse('https://wa.me/$assignedPhone');
                            if (await canLaunchUrl(uri)) {
                              launchUrl(
                                uri,
                                mode: LaunchMode.externalApplication,
                              );
                            }
                          },
                  ),
                  const Spacer(),
                  Text(
                    'المعيّن حالياً: $assignedName',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      );
    }

    if (!hasAssigned) {
      return Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border),
        ),
        child: const Center(
          child: Text(
            'لم يتم تعيين فني بعد',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Row(
            children: [
              _techActionBtn(
                icon: Iconsax.call,
                onTap: assignedPhone.isEmpty
                    ? null
                    : () async {
                        final uri = Uri.parse('tel:$assignedPhone');
                        if (await canLaunchUrl(uri)) launchUrl(uri);
                      },
              ),
              const SizedBox(width: 8),
              _techActionBtn(
                icon: Iconsax.message,
                onTap: assignedPhone.isEmpty
                    ? null
                    : () async {
                        final uri = Uri.parse('https://wa.me/$assignedPhone');
                        if (await canLaunchUrl(uri)) {
                          launchUrl(
                            uri,
                            mode: LaunchMode.externalApplication,
                          );
                        }
                      },
              ),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  assignedName,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (assignedPhone.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    assignedPhone,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 14),
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.orangeDark, AppColors.orangePrimary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: Text(
                _getInitials(assignedName),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getInitials(String? name) {
    if (name == null || name.isEmpty) return '?';
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}';
    return parts[0].isNotEmpty ? parts[0][0] : '?';
  }

  Widget _techActionBtn({required IconData icon, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: AppColors.surfaceHigher,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border, width: 1),
        ),
        child: Icon(icon, size: 16, color: AppColors.orangePrimary),
      ),
    );
  }

  // ── Timeline ───────────────────────────────────────────────────────────────
  // Widget _buildTimeline() {
  //   return Column(
  //     children: widget.request.timeline.asMap().entries.map((entry) {
  //       final isLast = entry.key == widget.request.timeline.length - 1;
  //       return _timelineItem(entry.value, isLast: isLast);
  //     }).toList(),
  //   );
  // }

  Widget _timelineItem(TimelineEvent event, {bool isLast = false}) {
    final isDone = event.status == TimelineStatus.done;
    final isActive = event.status == TimelineStatus.active;

    Color dotBg, dotBorder;
    Widget dotChild;

    if (isDone) {
      dotBg = AppColors.greenBg;
      dotBorder = AppColors.greenBorder;
      dotChild = const Icon(
        Iconsax.tick_circle,
        size: 16,
        color: AppColors.green,
      );
    } else if (isActive) {
      dotBg = const Color(0xFFFFF0E6);
      dotBorder = AppColors.orangePrimary;
      dotChild = Container(
        width: 10,
        height: 10,
        decoration: const BoxDecoration(
          color: AppColors.orangePrimary,
          shape: BoxShape.circle,
        ),
      );
    } else {
      dotBg = AppColors.surfaceHigher;
      dotBorder = AppColors.border;
      dotChild = Container(
        width: 10,
        height: 10,
        decoration: const BoxDecoration(
          color: Color(0xFFCCCCCC),
          shape: BoxShape.circle,
        ),
      );
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: dotBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: dotBorder, width: 1),
                ),
                child: Center(child: dotChild),
              ),
              if (!isLast)
                Expanded(child: Container(width: 2, color: AppColors.border)),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(top: 8, bottom: isLast ? 0 : 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    event.title,
                    style: TextStyle(
                      color: event.status == TimelineStatus.pending
                          ? AppColors.textHint
                          : AppColors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (event.time != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        event.time!,
                        style: const TextStyle(
                          color: AppColors.textHint,
                          fontSize: 11,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
