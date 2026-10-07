import 'dart:async';

import 'package:Delta/screens/repair/repair_theme.dart';
import 'package:Delta/services/DioServiceCert.dart';
import 'package:Delta/services/LocationService.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:iconsax/iconsax.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

class _WorkJob {
  final String id;
  final String kind; // elevator | maintenance
  final String clientName;
  final String address;
  final String subtitle;
  double? lat;
  double? lng;
  double? distanceMeters;

  _WorkJob({
    required this.id,
    required this.kind,
    required this.clientName,
    required this.address,
    required this.subtitle,
    this.lat,
    this.lng,
  });

  String get key => '$kind-$id';

  String get title {
    if (clientName.isNotEmpty) return clientName;
    return kind == 'elevator' ? 'مشروع مصعد #$id' : 'طلب صيانة #$id';
  }
}

/// Work zone: pick nearest elevator/maintenance job, live distance, Maps.
class AdminWorkZoneScreen extends StatefulWidget {
  const AdminWorkZoneScreen({super.key});

  @override
  State<AdminWorkZoneScreen> createState() => _AdminWorkZoneScreenState();
}

class _AdminWorkZoneScreenState extends State<AdminWorkZoneScreen> {
  final _locationService = LocationService();

  bool _loading = true;
  bool _loadingGps = true;
  bool _loadingJobs = false;
  String _jobTitle = '';
  String _branchName = '';
  String _branchAddress = '';
  String _assignedZone = '';

  String _currentAddress = '';
  double? _lat;
  double? _lng;
  String? _gpsError;

  /// 0 = مشاريع المصاعد, 1 = طلبات الصيانة
  int _kindTab = 1;
  List<_WorkJob> _jobs = [];
  String? _selectedKey;
  StreamSubscription<Position>? _gpsSub;

  _WorkJob? get _selected {
    if (_jobs.isEmpty) return null;
    final match = _jobs.where((j) => j.key == _selectedKey);
    return match.isEmpty ? _jobs.first : match.first;
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _gpsSub?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    await Future.wait([_loadZone(), _bootstrapLocation()]);
  }

