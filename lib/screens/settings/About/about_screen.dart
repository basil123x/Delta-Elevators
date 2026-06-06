
import 'package:Delta/constants/app_colors.dart';
import 'package:Delta/screens/settings/About/contact_menu.dart';
import 'package:flutter/material.dart';
import 'package:flutter_boxicons/flutter_boxicons.dart';
import 'package:iconsax/iconsax.dart';

class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  static const String _description =
      "شركة دلتا هي شركة متخصصة في تقديم حلول مبتكرة ومتطورة في مجالات التكنولوجيا والخدمات الرقمية. تسعى دلتا دائمًا إلى تمكين الأفراد والشركات من خلال توفير تقنيات حديثة تُسهم في تحسين الكفاءة وزيادة الإنتاجية. من خلال التركيز على الجودة والإبداع، تلتزم دلتا بتقديم أفضل المنتجات والخدمات التي تلبي احتياجات عملائها وتساعدهم على تحقيق أهدافهم بنجاح. سواء كان ذلك من خلال تطوير البرمجيات، تقديم الاستشارات التقنية، أو توفير الحلول الذكية، دلتا دائماً في المقدمة.";

  List<Map<dynamic, dynamic>> socialIcons = [
    {"icon": Boxicons.bx_envelope},
    {"icon": Boxicons.bxl_facebook},
    {"icon": Boxicons.bxl_instagram},
    {"icon": Boxicons.bxl_snapchat},
  ];

  Widget _floatingIconCircle() {
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFFFFF0E5),
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1AF37021),
            blurRadius: 12,
          ),
        ],
      ),
      child: const Icon(
        Iconsax.building,
        color: Color(0xFFF37021),
        size: 32,
      ),
    );
  }

  Widget _buildSocialIcon(int i) {
    return GestureDetector(
      onTap: () async {
        switch (i) {
          case 0:
            await UrlHelper.openEmail(email: "info@daltalifts.com");
            break;
          case 1:
            await UrlHelper.openWebsite(
              "https://www.facebook.com/profile.php?id=61587296592205",
            );
            break;
          case 2:
            await UrlHelper.openWebsite(
              "https://www.instagram.com/delta.aelevator",
            );
            break;
          case 3:
            await UrlHelper.openWebsite(
              "https://www.snapchat.com/@delta_elevate",
            );
            break;
          default:
        }
      },
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFFFFF0E5),
          border: Border.all(color: const Color(0xFFFFD5B5), width: 1),
        ),
        child: Icon(
          socialIcons[i]['icon'],
          color: const Color(0xFFF37021),
          size: 24,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.paddingOf(context).top;
    final iconTop = kToolbarHeight + topPadding - 36;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.primary,
        appBar: AppBar(
          title: Text("عن الشركة", style: TextStyle(color: Colors.white)),
          centerTitle: true,
          forceMaterialTransparency: true,
          backgroundColor: AppColors.primary,
          iconTheme: IconThemeData(color: Colors.white),
        ),
        body: Stack(
          clipBehavior: Clip.none,
          children: [
            Column(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(28),
                      topRight: Radius.circular(28),
                    ),
                    child: Container(
                      color: Colors.white,
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(20, 56, 20, 30),
                        child: Column(
                          children: [
                            const Text(
                              "دلتا لتكنولوجيا المصاعد والتجارة",
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF1A1A2E),
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            Container(
                              width: 60,
                              height: 3,
                              decoration: BoxDecoration(
                                color: Color(0xFFF37021),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(height: 20),
                            const Text(
                              _description,
                              style: TextStyle(
                                fontSize: 15,
                                color: Color(0xFF555555),
                                height: 1.8,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 32),
                            const Text(
                              "تواصل معنا",
                              style: TextStyle(
                                fontSize: 14,
                                color: Color(0xFF888888),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: List.generate(
                                socialIcons.length,
                                (i) => _buildSocialIcon(i),
                              ),
                            ),
                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Positioned(
              top: iconTop,
              left: 0,
              right: 0,
              child: Center(child: _floatingIconCircle()),
            ),
          ],
        ),
      ),
    );
  }
}
