import 'package:Delta/constants/admin_manager_contact.dart';
import 'package:Delta/screens/repair/repair_theme.dart';
import 'package:Delta/screens/settings/About/contact_menu.dart';
import 'package:flutter/material.dart';
import 'package:flutter_boxicons/flutter_boxicons.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

/// Technician → management contact (call + WhatsApp only, no in-app chat).
/// Manager details live in [AdminManagerContact] — intentionally static.
class AdminContactScreen extends StatelessWidget {
  const AdminContactScreen({super.key});

  static const _orange = Color(0xFFF37021);
  static const _textPrimary = Color(0xFF1A1A2E);
  static const _bg = Color(0xFFF2F3F7);
  static const _green = Color(0xFF25D366);

  // TODO: Replace these placeholder FAQ answers with real ops content.
  static const _faqs = <Map<String, String>>[
    {
      'q': 'إزاي أقفل تذكرة صيانة؟',
      'a':
          'من شاشة مهامي افتح التذكرة، أكمل خطوات العمل المطلوبة، ثم حدّث الحالة إلى مكتملة بعد التأكد من إنهاء المهمة في الموقع.',
    },
    {
      'q': 'إزاي أطلب قطعة غيار؟',
      'a':
          'من شاشة المخزون وقطع الغيار ابحث بالكود أو الاسم وتأكد من الصنف. لو القطعة غير متوفرة تواصل مع الإدارة من هذه الشاشة.',
    },
    {
      'q': 'مين المسؤول عن اعتماد بلاغاتي؟',
      'a':
          'البلاغات تصل للإدارة عبر التطبيق وتيليجرام. المشرف/الإدارة يراجعون البلاغ ويتابعون معك عند الحاجة.',
    },
    {
      'q': 'حصل عطل طارئ في الموقع، أعمل إيه؟',
      'a':
          'أمّن الموقع أولاً، ثم أبلغ من شاشة الإبلاغ عن مشكلة واختر «مشكلة أمان/خطورة بالموقع»، واتصل مباشرة بالإدارة من الأزرار أعلاه.',
    },
  ];

  Future<void> _call() async {
    await UrlHelper.openPhone(AdminManagerContact.phone);
  }

  Future<void> _whatsapp() async {
    await UrlHelper.openWhatsApp(
      AdminManagerContact.phone,
      'مرحباً، أحتاج التواصل مع الإدارة بخصوص مهمة ميدانية.',
    );
  }

  Widget _actionButton({
    required String label,
    required IconData icon,
    required Color color,
    required Color bg,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 48,
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
                style: GoogleFonts.cairo(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _bg,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          iconTheme: const IconThemeData(color: _textPrimary),
          title: Text(
            'التواصل مع الإدارة',
            style: GoogleFonts.cairo(
              color: _textPrimary,
              fontWeight: FontWeight.w800,
              fontSize: 17,
            ),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: _orange.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(Iconsax.call, size: 34, color: _orange),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'التواصل مع الإدارة',
                textAlign: TextAlign.center,
                style: GoogleFonts.cairo(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: _textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'تواصل مباشر مع المسؤول',
                textAlign: TextAlign.center,
                style: GoogleFonts.cairo(
                  fontSize: 13,
                  color: Colors.black.withValues(alpha: 0.45),
                  fontWeight: FontWeight.w600,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: RepairTheme.cardDecoration(),
                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 30,
                      backgroundColor: Color(0xFFFFF0E5),
                      child: Icon(
                        Iconsax.user,
                        color: _orange,
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
                            style: GoogleFonts.cairo(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: _textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            AdminManagerContact.role,
                            style: GoogleFonts.cairo(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: RepairTheme.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            AdminManagerContact.phone,
                            style: GoogleFonts.cairo(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: _orange,
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
                  _actionButton(
                    label: 'اتصال مباشر',
                    icon: Iconsax.call,
                    color: _orange,
                    bg: const Color(0xFFFFF0E5),
                    onTap: _call,
                  ),
                  const SizedBox(width: 10),
                  _actionButton(
                    label: 'واتساب',
                    icon: Boxicons.bxl_whatsapp,
                    color: _green,
                    bg: const Color(0xFFEDFAF4),
                    onTap: _whatsapp,
                  ),
                ],
              ),
              const SizedBox(height: 28),
              Row(
                children: [
                  Container(
                    width: 4,
                    height: 18,
                    decoration: BoxDecoration(
                      color: _orange,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'أسئلة شائعة',
                    style: GoogleFonts.cairo(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: _textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ..._faqs.map((faq) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: RepairTheme.cardDecoration(radius: 14),
                  child: Theme(
                    data: Theme.of(context).copyWith(
                      dividerColor: Colors.transparent,
                      splashColor: _orange.withValues(alpha: 0.08),
                    ),
                    child: ExpansionTile(
                      tilePadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 2,
                      ),
                      childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                      iconColor: _orange,
                      collapsedIconColor: const Color(0xFF94A3B8),
                      title: Text(
                        faq['q']!,
                        style: GoogleFonts.cairo(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: _textPrimary,
                        ),
                      ),
                      children: [
                        Text(
                          faq['a']!,
                          style: GoogleFonts.cairo(
                            fontSize: 13,
                            height: 1.7,
                            color: RepairTheme.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}
