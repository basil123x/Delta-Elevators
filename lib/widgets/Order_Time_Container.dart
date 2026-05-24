import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFF5C6BC0); // بنفسجي مثل الـ mockup
  static const Color doneColor = Color(0xFF4CAF82); // أخضر
  static const Color grayColor = Color(0xFF9E9E9E);
  static const Color pendingBg = Color(0xFFF5F5F5);
  static const Color doneBg = Color(0xFFEDF7F2);
}

class OrderTimeContainer extends StatelessWidget {
  const OrderTimeContainer({super.key});
  

  @override
  Widget build(BuildContext context) {
    
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: AppColors.doneColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.doneColor.withOpacity(0.2),
          width: 1,
        ),
      ),
    );
  }
}