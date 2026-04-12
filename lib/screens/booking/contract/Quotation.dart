import 'package:Delta/constants/app_colors.dart';
import 'package:Delta/screens/booking/contract/QuantityWidget.dart';
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
  

  @override
  Widget build(BuildContext context) {
    print(widget.bookDets);
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text("إضافة عدد الطوابق (الوقفات)", style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 17
        ),),
        SizedBox(height: 20,),
        Stack(
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
          SizedBox(height: 50,),
          Text("إضافة عدد الركاب", style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 17
          ),),
          SizedBox(height: 20,),
          Stack(
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
          SizedBox(height: 50,),
          Visibility(
            visible: widget.bookDets[0]['stb'] == '1' ? true : false,
            child: Container(
                width: double.maxFinite,
                margin: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                padding: EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.primary, width: 3),
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child:  Text(
                        "في إنتظار الرد من الشركة",
                        style: TextStyle(fontSize: 20, color: Colors.black),
                      ),
              ),
          ),
          Visibility(
            visible: widget.bookDets[0]['stb'] == '0' ? true : false,
            child: GestureDetector(
              onTap: () async {
                await Dio().post("https://daltalifts.com/app2026/sql.php?k=${DateTime.now().millisecondsSinceEpoch}", data: {
                  "action": "updateCounterRequest",
                  "bookId": widget.bookDets[0]['id'].toString(),
                  "floors": floors.toString(),
                  "persons": persons.toString(),
                  "stb": "1"
                });
              },
              child: Container(
                  width: double.maxFinite,
                  margin: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  padding: EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  alignment: Alignment.center,
                  child:  Text(
                          "إرسال الطلب",
                          style: TextStyle(fontSize: 20, color: Colors.white),
                        ),
                ),
            ),
          ),
          Visibility(
            visible: widget.bookDets[0]['stb'] == '1' || widget.bookDets[0]['stb'] == '0' ? false : true,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                GestureDetector(
                  onTap: () async {
                    var result =  await Dio().post("https://daltalifts.com/app2026/sql.php?k=${DateTime.now().millisecondsSinceEpoch}", data: {
                      "action": "updateCounterRequest",
                      "bookId": widget.bookDets[0]['id'].toString(),
                      "floors": floors.toString(),
                      "persons": persons.toString(),
                      "stb": "3"
                    });
                    if (result.data['success'] == true) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("تم إرسال موافقتك , في إنتظار الشركة"), backgroundColor: AppColors.success,));
                      await sendToTelegram("3");
                      await Dio().post("https://daltalifts.com/app2026/sql.php?k=${DateTime.now().millisecondsSinceEpoch}", data: {
                        "action": "updateQuotationStx",
                        "bookId": widget.bookDets[0]['id'].toString(),
                        "stx": "2"
                      });
                    }
                  },
                  child: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: Icon(
                      Iconsax.tick_circle,
                      color: AppColors.primary,
                      size: 26,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () async {
                    var result = await Dio().post("https://daltalifts.com/app2026/sql.php?k=${DateTime.now().millisecondsSinceEpoch}", data: {
                      "action": "updateCounterRequest",
                      "bookId": widget.bookDets[0]['id'].toString(),
                      "floors": floors.toString(),
                      "persons": persons.toString(),
                      "stb": "4"
                    });
                    if (result.data['success'] == true) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("تم إرسال رفضك على الطلب"), backgroundColor: AppColors.error,));
                      await sendToTelegram("4");
                    }
                  },
                  child: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: Icon(
                      Iconsax.close_circle,
                      color: AppColors.primary,
                      size: 26,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () async {
                    var result = await Dio().post("https://daltalifts.com/app2026/sql.php?k=${DateTime.now().millisecondsSinceEpoch}", data: {
                      "action": "updateCounterRequest",
                      "bookId": widget.bookDets[0]['id'].toString(),
                      "floors": floors.toString(),
                      "persons": persons.toString(),
                      "stb": "5"
                    });
                    if (result.data['success'] == true) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("تم إرسال طلب إستفسار إلى الشركة"), backgroundColor: AppColors.warning,));
                      await sendToTelegram("5");
                    }
                  },
                  child: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: Icon(
                      Iconsax.message,
                      color: AppColors.primary,
                      size: 26,
                    ),
                  ),
                ),
              ],
            ),
          )
      ],
    );
  }
}