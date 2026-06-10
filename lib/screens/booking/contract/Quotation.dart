import 'dart:async';

import 'package:Delta/constants/app_colors.dart';
import 'package:Delta/screens/booking/contract/QuantityWidget.dart';
import 'package:Delta/screens/booking/contract/contract_theme.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:webview_flutter/webview_flutter.dart';

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
  bool _pdfLoading = true;
  WebViewController? _webViewController;
  final TextEditingController _rejectionReasonController =
      TextEditingController();
  bool _sendingReason = false;
  bool _reasonSent = false;
  bool _reasonLoading = true;
  List<Map<String, dynamic>> _chatMessages = [];
  bool _chatLoading = true;
  final TextEditingController _chatInputController = TextEditingController();
  bool _sendingMsg = false;
  Timer? _chatTimer;
  bool _adminTyping = false;
  DateTime? _lastTypingSent;

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

  void _initWebView() {
    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..setNavigationDelegate(NavigationDelegate(
        onPageStarted: (url) {
          if (mounted) setState(() => _pdfLoading = true);
        },
        onPageFinished: (url) {
          if (mounted) setState(() => _pdfLoading = false);
        },
        onWebResourceError: (error) {
          if (mounted) setState(() => _pdfLoading = false);
        },
      ))
      ..loadRequest(Uri.parse(
        'https://daltalifts.com/app2026/PDF_Final/index.php?ktype=2&batchId=${widget.bookDets[0]['id']}',
      ));
  }

  Future<void> _loadChat() async {
    try {
      final result = await Dio().post(
        "https://daltalifts.com/app2026/sql.php",
        data: {
          "action": "getChatMessages",
          "bookId": widget.bookDets[0]['id'].toString(),
        },
      );
      final adminTyping = result.data['admin_typing'] == true;
      if (mounted) {
        setState(() {
          _chatMessages = List<Map<String, dynamic>>.from(
            result.data['messages'] ?? [],
          );
          _adminTyping = adminTyping;
          _chatLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _chatLoading = false);
    }
  }

  Future<void> _sendClientMsg() async {
    final msg = _chatInputController.text.trim();
    if (msg.isEmpty || _sendingMsg) return;
    setState(() => _sendingMsg = true);
    _chatInputController.clear();

    try {
      await Dio().post(
        "https://daltalifts.com/app2026/sql.php",
        data: {
          "action": "sendClientChatMsg",
          "bookId": widget.bookDets[0]['id'].toString(),
          "message": msg,
        },
      );
      await _loadChat();
    } finally {
      if (mounted) setState(() => _sendingMsg = false);
    }
  }

  void _sendTypingIndicator() {
    final now = DateTime.now();
    if (_lastTypingSent != null &&
        now.difference(_lastTypingSent!).inSeconds < 2) {
      return;
    }
    _lastTypingSent = now;

    Dio().post(
      "https://daltalifts.com/app2026/sql.php",
      data: {
        "action": "sendTypingIndicator",
        "bookId": widget.bookDets[0]['id'].toString(),
        "sender": "client",
      },
    );
  }

  Widget _buildTypingDots() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(
        3,
        (i) => TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.2, end: 1.0),
          duration: Duration(milliseconds: 400 + (i * 150)),
          builder: (ctx, val, _) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 1),
            child: Opacity(
              opacity: val,
              child: const Text(
                "•",
                style: TextStyle(color: Color(0xFFF37021), fontSize: 18),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _loadRejectionReason() async {
    try {
      final result = await Dio().post(
        "https://daltalifts.com/app2026/sql.php",
        data: {
          "action": "getRejectionReason",
          "bookId": widget.bookDets[0]['id'].toString(),
        },
      );
      final reason = result.data['rejection_reason'] ?? '';
      if (reason.isNotEmpty) {
        setState(() {
          _rejectionReasonController.text = reason;
          _reasonSent = true;
        });
      }
    } catch (e) {
      // fail silently
    } finally {
      if (mounted) setState(() => _reasonLoading = false);
    }
  }

  @override
  void initState() {
    super.initState();
    setState(() {
      floors = int.parse(widget.bookDets[0]['floors']);
      persons = int.parse(widget.bookDets[0]['persons']);
    });

    if (widget.bookDets[0]['stb'] == '4') {
      _loadRejectionReason();
    } else {
      _reasonLoading = false;
    }

    if (widget.bookDets[0]['stb'] == '5') {
      _loadChat();
      _chatTimer = Timer.periodic(
        const Duration(seconds: 5),
        (_) => _loadChat(),
      );
    } else {
      _chatLoading = false;
    }

    _initWebView();
  }

  @override
  void dispose() {
    _chatTimer?.cancel();
    _rejectionReasonController.dispose();
    _chatInputController.dispose();
    super.dispose();
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

  Widget _buildQuantityCounters(String stb) {
    return Column(
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
                  visible: stb != '0',
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
                  visible: stb != '0',
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
      ],
    );
  }

  Widget _buildRejectionUI() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF0F0),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFFCCCC)),
      ),
      child: const Column(
        children: [
          Icon(Iconsax.close_circle, color: Color(0xFFEF4444), size: 64),
          SizedBox(height: 16),
          Text(
            "تم رفض عرض السعر",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Color(0xFFEF4444),
            ),
          ),
          SizedBox(height: 8),
          Text(
            "قام فريقنا بمراجعة طلبك وسيتواصل معك قريباً بعرض جديد",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRejectionReasonForm() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "سبب الرفض",
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 14,
              color: Color(0xFF333333),
            ),
          ),
          const SizedBox(height: 10),
          if (_reasonLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(
                  color: Color(0xFFEF4444),
                  strokeWidth: 2,
                ),
              ),
            )
          else ...[
            TextField(
              controller: _rejectionReasonController,
              enabled: !_reasonSent,
              maxLines: 4,
              textDirection: TextDirection.rtl,
              textAlign: TextAlign.right,
              style: TextStyle(
                color: _reasonSent ? Colors.grey : const Color(0xFF333333),
              ),
              decoration: InputDecoration(
                hintText: "اكتب سبب الرفض هنا من فضلك...",
                hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
                filled: true,
                fillColor: const Color(0xFFF8F8F8),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 12),
            if (_reasonSent)
              Container(
                width: double.infinity,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE0E0E0)),
                ),
                alignment: Alignment.center,
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Iconsax.tick_circle, color: Colors.grey, size: 18),
                    SizedBox(width: 8),
                    Text(
                      "تم إرسال سببك — بانتظار تعديل العرض",
                      style: TextStyle(
                        color: Colors.grey,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              )
            else
              GestureDetector(
                onTap: () async {
                  if (_sendingReason) return;
                  final reason = _rejectionReasonController.text.trim();
                  if (reason.isEmpty) return;
                  setState(() => _sendingReason = true);
                  try {
                    await Dio().post(
                      "https://daltalifts.com/app2026/sql.php?k=${DateTime.now().millisecondsSinceEpoch}",
                      data: {
                        "action": "saveRejectionReason",
                        "bookId": widget.bookDets[0]['id'].toString(),
                        "reason": reason,
                      },
                    );
                    await Dio().post(
                      'https://api.telegram.org/bot8499367531:AAEnMG1yvNeAIanEgCbyYGlXWuYWImeTMyI/sendMessage',
                      queryParameters: {
                        'chat_id': '-1003877690157',
                        'parse_mode': 'HTML',
                        'text': """
🚫 <b>رفض عرض السعر</b>

📋 <b>رقم الطلب:</b> #${widget.bookDets[0]['id']}
👤 <b>العميل:</b> ${widget.bookDets[0]['a1']}
📞 <b>الهاتف:</b> ${widget.bookDets[0]['a2']}

❌ <b>سبب الرفض:</b>
<i>$reason</i>
    """,
                      },
                    );
                    if (!mounted) return;
                    setState(() {
                      _reasonSent = true;
                      _sendingReason = false;
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("تم إرسال سبب الرفض"),
                        backgroundColor: Color(0xFFEF4444),
                      ),
                    );
                  } finally {
                    if (mounted && !_reasonSent) {
                      setState(() => _sendingReason = false);
                    }
                  }
                },
                child: Container(
                  width: double.infinity,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: _sendingReason
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          "إرسال سبب الرفض",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildChatUI() {
    return Column(
      children: [
        Container(
          height: 420,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8)],
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: const BoxDecoration(
                  color: Color(0xFFFFF5EE),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: const Row(
                  children: [
                    Icon(Iconsax.message, color: Color(0xFFF37021), size: 20),
                    SizedBox(width: 8),
                    Text(
                      "محادثة الاستفسار",
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFF37021),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _chatLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFFF37021),
                        ),
                      )
                    : _chatMessages.isEmpty && !_adminTyping
                        ? const Center(
                            child: Text(
                              "ابدأ المحادثة مع الشركة",
                              style: TextStyle(color: Colors.grey),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(12),
                            itemCount:
                                _chatMessages.length + (_adminTyping ? 1 : 0),
                            itemBuilder: (ctx, i) {
                              if (i == _chatMessages.length) {
                                return Align(
                                  alignment: Alignment.centerLeft,
                                  child: Container(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 10,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF0F0F0),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Text(
                                          "يكتب ",
                                          style: TextStyle(
                                            color: Colors.grey,
                                            fontSize: 12,
                                          ),
                                        ),
                                        _buildTypingDots(),
                                      ],
                                    ),
                                  ),
                                );
                              }
                              final msg = _chatMessages[i];
                              final isClient = msg['sender'] == 'client';
                              return Align(
                                alignment: isClient
                                    ? Alignment.centerRight
                                    : Alignment.centerLeft,
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 10,
                                  ),
                                  constraints:
                                      const BoxConstraints(maxWidth: 260),
                                  decoration: BoxDecoration(
                                    color: isClient
                                        ? const Color(0xFFF37021)
                                        : const Color(0xFFF0F0F0),
                                    borderRadius: BorderRadius.only(
                                      topLeft: const Radius.circular(16),
                                      topRight: const Radius.circular(16),
                                      bottomLeft:
                                          Radius.circular(isClient ? 16 : 4),
                                      bottomRight:
                                          Radius.circular(isClient ? 4 : 16),
                                    ),
                                  ),
                                  child: Text(
                                    msg['message']?.toString() ?? '',
                                    style: TextStyle(
                                      color: isClient
                                          ? Colors.white
                                          : Colors.black87,
                                      fontSize: 13,
                                    ),
                                    textDirection: TextDirection.rtl,
                                  ),
                                ),
                              );
                            },
                          ),
              ),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: const BoxDecoration(
                  border: Border(top: BorderSide(color: Color(0xFFEEEEEE))),
                ),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: _sendClientMsg,
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: const BoxDecoration(
                          color: Color(0xFFF37021),
                          shape: BoxShape.circle,
                        ),
                        child: _sendingMsg
                            ? const Padding(
                                padding: EdgeInsets.all(10),
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(
                                Iconsax.send1,
                                color: Colors.white,
                                size: 18,
                              ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _chatInputController,
                        textDirection: TextDirection.rtl,
                        textAlign: TextAlign.right,
                        decoration: InputDecoration(
                          hintText: "اكتب رسالتك...",
                          hintStyle: const TextStyle(
                            color: Colors.grey,
                            fontSize: 13,
                          ),
                          filled: true,
                          fillColor: const Color(0xFFF8F8F8),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                        ),
                        onChanged: (_) => _sendTypingIndicator(),
                        onSubmitted: (_) => _sendClientMsg(),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildPdfViewer() {
    return Column(
      children: [
        Container(
          width: double.infinity,
          height: 550,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8)],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              children: [
                if (_webViewController != null)
                  WebViewWidget(controller: _webViewController!),
                if (_pdfLoading)
                  const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFFF37021),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
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
                    content: Text("تم إرسال طلب إستفسار إلى الشركة"),
                    backgroundColor: AppColors.warning));
                await sendToTelegram("5");
              }
            } finally {
              if (mounted) setState(() => _actionLoading = null);
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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
                    content:
                        Text("تم إرسال موافقتك , في إنتظار الشركة"),
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
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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
    );
  }

  @override
  Widget build(BuildContext context) {
    final stb = widget.bookDets[0]['stb'].toString();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          if (stb == '0' || stb == '1') _buildQuantityCounters(stb),
          if (stb == '1')
            Container(
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
          if (stb == '3')
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: ContractTheme.cardDecoration(),
              alignment: Alignment.center,
              child: const Text(
                "تمت الموافقة، في انتظار الشركة",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: ContractTheme.textPrimary,
                ),
              ),
            ),
          if (stb == '4') ...[
            _buildRejectionUI(),
            const SizedBox(height: 16),
            _buildRejectionReasonForm(),
          ],
          if (stb == '5') _buildChatUI(),
          if (stb == '5') _buildActionButtons(),
          if (stb == '0')
            GestureDetector(
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
          if (stb == '2') _buildPdfViewer(),
          if (stb == '2') _buildActionButtons(),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
