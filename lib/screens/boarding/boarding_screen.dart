import 'package:Delta/constants/app_colors.dart';
import 'package:Delta/screens/boarding/intro_screen.dart';
import 'package:flutter/material.dart';

class BoardingScreen extends StatefulWidget {
  const BoardingScreen({super.key});

  @override
  State<BoardingScreen> createState() => _BoardingScreenState();
}

class _BoardingScreenState extends State<BoardingScreen> {
  int currentIndex = 0;
  double boardProgress = 0.0;
  PageController pageController = PageController();

  List<Map<String, dynamic>> boardingItems = [
    {
      "img": "Home",
      "title": "مرحبا بك في دلتا لتكنولوجيا المصاعد والتجارة",
      "subtitle":
          "تطبيقنا يوفر أفضل خدمات صيانة وتركيب المصاعد بأعلى معايير الجودة و الأمان بكفاءة دائمة.",
    },
    {
      "img": "repair",
      "title": "استمتع بميزات رائعة مثل الصيانة الممتازة وطلب مصعدك بسهولة",
      "subtitle":
          "يمكنك الأن طلب مصعد بتشكيلات و اشكال مختلفة و الحصور أيضاً على الصيانة بشكل سريع وفوري",
    },
    {
      "img": "order",
      "title": "تابع خطوات تركيب مصعدك بسلاسة و دقة يومياً معنا",
      "subtitle":
          "استمتع بتركيب مصعد بسلاسة مع دلتا لتكنولوجيا المصاعد والتجارة , نقدم لك خطوات يومية دقيقة لضمان التركيب المثالي",
    },
  ];
  @override
  Widget build(BuildContext context) {
    switch (currentIndex) {
      case 0:
        boardProgress = 0.2;
        break;
      case 1:
        boardProgress = 0.5;
        break;
      case 2:
        boardProgress = 1;
        break;
      default:
    }
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Column(
                children: [
                  Visibility(
                    visible: currentIndex == 2 ? false : true,
                    child: GestureDetector(
                      onTap: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => IntroScreen(),
                          ),
                        );
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                        alignment: Alignment.centerRight,
                        child: Text("تخطي"),
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  Expanded(
                    child: PageView(
                      controller: pageController,
                      onPageChanged: (val) {
                        setState(() {
                          currentIndex = val;
                        });
                      },
                      children: List.generate(boardingItems.length, (i) {
                        return Image.asset(
                          'assets/img/${boardingItems[i]['img']}.png',
                        );
                      }),
                    ),
                  ),
                ],
              ),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Directionality(
                  textDirection: TextDirection.rtl,
                  child: Container(
                    color: Colors.white,
                    width: double.maxFinite,
                    height: 300,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TweenAnimationBuilder<double>(
                          duration: const Duration(milliseconds: 500),
                          curve: Curves.easeInOut,
                          tween: Tween<double>(begin: 0, end: boardProgress),
                          builder: (context, value, _) =>
                              LinearProgressIndicator(
                                value: value,
                                backgroundColor: Colors.grey,
                                color: Colors.orange,
                              ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              Text(
                                boardingItems[currentIndex]['title'],
                                style: TextStyle(fontSize: 25),
                              ),
                              SizedBox(height: 10),
                              Text(
                                boardingItems[currentIndex]['subtitle'],
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey.shade400,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Spacer(),
                        if (currentIndex != 1)
                          GestureDetector(
                            onTap: () {
                              if (currentIndex == 0) {
                                setState(() {
                                  currentIndex = 1;
                                });
                              } else {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => IntroScreen(),
                                  ),
                                );
                              }

                              pageController.animateToPage(
                                currentIndex,
                                duration: Duration(milliseconds: 200),
                                curve: Curves.easeInOut,
                              );
                            },
                            child: Container(
                              width: double.maxFinite,
                              margin: EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 8,
                              ),
                              padding: EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                currentIndex == 2 ? "ابدأ الأن" : "التالي",
                                style: TextStyle(
                                  fontSize: 20,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        if (currentIndex == 1)
                          Row(
                            children: [
                              Expanded(
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      currentIndex = 2;
                                    });
                                    pageController.animateToPage(
                                      currentIndex,
                                      duration: Duration(milliseconds: 200),
                                      curve: Curves.easeInOut,
                                    );
                                  },
                                  child: Container(
                                    width: double.maxFinite,
                                    margin: EdgeInsets.symmetric(
                                      horizontal: 10,
                                    ),
                                    padding: EdgeInsets.symmetric(vertical: 10),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      "التالي",
                                      style: TextStyle(
                                        fontSize: 20,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      currentIndex = 0;
                                    });
                                    pageController.animateToPage(
                                      currentIndex,
                                      duration: Duration(milliseconds: 200),
                                      curve: Curves.easeInOut,
                                    );
                                  },
                                  child: Container(
                                    width: double.maxFinite,
                                    margin: EdgeInsets.symmetric(
                                      horizontal: 10,
                                    ),
                                    padding: EdgeInsets.symmetric(vertical: 10),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: AppColors.primary,
                                      ),
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      "السابق",
                                      style: TextStyle(
                                        fontSize: 20,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
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
