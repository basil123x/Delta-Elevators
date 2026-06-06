import 'package:flutter/material.dart';

class ContractTheme {
  ContractTheme._();

  static const orange = Color(0xFFF37021);
  static const bg = Color(0xFFF2F3F7);
  static const textPrimary = Color(0xFF1A1A2E);
  static const textSecondary = Color(0xFF888888);
  static const border = Color(0xFFEBEBEB);
  static const green = Color(0xFF22C55E);
  static const greenBg = Color(0xFFEDFAF4);
  static const pendingGrey = Color(0xFFE5E7EB);

  static const cardShadow = BoxShadow(
    color: Color(0x0D000000),
    blurRadius: 8,
    offset: Offset(0, 2),
  );

  static BoxDecoration cardDecoration({double radius = 16}) {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: border),
      boxShadow: const [cardShadow],
    );
  }

  static BoxDecoration primaryGradientButton({double radius = 16}) {
    return BoxDecoration(
      gradient: const LinearGradient(
        colors: [Color(0xFFF37021), Color(0xFFFF8C00)],
      ),
      borderRadius: BorderRadius.circular(radius),
      boxShadow: [
        BoxShadow(
          color: orange.withOpacity(0.4),
          blurRadius: 16,
          offset: const Offset(0, 6),
        ),
      ],
    );
  }
}
