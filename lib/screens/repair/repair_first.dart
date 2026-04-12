import 'package:Delta/constants/app_colors.dart';
import 'package:Delta/screens/repair/repair_contract.dart';
import 'package:Delta/screens/repair/repair_screen.dart';
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
  String selectCard = "من تختار ؟";

  Future getSharedSettings() async {
    
    SharedPreferences prefx = await SharedPreferences.getInstance();
    // prefx.remove("currentCard");
    int? curcx = prefx.getInt("currentCard");
    if (curcx != null) {
      if (curcx == 1) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => RepairScreen()));
      } else {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => RepairContract()));
      }
    }
  }

  @override
  void initState() {
    getSharedSettings();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          "إختر من يريد طلب الصيانة",
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Container(
        margin: EdgeInsets.all(20),
        child: Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    currentCard = 2;
                    selectCard = "عميل جديد";
                  });
                },
                child: Container(
                  height: 190,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: currentCard == 2 ? AppColors.success : AppColors.primary, width: 3),
                  ),
                  child: Center(child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Iconsax.user_add, size: 60,),
                      SizedBox(height: 17,),
                      Text("عميل جديد", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),)
                    ],
                  )),
                ),
              ),
            ),
            SizedBox(width: 10),
            Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    currentCard = 1;
                    selectCard = "عميل دلتا";
                  });
                },
                child: Container(
                  height: 190,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: currentCard == 1 ? AppColors.success : AppColors.primary, width: 3),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset('assets/img/brand_logo_big.png', width: 80,),
                        SizedBox(height: 14,),
                        Text("عملاء دلتا", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),)
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: GestureDetector(
        onTap: () async {
          SharedPreferences prefx = await SharedPreferences.getInstance();
          prefx.setInt("currentCard", currentCard);
          if (currentCard == 1) {
            Navigator.push(context, MaterialPageRoute(builder: (context) => RepairScreen()));
          } else {
            Navigator.push(context, MaterialPageRoute(builder: (context) => RepairContract()));
          }
          setState(() {});
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
            selectCard,
            style: TextStyle(fontSize: 18, color: Colors.white),
          ),
        ),
      ),
    );
  }
}
