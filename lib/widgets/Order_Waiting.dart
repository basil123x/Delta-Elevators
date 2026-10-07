import 'package:Delta/widgets/CustomCheckbox.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

class OrderWaiting extends StatefulWidget {
  final String bookId;
  const OrderWaiting({super.key, required this.bookId});

  @override
  State<OrderWaiting> createState() => _OrderWaitingState();
}

class _OrderWaitingState extends State<OrderWaiting> {
  List bookStat = [];
  bool isEnter = false;

  Future getBookingStatus() async {
    var request = await Dio().post(
      "https://daltalifts.com/app2026/sql.php?k=${DateTime.now().millisecondsSinceEpoch}",
      data: {"action": "getEnterClient", "bookId": widget.bookId},
    );
    setState(() {
      bookStat = request.data['data'];
    });
  }

  Future<void> sendToTelegram() async {
    const String botToken = '8499367531:AAEnMG1yvNeAIanEgCbyYGlXWuYWImeTMyI';
    const String chatId = '-1003877690157';

    final message =
        """
      ⚡️ *إعلام دخول الكهرباء*

      ✅ تم توصيل الكهرباء

      👤 *المالك:* ${bookStat[0]['a1']}
      📋 *رقم الطلب:* ${widget.bookId}

      يرجى المتابعة لتشغيل المصعد في أقرب وقت 🔧
      """;

    await Dio().post(
      'https://api.telegram.org/bot$botToken/sendMessage',
      queryParameters: {
        'chat_id': chatId,
        'parse_mode': 'HTML',
        'text': message,
      },
    );
  }

  @override
  void initState() {
    super.initState();
    getBookingStatus();
  }

  @override
  Widget build(BuildContext context) {
    switch (bookStat[0]['enter']) {
      case 'true':
        isEnter = true;
        break;
      case 'false':
        isEnter = false;
        break;
      default:
    }
    return CustomCheckbox(
      label: "إعلام دخول الكهرباء",
      initialValue: isEnter,
      onChanged: (val) async {
        await Dio().post(
          "https://daltalifts.com/app2026/sql.php?k=${DateTime.now().millisecondsSinceEpoch}",
          data: {
            "action": "updateEnterClient",
            "bookId": widget.bookId,
            "enter": val.toString(),
          },
        );
        if (val == true) {
          await sendToTelegram();
        }
      },
    );
  }
}
