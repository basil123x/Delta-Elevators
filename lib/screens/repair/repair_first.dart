import 'package:Delta/screens/repair/repair_contract.dart';
import 'package:Delta/screens/repair/repair_screen.dart';
import 'package:Delta/screens/repair/repair_theme.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RepairFirst extends StatefulWidget {
  const RepairFirst({super.key});

  @override
  State<RepairFirst> createState() => _RepairFirstState();
}

class _RepairFirstState extends State<RepairFirst> {
  int currentCard = 0;
  String selectCard = "من تختار؟";

  Future getSharedSettings() async {
    SharedPreferences prefx = await SharedPreferences.getInstance();
    int? curcx = prefx.getInt("currentCard");
    if (curcx != null) {
      if (curcx == 1) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => RepairScreen()),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => RepairContract()),
        );
      }
    }
  }

  @override
  void initState() {
    getSharedSettings();
    super.initState();
  }

  Widget _selectionCard({
    required int cardId,
    required String label,
    required Widget icon,
  }) {
    final selected = currentCard == cardId;
    return GestureDetector(
      onTap: () {
        setState(() {
          currentCard = cardId;
          selectCard = cardId == 1 ? "عملاء دلتا" : "عميل جديد";
        });
      },
      child: Container(
        decoration: BoxDecoration(
          color: RepairTheme.cardBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? RepairTheme.orange : RepairTheme.border,
            width: selected ? 2 : 1,
          ),
          boxShadow: const [RepairTheme.cardShadow],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            icon,
            const SizedBox(height: 12),
            Text(
              label,
              style: RepairTheme.cairo(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: RepairTheme.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: RepairTheme.bg,
        body: Column(
          children: [
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Color(0xFFF37021),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(28),
                  bottomRight: Radius.circular(28),
                ),
              ),
              padding: EdgeInsets.fromLTRB(
                16,
                MediaQuery.paddingOf(context).top + 12,
                16,
                28,
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.maybePop(context),
                    child: const Icon(
                      Iconsax.arrow_right_3,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      "إختر من يريد طلب الصيانة",
                      textAlign: TextAlign.center,
                      style: RepairTheme.cairo(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 22),
                ],
              ),
            ),
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 160,
                          child: _selectionCard(
                            cardId: 2,
                            label: "عميل جديد",
                            icon: const Icon(
                              Iconsax.user_add,
                              size: 48,
                              color: RepairTheme.orange,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: SizedBox(
                          height: 160,
                          child: _selectionCard(
                            cardId: 1,
                            label: "عملاء دلتا",
                            icon: Image.asset(
                              'assets/img/brand_logo_big.png',
                              width: 48,
                              height: 48,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SafeArea(
              top: false,
              child: RepairTheme.primaryButton(
                label: selectCard,
                onTap: currentCard == 0
                    ? null
                    : () async {
                        SharedPreferences prefx =
                            await SharedPreferences.getInstance();
                        prefx.setInt("currentCard", currentCard);
                        if (currentCard == 1) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => RepairScreen(),
                            ),
                          );
                        } else {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => RepairContract(),
                            ),
                          );
                        }
                        setState(() {});
                      },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
