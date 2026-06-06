import 'package:Delta/provider/app_provider.dart';
import 'package:Delta/screens/home/notifications_screen.dart';
import 'package:Delta/screens/settings/Profile/profile_screen.dart';
import 'package:Delta/screens/home/search_screen.dart';
import 'package:Delta/screens/items/items_screen.dart';
import 'package:Delta/screens/repair/repair_first.dart';
import 'package:Delta/screens/settings/About/about_screen.dart';
import 'package:Delta/screens/settings/Complaints/Complaints_screen.dart';
import 'package:Delta/screens/settings/Sales/SalesScreen.dart';
import 'package:Delta/services/DioServiceCert.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:iconsax/iconsax.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const Color _orange = Color(0xFFF37021);
  static const Color _bodyBg = Color(0xFFF2F3F7);
  static const Color _textDark = Color(0xFF1A1A2E);

  final TextEditingController searchController = TextEditingController();
  final PageController _promoController = PageController();
  int _promoPage = 0;

  bool isSearch = false;
  List searchItemsList = [];
  List promosImages = [];
  String userName = "";
  String? _profileImageUrl;
  String _serviceStatus = 'جاري التحميل...';
  String _lastOrderText = '';
  Color _statusDotColor = Colors.grey;
  int _activeOrdersCount = 0;
  int _completedOrdersCount = 0;

  Future<void> getUserProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final uid = prefs.getString("userId") ?? "";
    final result = await getDio().post(
      "https://daltalifts.com/app2026/sql.php",
      data: {"action": "profile", "uid": uid},
    );
    final data = result.data['data'];
    if (data is! Map) return;

    final photo = data['a6']?.toString() ?? '';
    if (photo.isNotEmpty) {
      await prefs.setString('profilePhoto', photo);
    }

    if (!mounted) return;
    setState(() {
      userName = data['a1']?.toString() ?? '';
      if (photo.isNotEmpty) {
        _profileImageUrl = photo;
      } else {
        final savedPhoto = prefs.getString('profilePhoto') ?? '';
        _profileImageUrl = savedPhoto.isNotEmpty ? savedPhoto : null;
      }
    });
    debugPrint('🖼️ Home photo from API a6: $photo');
  }

  Future<void> searchItems(dynamic kval) async {
    final result = await getDio().post(
      "https://daltalifts.com/app2026/sql.php?k=${DateTime.now().millisecondsSinceEpoch}",
      data: {"action": "search", "kval": kval},
    );
    setState(() {
      searchItemsList = result.data['data'];
    });
  }

  Future<void> getPromos() async {
    final result = await getDio().post(
      "https://daltalifts.com/app2026/sql.php?k=${DateTime.now().millisecondsSinceEpoch}",
      data: {"action": "promos"},
    );
    setState(() {
      promosImages = result.data['data'];
    });
  }

  Future<void> _loadDashboardData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final uid = prefs.getString('userId') ?? '';

      final result = await getDio().post(
        'https://daltalifts.com/app2026/sql.php',
        data: {'action': 'dashboard', 'uid': uid},
      );

      if (!mounted) return;
      if (result.data['success'] != true && result.data['success'] != 1) {
        return;
      }

      final payload = result.data['data'];
      if (payload is! Map) return;

      final active =
          int.tryParse(payload['active_orders']?.toString() ?? '0') ?? 0;
      final completed =
          int.tryParse(payload['completed_orders']?.toString() ?? '0') ?? 0;
      final lastOrder = payload['last_order_date']?.toString() ?? '';

      String lastOrderText = '';
      if (lastOrder.isNotEmpty) {
        try {
          final date = DateTime.parse(lastOrder);
          final diff = DateTime.now().difference(date);
          if (diff.inDays == 0) {
            lastOrderText = 'آخر طلب: اليوم';
          } else if (diff.inDays == 1) {
            lastOrderText = 'آخر طلب: أمس';
          } else if (diff.inDays < 30) {
            lastOrderText = 'آخر طلب: منذ ${diff.inDays} أيام';
          } else if (diff.inDays < 365) {
            final months = (diff.inDays / 30).floor();
            lastOrderText = 'آخر طلب: منذ $months شهر';
          } else {
            lastOrderText = 'آخر طلب: منذ فترة';
          }
        } catch (_) {}
      }

      String status;
      Color dotColor;
      if (active > 0) {
        status = 'نشطة';
        dotColor = const Color(0xFF4CAF50);
      } else if (completed > 0) {
        status = 'لا يوجد طلبات نشطة';
        dotColor = Colors.orange;
      } else {
        status = 'لم يتم الطلب بعد';
        dotColor = Colors.grey;
      }

      setState(() {
        _serviceStatus = status;
        _statusDotColor = dotColor;
        _lastOrderText = lastOrderText;
        _activeOrdersCount = active;
        _completedOrdersCount = completed;
      });
    } catch (e) {
      debugPrint('Dashboard error: $e');
    }
  }

  void _goToOrderTab() {
    context.read<AppProvider>().jumpToPagex(2);
  }

  void _navigateService(Widget screen) {
    Navigator.push(
      context,
      MaterialPageRoute<void>(builder: (context) => screen),
    );
  }

  @override
  void initState() {
    super.initState();
    Future(() async {
      final prefs = await SharedPreferences.getInstance();
      debugPrint('🖼️ profilePhoto from prefs: ${prefs.getString('profilePhoto')}');
      final photo = prefs.getString('profilePhoto') ?? '';
      if (!mounted) return;
      setState(() {
        _profileImageUrl = photo.isNotEmpty ? photo : null;
      });
    });
    getUserProfile();
    getPromos();
    _loadDashboardData();
  }

  @override
  void dispose() {
    _promoController.dispose();
    searchController.dispose();
    super.dispose();
  }

  Widget _buildHeaderContent() {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Column(
        children: [
          Row(
              children: [
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder: (context) => const NotificationsScreen(),
                      ),
                    );
                  },
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.20),
                      borderRadius: BorderRadius.circular(13),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.30)),
                    ),
                    child: const Icon(
                      Iconsax.notification,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
                const Spacer(),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'أهلاً بك،',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.white.withValues(alpha: 0.4),
                      ),
                    ),
                    Text(
                      userName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: () => Navigator.push<void>(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => const ProfileScreen(),
                    ),
                  ).then((_) async {
                    final prefs = await SharedPreferences.getInstance();
                    final photo = prefs.getString('profilePhoto') ?? '';
                    if (mounted) {
                      setState(() {
                        _profileImageUrl = photo.isNotEmpty ? photo : null;
                      });
                    }
                  }),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: ClipOval(
                      child: _profileImageUrl != null &&
                              _profileImageUrl!.isNotEmpty
                          ? Image.network(
                              _profileImageUrl!,
                              width: 44,
                              height: 44,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                color: Colors.white.withOpacity(0.25),
                                child: Center(
                                  child: Text(
                                    userName.isNotEmpty ? userName[0] : 'U',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            )
                          : Container(
                              color: Colors.white.withOpacity(0.25),
                              child: Center(
                                child: Text(
                                  userName.isNotEmpty ? userName[0] : 'U',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withOpacity(0.25)),
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: _goToOrderTab,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF37021),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'اطلب الآن',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const Spacer(),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'حالة الخدمة',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.white.withOpacity(0.75),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _serviceStatus,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _statusDotColor,
                            ),
                          ),
                        ],
                      ),
                      if (_lastOrderText.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          _lastOrderText,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.white.withOpacity(0.80),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
      ),
    );
  }

  Widget _buildHeader() {
    final topPad = MediaQuery.paddingOf(context).top;
    return Container(
      width: double.infinity,
      color: _orange,
      padding: EdgeInsets.fromLTRB(16, topPad + 14, 16, 36),
      child: _buildHeaderContent(),
    );
  }

  Widget _buildSearchField() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
      child: Container(
        height: 46,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFEBEBEB)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: Row(
          children: [
            const Icon(Iconsax.search_normal, color: Color(0xFFCCCCCC), size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: searchController,
                textAlign: TextAlign.right,
                keyboardType: TextInputType.text,
                onChanged: (val) {
                  setState(() {
                    if (val.isEmpty) {
                      isSearch = false;
                    } else {
                      isSearch = true;
                      searchItems(val);
                    }
                  });
                },
                decoration: const InputDecoration(
                  hintText: 'ابحث هنا...',
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                  hintStyle: TextStyle(
                    color: Color(0xFFCCCCCC),
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStats() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 16),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Row(
          children: [
            Expanded(
              child: _StatCard(
                value: '$_activeOrdersCount',
                label: 'طلبات نشطة',
                iconBg: const Color(0xFFFFF0E5),
                iconColor: const Color(0xFFF37021),
                icon: Iconsax.clock,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _StatCard(
                value: '$_completedOrdersCount',
                label: 'مكتملة',
                iconBg: const Color(0xFFEDFAF4),
                iconColor: const Color(0xFF22C55E),
                icon: Iconsax.tick_circle,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPromoSlider() {
    final count = promosImages.isEmpty ? 1 : promosImages.length;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'أحدث العروض',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  color: _textDark,
                ),
              ),
              Text(
                'عرض الكل',
                style: TextStyle(
                  fontSize: 11,
                  color: _orange,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 180,
          child: PageView.builder(
            controller: _promoController,
            itemCount: count,
            onPageChanged: (i) => setState(() => _promoPage = i),
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A2E),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFFF37021).withValues(alpha: 0.25),
                      width: 1.5,
                    ),
                  ),
                  clipBehavior: Clip.hardEdge,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (promosImages.isNotEmpty)
                        Positioned.fill(
                          child: Image.network(
                            promosImages[index].toString(),
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                          ),
                        ),
                      Positioned.fill(
                        child: Container(
                          color: const Color(0xFF1A1A2E).withValues(alpha: 0.55),
                        ),
                      ),
                      Positioned(
                        top: -25,
                        right: -25,
                        child: Container(
                          width: 110,
                          height: 110,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFFF37021).withValues(alpha: 0.20),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: -30,
                        left: 10,
                        child: Container(
                          width: 90,
                          height: 90,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFFF37021).withValues(alpha: 0.15),
                          ),
                        ),
                      ),
                      Positioned(
                        right: 0,
                        top: 0,
                        bottom: 0,
                        child: Container(
                          width: 5,
                          color: const Color(0xFFF37021),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            count,
            (i) => AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: _promoPage == i ? 20 : 6,
              height: 6,
              decoration: BoxDecoration(
                color: _promoPage == i ? _orange : const Color(0xFFDDDDDD),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildServicesSection() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'خدماتنا',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  color: _textDark,
                ),
              ),
              Text(
                'عرض الكل',
                style: TextStyle(
                  fontSize: 11,
                  color: _orange,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 0, 14, 20),
          child: Column(
            children: [
              _ServiceRow(
                color: const Color(0xFFF37021),
                iconBg: const Color(0xFFFFF0E5),
                icon: Iconsax.setting,
                name: 'صيانة المصاعد',
                desc: 'طلب صيانة عاجلة أو دورية',
                onTap: () => _navigateService(const RepairFirst()),
              ),
              const SizedBox(height: 9),
              _ServiceRow(
                color: const Color(0xFF3B82F6),
                iconBg: const Color(0xFFEEF4FF),
                icon: Iconsax.box,
                name: 'المنتجات',
                desc: 'تصفح مصاعدنا وأنظمة التحكم',
                onTap: () => _navigateService(const ItemsScreen()),
              ),
              const SizedBox(height: 9),
              _ServiceRow(
                color: const Color(0xFF22C55E),
                iconBg: const Color(0xFFEDFAF4),
                icon: Iconsax.message,
                name: 'شكاوي واقتراحات',
                desc: 'تواصل معنا وأرسل ملاحظاتك',
                onTap: () => _navigateService(const ComplaintScreen()),
              ),
              const SizedBox(height: 9),
              _ServiceRow(
                color: const Color(0xFFF59E0B),
                iconBg: const Color(0xFFFFF8ED),
                icon: Iconsax.chart_2,
                name: 'قسم المبيعات',
                desc: 'تواصل مع فريق المبيعات',
                onTap: () => _navigateService(const SalesScreen()),
              ),
              const SizedBox(height: 9),
              _ServiceRow(
                color: const Color(0xFF8B5CF6),
                iconBg: const Color(0xFFF3EEFF),
                icon: Iconsax.info_circle,
                name: 'حول الشركة',
                desc: 'تعرف على دلتا لتكنولوجيا المصاعد',
                onTap: () => _navigateService(const AboutScreen()),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBodyContent() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildSearchField(),
        if (!isSearch) ...[
          _buildStats(),
          _buildPromoSlider(),
          _buildServicesSection(),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.paddingOf(context).bottom + 8;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _orange,
        body: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: _bodyBg,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(28),
                    topRight: Radius.circular(28),
                  ),
                ),
                clipBehavior: Clip.hardEdge,
                child: isSearch
                    ? Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 18),
                            child: _buildSearchField(),
                          ),
                          Expanded(
                            child: SearchScreen(
                              searchItemsList: searchItemsList,
                            ),
                          ),
                        ],
                      )
                    : SingleChildScrollView(
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(0, 18, 0, bottomPad),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _buildBodyContent(),
                              const SizedBox(height: 100),
                            ],
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
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.value,
    required this.label,
    required this.iconBg,
    required this.iconColor,
    required this.icon,
  });

  final String value;
  final String label;
  final Color iconBg;
  final Color iconColor;
  final IconData icon;

  static const Color _textDark = Color(0xFF1A1A2E);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEBEBEB)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: _textDark,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  label,
                  style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
        ],
      ),
    );
  }
}

class _ServiceRow extends StatelessWidget {
  const _ServiceRow({
    required this.color,
    required this.iconBg,
    required this.icon,
    required this.name,
    required this.desc,
    required this.onTap,
  });

  final Color color;
  final Color iconBg;
  final IconData icon;
  final String name;
  final String desc;
  final VoidCallback onTap;

  static const Color _textDark = Color(0xFF1A1A2E);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFEBEBEB)),
        ),
        child: Row(
          children: [
            Container(
              width: 4,
              height: 46,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(width: 6),
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: _textDark,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    desc,
                    style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(9),
              ),
              child: const Icon(
                Iconsax.arrow_left_3,
                // Iconsax.arrow_right_3,
                size: 12,
                color: Color(0xFFBBBBBB),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
