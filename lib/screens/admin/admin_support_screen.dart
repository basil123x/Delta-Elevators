import 'package:Delta/constants/admin_manager_contact.dart';
import 'package:Delta/screens/repair/repair_theme.dart';
import 'package:Delta/screens/settings/About/contact_menu.dart';
import 'package:flutter/material.dart';
import 'package:flutter_boxicons/flutter_boxicons.dart';
import 'package:iconsax/iconsax.dart';

class AdminSupportScreen extends StatelessWidget {
  const AdminSupportScreen({super.key});

  static const _green = Color(0xFF25D366);

  Future<void> _call() => UrlHelper.openPhone(AdminManagerContact.phone);

  Future<void> _whatsapp() => UrlHelper.openWhatsApp(
        AdminManagerContact.phone,
        'مرحباً، أحتاج الدعم الفني بخصوص التطبيق / مهمة ميدانية.',
      );

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: RepairTheme.bg,
        body: Column(
          children: [
            RepairTheme.orangeHeader(context: context, title: 'الدعم الفني'),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 22, 16, 28),
                children: [
                  Center(
                    child: Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF0E5),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(
                        Iconsax.headphone,
                        size: 34,
                        color: RepairTheme.orange,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'تواصل مع الإدارة',
                    textAlign: TextAlign.center,
                    style: RepairTheme.cairo(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'اتصال أو واتساب مع المسؤول مباشرة',
                    textAlign: TextAlign.center,
                    style: RepairTheme.cairo(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: RepairTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 22),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: RepairTheme.cardDecoration(radius: 18),
                    child: Row(
                      children: [
                        const CircleAvatar(
                          radius: 30,
                          backgroundColor: Color(0xFFFFF0E5),
                          child: Icon(
                            Iconsax.user,
                            color: RepairTheme.orange,
                            size: 26,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                AdminManagerContact.name,
                                style: RepairTheme.cairo(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                AdminManagerContact.role,
                                style: RepairTheme.cairo(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: RepairTheme.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                AdminManagerContact.phone,
                                style: RepairTheme.cairo(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: RepairTheme.orange,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _btn(
                          label: 'اتصال',
                          icon: Iconsax.call,
                          color: RepairTheme.orange,
                          bg: const Color(0xFFFFF0E5),
                          onTap: _call,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _btn(
                          label: 'واتساب',
                          icon: Boxicons.bxl_whatsapp,
                          color: _green,
                          bg: const Color(0xFFEDFAF4),
                          onTap: _whatsapp,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _btn({
    required String label,
    required IconData icon,
    required Color color,
    required Color bg,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: RepairTheme.cairo(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
