import 'package:Delta/constants/app_colors.dart';
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
        backgroundColor: Colors.white,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Column(
              children: [
                SizedBox(height: 50),
                SvgPicture.asset('assets/img/icons/contract.svg'),
                SizedBox(height: 30),
                Text(
                  "تم تقديم الطلب بالفعل",
                  style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 20),
                Text(
                  "لقد قمت بتقديم الطلب بالفعل و سيتم الرد عليك خلال 48 ساعة لمعرفة كافة التفاصيل وشكرا لاستخدامك تطبيق دلتا",
                  style: TextStyle(fontSize: 20),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
        floatingActionButton: GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => SalesScreen()),
            );
          },
          child: Container(
            width: double.maxFinite,
            height: 60,
            margin: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            padding: EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: Text(
              "تواصل مع قسم المبيعات",
              style: TextStyle(fontSize: 20, color: Colors.white),
            ),
          ),
        ),
      ),
    );
  }
}
