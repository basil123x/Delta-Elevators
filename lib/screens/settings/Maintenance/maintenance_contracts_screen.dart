import 'package:Delta/screens/repair/repair_first.dart';
import 'package:Delta/screens/repair/repair_theme.dart';
import 'package:Delta/screens/settings/Maintenance/maintenance_contract_preview_screen.dart';
import 'package:Delta/services/DioServiceCert.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Settings → عقود الصيانة: list contracts + expiry colors + new-contract CTA.
class MaintenanceContractsScreen extends StatefulWidget {
  const MaintenanceContractsScreen({super.key});

  @override
  State<MaintenanceContractsScreen> createState() =>
      _MaintenanceContractsScreenState();
}

class _MaintenanceContractsScreenState
    extends State<MaintenanceContractsScreen> {
  static const _endpoint = 'https://daltalifts.com/app2026/sql.php';

  bool _loading = true;
  bool _canCreateNew = false;
  List<Map<String, dynamic>> _contracts = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final uid = prefs.getString('userId') ?? '';
      final res = await getDio().post(
        '$_endpoint?k=${DateTime.now().millisecondsSinceEpoch}',
        data: {'action': 'getMyMaintenanceContracts', 'uid': uid},
      );
      final data = res.data;
      final payload = (data is Map) ? data['data'] : null;
      final list = (payload is Map && payload['contracts'] is List)
          ? (payload['contracts'] as List)
          : <dynamic>[];
      final canCreate = payload is Map &&
          (payload['can_create_new']?.toString() == '1' ||
              payload['can_create_new'] == 1 ||
              payload['can_create_new'] == true);

      if (!mounted) return;
      setState(() {
        _contracts = list
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
        _canCreateNew = canCreate || _contracts.isEmpty;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _contracts = [];
        _canCreateNew = true;
      });
    }
  }

  Future<void> _onCreateNew() async {
    if (!_canCreateNew) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'لا يمكن عمل عقد جديد قبل انتهاء العقد الحالي',
            style: RepairTheme.cairo(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          backgroundColor: const Color(0xFF6B7280),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const RepairFirst()),
    );
    if (mounted) _load();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF4F5F8),
        body: Column(
          children: [
            RepairTheme.orangeHeader(
              context: context,
              title: 'عقود الصيانة',
            ),
            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: RepairTheme.orange,
                      ),
                    )
                  : RefreshIndicator(
                      color: RepairTheme.orange,
                      onRefresh: _load,
                      child: _contracts.isEmpty
                          ? ListView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.fromLTRB(20, 40, 20, 20),
                              children: [
                                const SizedBox(height: 40),
                                Center(
                                  child: Container(
                                    width: 88,
                                    height: 88,
                                    decoration: BoxDecoration(
                                      color: RepairTheme.orange.withOpacity(0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Iconsax.document_text,
                                      color: RepairTheme.orange,
                                      size: 40,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 20),
                                Text(
                                  'لا توجد عقود صيانة بعد',
                                  textAlign: TextAlign.center,
                                  style: RepairTheme.cairo(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'ابدأ بعقد صيانة جديد من الزر بالأسفل',
                                  textAlign: TextAlign.center,
                                  style: RepairTheme.cairo(
                                    fontSize: 14,
                                    color: RepairTheme.textSecondary,
                                  ),
                                ),
                              ],
                            )
                          : ListView.separated(
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                              itemCount: _contracts.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 12),
                              itemBuilder: (context, i) => _ContractCard(
                                contract: _contracts[i],
                                onTap: () {
                                  final c = _contracts[i];
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          MaintenanceContractPreviewScreen(
                                        contractId: c['id']?.toString() ?? '',
                                        bookingId:
                                            c['booking_id']?.toString() ?? '',
                                        title:
                                            'عقد صيانة #${c['id'] ?? ''}',
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                    ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: _CreateContractButton(
                  enabled: _canCreateNew,
                  onTap: _onCreateNew,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CreateContractButton extends StatelessWidget {
  const _CreateContractButton({
    required this.enabled,
    required this.onTap,
  });

  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : 0.55,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Ink(
            height: 58,
            decoration: BoxDecoration(
              gradient: enabled
                  ? RepairTheme.primaryGradient
                  : const LinearGradient(
                      colors: [Color(0xFF9CA3AF), Color(0xFF6B7280)],
                    ),
              borderRadius: BorderRadius.circular(18),
              boxShadow: enabled
                  ? const [
                      BoxShadow(
                        color: Color(0x33F37021),
                        blurRadius: 18,
                        offset: Offset(0, 8),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  enabled ? Iconsax.document_upload : Iconsax.lock_1,
                  color: Colors.white,
                  size: 22,
                ),
                const SizedBox(width: 10),
                Text(
                  enabled
                      ? 'عمل عقد صيانة جديد'
                      : 'عقد صيانة جديد (مقفل حتى انتهاء العقد)',
                  style: RepairTheme.cairo(
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
    );
  }
}

class _ContractCard extends StatelessWidget {
  const _ContractCard({
    required this.contract,
    required this.onTap,
  });

  final Map<String, dynamic> contract;
  final VoidCallback onTap;

  _ExpiryStyle get _style {
    final status = contract['status']?.toString() ?? 'active';
    switch (status) {
      case 'expired':
        return const _ExpiryStyle(
          accent: Color(0xFFDC2626),
          soft: Color(0xFFFEF2F2),
          border: Color(0xFFFECACA),
          label: 'منتهي',
          icon: Iconsax.close_circle,
        );
      case 'expiring_soon':
        return const _ExpiryStyle(
          accent: Color(0xFFD97706),
          soft: Color(0xFFFFFBEB),
          border: Color(0xFFFDE68A),
          label: 'قارب على الانتهاء',
          icon: Iconsax.warning_2,
        );
      default:
        return const _ExpiryStyle(
          accent: Color(0xFFF37021),
          soft: Color(0xFFFFF7F2),
          border: Color(0xFFFFE0CC),
          label: 'ساري',
          icon: Iconsax.tick_circle,
        );
    }
  }

  String _fmt(String? raw) {
    if (raw == null || raw.trim().isEmpty) return '—';
    return raw.trim();
  }

  @override
  Widget build(BuildContext context) {
    final style = _style;
    final id = contract['id']?.toString() ?? '';
    final name = contract['customer_name']?.toString() ?? '';
    final address = contract['address']?.toString() ?? '';
    final start = _fmt(contract['start_date']?.toString());
    final end = _fmt(contract['end_date']?.toString());
    final daysLeft = contract['days_left'];
    String daysText = '';
    if (daysLeft is int) {
      if (daysLeft < 0) {
        daysText = 'انتهى منذ ${-daysLeft} يوم';
      } else if (daysLeft == 0) {
        daysText = 'ينتهي اليوم';
      } else {
        daysText = 'متبقي $daysLeft يوم';
      }
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: style.border, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: style.accent.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  style.soft,
                  Colors.white,
                ],
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
              ),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(22),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: style.accent.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(Iconsax.document_text, color: style.accent),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'عقد صيانة #$id',
                        style: RepairTheme.cairo(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      if (name.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          name,
                          style: RepairTheme.cairo(
                            fontSize: 13,
                            color: RepairTheme.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: style.accent.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(style.icon, size: 14, color: style.accent),
                      const SizedBox(width: 4),
                      Text(
                        style.label,
                        style: RepairTheme.cairo(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: style.accent,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
            child: Column(
              children: [
                if (address.trim().isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Iconsax.location,
                          size: 16, color: Colors.grey.shade500),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          address,
                          style: RepairTheme.cairo(
                            fontSize: 13,
                            color: RepairTheme.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: _DateChip(
                        title: 'بداية العقد',
                        value: start,
                        color: style.accent,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _DateChip(
                        title: 'تاريخ الانتهاء',
                        value: end,
                        color: style.accent,
                        emphasize: true,
                      ),
                    ),
                  ],
                ),
                if (daysText.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      daysText,
                      style: RepairTheme.cairo(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: style.accent,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      Iconsax.document_download,
                      size: 16,
                      color: style.accent,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'اضغط لعرض العقد الموقّع',
                      style: RepairTheme.cairo(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: style.accent,
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      Iconsax.arrow_left_2,
                      size: 16,
                      color: style.accent,
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
    );
  }
}

class _DateChip extends StatelessWidget {
  const _DateChip({
    required this.title,
    required this.value,
    required this.color,
    this.emphasize = false,
  });

  final String title;
  final String value;
  final Color color;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: emphasize ? color.withOpacity(0.08) : const Color(0xFFF8F9FB),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: emphasize ? color.withOpacity(0.25) : const Color(0xFFEEEEF2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: RepairTheme.cairo(
              fontSize: 11,
              color: RepairTheme.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: RepairTheme.cairo(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: emphasize ? color : RepairTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _ExpiryStyle {
  const _ExpiryStyle({
    required this.accent,
    required this.soft,
    required this.border,
    required this.label,
    required this.icon,
  });

  final Color accent;
  final Color soft;
  final Color border;
  final String label;
  final IconData icon;
}
