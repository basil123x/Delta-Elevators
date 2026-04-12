import 'package:Delta/constants/app_colors.dart';
import 'package:Delta/provider/app_provider.dart';
import 'package:Delta/screens/booking/BookingScreen.dart';
import 'package:Delta/screens/home/home_screen.dart';
import 'package:Delta/screens/order/order_screen.dart';
import 'package:Delta/screens/settings/Profile/profile_screen.dart';
import 'package:Delta/screens/settings/settings_screen.dart';
import 'package:animated_bottom_navigation_bar/animated_bottom_navigation_bar.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final autoSizeGroup = AutoSizeGroup();
  List<Widget> pages = [
    HomeScreen(),
    Bookingscreen(),
    OrderScreen(),
    SettingsScreen(),
  ];

  List icons = [
    Iconsax.home,
    Iconsax.calendar_search,
    Iconsax.note_add,
    Iconsax.setting,
  ];

  List iconsTxt = [
    "الرئيسية",
    "الحجوزات",
    "تقديم طلب",
    "الإعدادات",
  ];

  PageController pageController = PageController();
  int currentPage = 0;

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
          // لو في تغيير من برة (من صفحة تانية)
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
                  duration: Duration(milliseconds: 200),
                  curve: Curves.easeInOut,
                );
              }
            });
          }

          return Scaffold(
            backgroundColor: Colors.white,
            body: PageView(
              physics: NeverScrollableScrollPhysics(),
              controller: pageController,
              onPageChanged: (val) {
                setState(() {
                  currentPage = val;
                });
                // حدّث الـ Provider عشان يبقى متزامن
                app.jumpToPagex(val);
              },
              children: pages,
            ),
            floatingActionButton: FloatingActionButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ProfileScreen()),
                );
              },
              elevation: 0,
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(50),
              ),
              child: Icon(Iconsax.user, color: Colors.white),
            ),
            floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
            bottomNavigationBar: AnimatedBottomNavigationBar.builder(
              gapLocation: GapLocation.center,
              notchSmoothness: NotchSmoothness.verySmoothEdge,
              leftCornerRadius: 32,
              rightCornerRadius: 32,
              itemCount: icons.length, tabBuilder: (int index, bool isActive) {
              
          final color = isActive
              ? AppColors.primary
              : Colors.grey.shade500;
          return Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icons[index],
                size: 24,
                color: color,
              ),
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: AutoSizeText(
                  iconsTxt[index],
                  maxLines: 1,
                  style: TextStyle(color: color),
                  group: autoSizeGroup,
                ),
              )
            ],
          );
        }, activeIndex: currentPage, onTap: (i) {
                setState(() {
                  currentPage = i;
                });
                pageController.animateToPage(
                  i,
                  duration: Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
                // حدّث الـ Provider
                app.jumpToPagex(i);
              },),
          );
        },
      ),
    );
  }
}