  Future<void> _loadZone() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final uid = prefs.getString('userId') ?? '';
      final result = await getDio().post(
        'https://daltalifts.com/app2026/sql.php?k=${DateTime.now().millisecondsSinceEpoch}',
        data: {'action': 'getTechnicianWorkZone', 'uid': uid},
      );
      final data = result.data['data'];
      if (!mounted) return;
      if (data is Map) {
        setState(() {
          _jobTitle = data['job_title']?.toString() ?? '';
          _branchName = data['branch_name']?.toString() ?? '';
          _branchAddress = data['branch_address']?.toString() ?? '';
          _assignedZone = data['assigned_zone']?.toString() ?? '';
          _loading = false;
        });
      } else {
        setState(() => _loading = false);
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _bootstrapLocation() async {
    await _refreshGps(startStream: true);
  }

  Future<void> _refreshGps({bool startStream = false}) async {
    if (mounted) {
      setState(() {
        _loadingGps = true;
        _gpsError = null;
      });
    }
    try {
      final pos = await _locationService.getCurrentLocation();
      if (!mounted) return;
      if (pos == null) {
        setState(() {
          _gpsError = 'فعّل صلاحية الموقع لمعرفة مكانك الحالي';
          _loadingGps = false;
        });
        await _loadJobs();
        return;
      }
      await _applyPosition(pos, reverseGeocode: true);
      if (startStream) _listenLiveGps();
      await _loadJobs();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _gpsError = 'تعذر تحديد الموقع الحالي';
        _loadingGps = false;
      });
      await _loadJobs();
    }
  }

  Future<void> _applyPosition(Position pos, {bool reverseGeocode = false}) async {
    String address = _currentAddress;
    if (reverseGeocode || address.isEmpty) {
      address = _cleanAddress(
        await _locationService.getAddressFromCoordinates(
          pos.latitude,
          pos.longitude,
        ),
      );
    }
    if (!mounted) return;
    setState(() {
      _lat = pos.latitude;
      _lng = pos.longitude;
      _currentAddress = address;
      _loadingGps = false;
      _gpsError = null;
    });
    _recalcDistances();
  }

  void _listenLiveGps() {
    _gpsSub?.cancel();
    _gpsSub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5,
      ),
    ).listen((pos) {
      if (!mounted) return;
      setState(() {
        _lat = pos.latitude;
        _lng = pos.longitude;
      });
      _recalcDistances();
    });
  }

  Future<void> _setKindTab(int i) async {
    if (_kindTab == i) return;
    setState(() {
      _kindTab = i;
      _selectedKey = null;
      _jobs = [];
    });
    await _loadJobs();
  }

  Future<void> _loadJobs() async {
    if (mounted) setState(() => _loadingJobs = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final uid = prefs.getString('userId') ?? '';
      final jobs = _kindTab == 0
          ? await _fetchElevatorJobs(uid)
          : await _fetchMaintenanceJobs(uid);
      await _fillMissingCoords(jobs);
      _sortJobs(jobs);
      if (!mounted) return;
      setState(() {
        _jobs = jobs;
        if (_selectedKey == null ||
            jobs.every((j) => j.key != _selectedKey)) {
          _selectedKey = jobs.isEmpty ? null : jobs.first.key;
        }
        _loadingJobs = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingJobs = false);
    }
  }

  Future<List<_WorkJob>> _fetchElevatorJobs(String uid) async {
    final result = await getDio().post(
      'https://daltalifts.com/app2026/sql.php?k=${DateTime.now().millisecondsSinceEpoch}',
      data: {
        'action': 'getMyBookings',
        'uid': uid,
        'indexChanged': 1,
      },
    );
    final raw = result.data['data'];
    final list = raw is List ? List.from(raw) : <dynamic>[];
    final jobs = <_WorkJob>[];
    for (final row in list) {
      if (row is! Map) continue;
      final enter = row['enter']?.toString() ?? '';
      if (enter.contains('صيانة')) continue;
      final stl = row['stl']?.toString() ?? '';
      final stb = row['stb']?.toString() ?? '';
      if (stl == '9' || stb == '4') continue;
      final id = row['id']?.toString() ?? '';
      if (id.isEmpty) continue;
      final addr = _composeAddress(row);
      if (addr.isEmpty) continue;
      jobs.add(
        _WorkJob(
          id: id,
          kind: 'elevator',
          clientName: row['client_name']?.toString() ?? '',
          address: addr,
          subtitle: 'مشروع مصعد #$id',
          lat: _parseCoord(row['latitude']),
          lng: _parseCoord(row['longitude']),
        ),
      );
    }
    return jobs;
  }

  Future<List<_WorkJob>> _fetchMaintenanceJobs(String uid) async {
    final result = await getDio().post(
      'https://daltalifts.com/app2026/sql.php?k=${DateTime.now().millisecondsSinceEpoch}',
      data: {
        'action': 'getMaintenances',
        'uid': uid,
        'indexChanged': 0,
      },
    );
    final raw = result.data['data'];
    final list = raw is List ? List.from(raw) : <dynamic>[];
    final jobs = <_WorkJob>[];
    for (final row in list) {
      if (row is! Map) continue;
      final type = row['a5']?.toString() ?? '';
      if (type != 'Normal' && type != 'Urgent') continue;
      final stx = row['stx']?.toString() ?? '0';
      if (stx == '2' || stx == '9') continue;
      final id = row['id']?.toString() ?? '';
      if (id.isEmpty) continue;
      final addr = _composeAddress(row);
      if (addr.isEmpty) continue;
      final urgent = type == 'Urgent';
      jobs.add(
        _WorkJob(
          id: id,
          kind: 'maintenance',
          clientName: row['client_name']?.toString() ?? '',
          address: addr,
          subtitle: urgent ? 'صيانة عاجلة #$id' : 'طلب صيانة #$id',
          lat: _parseCoord(row['latitude']),
          lng: _parseCoord(row['longitude']),
        ),
      );
    }
    return jobs;
  }

  Future<void> _fillMissingCoords(List<_WorkJob> jobs) async {
    var filled = 0;
    for (final job in jobs) {
      if (job.lat != null && job.lng != null) continue;
      if (filled >= 12) break;
      try {
        final coords = await _locationService.getCoordinatesFromAddress(
          '${job.address}، قطر',
        );
        if (coords != null) {
          job.lat = coords.latitude;
          job.lng = coords.longitude;
          filled++;
        }
      } catch (_) {}
    }
  }

  void _recalcDistances() {
    if (_jobs.isEmpty) return;
    _sortJobs(_jobs);
    if (!mounted) return;
    setState(() {});
  }

  void _sortJobs(List<_WorkJob> jobs) {
    final lat = _lat;
    final lng = _lng;
    for (final job in jobs) {
      if (lat != null && lng != null && job.lat != null && job.lng != null) {
        job.distanceMeters = Geolocator.distanceBetween(
          lat,
          lng,
          job.lat!,
          job.lng!,
        );
      } else {
        job.distanceMeters = null;
      }
    }
    jobs.sort((a, b) {
      final da = a.distanceMeters;
      final db = b.distanceMeters;
      if (da == null && db == null) return 0;
      if (da == null) return 1;
      if (db == null) return -1;
      return da.compareTo(db);
    });
  }

  double? _parseCoord(dynamic raw) {
    final n = double.tryParse(raw?.toString() ?? '');
    if (n == null || n == 0) return null;
    return n;
  }

  String _composeAddress(Map row) {
    final parts = [
      row['building']?.toString() ?? '',
      row['street']?.toString() ?? '',
      row['zone']?.toString() ?? '',
      row['city']?.toString() ?? '',
    ].where((e) => e.trim().isNotEmpty).toList();
    return parts.join('، ');
  }

  String _cleanAddress(String raw) {
    return raw
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty && e.toLowerCase() != 'null')
        .join('، ');
  }

  String _distanceLabel(double? meters) {
    if (meters == null) return '';
    if (meters < 1000) return '${meters.round()} متر';
    if (meters < 10000) {
      return '${(meters / 1000).toStringAsFixed(2)} كم · ${meters.round()} متر';
    }
    return '${(meters / 1000).toStringAsFixed(1)} كم';
  }

  Future<void> _openGoogleMaps(_WorkJob job) async {
    final lat = job.lat;
    final lng = job.lng;
    final dest = (lat != null && lng != null)
        ? '$lat,$lng'
        : Uri.encodeComponent('${job.address}, Qatar');
    final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=$dest&travelmode=driving',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _pickJob() async {
    if (_jobs.isEmpty) return;
    final chosen = await showModalBottomSheet<_WorkJob>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 18),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE5E5EA),
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    _kindTab == 0
                        ? 'اختر مشروع المصعد الأقرب'
                        : 'اختر طلب الصيانة الأقرب',
                    style: RepairTheme.cairo(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(ctx).size.height * 0.55,
                    ),
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: _jobs.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (_, i) {
                        final job = _jobs[i];
                        final selected = job.key == _selectedKey;
                        final nearest = i == 0 && job.distanceMeters != null;
                        return InkWell(
                          onTap: () => Navigator.pop(ctx, job),
                          borderRadius: BorderRadius.circular(14),
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: selected
                                  ? const Color(0xFFFFF0E5)
                                  : RepairTheme.bg,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: selected
                                    ? RepairTheme.orange
                                    : RepairTheme.border,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  job.kind == 'elevator'
                                      ? Iconsax.building
                                      : Iconsax.setting_2,
                                  color: RepairTheme.orange,
                                  size: 20,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        job.title,
                                        style: RepairTheme.cairo(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                      Text(
                                        job.subtitle,
                                        style: RepairTheme.cairo(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: RepairTheme.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (nearest)
                                  Container(
                                    margin: const EdgeInsets.only(left: 8),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF16A34A),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      'الأقرب',
                                      style: RepairTheme.cairo(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                if (job.distanceMeters != null)
                                  Text(
                                    _distanceLabel(job.distanceMeters),
                                    style: RepairTheme.cairo(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                      color: RepairTheme.orange,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
    if (chosen == null || !mounted) return;
    setState(() => _selectedKey = chosen.key);
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: RepairTheme.bg,
        body: Column(
          children: [
            RepairTheme.orangeHeader(
              context: context,
              title: 'منطقة العمل',
            ),
            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: RepairTheme.orange,
                      ),
                    )
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(16, 18, 16, 28),
                      children: [
                        _currentLocationCard(),
                        const SizedBox(height: 12),
                        _kindTabs(),
                        const SizedBox(height: 12),
                        if (_loadingJobs)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 24),
                            child: Center(
                              child: CircularProgressIndicator(
                                color: RepairTheme.orange,
                              ),
                            ),
                          )
                        else if (_jobs.isEmpty)
                          _emptyJobsCard()
                        else ...[
                          _jobPickerCard(),
                          const SizedBox(height: 12),
                          _clientCompareCard(_selected!),
                        ],
                        const SizedBox(height: 12),
                        if (_assignedZone.trim().isNotEmpty)
                          _row('المنطقة المسندة', _assignedZone),
                        if (_jobTitle.isNotEmpty)
                          _row('المسمّى الوظيفي', _jobTitle),
                        if (_branchName.isNotEmpty)
                          _row('فرع الشركة', _branchName),
                        if (_branchAddress.isNotEmpty)
                          _row('عنوان الفرع', _branchAddress),
                        const SizedBox(height: 8),
                        Text(
                          'اختر أقرب مشروع أو طلب صيانة، حدّث موقعك، وافتح الخريطة للوصول للعميل.',
                          textAlign: TextAlign.center,
                          style: RepairTheme.cairo(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: RepairTheme.hint,
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _kindTabs() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: RepairTheme.cardDecoration(radius: 14),
      child: Row(
        children: [
          _kindChip(1, 'طلبات الصيانة', Iconsax.setting_2),
          _kindChip(0, 'مشاريع المصاعد', Iconsax.building),
        ],
      ),
    );
  }

  Widget _kindChip(int index, String label, IconData icon) {
    final active = _kindTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => _setKindTab(index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: active ? RepairTheme.orange : Colors.transparent,
            borderRadius: BorderRadius.circular(11),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: active ? Colors.white : RepairTheme.textSecondary,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: RepairTheme.cairo(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: active ? Colors.white : RepairTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _jobPickerCard() {
    final selected = _selected;
    return InkWell(
      onTap: _pickJob,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: RepairTheme.cardDecoration(radius: 18),
        child: Row(
          children: [
            const Icon(Iconsax.search_normal, color: RepairTheme.orange, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _kindTab == 0 ? 'مشروع المصعد' : 'طلب الصيانة',
                    style: RepairTheme.cairo(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: RepairTheme.textSecondary,
                    ),
                  ),
                  Text(
                    selected == null
                        ? 'اختر من القائمة حسب الأقرب لك'
                        : '${selected.title} · ${selected.subtitle}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: RepairTheme.cairo(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Iconsax.arrow_down_1, size: 18, color: RepairTheme.orange),
          ],
        ),
      ),
    );
  }

  Widget _emptyJobsCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: RepairTheme.cardDecoration(radius: 18),
      child: Text(
        _kindTab == 0
            ? 'لا توجد مشاريع مصاعد قيد التنفيذ حالياً'
            : 'لا توجد طلبات صيانة مفتوحة حالياً',
        textAlign: TextAlign.center,
        style: RepairTheme.cairo(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: RepairTheme.textSecondary,
        ),
      ),
    );
  }

  Widget _currentLocationCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: RepairTheme.cardDecoration(radius: 18),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF0E5),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Iconsax.location,
                  color: RepairTheme.orange,
                  size: 26,
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: _loadingGps ? null : () => _refreshGps(),
                icon: _loadingGps
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: RepairTheme.orange,
                        ),
                      )
                    : const Icon(Iconsax.refresh, color: RepairTheme.orange),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              'موقعك الحالي',
              style: RepairTheme.cairo(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: RepairTheme.textSecondary,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              _loadingGps
                  ? 'جاري تحديد موقعك...'
                  : (_gpsError ??
                      (_currentAddress.isNotEmpty
                          ? _currentAddress
                          : 'تعذر قراءة العنوان')),
              style: RepairTheme.cairo(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                height: 1.5,
              ),
            ),
          ),
          if (_lat != null && _lng != null) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                '${_lat!.toStringAsFixed(5)} ، ${_lng!.toStringAsFixed(5)}',
                style: RepairTheme.cairo(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: RepairTheme.hint,
                ),
              ),
            ),
          ],
          if (_gpsError != null) ...[
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => _locationService.openAppSettings(),
              child: Text(
                'فتح إعدادات الموقع',
                style: RepairTheme.cairo(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: RepairTheme.orange,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _clientCompareCard(_WorkJob job) {
    final dist = job.distanceMeters;
    String status;
    Color statusColor;
    Color statusBg;
    IconData statusIcon;
    if (dist == null) {
      status = 'قارن العنوان على الخريطة للتأكد من الموقع';
      statusColor = RepairTheme.textSecondary;
      statusBg = const Color(0xFFF4F4F6);
      statusIcon = Iconsax.info_circle;
    } else if (dist <= 80) {
      status = 'أنت في موقع العميل';
      statusColor = const Color(0xFF16A34A);
      statusBg = const Color(0xFFEDFAF4);
      statusIcon = Iconsax.tick_circle;
    } else if (dist <= 400) {
      status = 'قريب من موقع العميل';
      statusColor = const Color(0xFFF37021);
      statusBg = const Color(0xFFFFF0E5);
      statusIcon = Iconsax.location;
    } else {
      status = 'لست في موقع العميل بعد';
      statusColor = const Color(0xFFDC2626);
      statusBg = const Color(0xFFFEECEC);
      statusIcon = Iconsax.warning_2;
    }

    final distLabel = _distanceLabel(dist);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: RepairTheme.cardDecoration(radius: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF4FF),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  job.kind == 'elevator' ? Iconsax.building : Iconsax.house,
                  color: const Color(0xFF3B82F6),
                  size: 22,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      job.title,
                      style: RepairTheme.cairo(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      job.subtitle,
                      style: RepairTheme.cairo(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: RepairTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            job.address,
            style: RepairTheme.cairo(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: statusBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(statusIcon, color: statusColor, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    distLabel.isEmpty ? status : '$status · يبعد $distLabel',
                    style: RepairTheme.cairo(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (job.lat != null && job.lng != null) ...[
            const SizedBox(height: 12),
            _OsmMapPreview(
              lat: job.lat!,
              lng: job.lng!,
              onOpenMaps: () => _openGoogleMaps(job),
            ),
          ],
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _openGoogleMaps(job),
              icon: const Icon(Iconsax.map, size: 18),
              label: Text(
                'افتح الموقع على Google Maps',
                style: RepairTheme.cairo(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: RepairTheme.orange,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: RepairTheme.cardDecoration(radius: 14),
      child: Row(
        children: [
          Text(
            label,
            style: RepairTheme.cairo(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: RepairTheme.textSecondary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.left,
              style: RepairTheme.cairo(
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OsmMapPreview extends StatefulWidget {
  const _OsmMapPreview({
    required this.lat,
    required this.lng,
    required this.onOpenMaps,
  });

  final double lat;
  final double lng;
  final VoidCallback onOpenMaps;

  @override
  State<_OsmMapPreview> createState() => _OsmMapPreviewState();
}

class _OsmMapPreviewState extends State<_OsmMapPreview> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFFF2F3F7))
      ..loadRequest(Uri.parse(_embedUrl(widget.lat, widget.lng)));
  }

  @override
  void didUpdateWidget(covariant _OsmMapPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.lat != widget.lat || oldWidget.lng != widget.lng) {
      _controller.loadRequest(Uri.parse(_embedUrl(widget.lat, widget.lng)));
    }
  }

  String _embedUrl(double lat, double lng) {
    const padLng = 0.012;
    const padLat = 0.008;
    final minLng = lng - padLng;
    final minLat = lat - padLat;
    final maxLng = lng + padLng;
    final maxLat = lat + padLat;
    return 'https://www.openstreetmap.org/export/embed.html?bbox=$minLng%2C$minLat%2C$maxLng%2C$maxLat&layer=mapnik&marker=$lat%2C$lng';
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: SizedBox(
        height: 200,
        child: Stack(
          children: [
            WebViewWidget(
              controller: _controller,
              gestureRecognizers: const <Factory<OneSequenceGestureRecognizer>>{},
            ),
            Positioned.fill(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: widget.onOpenMaps,
                  child: const SizedBox.expand(),
                ),
              ),
            ),
            Positioned(
              left: 10,
              bottom: 10,
              child: IgnorePointer(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.92),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Row(
                    children: [
                      Icon(Iconsax.map_1, size: 14, color: RepairTheme.orange),
                      SizedBox(width: 6),
                      Text(
                        'اضغط لفتح Google Maps',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
