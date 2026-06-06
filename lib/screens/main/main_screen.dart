import 'package:Delta/provider/app_provider.dart';
import 'package:Delta/screens/booking/BookingScreen.dart';
import 'package:Delta/screens/home/home_screen.dart';
import 'package:Delta/screens/order/order_screen.dart';
import 'package:Delta/screens/settings/Profile/profile_screen.dart';
import 'package:Delta/screens/settings/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:iconsax/iconsax.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  static const Color _orange = Color(0xFFF37021);

  final List<Widget> pages = [
    const HomeScreen(),
    const Bookingscreen(),
    const OrderScreen(),
    const SettingsScreen(),
  ];

  final PageController pageController = PageController();
  int currentPage = 0;

  /// Bottom slots: 0 home, 1 bookings, 2 FAB (profile), 3 order, 4 settings → PageView 0..3
  int _pageIndexFromNavSlot(int navSlot) {
    if (navSlot < 2) return navSlot;
    return navSlot - 1;
  }

  void _onNavTap(BuildContext context, AppProvider app, int navSlot) {
    if (navSlot == 2) {
      Navigator.push(
        context,
        MaterialPageRoute<void>(builder: (context) => const ProfileScreen()),
      );
      return;
    }
    final i = _pageIndexFromNavSlot(navSlot);
    setState(() {
      currentPage = i;
    });
    pageController.animateToPage(
      i,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
    app.jumpToPagex(i);
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
          if (app.currentTab != currentPage &&
              app.currentTab >= 0 &&
              app.currentTab < pages.length) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (pageController.hasClients && mounted) {
                setState(() {
                  currentPage = app.currentTab;
                });
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
            body: PageView(
              physics: const NeverScrollableScrollPhysics(),
              controller: pageController,
              onPageChanged: (val) {
                setState(() {
                  currentPage = val;
                });
                app.jumpToPagex(val);
              },
              children: pages,
            ),
            bottomNavigationBar: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(
                  top: BorderSide(color: Color(0xFFF0F0F0), width: 1),
                ),
              ),
              child: SafeArea(
                top: false,
                child: SizedBox(
                  height: 60,
                  child: Row(
                    children: [
                      _NavItem(
                        icon: Iconsax.home,
                        label: 'الرئيسية',
                        isActive: currentPage == 0,
                        onTap: () => _onNavTap(context, app, 0),
                      ),
                      _NavItem(
                        icon: Iconsax.calendar,
                        label: 'الحجوزات',
                        isActive: currentPage == 1,
                        onTap: () => _onNavTap(context, app, 1),
                      ),
                      SizedBox(
                        width: 56,
                        child: Align(
                          alignment: Alignment.topCenter,
                          child: GestureDetector(
                            onTap: () => _onNavTap(context, app, 2),
                            child: Container(
                              width: 52,
                              height: 52,
                              margin: const EdgeInsets.only(bottom: 8),
                              decoration: BoxDecoration(
                                color: _orange,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: const Color(0xFFF5F5F7),
                                  width: 3,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: _orange.withValues(alpha: 0.3),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Iconsax.user,
                                color: Colors.white,
                                size: 26,
                              ),
                            ),
                          ),
                        ),
                      ),
                      _NavItem(
                        icon: Iconsax.category,
                        label: 'تقديم طلب',
                        isActive: currentPage == 2,
                        onTap: () => _onNavTap(context, app, 3),
                      ),
                      _NavItem(
                        icon: Iconsax.user,
                        label: 'الإعدادات',
                        isActive: currentPage == 3,
                        onTap: () => _onNavTap(context, app, 4),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  static const Color _orange = Color(0xFFF37021);
  static const Color _muted = Color(0xFFBBBBBB);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 22, color: isActive ? _orange : _muted),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                color: isActive ? _orange : _muted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// YqeR-dkt71LsuqVdKQpO9n_Ckq_xEvh6ptYhnF92SQY