import 'package:Delta/constants/app_colors.dart';
import 'package:Delta/provider/app_provider.dart';
import 'package:Delta/screens/admin/admin_my_reports_screen.dart';
import 'package:Delta/screens/admin/engineer_task_scope.dart';
import 'package:Delta/screens/admin/admin_support_screen.dart';
import 'package:Delta/screens/admin/admin_task_history_screen.dart';
import 'package:Delta/screens/admin/admin_work_zone_screen.dart';
import 'package:Delta/screens/settings/About/about_screen.dart';
import 'package:Delta/screens/settings/Addresses/Addresses_Screen.dart';
import 'package:Delta/screens/settings/Complaints/Complaints_Details.dart';
import 'package:Delta/screens/settings/Maintenance/maintenance_contracts_screen.dart';
import 'package:Delta/screens/settings/Profile/profile_screen.dart';
import 'package:Delta/screens/splash_screen.dart';
import 'package:Delta/services/DioServiceCert.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shorebird_code_push/shorebird_code_push.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsItem {
  const _SettingsItem({
    required this.id,
    required this.text,
    required this.icon,
    this.pageBuilder,
    this.destructive = false,
  });

  final String id;
  final String text;
  final IconData icon;
  final Widget Function()? pageBuilder;
  final bool destructive;
}

class _SettingsScreenState extends State<SettingsScreen> {
  int isLoading = -1;
  int isNotify = -2;
  String name = "";
  String _appVersion = '—';
  String _buildNumber = '—';
  String _shorebirdPatch = '—';

  List<_SettingsItem> _items(bool isAdmin) {
    if (isAdmin) {
      return [
        _SettingsItem(
          id: 'profile',
          text: 'الملف الشخصي',
          icon: Iconsax.user,
          pageBuilder: () => const ProfileScreen(),
        ),
        _SettingsItem(
          id: 'task_history',
          text: 'سجل المهام',
          icon: Iconsax.clipboard_text,
          pageBuilder: () => const AdminTaskHistoryScreen(),
        ),
        _SettingsItem(
          id: 'work_zone',
          text: 'منطقة العمل',
          icon: Iconsax.map,
          pageBuilder: () => const AdminWorkZoneScreen(),
        ),
        const _SettingsItem(
          id: 'notifications',
          text: 'الإشعارات',
          icon: Iconsax.notification,
        ),
        _SettingsItem(
          id: 'my_reports',
          text: 'بلاغاتي',
          icon: Iconsax.note_2,
          pageBuilder: () => const AdminMyReportsScreen(),
        ),
        const _SettingsItem(
          id: 'logout',
          text: 'تسجيل الخروج',
          icon: Iconsax.logout,
          destructive: true,
        ),
        _SettingsItem(
          id: 'support',
          text: 'الدعم الفني',
          icon: Iconsax.headphone,
          pageBuilder: () => const AdminSupportScreen(),
        ),
      ];
    }
    return [
      _SettingsItem(
        id: 'profile',
        text: 'الملف الشخصي',
        icon: Iconsax.user,
        pageBuilder: () => const ProfileScreen(),
      ),
      _SettingsItem(
        id: 'maintenance',
        text: 'عقود الصيانة',
        icon: Iconsax.stickynote,
        pageBuilder: () => const MaintenanceContractsScreen(),
      ),
      _SettingsItem(
        id: 'addresses',
        text: 'العناوين',
        icon: Iconsax.location,
        pageBuilder: () => const AddressesScreen(),
      ),
      _SettingsItem(
        id: 'about',
        text: 'حول الشركة',
        icon: Iconsax.info_circle,
        pageBuilder: () => const AboutScreen(),
      ),
      const _SettingsItem(
        id: 'notifications',
        text: 'الإشعارات',
        icon: Iconsax.notification,
      ),
      _SettingsItem(
        id: 'complaints',
        text: 'شكاوي',
        icon: Iconsax.note_2,
        pageBuilder: () => const ComplaintDetails(),
      ),
      const _SettingsItem(
        id: 'logout',
        text: 'تسجيل الخروج',
        icon: Iconsax.logout,
        destructive: true,
      ),
      const _SettingsItem(
        id: 'delete',
        text: 'حذف الحساب',
        icon: Iconsax.trash,
        destructive: true,
      ),
    ];
  }

