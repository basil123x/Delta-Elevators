
import 'package:Delta/screens/settings/About/contact_menu.dart';
import 'package:flutter/material.dart';
import 'package:flutter_boxicons/flutter_boxicons.dart';
import 'package:iconsax/iconsax.dart';

class SalesScreen extends StatefulWidget {
  const SalesScreen({super.key});

  @override
  State<SalesScreen> createState() => _SalesScreenState();
}

class _SalesScreenState extends State<SalesScreen> {
  static const Color _orange = Color(0xFFF37021);
  static const Color _bg = Color(0xFFF2F3F7);
  static const Color _textDark = Color(0xFF1A1A2E);
  static const Color _textSecondary = Color(0xFF888888);
  static const Color _border = Color(0xFFEBEBEB);
  static const Color _green = Color(0xFF22C55E);
  static const Color _greenBg = Color(0xFFF0FFF4);

  TextEditingController userController = TextEditingController();
  TextEditingController mobileController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  GlobalKey<FormState> formkey = GlobalKey<FormState>();
  List<Map<String, dynamic>> salesMan = [
    {"name": "محمد رأفت", "mobile": "30006374"},
    {"name": "خالد", "mobile": "33856188"},
    {"name": "نور", "mobile": "30006532"},
    {"name": "فراس الابراهيم", "mobile": "66691206"},
  ];

  bool isLoading = false;

  String _initials(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return '?';
    return trimmed.characters.first;
  }

  Widget _floatingIconCircle() {
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFFFFF0E5),
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: const Icon(
        Iconsax.chart_2,
        color: _orange,
        size: 32,
      ),
    );
  }

  Widget _buildHeader() {
    final topPad = MediaQuery.paddingOf(context).top;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(8, topPad + 8, 8, 52),
      decoration: const BoxDecoration(
        color: _orange,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.maybePop(context),
            icon: const Icon(
              Iconsax.arrow_right_3,
              color: Colors.white,
              size: 22,
            ),
          ),
          const Expanded(
            child: Text(
              'قسم المبيعات',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildSalesCard(Map<String, dynamic> person) {
    final name = person['name'].toString();
    final mobile = person['mobile'].toString();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text(
                        'الإسم',
                        style: TextStyle(
                          fontSize: 12,
                          color: _textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: _textDark,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Iconsax.call,
                            size: 14,
                            color: _textSecondary,
                          ),
                          const SizedBox(width: 4),
                          const Text(
                            'الهاتف',
                            style: TextStyle(
                              fontSize: 12,
                              color: _textSecondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        mobile,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: _textDark,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                Container(
                  width: 52,
                  height: 52,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFFFFF0E5),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    _initials(name),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: _orange,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFF5F5F5)),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      UrlHelper.openPhone(mobile);
                    },
                    child: Container(
                      height: 44,
                      decoration: BoxDecoration(
                        color: _greenBg,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Iconsax.call, color: _green, size: 18),
                          SizedBox(width: 6),
                          Text(
                            'اتصال',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: _green,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      UrlHelper.openWhatsApp(
                        mobile.trim(),
                        "مرحبا قسم المبيعات",
                      );
                    },
                    child: Container(
                      height: 44,
                      decoration: BoxDecoration(
                        color: _greenBg,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Boxicons.bxl_whatsapp,
                            color: _green,
                            size: 20,
                          ),
                          SizedBox(width: 6),
                          Text(
                            'واتساب',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: _green,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _orange,
        body: Form(
          key: formkey,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Column(
                children: [
                  _buildHeader(),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(28),
                        topRight: Radius.circular(28),
                      ),
                      child: Container(
                        width: double.infinity,
                        color: _bg,
                        child: ListView.separated(
                          padding:
                              const EdgeInsets.fromLTRB(16, 50, 16, 24),
                          itemCount: salesMan.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, i) =>
                              _buildSalesCard(salesMan[i]),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              Positioned(
                top: MediaQuery.paddingOf(context).top + 72,
                left: 0,
                right: 0,
                child: Center(child: _floatingIconCircle()),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
