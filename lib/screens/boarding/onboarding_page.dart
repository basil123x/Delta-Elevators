import 'package:flutter/material.dart';

/// Content and chrome for one onboarding step.
///
/// Pages are shown in this list order (indices 0…2). The last index completes
/// onboarding with [primaryLabel] (e.g. ابدأ الآن).
@immutable
class OnboardingPage {
  const OnboardingPage({
    required this.title,
    required this.subtitle,
    required this.imageAsset,
    required this.showSkip,
    required this.showPreviousButton,
    required this.primaryLabel,
  });

  final String title;
  final String subtitle;
  final String imageAsset;
  final bool showSkip;
  final bool showPreviousButton;
  final String primaryLabel;

  /// Ordered for [PageView]: welcome → features → installation (finish).
  static const List<OnboardingPage> flow = [
    OnboardingPage(
      title: 'مرحبا بك في دلتا لتكنولوجيا المصعد والتجارة',
      subtitle:
          'تطبيقنا يوفر أفضل خدمات صيانة وتركيب المصاعد بأعلى معايير الجودة و الأمان بكفاءة دائمة',
      imageAsset: 'assets/images/onboarding_1.png',
      showSkip: true,
      showPreviousButton: false,
      primaryLabel: 'التالي',
    ),
    OnboardingPage(
      title:
          'استمتع بميزات رائعة مثل الصيانة الممتازة وطلب مصعدك بسهولة',
      subtitle:
          'يمكنك الآن طلب مصعد بتشكيلات و اشكال مختلفة و الحصور أيضاً على الصيانة بشكل سريع وفوري',
      imageAsset: 'assets/images/onboarding_3.png',
      showSkip: true,
      showPreviousButton: true,
      primaryLabel: 'التالي',
    ),
    OnboardingPage(
      title: 'تابع خطوات تركيب مصعدك بسلاسة و دقة يومياً معنا',
      subtitle:
          'استمتع بتركيب مصعد بسلاسة مع دلتا لتكنولوجيا المصاعد والتجارة , نقدم لك خطوات يومية دقيقة لضمان التركيب المثالي',
      imageAsset: 'assets/images/onboarding_2.png',
      showSkip: false,
      showPreviousButton: false,
      primaryLabel: 'ابدأ الآن',
    ),
  ];
}
