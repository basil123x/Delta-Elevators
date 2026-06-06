import 'package:Delta/constants/app_colors.dart';
import 'package:Delta/screens/booking/contract/QuantityWidget.dart';
import 'package:Delta/screens/booking/contract/contract_theme.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

class QuotationScreen extends StatefulWidget {
  final List bookDets;
  const QuotationScreen({super.key, required this.bookDets});

  @override
  State<QuotationScreen> createState() => _QuotationScreenState();
}

class _QuotationScreenState extends State<QuotationScreen> {
  int floors = 0;
  int persons = 0;
  bool _isLoading = false;
  int? _actionLoading;

  Future<void> sendToTelegram(String status) async {
    const String botToken = '8499367531:AAEnMG1yvNeAIanEgCbyYGlXWuYWImeTMyI';
    const String chatId = '-1003877690157';

    final Map<String, String> statusMap = {
      "1": "✅ موافقة على الطلب",
      "2": "❌ رفض الطلب",
      "3": "💬 طلب استفسار",
    };

    await Dio().post(
      'https://api.telegram.org/bot$botToken/sendMessage',
      queryParameters: {
        'chat_id': chatId,
        'parse_mode': 'HTML',
        'text': """
  🛗 <b>تحديث طلب عرض سعر</b>

  📋 <b>رقم الطلب:</b> ${widget.bookDets[0]['id']}
  ${statusMap[status]}

  🏢 <b>تفاصيل المصعد:</b>
  إسم العميل: ${widget.bookDets[0]['a1']}
  رقم هاتف العميل: ${widget.bookDets[0]['a2']}
  🔢 عدد الوقفات: $floors طابق
  👥 عدد الركاب: $persons شخص
  """,
      },
    );
  }

  @override
  void initState() {
    super.initState();
    setState(() {
      floors = int.parse(widget.bookDets[0]['floors']);
      persons = int.parse(widget.bookDets[0]['persons']);
    });
  }

