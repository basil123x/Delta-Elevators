import 'dart:async';
import 'dart:math' as math;

import 'package:Delta/screens/auth/auth_design.dart';
import 'package:Delta/screens/auth/auth_wave_clipper.dart';
import 'package:Delta/screens/main/main_screen.dart';
import 'package:Delta/services/DioServiceCert.dart';
import 'package:Delta/services/OneSignalServices.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart' as intlx;
import 'package:onesignal_flutter/onesignal_flutter.dart';
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

class _OTPScreenState extends State<OTPScreen> with TickerProviderStateMixin {
  static const int _otpLength = 6;
  static const Color _orange = Color(0xFFF37021);
  static const Color _textDark = Color(0xFF1A1A2E);

  final List<TextEditingController> _digitControllers =
      List.generate(_otpLength, (_) => TextEditingController());
  final List<FocusNode> _digitFocus = List.generate(_otpLength, (_) => FocusNode());

  bool isLoading = false;
  int? currentOtp;

  Timer? _timer;
  int _secondsLeft = 60;
  bool canResend = false;

  late AnimationController _shakeController;
  late Animation<double> _shakeAnim;

  void _otpFieldListener() {
    if (mounted) setState(() {});
  }

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _shakeAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 10.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 10.0, end: -10.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -10.0, end: 10.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 10.0, end: -10.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -10.0, end: 0.0), weight: 1),
    ]).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.linear),
    );

    if (widget.mobile == '11111111') {
      currentOtp = 111111;
    } else {
      currentOtp = widget.otp;
    }
    sendOTP();
    startTimer();
    for (var i = 0; i < _otpLength; i++) {
      _digitFocus[i].addListener(_otpFieldListener);
      _digitControllers[i].addListener(_otpFieldListener);
    }
  }

  void startTimer() {
    _timer?.cancel();
    setState(() {
      _secondsLeft = 60;
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

  String get _maskedPhoneSubtitle {
    final digits = widget.mobile?.replaceAll(RegExp(r'\D'), '') ?? '';
    return 'تم إرسال رمز التحقق إلى +974$digits';
  }

  Future<void> sendOTP() async {
    await getDio().post(
      'https://graph.facebook.com/v22.0/1019878864550538/messages',
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
              "index": 0,
              "parameters": [
                {"type": "text", "text": currentOtp.toString()},
              ],
            },
          ],
        },
      },
    );
  }

  String _otpCode() =>
      _digitControllers.map((c) => c.text).join().replaceAll(RegExp(r'\D'), '');

  Color _otpCellBorderColor(int i) {
    final filled = _digitControllers[i].text.isNotEmpty;
    final focused = _digitFocus[i].hasFocus;
    if (filled) return const Color(0xFF4CAF50);
    if (focused) return _orange;
    return const Color(0xFFEFEFEF);
  }

  void _onDigitChanged(int index, String value) {
    final digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) {
      _digitControllers[index].clear();
      if (index > 0) {
        FocusScope.of(context).requestFocus(_digitFocus[index - 1]);
      }
      setState(() {});
      return;
    }
    final last = digits.substring(digits.length - 1);
    _digitControllers[index].text = last;
    _digitControllers[index].selection =
        TextSelection.collapsed(offset: _digitControllers[index].text.length);

    if (index < _otpLength - 1) {
      FocusScope.of(context).requestFocus(_digitFocus[index + 1]);
    } else {
      FocusScope.of(context).unfocus();
    }
    setState(() {});

    if (_otpCode().length == _otpLength) {
      _verifyOtp();
    }
  }

  Future<void> _playShake() async {
    await _shakeController.forward(from: 0);
    if (mounted) {
      _shakeController.reset();
    }
  }

  Future<void> _verifyOtp() async {
    final code = _otpCode();
    if (code.length != _otpLength) return;
    if (isLoading) return;

    if (currentOtp.toString() == code) {
      setState(() {
        isLoading = true;
      });
      final playerId = OneSignal.User.pushSubscription.id;
      if (widget.keylogin == 'Register') {
        final uid = 1000 + math.Random().nextInt(9000);
        final oid = 1000 + math.Random().nextInt(9000);
        final result = await getDio().post(
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
        final prefx = await SharedPreferences.getInstance();
        final regBody = authResponseAsMap(result.data);
        final regOk = regBody['success'] == true ||
            regBody['success'] == 1 ||
            regBody['success'] == 'true';
        if (regOk) {
          await prefx.setString("userId", uid.toString());
          await prefx.setString("orderId", oid.toString());
          if (!mounted) return;
          setState(() {
            isLoading = false;
          });
          final playerIdsx = <String>[];
          final playerIds = await getDio().post(
            "https://daltalifts.com/app2026/sql.php",
            data: {"action": "getPlayerIds"},
          );
          final pidBody = authResponseAsMap(playerIds.data);
          final rawPlayerData = pidBody['data'];
          if (rawPlayerData is List) {
            for (var i = 0; i < rawPlayerData.length; i++) {
              final row = rawPlayerData[i];
              if (row is Map && row['player_id'] != null) {
                playerIdsx.add(row['player_id'].toString());
              }
            }
          } else if (rawPlayerData is Map) {
            for (final entry in rawPlayerData.entries) {
              final v = entry.value;
              if (v is Map && v['player_id'] != null) {
                playerIdsx.add(v['player_id'].toString());
              }
            }
          }
          if (!mounted) return;
          setState(() {});
          await OneSignalNotification.sendToMultipleUsers(
            subscriptionIds: playerIdsx,
            title: "مستخدم جديد",
            message: "يوجد لديك مستخدم جديد من التطبيق الأن",
          );
          if (!mounted) return;
          Navigator.pushReplacement(
            context,
            MaterialPageRoute<void>(
              builder: (context) => MainScreen(),
            ),
          );
        } else {
          if (!mounted) return;
          setState(() => isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("المستخدم موجود بالفعل")),
          );
        }
      } else {
        final result = await getDio().post(
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
        final prefx = await SharedPreferences.getInstance();
        final loginBody = authResponseAsMap(result.data);
        final loginOk = loginBody['success'] == true ||
            loginBody['success'] == 1 ||
            loginBody['success'] == 'true';
        if (loginOk) {
          final data = loginBody['data'];
          final a3Str = data is Map ? (data['a3']?.toString() ?? '') : '';
          final a4Str = data is Map ? (data['a4']?.toString() ?? '') : '';
          await prefx.setString("userId", a3Str);
          await prefx.setString("orderId", a4Str);
          if (!mounted) return;
          setState(() {
            isLoading = false;
          });
          Navigator.pushReplacement(
            context,
            MaterialPageRoute<void>(
              builder: (context) => MainScreen(),
            ),
          );
        } else {
          if (!mounted) return;
          setState(() => isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("المستخدم ليس مسجلاً")),
          );
        }
      }
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("رمز التحقق غير صحيح")),
      );
      await _playShake();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _shakeController.dispose();
    for (var i = 0; i < _otpLength; i++) {
      _digitFocus[i].removeListener(_otpFieldListener);
      _digitControllers[i].removeListener(_otpFieldListener);
    }
    for (final c in _digitControllers) {
      c.dispose();
    }
    for (final f in _digitFocus) {
      f.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final topPad = MediaQuery.paddingOf(context).top;
    print(currentOtp);
    return Directionality(
      textDirection: TextDirection.rtl,
      child: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Scaffold(
          resizeToAvoidBottomInset: true,
          backgroundColor: Colors.white,
          body: Stack(
            clipBehavior: Clip.none,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(height: topPad),
                  Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.center,
                    children: [
                      ClipPath(
                        clipper: AuthWaveHeaderClipper(),
                        child: Container(
                          width: double.infinity,
                          height: 200,
                          color: _orange,
                        ),
                      ),
                      Positioned(
                        bottom: -40,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                              border: Border.all(
                                color: const Color(0xFFF37021),
                                width: 3,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFF37021).withValues(alpha: 0.25),
                                  blurRadius: 20,
                                  spreadRadius: 4,
                                ),
                              ],
                            ),
                            padding: const EdgeInsets.all(12),
                            child: Image.asset(
                              'assets/images/logo.png',
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) => Image.asset(
                                'assets/img/logo.png',
                                fit: BoxFit.contain,
                                errorBuilder: (_, __, ___) => Icon(
                                  Icons.apartment_rounded,
                                  color: _orange.withValues(alpha: 0.85),
                                  size: 40,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 50),
                  Expanded(
                    child: AnimatedPadding(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeOut,
                      padding: EdgeInsets.only(bottom: bottomInset),
                      child: SingleChildScrollView(
                        keyboardDismissBehavior:
                            ScrollViewKeyboardDismissBehavior.onDrag,
                        padding: const EdgeInsets.symmetric(horizontal: 28),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'DELTA ELEVATORS',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey.shade600,
                                letterSpacing: 2,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text.rich(
                              TextSpan(
                                children: [
                                  TextSpan(
                                    text: 'تحقق من ',
                                    style: TextStyle(
                                      color: _textDark,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 26,
                                    ),
                                  ),
                                  TextSpan(
                                    text: 'هويتك',
                                    style: const TextStyle(
                                      color: _orange,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 26,
                                    ),
                                  ),
                                ],
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _maskedPhoneSubtitle,
                              textAlign: TextAlign.center,
                              textDirection: TextDirection.rtl,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade600,
                                height: 1.45,
                              ),
                            ),
                            const SizedBox(height: 28),
                            AnimatedBuilder(
                              animation: _shakeController,
                              builder: (context, child) {
                                return Transform.translate(
                                  offset: Offset(_shakeAnim.value, 0),
                                  child: child,
                                );
                              },
                              child: Directionality(
                                textDirection: TextDirection.ltr,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: List.generate(_otpLength, (i) {
                                    return Padding(
                                      padding: EdgeInsets.only(
                                        left: i < _otpLength - 1 ? 6 : 0,
                                      ),
                                      child: SizedBox(
                                        width: 42,
                                        height: 52,
                                        child: TextField(
                                          controller: _digitControllers[i],
                                          focusNode: _digitFocus[i],
                                          textDirection: TextDirection.ltr,
                                          textAlign: TextAlign.center,
                                          keyboardType: TextInputType.number,
                                          maxLength: 1,
                                          style: const TextStyle(
                                            fontSize: 22,
                                            fontWeight: FontWeight.bold,
                                            color: _textDark,
                                          ),
                                          inputFormatters: [
                                            FilteringTextInputFormatter.digitsOnly,
                                          ],
                                          decoration: InputDecoration(
                                            counterText: '',
                                            filled: true,
                                            fillColor: const Color(0xFFF8F8F8),
                                            contentPadding: EdgeInsets.zero,
                                            border: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(12),
                                              borderSide: BorderSide(
                                                color: _otpCellBorderColor(i),
                                                width: 1.5,
                                              ),
                                            ),
                                            enabledBorder: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(12),
                                              borderSide: BorderSide(
                                                color: _otpCellBorderColor(i),
                                                width: 1.5,
                                              ),
                                            ),
                                            focusedBorder: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(12),
                                              borderSide: BorderSide(
                                                color: _otpCellBorderColor(i),
                                                width: 1.5,
                                              ),
                                            ),
                                          ),
                                          onChanged: (v) => _onDigitChanged(i, v),
                                          onSubmitted: (_) {
                                            if (i < _otpLength - 1) {
                                              _digitFocus[i + 1].requestFocus();
                                            }
                                          },
                                        ),
                                      ),
                                    );
                                  }),
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            if (canResend)
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                textDirection: TextDirection.rtl,
                                children: [
                                  Text(
                                    'لم يصلك الرمز؟ ',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () async {
                                      setState(() {
                                        currentOtp =
                                            100000 + math.Random().nextInt(900000);
                                      });
                                      await sendOTP();
                                      startTimer();
                                      for (final c in _digitControllers) {
                                        c.clear();
                                      }
                                      if (mounted) {
                                        FocusScope.of(context)
                                            .requestFocus(_digitFocus.first);
                                      }
                                    },
                                    child: const Text(
                                      'إعادة الإرسال',
                                      style: TextStyle(
                                        color: _orange,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            else
                              Text(
                                'لم يصلك الرمز؟ إعادة الإرسال ($_secondsLeft)',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            const SizedBox(height: 28),
                            SizedBox(
                              height: 54,
                              width: double.infinity,
                              child: FilledButton(
                                onPressed: isLoading ? null : _verifyOtp,
                                style: FilledButton.styleFrom(
                                  backgroundColor: _orange,
                                  foregroundColor: Colors.white,
                                  disabledBackgroundColor:
                                      _orange.withValues(alpha: 0.65),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                ),
                                child: isLoading
                                    ? const Center(
                                        child: SizedBox(
                                          height: 24,
                                          width: 24,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2.5,
                                            color: Colors.white,
                                          ),
                                        ),
                                      )
                                    : const Center(
                                        child: Text(
                                          'تأكيد',
                                          textDirection: TextDirection.rtl,
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                              ),
                            ),
                            SizedBox(
                              height: MediaQuery.sizeOf(context).height * 0.08,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              Positioned(
                top: topPad + 4,
                right: 12,
                child: IconButton(
                  onPressed: () => Navigator.maybePop(context),
                  icon: const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 18,
                    color: Color(0xFF1A1A2E),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
