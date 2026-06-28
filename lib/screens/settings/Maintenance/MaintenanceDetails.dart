import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iconsax/iconsax.dart';
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

  Future getMaintenanceDetails() async {
    var request = await Dio().post(
      "https://daltalifts.com/app2026/sql.php?k=${DateTime.now().millisecondsSinceEpoch}",
      data: {
        "action": "getMaintenanceDetails",
        "maintenanceId": widget.maintenanceId,
      },
    );
    setState(() {
      mainList = request.data['data'];
    });
  }

  @override
  void initState() {
    super.initState();
    getMaintenanceDetails();
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
                            _buildSection('الفني المسؤول', _buildTechCard()),
                            // _buildSection('مراحل الطلب', _buildTimeline()),
                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
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
      'in_progress': [AppColors.green, 'قيد التنفيذ'],
      'done': [AppColors.green, 'مكتمل'],
      'pending': [AppColors.orangePrimary, 'قيد الانتظار'],
      'assigned': [Colors.blue, 'تم التعيين'],
    };
    final data = colors["in_progress"] ?? [AppColors.green, 'غير معروف'];

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
    final rows = [
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
            children: [
              Flexible(
                child: Text(
                  value,
                  style: TextStyle(
                    color: isOrange
                        ? AppColors.orangePrimary
                        : AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
              ),
              const Spacer(),
              Row(
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(icon, size: 14, color: AppColors.textSecondary),
                ],
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
    if (mainList[0]['hr_name'] == null) {
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

    final tech = "";
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
                onTap: () async {
                  final phone = mainList[0]['hr_phone']?.toString() ?? '';
                  final uri = Uri.parse('tel:$phone');
                  if (await canLaunchUrl(uri)) launchUrl(uri);
                },
              ),
              const SizedBox(width: 8),
              _techActionBtn(
                icon: Iconsax.message,
                onTap: () async {
                  final phone = mainList[0]['hr_phone']?.toString() ?? '';
                  final uri = Uri.parse('https://wa.me/$phone');
                  if (await canLaunchUrl(uri)) {
                    launchUrl(uri, mode: LaunchMode.externalApplication);
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
                  mainList[0]['hr_name']?.toString() ?? '',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  mainList[0]['hr_phone']?.toString() ?? '',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
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
                _getInitials(mainList[0]['hr_name']?.toString()),
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
