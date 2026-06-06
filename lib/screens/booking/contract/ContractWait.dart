import 'package:Delta/screens/booking/contract/contract_theme.dart';
import 'package:Delta/screens/settings/Sales/SalesScreen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class ContractWait extends StatefulWidget {
  const ContractWait({super.key});

  @override
  State<ContractWait> createState() => _ContractWaitState();
}

class _ContractWaitState extends State<ContractWait> {
  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: ContractTheme.bg,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SvgPicture.asset('assets/img/icons/contract.svg'),
                const SizedBox(height: 24),
                const Text(
                  "تم تقديم الطلب بالفعل",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: ContractTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  "لقد قمت بتقديم الطلب بالفعل و سيتم الرد عليك خلال 48 ساعة لمعرفة كافة التفاصيل وشكرا لاستخدامك تطبيق دلتا",
                  style: TextStyle(
                    fontSize: 15,
                    color: ContractTheme.textSecondary,
                    height: 1.6,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => SalesScreen()),
                );
              },
              child: Container(
                height: 56,
                decoration: ContractTheme.primaryGradientButton(),
                alignment: Alignment.center,
                child: const Text(
                  "تواصل مع قسم المبيعات",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
