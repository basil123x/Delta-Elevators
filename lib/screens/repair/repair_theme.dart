import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

/// Shared visual tokens for repair flow screens.
class RepairTheme {
  RepairTheme._();

  static const orange = Color(0xFFF37021);
  static const bg = Color(0xFFF2F3F7);
  static const cardBg = Color(0xFFFFFFFF);
  static const border = Color(0xFFEBEBEB);
  static const textPrimary = Color(0xFF1A1A2E);
  static const textSecondary = Color(0xFF888888);
  static const hint = Color(0xFFAAAAAA);

  static const cardShadow = BoxShadow(
    color: Color(0x0D000000),
    blurRadius: 8,
    offset: Offset(0, 2),
  );

  static const primaryGradient = LinearGradient(
    colors: [Color(0xFFF37021), Color(0xFFFF8C00)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static TextStyle cairo({
    double fontSize = 14,
    FontWeight fontWeight = FontWeight.w400,
    Color color = textPrimary,
    FontStyle? fontStyle,
    double? height,
  }) {
    return GoogleFonts.cairo(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      fontStyle: fontStyle,
      height: height,
    );
  }

  static BoxDecoration cardDecoration({double radius = 16}) {
    return BoxDecoration(
      color: cardBg,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: border),
      boxShadow: const [cardShadow],
    );
  }

  static Widget orangeHeader({
    required BuildContext context,
    required String title,
    bool showBack = true,
    VoidCallback? onBack,
    Widget? bottom,
  }) {
    final topPad = MediaQuery.paddingOf(context).top;
    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: const BoxDecoration(
        color: orange,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      padding: EdgeInsets.fromLTRB(16, topPad + 12, 16, 28),
      child: Column(
        children: [
          Row(
            children: [
              if (showBack)
                GestureDetector(
                  onTap: onBack ?? () => Navigator.maybePop(context),
                  child: const Icon(
                    Iconsax.arrow_right_3,
                    color: Colors.white,
                    size: 22,
                  ),
                )
              else
                const SizedBox(width: 22),
              Expanded(
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  style: cairo(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 22),
            ],
          ),
          if (bottom != null) ...[
            const SizedBox(height: 16),
            bottom,
          ],
        ],
      ),
    );
  }

  static Widget primaryButton({
    required String label,
    VoidCallback? onTap,
    bool loading = false,
    Widget? loadingChild,
    IconData? icon,
    Color? backgroundColor,
    Gradient? gradient,
  }) {
    final enabled = onTap != null;
    return GestureDetector(
      onTap: enabled && !loading ? onTap : null,
      child: Container(
        height: 56,
        width: double.infinity,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          gradient: enabled
              ? (gradient ?? primaryGradient)
              : null,
          color: enabled ? null : const Color(0xFFBDBDBD),
          borderRadius: BorderRadius.circular(16),
          boxShadow: enabled && gradient == null && backgroundColor == null
              ? [
                  BoxShadow(
                    color: orange.withOpacity(0.4),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ]
              : null,
        ),
        alignment: Alignment.center,
        child: loading
            ? (loadingChild ??
                const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2.5,
                  ),
                ))
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(icon, color: Colors.white, size: 22),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    label,
                    style: cairo(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  static Widget gradientButton({
    required String label,
    required List<Color> colors,
    VoidCallback? onTap,
    IconData? icon,
    double height = 48,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: height,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: colors),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: colors.first.withOpacity(0.35),
              blurRadius: 12,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(width: 8),
            ],
            Text(
              label,
              style: cairo(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget infoTile({
    required IconData icon,
    required String label,
    required String value,
    Color iconColor = orange,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: cardDecoration(radius: 12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  label,
                  style: cairo(fontSize: 12, color: textSecondary),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  textAlign: TextAlign.right,
                  style: cairo(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
