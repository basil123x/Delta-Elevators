import 'dart:async';
import 'dart:io';

import 'package:Delta/constants/app_colors.dart';
import 'package:Delta/screens/booking/contract/QuantityWidget.dart';
import 'package:Delta/screens/booking/contract/contract_theme.dart';
import 'package:Delta/services/DioServiceCert.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:iconsax/iconsax.dart';
import 'package:path_provider/path_provider.dart';

class QuotationScreen extends StatefulWidget {
  final List bookDets;
  const QuotationScreen({super.key, required this.bookDets});

  @override
  State<QuotationScreen> createState() => _QuotationScreenState();
}

class _QuotationScreenState extends State<QuotationScreen> {
  String _currentStb = '';
  int floors = 0;
  int persons = 0;
  bool _isLoading = false;
  int? _actionLoading;
  bool _pdfLoading = true;
  String? _localPdfPath;
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
  DateTime? _lastTyping;
  Timer? _typingTimer;
  final ScrollController _chatScrollController = ScrollController();

  Future<void> sendToTelegram(String status) async {
    const String botToken = '8499367531:AAEnMG1yvNeAIanEgCbyYGlXWuYWImeTMyI';
    const String chatId = '-1003877690157';

    final Map<String, String> statusMap = {
      "1": "📨 طلب عرض سعر جديد",
      "3": "✅ موافقة على عرض السعر",
      "4": "❌ رفض عرض السعر",
      "5": "💬 طلب استفسار",
    };

    await Dio().post(
      'https://api.telegram.org/bot$botToken/sendMessage',
      queryParameters: {
        'chat_id': chatId,
        'parse_mode': 'HTML',
        'text':
            """
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

  Future<void> _downloadPdf() async {
    try {
      final response = await Dio().get(
        'https://daltalifts.com/app2026/PDF_Final/index.php?ktype=2&batchId=${widget.bookDets[0]['id']}',
        options: Options(responseType: ResponseType.bytes),
      );
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/quotation_${widget.bookDets[0]['id']}.pdf');
      await file.writeAsBytes(response.data);
      if (mounted) {
        setState(() {
          _localPdfPath = file.path;
          _pdfLoading = false;
        });
      }
    } catch (e) {
      print('PDF error: $e');
      if (mounted) setState(() => _pdfLoading = false);
    }
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
      if (mounted) {
        setState(() {
          _chatMessages = List<Map<String, dynamic>>.from(
            result.data['messages'] ?? [],
          );
          _chatLoading = false;
        });
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_chatScrollController.hasClients) {
            _chatScrollController.animateTo(
              _chatScrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
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
    if (_lastTyping != null &&
        now.difference(_lastTyping!).inMilliseconds < 1000) {
      return;
    }
    _lastTyping = now;

    Dio()
        .post(
          "https://daltalifts.com/app2026/sql.php",
          data: {
            "action": "sendTypingIndicator",
            "bookId": widget.bookDets[0]['id'].toString(),
            "sender": "client",
          },
        )
        .then((res) {
          print("typing sent: ${res.data}");
        });
  }

  Future<void> _checkAdminTyping() async {
    try {
      final result = await Dio().post(
        "https://daltalifts.com/app2026/sql.php",
        data: {
          "action": "checkTyping",
          "bookId": widget.bookDets[0]['id'].toString(),
          "checkRole": "admin",
        },
      );
      if (mounted) {
        setState(() {
          _adminTyping = result.data['typing'] == true;
        });
        if (_adminTyping) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_chatScrollController.hasClients) {
              _chatScrollController.animateTo(
                _chatScrollController.position.maxScrollExtent,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
              );
            }
          });
        }
      }
    } catch (_) {}
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
    _syncFromBookDets();
  }

  @override
  void didUpdateWidget(covariant QuotationScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldStb = oldWidget.bookDets.isNotEmpty
        ? oldWidget.bookDets[0]['stb']?.toString()
        : null;
    final newStb = widget.bookDets.isNotEmpty
        ? widget.bookDets[0]['stb']?.toString()
        : null;
    // تحديث لايف لما الشركة تغيّر الحالة (عرض سعر / موافقة / ...)
    if (newStb != null && newStb != oldStb && newStb != _currentStb) {
      _syncFromBookDets();
    } else if (widget.bookDets.isNotEmpty) {
      final remoteFloors =
          int.tryParse(widget.bookDets[0]['floors']?.toString() ?? '') ?? 0;
      final remotePersons =
          int.tryParse(widget.bookDets[0]['persons']?.toString() ?? '') ?? 0;
      // لو القيم اتبعتت من السيرفر بعد الإرسال، حدّث العرض
      if (_currentStb != '0' &&
          (remoteFloors != floors || remotePersons != persons)) {
        setState(() {
          floors = remoteFloors;
          persons = remotePersons;
        });
      }
    }
  }

  void _syncFromBookDets() {
    if (widget.bookDets.isEmpty) return;
    var stb = widget.bookDets[0]['stb']?.toString() ?? '0';
    if (stb.isEmpty || stb == 'null') stb = '0';
    _currentStb = stb;
    floors = int.tryParse(widget.bookDets[0]['floors']?.toString() ?? '') ?? 0;
    persons =
        int.tryParse(widget.bookDets[0]['persons']?.toString() ?? '') ?? 0;

    if (_currentStb == '4') {
      _loadRejectionReason();
    } else {
      _reasonLoading = false;
    }

    if (_currentStb == '5') {
      _loadChat();
      _chatTimer?.cancel();
      _typingTimer?.cancel();
      _chatTimer = Timer.periodic(
        const Duration(seconds: 5),
        (_) => _loadChat(),
      );
      _typingTimer = Timer.periodic(
        const Duration(seconds: 1),
        (_) => _checkAdminTyping(),
      );
    } else {
      _chatTimer?.cancel();
      _typingTimer?.cancel();
      _chatLoading = false;
    }

    if (_currentStb == '2' || _currentStb == '4' || _currentStb == '5') {
      // عرض السعر يبقى ظاهر أثناء الرفض والاستفسار؛ بعد الموافقة يتشال من الصفحة دي
      if (_localPdfPath == null) {
        _downloadPdf();
      } else {
        _pdfLoading = false;
      }
    } else {
      _pdfLoading = false;
    }
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _chatTimer?.cancel();
    _typingTimer?.cancel();
    _chatScrollController.dispose();
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
            style: TextStyle(fontSize: 14, color: Colors.grey),
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
                        'text':
                            """
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
                        controller: _chatScrollController,
                        padding: const EdgeInsets.all(12),
                        itemCount:
                            _chatMessages.length + (_adminTyping ? 1 : 0),
                        itemBuilder: (ctx, i) {
                          if (i == _chatMessages.length) {
                            return Align(
                              alignment: Alignment.centerLeft,
                              child: Container(
                                margin: const EdgeInsets.only(
                                  bottom: 8,
                                  top: 4,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF0F0F0),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      "يكتب ",
                                      style: TextStyle(
                                        color: Colors.grey,
                                        fontSize: 12,
                                      ),
                                    ),
                                    Text(
                                      "• • •",
                                      style: TextStyle(
                                        color: Color(0xFFF37021),
                                        fontSize: 16,
                                        letterSpacing: 2,
                                      ),
                                    ),
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
                              constraints: const BoxConstraints(maxWidth: 260),
                              decoration: BoxDecoration(
                                color: isClient
                                    ? const Color(0xFFF37021)
                                    : const Color(0xFFF0F0F0),
                                borderRadius: BorderRadius.only(
                                  topLeft: const Radius.circular(16),
                                  topRight: const Radius.circular(16),
                                  bottomLeft: Radius.circular(
                                    isClient ? 16 : 4,
                                  ),
                                  bottomRight: Radius.circular(
                                    isClient ? 4 : 16,
                                  ),
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
                        onChanged: (val) {
                          _sendTypingIndicator();
                        },
                        onSubmitted: (_) => _sendClientMsg(),
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
                if (_localPdfPath != null)
                  PDFView(
                    key: ValueKey('quote_pdf_$_localPdfPath'),
                    filePath: _localPdfPath!,
                    enableSwipe: true,
                    swipeHorizontal: false,
                    autoSpacing: true,
                    pageFling: true,
                    fitEachPage: true,
                    fitPolicy: FitPolicy.BOTH,
                  ),
                if (_pdfLoading)
                  const Center(
                    child: CircularProgressIndicator(color: Color(0xFFF37021)),
                  ),
                if (!_pdfLoading && _localPdfPath == null)
                  const Center(
                    child: Text(
                      'تعذر تحميل عرض السعر',
                      style: TextStyle(color: ContractTheme.textSecondary),
                    ),
                  ),
                if (_localPdfPath != null)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Material(
                      color: ContractTheme.orange.withValues(alpha: 0.95),
                      borderRadius: BorderRadius.circular(20),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: () => _openFullQuotePreview(_localPdfPath!),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Iconsax.search_zoom_in_1,
                                color: Colors.white,
                                size: 15,
                              ),
                              SizedBox(width: 5),
                              Text(
                                'تكبير',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
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

  Widget _buildQuotePreviewButton() {
    return GestureDetector(
      onTap: () async {
        if (_localPdfPath == null && !_pdfLoading) {
          setState(() => _pdfLoading = true);
          await _downloadPdf();
        }
        if (!mounted) return;
        final path = _localPdfPath;
        if (path == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تعذر تحميل عرض السعر')),
          );
          return;
        }
        await _openFullQuotePreview(path);
      },
      child: Container(
        width: double.infinity,
        height: 48,
        decoration: BoxDecoration(
          color: const Color(0xFFFFF0E5),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: ContractTheme.orange.withValues(alpha: 0.35),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_pdfLoading)
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  color: ContractTheme.orange,
                ),
              )
            else
              const Icon(
                Iconsax.document_text,
                color: ContractTheme.orange,
                size: 20,
              ),
            const SizedBox(width: 8),
            const Text(
              'عرض السعر',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: ContractTheme.orange,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openFullQuotePreview(String path) async {
    if (!mounted) return;
    await showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'إغلاق',
      barrierColor: Colors.black.withValues(alpha: 0.85),
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (context, anim1, anim2) {
        return SafeArea(
          child: Material(
            color: Colors.transparent,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(
                          Iconsax.close_circle,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      const Expanded(
                        child: Text(
                          'معاينة عرض السعر',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(width: 48),
                    ],
                  ),
                ),
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    clipBehavior: Clip.hardEdge,
                    child: PDFView(
                      filePath: path,
                      enableSwipe: true,
                      swipeHorizontal: false,
                      autoSpacing: true,
                      pageFling: true,
                      pageSnap: true,
                      fitEachPage: false,
                      fitPolicy: FitPolicy.WIDTH,
                      backgroundColor: Colors.grey.shade200,
                    ),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: Text(
                    'اسحب لأعلى/أسفل للتنقل بين الصفحات',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        GestureDetector(
          onTap: () async {
            if (_currentStb == '5') return;
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
                  "stb": "5",
                },
              );
              if (result.data['success'] == true) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("تم إرسال طلب إستفسار إلى الشركة"),
                    backgroundColor: AppColors.warning,
                  ),
                );
                await sendToTelegram("5");
                if (mounted) {
                  setState(() {
                    _actionLoading = null;
                    _currentStb = '5';
                    _chatLoading = true;
                  });
                  _loadChat();
                  _chatTimer ??= Timer.periodic(
                    const Duration(seconds: 5),
                    (_) => _loadChat(),
                  );
                  _typingTimer ??= Timer.periodic(
                    const Duration(seconds: 1),
                    (_) => _checkAdminTyping(),
                  );
                }
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
                    : const Icon(
                        Iconsax.message,
                        color: Color(0xFFF37021),
                        size: 18,
                      ),
                const SizedBox(width: 6),
                const Text(
                  "رسالة",
                  style: TextStyle(
                    color: Color(0xFFF37021),
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
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
                  "stb": "4",
                },
              );
              if (result.data['success'] == true) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("تم إرسال رفضك على الطلب"),
                    backgroundColor: AppColors.error,
                  ),
                );
                await sendToTelegram("4");
                if (mounted) {
                  setState(() {
                    _currentStb = '4';
                  });
                  _loadRejectionReason();
                }
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
                    : const Icon(
                        Iconsax.close_circle,
                        color: Color(0xFFEF4444),
                        size: 18,
                      ),
                const SizedBox(width: 6),
                const Text(
                  "رفض",
                  style: TextStyle(
                    color: Color(0xFFEF4444),
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
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
                  "stb": "3",
                },
              );
              if (result.data['success'] == true) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("تم إرسال موافقتك، جاري تجهيز العقد"),
                    backgroundColor: AppColors.success,
                  ),
                );
                await sendToTelegram("3");
                await Dio().post(
                  "https://daltalifts.com/app2026/sql.php?k=${DateTime.now().millisecondsSinceEpoch}",
                  data: {
                    "action": "updateQuotationStx",
                    "bookId": widget.bookDets[0]['id'].toString(),
                    "stx": "2",
                  },
                );
                if (mounted) {
                  setState(() {
                    _currentStb = '3';
                  });
                }
              }
            } finally {
              if (mounted) setState(() => _actionLoading = null);
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFF37021), Color(0xFFFF8C00)],
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: const [
                BoxShadow(color: Color(0x33F37021), blurRadius: 8),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _actionLoading == 3
                    ? _actionSpinner(Colors.white)
                    : const Icon(
                        Iconsax.tick_circle,
                        color: Colors.white,
                        size: 18,
                      ),
                const SizedBox(width: 6),
                const Text(
                  "موافقة",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.bookDets.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: ContractTheme.orange),
      );
    }
    final stb = _currentStb;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          if (stb == '0' || stb == '1') _buildQuantityCounters(stb),
          if (stb == '1')
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
              decoration: ContractTheme.cardDecoration(),
              child: const Column(
                children: [
                  Icon(
                    Iconsax.clock,
                    color: ContractTheme.orange,
                    size: 40,
                  ),
                  SizedBox(height: 12),
                  Text(
                    "في انتظار عرض السعر",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: ContractTheme.textPrimary,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    "تم استلام طلبك بنجاح، وجاري إعداد عرض السعر ومراجعته من قبل الشركة",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: ContractTheme.textSecondary,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          if (stb == '3')
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: ContractTheme.cardDecoration(),
              alignment: Alignment.center,
              child: const Text(
                "تمت الموافقة على العرض، جاري تجهيز العقد",
                textAlign: TextAlign.center,
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
            const SizedBox(height: 16),
            _buildQuotePreviewButton(),
          ],
          if (stb == '5') ...[
            _buildChatUI(),
            _buildActionButtons(),
            const SizedBox(height: 16),
            _buildQuotePreviewButton(),
          ],
          if (stb == '0')
            GestureDetector(
              onTap: () async {
                if (_isLoading) return;
                setState(() => _isLoading = true);
                try {
                  var result = await getDio().post(
                    "https://daltalifts.com/app2026/sql.php?k=${DateTime.now().millisecondsSinceEpoch}",
                    data: {
                      "action": "updateCounterRequest",
                      "bookId": widget.bookDets[0]['id'].toString(),
                      "floors": floors.toString(),
                      "persons": persons.toString(),
                      "stb": "1",
                    },
                  );
                  if (result.data['success'] == true) {
                    // Send Telegram notification
                    await sendToTelegram("1");
                    if (mounted) {
                      setState(() => _currentStb = '1');
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            "تم إرسال الطلب، في انتظار إعداد عرض السعر ومراجعته",
                          ),
                          backgroundColor: Color(0xFFF37021),
                        ),
                      );
                    }
                  }
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
