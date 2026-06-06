import 'package:Delta/screens/auth/login/login_screen.dart';
import 'package:Delta/screens/boarding/onboarding_page.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:iconsax/iconsax.dart';

/// Delta onboarding accent (brand orange).
const Color _kOnboardingOrange = Color(0xFFF37021);

class BoardingScreen extends StatefulWidget {
  const BoardingScreen({super.key});

  @override
  State<BoardingScreen> createState() => _BoardingScreenState();
}

class _BoardingScreenState extends State<BoardingScreen> {
  static const String _prefsKeySeenOnboarding = 'seen_onboarding';

  final PageController _pageController = PageController();
  int _currentPage = 0;

  List<OnboardingPage> get _pages => OnboardingPage.flow;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _markOnboardingSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefsKeySeenOnboarding, true);
  }

  void _goToLogin() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
    );
  }

  Future<void> _completeOnboarding() async {
    await _markOnboardingSeen();
    if (!mounted) return;
    _goToLogin();
  }

  void _onNext() {
    if (_currentPage >= _pages.length - 1) return;
    _pageController.nextPage(
      duration: const Duration(milliseconds: 380),
      curve: Curves.easeOutCubic,
    );
  }

  void _onPrevious() {
    if (_currentPage <= 0) return;
    _pageController.previousPage(
      duration: const Duration(milliseconds: 380),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final page = _pages[_currentPage];
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Column(
            children: [
              SizedBox(
                height: 48,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    if (page.showSkip)
                      Positioned(
                        top: 0,
                        right: 8,
                        child: TextButton(
                          onPressed: _completeOnboarding,
                          child: Text(
                            'تخطي',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Expanded(
                flex: 6,
                child: Column(
                  children: [
                    Expanded(
                      child: PageView.builder(
                        controller: _pageController,
                        itemCount: _pages.length,
                        onPageChanged: (i) => setState(() => _currentPage = i),
                        itemBuilder: (context, index) {
                          print(_pages[index].imageAsset);
                          return _OnboardingImagePanel(
                            assetPath: _pages[index].imageAsset,
                          );
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
                      child: Column(
                        children: [
                          _ProgressLine(
                            pageCount: _pages.length,
                            currentIndex: _currentPage,
                            accent: _kOnboardingOrange,
                          ),
                          const SizedBox(height: 10),
                          _PageDots(
                            count: _pages.length,
                            currentIndex: _currentPage,
                            accent: _kOnboardingOrange,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: double.infinity,
                height: 2,
                color: _kOnboardingOrange,
              ),
              Expanded(
                flex: 4,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(24, 20, 24, 16 + bottomInset),
                  child: Column(
                    children: [
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 320),
                        switchInCurve: Curves.easeOut,
                        switchOutCurve: Curves.easeIn,
                        transitionBuilder: (child, anim) {
                          return FadeTransition(
                            opacity: anim,
                            child: SlideTransition(
                              position: Tween<Offset>(
                                begin: const Offset(0, 0.06),
                                end: Offset.zero,
                              ).animate(anim),
                              child: child,
                            ),
                          );
                        },
                        child: Column(
                          key: ValueKey<int>(_currentPage),
                          children: [
                            Text(
                              page.title,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                height: 1.35,
                                color: Color(0xFF1A1A1A),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              page.subtitle,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14,
                                height: 1.5,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 280),
                        switchInCurve: Curves.easeOut,
                        switchOutCurve: Curves.easeIn,
                        child: _BottomActions(
                          key: ValueKey<String>(
                            '${page.showPreviousButton}_${page.primaryLabel}',
                          ),
                          showPrevious: page.showPreviousButton,
                          primaryLabel: page.primaryLabel,
                          onPrimary: _currentPage == _pages.length - 1
                              ? _completeOnboarding
                              : _onNext,
                          onPrevious: _onPrevious,
                        ),
                      ),
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
}

class _OnboardingImagePanel extends StatelessWidget {
  const _OnboardingImagePanel({required this.assetPath});

  static const Color _panelBg = Color(0xFFF5F5F5);

  final String assetPath;

  @override
  Widget build(BuildContext context) {
    final screenH = MediaQuery.sizeOf(context).height;
    final targetH = screenH * 0.55;

    return LayoutBuilder(
      builder: (context, constraints) {
        final h = targetH.clamp(160.0, constraints.maxHeight);
        final w = (constraints.maxWidth - 32).clamp(200.0, constraints.maxWidth);

        return Center(
          child: Container(
            width: w,
            height: h,
            decoration: BoxDecoration(
              color: _panelBg,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: _kOnboardingOrange.withValues(alpha: 0.22),
                  blurRadius: 36,
                  spreadRadius: -4,
                  offset: const Offset(0, 14),
                ),
                BoxShadow(
                  color: _kOnboardingOrange.withValues(alpha: 0.08),
                  blurRadius: 48,
                  spreadRadius: 2,
                  offset: Offset.zero,
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Image.asset(
                  assetPath,
                  fit: BoxFit.contain,
                  width: double.infinity,
                  height: double.infinity,
                  errorBuilder: (_, __, ___) => Center(
                    child: Icon(
                      Iconsax.image,
                      size: 64,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ProgressLine extends StatelessWidget {
  const _ProgressLine({
    required this.pageCount,
    required this.currentIndex,
    required this.accent,
  });

  final int pageCount;
  final int currentIndex;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final fraction = (currentIndex + 1) / pageCount;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
      height: 3,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Align(
        alignment: Alignment.centerRight,
        child: FractionallySizedBox(
          widthFactor: fraction,
          child: Container(
            decoration: BoxDecoration(
              color: accent,
              borderRadius: BorderRadius.circular(99),
            ),
          ),
        ),
      ),
    );
  }
}

class _PageDots extends StatelessWidget {
  const _PageDots({
    required this.count,
    required this.currentIndex,
    required this.accent,
  });

  final int count;
  final int currentIndex;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final active = i == currentIndex;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: active ? 22 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: active ? accent : Colors.grey.shade300,
            borderRadius: BorderRadius.circular(99),
          ),
        );
      }),
    );
  }
}

class _BottomActions extends StatelessWidget {
  const _BottomActions({
    super.key,
    required this.showPrevious,
    required this.primaryLabel,
    required this.onPrimary,
    required this.onPrevious,
  });

  final bool showPrevious;
  final String primaryLabel;
  final VoidCallback onPrimary;
  final VoidCallback onPrevious;

  @override
  Widget build(BuildContext context) {
    if (showPrevious) {
      return Row(
        children: [
          Expanded(
            child: _FilledOrangeButton(
              label: primaryLabel,
              onPressed: onPrimary,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: _OutlinedButton(
              label: 'السابق',
              onPressed: onPrevious,
            ),
          ),
        ],
      );
    }

    return _FilledOrangeButton(
      label: primaryLabel,
      onPressed: onPrimary,
    );
  }
}

class _FilledOrangeButton extends StatelessWidget {
  const _FilledOrangeButton({
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: double.infinity,
      height: 52,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: _kOnboardingOrange,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
        child: Text(label),
      ),
    );
  }
}

class _OutlinedButton extends StatelessWidget {
  const _OutlinedButton({
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: _kOnboardingOrange,
          side: const BorderSide(color: _kOnboardingOrange, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
        child: Text(label),
      ),
    );
  }
}
