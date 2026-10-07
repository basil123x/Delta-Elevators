import 'package:Delta/provider/app_provider.dart';
import 'package:Delta/screens/admin/admin_maintenance_screen.dart';
import 'package:Delta/screens/booking/BookingScreen.dart';
import 'package:Delta/screens/home/home_screen.dart';
import 'package:Delta/screens/order/order_screen.dart';
import 'package:Delta/screens/settings/Profile/profile_screen.dart';
import 'package:Delta/screens/settings/settings_screen.dart';
import 'package:animated_bottom_navigation_bar/animated_bottom_navigation_bar.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:iconsax/iconsax.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  static const Color _orange = Color(0xFFF37021);
  static const Color _muted = Color(0xFFB0B0B0);

  final PageController pageController = PageController();
  final AutoSizeGroup _labelGroup = AutoSizeGroup();
  int currentPage = 0;

  List<Widget> _pages(bool isAdmin) => [
    const HomeScreen(),
    const Bookingscreen(),
    isAdmin
        ? const AdminMaintenanceScreen(key: ValueKey('admin-maint'))
        : const OrderScreen(key: ValueKey('customer-order')),
    const SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _hydrateAdmin();
  }

  Future<void> _hydrateAdmin() async {
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getBool('is_app_manager') ?? false;
    if (!mounted) return;
    context.read<AppProvider>().setAppManager(cached);
  }

  void _goToPage(AppProvider app, int page) {
    if (currentPage != page) {
      setState(() => currentPage = page);
    }
    if (pageController.hasClients) {
      pageController.animateToPage(
        page,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      );
    }
    app.jumpToPagex(page);
  }

  void _openProfile() {
    Navigator.push(
      context,
      MaterialPageRoute<void>(builder: (context) => const ProfileScreen()),
    );
  }

  @override
  void dispose() {
    pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Consumer<AppProvider>(
        builder: (context, app, child) {
          final isAdmin = app.isAppManager;
          final pages = _pages(isAdmin);
          final icons = <IconData>[
            Iconsax.home,
            Iconsax.calendar,
            isAdmin ? Iconsax.setting_2 : Iconsax.category,
            Iconsax.user,
          ];
          final labels = <String>[
            'الرئيسية',
            'الحجوزات',
            isAdmin ? 'الصيانة' : 'تقديم طلب',
            'الإعدادات',
          ];

          if (app.currentTab != currentPage &&
              app.currentTab >= 0 &&
              app.currentTab < pages.length) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (pageController.hasClients && mounted) {
                setState(() => currentPage = app.currentTab);
                pageController.animateToPage(
                  app.currentTab,
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeInOut,
                );
              }
            });
          }

          return Scaffold(
            backgroundColor: const Color(0xFFF2F3F7),
            extendBody: true,
            body: PageView(
              physics: const NeverScrollableScrollPhysics(),
              controller: pageController,
              onPageChanged: (val) {
                setState(() => currentPage = val);
                app.jumpToPagex(val);
              },
              children: pages,
            ),
            floatingActionButton: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFFF8A3D), _orange],
                ),
                boxShadow: [
                  BoxShadow(
                    color: _orange.withValues(alpha: 0.45),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: _openProfile,
                  child: const Icon(
                    Iconsax.user,
                    color: Colors.white,
                    size: 26,
                  ),
                ),
              ),
            ),
            floatingActionButtonLocation:
                FloatingActionButtonLocation.centerDocked,
            bottomNavigationBar: AnimatedBottomNavigationBar.builder(
              itemCount: 4,
              activeIndex: currentPage.clamp(0, 3),
              gapLocation: GapLocation.center,
              gapWidth: 72,
              notchMargin: 8,
              notchSmoothness: NotchSmoothness.softEdge,
              leftCornerRadius: 18,
              rightCornerRadius: 18,
              height: 68,
              elevation: 12,
              splashColor: _orange,
              splashRadius: 28,
              splashSpeedInMilliseconds: 280,
              scaleFactor: 1.15,
              backgroundColor: Colors.white,
              shadow: BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 16,
                offset: const Offset(0, -2),
              ),
              onTap: (index) => _goToPage(app, index),
              tabBuilder: (index, isActive) {
                final color = isActive ? _orange : _muted;
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icons[index], size: 22, color: color),
                    const SizedBox(height: 4),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: AutoSizeText(
                        labels[index],
                        maxLines: 1,
                        minFontSize: 8,
                        group: _labelGroup,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: isActive
                              ? FontWeight.w800
                              : FontWeight.w500,
                          color: color,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          );
        },
      ),
    );
  }
}
