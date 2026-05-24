
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
  List<Map<dynamic, dynamic>> socialIcons = [
    {"icon": Boxicons.bx_envelope},
    {"icon": Boxicons.bxl_facebook},
    {"icon": Boxicons.bxl_instagram},
    {"icon": Boxicons.bxl_snapchat},
  ];

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
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
          children: [
            Positioned(
              top: screenHeight * 0.18,
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(25),
                    topRight: Radius.circular(25),
                  ),
                ),
                padding: EdgeInsets.symmetric(horizontal: 10),
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      SizedBox(height: 50),
                      // ===== Grid الأيقونات =====
                      Text(
                        "دلتا لتكنولوجيا المصاعد والتجارة",
                        style: TextStyle(
                          fontSize: 27,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 20),
                      Text(
                        "شركة دلتا هي شركة متخصصة في تقديم حلول مبتكرة ومتطورة في مجالات التكنولوجيا والخدمات الرقمية. تسعى دلتا دائمًا إلى تمكين الأفراد والشركات من خلال توفير تقنيات حديثة تُسهم في تحسين الكفاءة وزيادة الإنتاجية. من خلال التركيز على الجودة والإبداع، تلتزم دلتا بتقديم أفضل المنتجات والخدمات التي تلبي احتياجات عملائها وتساعدهم على تحقيق أهدافهم بنجاح. سواء كان ذلك من خلال تطوير البرمجيات، تقديم الاستشارات التقنية، أو توفير الحلول الذكية، دلتا دائماً في المقدمة.",
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 100,),
                      Container(
                        margin: EdgeInsets.only(bottom: 20),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: List.generate(socialIcons.length, (i) {
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
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(50),
                                ),
                                child: Icon(
                                  socialIcons[i]['icon'],
                                  color: AppColors.primary,
                                  size: 26,
                                ),
                              ),
                            );
                          }),
                        ),
                      ),
                    ],
                    
                  ),
                ),
              ),
            ),

            // ===== صورة البروفايل في المنتصف =====
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
                        child: Icon(
                          Iconsax.info_circle,
                          size: 30,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
