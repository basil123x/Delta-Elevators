import 'dart:async';
import 'dart:math';

import 'package:Delta/constants/app_colors.dart';
import 'package:Delta/screens/auth/login/login_screen.dart';
import 'package:Delta/screens/main/main_screen.dart';
import 'package:Delta/services/DioServiceCert.dart';
import 'package:Delta/services/OneSignalServices.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart' as intlx;
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:pinput/pinput.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OTPScreen extends StatefulWidget {
  final String? name;
  final String? mobile;
  final int? otp;
  final String keylogin;
  const OTPScreen({
    super.key,
    this.name,
    this.mobile,
    this.otp,
    required this.keylogin,
  });

  @override
  State<OTPScreen> createState() => _OTPScreenState();
}

class _OTPScreenState extends State<OTPScreen> {
  TextEditingController otpController = TextEditingController();
  bool isLoading = false;
  int? currentOtp;
  String? mobileApple;

  Timer? _timer;
  int _secondsLeft = 120; // دقيقتان
  bool canResend = false;

  void startTimer() {
    _timer?.cancel();
    setState(() {
      _secondsLeft = 120;
      canResend = false;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_secondsLeft == 0) {
        t.cancel();
        setState(() {
          currentOtp = 0;
          canResend = true;
        });
      } else {
        setState(() => _secondsLeft--);
      }
    });
  }

  String get timerLabel {
    final m = _secondsLeft ~/ 60;
    final s = _secondsLeft % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  Future sendOTP() async {
    await getDio().post(
      'https://graph.facebook.com/v22.0/1106981455822224/messages',
      options: Options(
        headers: {
          "Authorization":
              "Bearer EAAdhZCjMZCRZBABQZBhtWgeoQcYCOzXj32zhFSLi7aELSVCWDp32TaP8pd0NNbiZChZB95UwEvQw89izAsQuQEXugIMyiqZAQT8ZAxuq0CZAk8T323L6xJdxcLyG5MybKsaO4wtR9iCZBYMAHQdUg3ZAo9ApDHCld4Y6wri7JG39JBsagQa0aqqQAHWM8BfnEJsMgZDZD",
        },
      ),
      data: {
        "messaging_product": "whatsapp",
        "to": "974${widget.mobile!.replaceAll(RegExp(r'\D'), '')}",
        "type": "template",
        "template": {
          "name": "verify_otp",
          "language": {"code": "ar"},
          "components": [
            {
              "type": "body",
              "parameters": [
                {"type": "text", "text": currentOtp.toString()},
              ],
            },
            {
              "type": "button",
              "sub_type": "url",
              "index": "0",
              "parameters": [
                {"type": "text", "text": currentOtp.toString()},
              ],
            },
          ],
        },
      },
    );
  }

  // 8499367531:AAEnMG1yvNeAIanEgCbyYGlXWuYWImeTMyI

  @override
  void initState() {
    
    if (widget.mobile == '11111111') {
      setState(() {
        currentOtp = 111111;
      });
    } else {
      currentOtp = widget.otp;
    }
    sendOTP();
    startTimer();
    super.initState();
  }

  @override
  void dispose() {
    _timer?.cancel(); // نظّف التايمر عند الخروج
    otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: Colors.white,
            automaticallyImplyLeading: true,
          ),
          extendBodyBehindAppBar: true,
          body: Center(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Image.asset('assets/img/logo.png', width: 180),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "رمز",
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        " التحقق",
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 20),
                  Text(
                    "سيصلك رمز تحقق على رقمك هذا",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                  SizedBox(height: 5),
                  Text(
                    "${widget.mobile} 974+",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                  SizedBox(height: 20),
                  Directionality(
                    textDirection: TextDirection.ltr,
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      child: Pinput(controller: otpController, length: 6),
                    ),
                  ),
                  SizedBox(height: 20),
                  Container(
                    padding: EdgeInsets.all(20),
                    child: Container(
                      alignment: Alignment.center,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text("ألم يصلك رمز التحقق ؟"),
                          SizedBox(width: 8),
                          canResend
                              ? GestureDetector(
                                  onTap: () async {
                                    setState(() {
                                      currentOtp =
                                          100000 +
                                          Random().nextInt(
                                            900000,
                                          ); // رمز جديد 6 أرقام
                                    });
                                    await sendOTP();
                                    startTimer();
                                    otpController.clear();
                                  },
                                  child: Text(
                                    "إعادة إرسال",
                                    style: TextStyle(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                )
                              : Text(
                                  timerLabel,
                                  style: TextStyle(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                        ],
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () async {
                        if (currentOtp.toString() ==
                          otpController.text.toString()) {
                        setState(() {
                          isLoading = true;
                        });
                        final playerId = OneSignal.User.pushSubscription.id;
                        if (widget.keylogin == 'Register') {
                          int uid = 1000 + Random().nextInt(9000);
                          int oid = 1000 + Random().nextInt(9000);
                          var result = await getDio().post(
                            "https://daltalifts.com/app2026/sql.php",
                            options: Options(
                              headers: {"Content-Type": "application/json"},
                            ),
                            data: {
                              "action": "register",
                              "name": widget.name,
                              "created_at": intlx.DateFormat(
                                'yyyy-MM-dd',
                              ).format(DateTime.now()).toString(),
                              "phone": widget.mobile,
                              "uid": uid,
                              "oid": oid,
                              "playerId": playerId,
                            },
                          );
                          SharedPreferences prefx =
                              await SharedPreferences.getInstance();
                          if (result.data['success'] == true) {
                            await prefx.setString("userId", uid.toString());
                            await prefx.setString("orderId", oid.toString());
                            setState(() {
                              isLoading = false;
                            });
                            List<String> playerIdsx = [];
                            var playerIds = await getDio().post(
                              "https://daltalifts.com/app2026/sql.php",
                              data: {"action": "getPlayerIds"},
                            );
                            for (
                              var i = 0;
                              i < playerIds.data['data'].length;
                              i++
                            ) {
                              playerIdsx.add(
                                playerIds.data['data'][i]['player_id'],
                              );
                            }
                            setState(() {});
                            await OneSignalNotification.sendToMultipleUsers(
                              subscriptionIds: playerIdsx,
                              title: "مستخدم جديد",
                              message: "يوجد لديك مستخدم جديد من التطبيق الأن",
                            );
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) => MainScreen(),
                              ),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text("المستخدم موجود بالفعل")),
                            );
                          }
                        } else {
                          var result = await getDio().post(
                            "https://daltalifts.com/app2026/sql.php",
                            options: Options(
                              headers: {"Content-Type": "application/json"},
                            ),
                            data: {
                              "action": "login",
                              "phone": widget.mobile,
                              "playerId": playerId,
                            },
                          );
                          SharedPreferences _prefx =
                              await SharedPreferences.getInstance();
                          if (result.data['success'] == true) {
                            await _prefx.setString(
                              "userId",
                              result.data['data']['a3'].toString(),
                            );
                            await _prefx.setString(
                              "orderId",
                              result.data['data']['a4'].toString(),
                            );
                            setState(() {
                              isLoading = false;
                            });
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) => MainScreen(),
                              ),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text("المستخدم ليس مسجلاً")),
                            );
                          }
                        }
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("رمز التحقق غير صحيح")),
                        );
                      }
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
                      child: isLoading
                          ? CircularProgressIndicator(color: Colors.white)
                          : Text(
                              "تحقق من الرمز",
                              style: TextStyle(fontSize: 20, color: Colors.white),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