  Future getUserProfile({String? playId}) async {
    SharedPreferences prefx = await SharedPreferences.getInstance();
    String uid = prefx.getString("userId") ?? "";
    var result = await getDio().post(
      "https://daltalifts.com/app2026/sql.php?k=${DateTime.now().millisecondsSinceEpoch}",
      data: {"action": "profile", "uid": uid, "playId": playId},
    );
    final data = result.data['data'];
    if (data is Map) {
      await EngineerTaskScope.persistFromPayload(
        Map<String, dynamic>.from(data),
        prefx,
      );
    }
    if (!mounted) return;
    setState(() {
      name = data is Map ? (data['a1']?.toString() ?? '') : '';
    });
  }

  Future logoutAccount(int i) async {
    setState(() {
      isLoading = i;
    });
    final currentTab = Provider.of<AppProvider>(context, listen: false);
    SharedPreferences prefx = await SharedPreferences.getInstance();
    prefx.remove("userId");
    prefx.remove("orderId");
    await prefx.remove('customer_type');
    await prefx.remove('customer_uid');
    await prefx.remove('customer_phone');
    await prefx.remove('contract_id');
    await prefx.remove('currentCard');
    await prefx.remove('maint_customer_type');
    await prefx.remove('maint_booking_id');
    await prefx.remove('maint_delta_verified');
    await prefx.remove('maint_erp_contract_id');
    await prefx.remove('is_app_manager');
    await EngineerTaskScope.clearSession(prefx);
    currentTab.setAppManager(false);
    await prefx.remove('userId');
    await prefx.remove('addId');
    currentTab.jumpToPagex(0);
    await prefx.setBool('just_logged_in', true);
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => SplashScreen()),
    );
  }

  Future deleteAccount(int i) async {
    setState(() {
      isLoading = i;
    });
    final currentTab = Provider.of<AppProvider>(context, listen: false);
    SharedPreferences prefx = await SharedPreferences.getInstance();
    var uid = prefx.get("userId");
    await getDio().post(
      "https://daltalifts.com/app2026/sql.php?k=${DateTime.now().millisecondsSinceEpoch}",
      data: {"action": "deleteAccount", "userId": uid},
    );
    prefx.remove("userId");
    prefx.remove("orderId");
    await EngineerTaskScope.clearSession(prefx);
    currentTab.jumpToPagex(0);
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => SplashScreen()),
    );
  }

  Future getNotifyStatus() async {
    SharedPreferences prefx = await SharedPreferences.getInstance();
    isNotify = prefx.getInt('isNotify') ?? 0;
    setState(() {});
  }

  Future<void> _toggleNotifications(int i) async {
    SharedPreferences prefx = await SharedPreferences.getInstance();
    if (isNotify == 4) {
      isNotify = -1;
      prefx.setInt('isNotify', isNotify);
      getUserProfile(playId: "");
      getNotifyStatus();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("تم إلغاء الإشعارات"),
          backgroundColor: AppColors.primary,
        ),
      );
      setState(() {});
    } else {
      isNotify = 4;
      prefx.setInt('isNotify', isNotify);
      final playerId = OneSignal.User.pushSubscription.id;
      getUserProfile(playId: playerId);
      getNotifyStatus();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("تم تفعيل الإشعارات"),
          backgroundColor: AppColors.primary,
        ),
      );
      setState(() {});
    }
  }

  Future<void> _loadAppInfo() async {
    try {
      final info = await PackageInfo.fromPlatform();
      var patchLabel = '—';
      try {
        final patch = await ShorebirdUpdater().readCurrentPatch();
        patchLabel = patch == null ? '0' : '${patch.number}';
      } catch (_) {
        patchLabel = '—';
      }
      if (!mounted) return;
      setState(() {
        _appVersion = info.version;
        _buildNumber = info.buildNumber;
        _shorebirdPatch = patchLabel;
      });
    } catch (_) {}
  }

  @override
  void initState() {
    getUserProfile();
    getNotifyStatus();
    _loadAppInfo();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = context.watch<AppProvider>().isAppManager;
    final items = _items(isAdmin);
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: AppColors.primary,
      appBar: AppBar(
        title: const Text('الإعدادات', style: TextStyle(color: Colors.white)),
        centerTitle: true,
        forceMaterialTransparency: true,
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Stack(
        children: [
          Positioned(
            top: screenHeight * 0.18,
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(25),
                  topRight: Radius.circular(25),
                ),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 70),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        const crossCount = 4;
                        const hPad = 16.0;
                        const spacing = 10.0;
                        final cellWidth = (constraints.maxWidth -
                                hPad * 2 -
                                spacing * (crossCount - 1)) /
                            crossCount;
                        final fullCount =
                            (items.length ~/ crossCount) * crossCount;
                        final leftover = items.sublist(fullCount);

                        return SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
                          child: Column(
                            children: [
                              if (fullCount > 0)
                                GridView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  padding: EdgeInsets.zero,
                                  itemCount: fullCount,
                                  gridDelegate:
                                      const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: crossCount,
                                    crossAxisSpacing: spacing,
                                    mainAxisSpacing: 20,
                                    childAspectRatio: 0.85,
                                  ),
                                  itemBuilder: (context, i) =>
                                      _settingsTile(items[i], i),
                                ),
                              if (leftover.isNotEmpty) ...[
                                const SizedBox(height: 20),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    for (var i = 0;
                                        i < leftover.length;
                                        i++) ...[
                                      if (i > 0)
                                        const SizedBox(width: spacing),
                                      SizedBox(
                                        width: cellWidth,
                                        child: _settingsTile(
                                          leftover[i],
                                          fullCount + i,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  if (isAdmin) _buildVersionFooter(),
                ],
              ),
            ),
          ),
          Positioned(
            top: screenHeight * 0.11,
            left: 0,
            right: 0,
            child: Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.white,
                    child: CircleAvatar(
                      radius: 36,
                      backgroundColor: AppColors.primary.withOpacity(0.2),
                      child: Image.asset(
                        'assets/img/brand_logo_big.png',
                        width: 50,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
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

  Widget _settingsTile(_SettingsItem item, int i) {
    final notifyOn = item.id == 'notifications' && isNotify == 4;
    return GestureDetector(
      onTap: () async {
        switch (item.id) {
          case 'notifications':
            await _toggleNotifications(i);
            break;
          case 'logout':
            await logoutAccount(i);
            break;
          case 'delete':
            await deleteAccount(i);
            break;
          default:
            final page = item.pageBuilder?.call();
            if (page == null) return;
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => page),
            );
            break;
        }
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: item.destructive
                  ? Colors.red.withOpacity(0.12)
                  : notifyOn
                      ? AppColors.primary
                      : AppColors.primary.withOpacity(0.12),
              borderRadius: BorderRadius.circular(50),
            ),
            child: isLoading == i
                ? Center(
                    child: CircularProgressIndicator(
                      color: item.destructive
                          ? Colors.red
                          : AppColors.primary,
                    ),
                  )
                : Icon(
                    item.icon,
                    color: item.destructive
                        ? Colors.red
                        : notifyOn
                            ? Colors.white
                            : AppColors.primary,
                    size: 26,
                  ),
          ),
          const SizedBox(height: 8),
          Text(
            item.text,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildVersionFooter() {
    final bottomSafe = MediaQuery.paddingOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 4, 16, bottomSafe + 92),
      child: Column(
        children: [
          const Text(
            'تطبيق دلتا للموظفين',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: Color(0xFF4A4A4A),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'الإصدار $_appVersion  ·  البناء $_buildNumber',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Color(0xFF777777),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'باتش Shorebird  $_shorebirdPatch',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Color(0xFFF37021),
            ),
          ),
        ],
      ),
    );
  }
}