  Widget _sectionCard({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: ContractTheme.cardDecoration(),
      child: Column(
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 16,
              color: ContractTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _actionSpinner(Color color) {
    return SizedBox(
      width: 18,
      height: 18,
      child: CircularProgressIndicator(color: color, strokeWidth: 2.5),
    );
  }

  @override
  Widget build(BuildContext context) {
    print(widget.bookDets);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _sectionCard(
            title: "إضافة عدد الطوابق (الوقفات)",
            child: Stack(
              children: [
                QuantityCounter(
                  key: ValueKey('floors_$floors'),
                  initialValue: floors,
                  min: 0,
                  max: 99,
                  onChanged: (val) {
                    setState(() {
                      floors = val;
                    });
                  },
                ),
                Positioned(
                  top: 0,
                  left: 0,
                  child: Visibility(
                    visible: widget.bookDets[0]['stb'] != '0' ? true : false,
                    child: Container(
                      width: 200,
                      height: 200,
                      color: Colors.white60,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _sectionCard(
            title: "إضافة عدد الركاب",
            child: Stack(
              children: [
                QuantityCounter(
                  key: ValueKey('persons_$persons'),
                  initialValue: persons,
                  min: 0,
                  max: 99,
                  onChanged: (val) {
                    setState(() {
                      persons = val;
                    });
                  },
                ),
                Positioned(
                  top: 0,
                  left: 0,
                  child: Visibility(
                    visible: widget.bookDets[0]['stb'] != '0' ? true : false,
                    child: Container(
                      width: 200,
                      height: 200,
                      color: Colors.white60,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Visibility(
            visible: widget.bookDets[0]['stb'] == '1' ? true : false,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: ContractTheme.cardDecoration(),
              alignment: Alignment.center,
              child: const Text(
                "في إنتظار الرد من الشركة",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: ContractTheme.textPrimary,
                ),
              ),
            ),
          ),
          Visibility(
            visible: widget.bookDets[0]['stb'] == '0' ? true : false,
            child: GestureDetector(
              onTap: () async {
                if (_isLoading) return;
                setState(() => _isLoading = true);
                try {
                  await Dio().post(
                      "https://daltalifts.com/app2026/sql.php?k=${DateTime.now().millisecondsSinceEpoch}",
                      data: {
                        "action": "updateCounterRequest",
                        "bookId": widget.bookDets[0]['id'].toString(),
                        "floors": floors.toString(),
                        "persons": persons.toString(),
                        "stb": "1"
                      });
                } finally {
                  if (mounted) setState(() => _isLoading = false);
                }
              },
              child: Container(
                width: double.infinity,
                height: 56,
                decoration: ContractTheme.primaryGradientButton(),
                alignment: Alignment.center,
                child: _isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    : const Text(
                        "إرسال الطلب",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ),
          Visibility(
            visible: widget.bookDets[0]['stb'] == '1' ||
                    widget.bookDets[0]['stb'] == '0'
                ? false
                : true,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                GestureDetector(
                  onTap: () async {
                    if (_isLoading || _actionLoading != null) return;
                    setState(() => _actionLoading = 5);
                    try {
                      var result = await Dio().post(
                          "https://daltalifts.com/app2026/sql.php?k=${DateTime.now().millisecondsSinceEpoch}",
                          data: {
                            "action": "updateCounterRequest",
                            "bookId": widget.bookDets[0]['id'].toString(),
                            "floors": floors.toString(),
                            "persons": persons.toString(),
                            "stb": "5"
                          });
                      if (result.data['success'] == true) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content:
                                Text("تم إرسال طلب إستفسار إلى الشركة"),
                            backgroundColor: AppColors.warning));
                        await sendToTelegram("5");
                      }
                    } finally {
                      if (mounted) setState(() => _actionLoading = null);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF0E5),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFFFD5B5)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _actionLoading == 5
                            ? _actionSpinner(const Color(0xFFF37021))
                            : const Icon(Iconsax.message,
                                color: Color(0xFFF37021), size: 18),
                        const SizedBox(width: 6),
                        const Text("رسالة",
                            style: TextStyle(
                                color: Color(0xFFF37021),
                                fontWeight: FontWeight.w700,
                                fontSize: 13)),
                      ],
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () async {
                    if (_isLoading || _actionLoading != null) return;
                    setState(() => _actionLoading = 4);
                    try {
                      var result = await Dio().post(
                          "https://daltalifts.com/app2026/sql.php?k=${DateTime.now().millisecondsSinceEpoch}",
                          data: {
                            "action": "updateCounterRequest",
                            "bookId": widget.bookDets[0]['id'].toString(),
                            "floors": floors.toString(),
                            "persons": persons.toString(),
                            "stb": "4"
                          });
                      if (result.data['success'] == true) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text("تم إرسال رفضك على الطلب"),
                            backgroundColor: AppColors.error));
                        await sendToTelegram("4");
                      }
                    } finally {
                      if (mounted) setState(() => _actionLoading = null);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF0F0),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFFFCCCC)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _actionLoading == 4
                            ? _actionSpinner(const Color(0xFFEF4444))
                            : const Icon(Iconsax.close_circle,
                                color: Color(0xFFEF4444), size: 18),
                        const SizedBox(width: 6),
                        const Text("رفض",
                            style: TextStyle(
                                color: Color(0xFFEF4444),
                                fontWeight: FontWeight.w700,
                                fontSize: 13)),
                      ],
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () async {
                    if (_isLoading || _actionLoading != null) return;
                    setState(() => _actionLoading = 3);
                    try {
                      var result = await Dio().post(
                          "https://daltalifts.com/app2026/sql.php?k=${DateTime.now().millisecondsSinceEpoch}",
                          data: {
                            "action": "updateCounterRequest",
                            "bookId": widget.bookDets[0]['id'].toString(),
                            "floors": floors.toString(),
                            "persons": persons.toString(),
                            "stb": "3"
                          });
                      if (result.data['success'] == true) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text(
                                "تم إرسال موافقتك , في إنتظار الشركة"),
                            backgroundColor: AppColors.success));
                        await sendToTelegram("3");
                        await Dio().post(
                            "https://daltalifts.com/app2026/sql.php?k=${DateTime.now().millisecondsSinceEpoch}",
                            data: {
                              "action": "updateQuotationStx",
                              "bookId": widget.bookDets[0]['id'].toString(),
                              "stx": "2"
                            });
                      }
                    } finally {
                      if (mounted) setState(() => _actionLoading = null);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                          colors: [Color(0xFFF37021), Color(0xFFFF8C00)]),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: const [
                        BoxShadow(color: Color(0x33F37021), blurRadius: 8)
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _actionLoading == 3
                            ? _actionSpinner(Colors.white)
                            : const Icon(Iconsax.tick_circle,
                                color: Colors.white, size: 18),
                        const SizedBox(width: 6),
                        const Text("موافقة",
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 13)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
