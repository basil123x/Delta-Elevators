import 'dart:io';
import 'dart:typed_data';

import 'package:Delta/screens/booking/contract/contract_theme.dart';
import 'package:Delta/services/DioServiceCert.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:iconsax/iconsax.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:signature/signature.dart';

class Contract extends StatefulWidget {
  final List bookDets;
  const Contract({super.key, required this.bookDets});

  @override
  State<Contract> createState() => _ContractState();
}

class _ContractState extends State<Contract> {
  bool _contractApproved = false;
  bool _pdfLoading = true;
  String? _localPdfPath;
  String stt = "";
  bool _isLoading = false;
  String isLoadingTxt = "تحميل العقد";
  String pdfSend = "";
  String? _signedContractId;
  String? _signedPdfPath;
  String? _quotationPdfPath;
  /// null = لا معاينة، 'contract' أو 'quotation'
  String? _previewKind;
  bool _showingDocsHub = false;
  late SignatureController signatureController = SignatureController(
    penStrokeWidth: 5,
    penColor: Colors.black,
  );

  bool get _isSignedDone =>
      stt == '1' ||
      (widget.bookDets.isNotEmpty &&
          widget.bookDets[0]['stt']?.toString() == '1');

  bool get _readyToSign => _contractApproved && !_isSignedDone;

  String get _bookingId {
    if (widget.bookDets.isEmpty) return '';
    return widget.bookDets[0]['id']?.toString() ?? '';
  }

  String get _pdfKtype {
    if (widget.bookDets.isEmpty) return '1';
    final enter = widget.bookDets[0]['enter']?.toString() ?? '';
    return enter.contains('صيانة') ? '4' : '1';
  }

  String _liveContractPdfUrl() {
    final bust = DateTime.now().millisecondsSinceEpoch;
    final fromApi = widget.bookDets.isNotEmpty
        ? (widget.bookDets[0]['contract_pdf_url']?.toString() ?? '').trim()
        : '';
    if (fromApi.startsWith('http')) {
      final sep = fromApi.contains('?') ? '&' : '?';
      return '$fromApi${sep}t=$bust';
    }
    return 'https://daltalifts.com/app2026/PDF_Final/index.php'
        '?ktype=$_pdfKtype&batchId=$_bookingId&t=$bust';
  }

  Widget _asIsPdfView(String path) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: PDFView(
        key: ValueKey(path),
        filePath: path,
        enableSwipe: true,
        swipeHorizontal: false,
        autoSpacing: true,
        pageFling: true,
        pageSnap: true,
        fitEachPage: false,
        fitPolicy: FitPolicy.WIDTH,
        backgroundColor: const Color(0xFFF5F5F5),
        preventLinkNavigation: true,
        onError: (e) => debugPrint('PDF error: $e'),
      ),
    );
  }

  String get _effectiveContractId {
    if (_signedContractId != null &&
        _signedContractId!.isNotEmpty &&
        _signedContractId != 'null' &&
        _signedContractId != '0') {
      return _signedContractId!;
    }
    if (widget.bookDets.isEmpty) return '';
    final raw = widget.bookDets[0]['contract_id']?.toString() ?? '';
    if (raw.isEmpty || raw == 'null' || raw == '0') return '';
    return raw;
  }

  @override
  void dispose() {
    signatureController.dispose();
    super.dispose();
  }

  Future<void> uploadSignature(signId) async {
    if (signatureController.value.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('من فضلك قم بالتوقيع أولاً')));
      return;
    }

    setState(() => isLoadingTxt = "جاري رفع التوقيع");

    try {
      final Uint8List? signatureBytes = await signatureController.toPngBytes();
      print("ssssssss $signId");

      var res = await getDio().post(
        'https://daltalifts.com/app2026/sql.php?k=${DateTime.now().millisecondsSinceEpoch}',
        data: {
          'action': 'getPresignedUrlS3',
          'contractId': signId,
          'contractType': "1",
        },
      );

      String presignedUrl = res.data['url'];
      String s3Key = res.data['key'];

      await Dio().put(
        presignedUrl,
        data: signatureBytes,
        options: Options(
          headers: {
            'Content-Type': 'image/png',
            'Content-Length': signatureBytes!.length,
          },
          validateStatus: (code) => code != null && code >= 200 && code < 300,
        ),
      );

      // تأكيد إن الصورة اترفعت قبل ما نولّد الـ PDF (S3/CDN)
      final publicSignUrl =
          'https://daltaliftstech.s3.ap-south-1.amazonaws.com/$s3Key';
      var signatureReady = false;
      for (var i = 0; i < 6; i++) {
        try {
          final check = await Dio().get<List<int>>(
            publicSignUrl,
            options: Options(
              responseType: ResponseType.bytes,
              receiveTimeout: const Duration(seconds: 10),
              validateStatus: (c) => c != null && c < 500,
            ),
          );
          final bytes = check.data;
          if (check.statusCode == 200 &&
              bytes != null &&
              bytes.length > 100 &&
              !(String.fromCharCodes(bytes.take(80)).contains('<Error>'))) {
            signatureReady = true;
            break;
          }
        } catch (_) {}
        await Future.delayed(Duration(milliseconds: 400 + (i * 200)));
      }
      if (!signatureReady) {
        debugPrint('Signature not ready on S3 yet for $signId');
      }

      var response = await getDio().post(
        'https://daltalifts.com/app2026/sql.php',
        data: {
          'action': 'UploadSignature',
          'contractId': signId,
          's3Key': s3Key,
        },
      );

      if (response.data['success'] == true) {
        await downloadAndUploadPdf(signId);
      } else {
        if (mounted) setState(() => _isLoading = false);
        throw Exception(response.data['message'] ?? 'خطأ في الحفظ');
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
      rethrow;
    }
  }

  Future downloadAndUploadPdf(signId) async {
    SharedPreferences prefx = await SharedPreferences.getInstance();
    String oid = widget.bookDets.isNotEmpty
        ? (widget.bookDets[0]['orderId']?.toString() ?? '')
        : '';
    if (oid.isEmpty) {
      oid = prefx.getString("orderId") ?? '';
    }
    try {
      setState(() => isLoadingTxt = "جاري عمل بي دي اف");

      var dio = Dio(
        BaseOptions(
          connectTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 90),
          validateStatus: (code) => code != null && code < 600,
        ),
      );

      Map? payload;
      for (var attempt = 1; attempt <= 3; attempt++) {
        final bookId = widget.bookDets.isNotEmpty
            ? (widget.bookDets[0]['id']?.toString() ?? '')
            : '';
        final bust = DateTime.now().millisecondsSinceEpoch;
        final response = await dio.get(
          'https://daltalifts.com/app2026/pdf/index.php?contractId=$signId&sign=1&orderId=$oid&batchId=$bookId&ktype=1&v=$bust',
        );
        if (response.statusCode == 200 && response.data is Map) {
          payload = Map<String, dynamic>.from(response.data as Map);
          if (payload['success'] == true) break;
        }
        debugPrint(
          'PDF attempt $attempt failed: status=${response.statusCode} body=${response.data}',
        );
        payload = null;
        await Future.delayed(Duration(milliseconds: 700 * attempt));
      }

      if (payload != null && payload['success'] == true) {
        String pdfUrl = payload['url']?.toString() ?? '';

        setState(() => isLoadingTxt = "جاري تحميل العقد");

        final directory = await getApplicationDocumentsDirectory();
        final filePath = '${directory.path}/contract_signed_$signId.pdf';
        await dio.download(pdfUrl, filePath);

        // إرسال العقد الموقّع على تليجرام للموظفين
        setState(() => isLoadingTxt = "جاري إرسال العقد...");
        final b = widget.bookDets[0];
        final msg = """
📄 <b>عقد موقّع من العميل</b>

✅ تم توقيع وتحميل العقد بنجاح

🔢 رقم الطلب: <b>#${b['id']}</b>
📄 رقم العقد: <b>$signId</b>
👤 العميل: <b>${b['a1']}</b>
📞 الهاتف: <b>${b['a2']}</b>
📍 الموقع: <b>${b['city']} - ${b['zone']}</b>
🗓 التاريخ: <b>${b['date']}</b>

العقد الموقّع مرفق أدناه.
""";
        if (pdfUrl.isNotEmpty) {
          await sendTelegramMessageDocs(s3PdfUrl: pdfUrl, message: msg);
        }

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Expanded(
                  child: Text("تم تحميل العقد وإرساله بنجاح ✓"),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF4CAF50),
            duration: const Duration(seconds: 4),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );

        final livePath = await _fetchLiveContractPdf();
        if (!mounted) return;
        setState(() {
          _isLoading = false;
          _signedContractId = signId.toString();
          _signedPdfPath = livePath ?? filePath;
          _localPdfPath = livePath ?? filePath;
          isLoadingTxt = "تم تحميل العقد";
          stt = '1';
          _previewKind = null;
          _showingDocsHub = false;
        });
      } else {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تعذر إنشاء ملف العقد، حاول مرة أخرى'),
            ),
          );
        }
      }
    } catch (e) {
      print('Error: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('حدث خطأ أثناء تحميل العقد، حاول مرة أخرى'),
          ),
        );
      }
    }
  }

  Future<void> sendTelegramMessageDocs({
    required String s3PdfUrl,
    required String message,
  }) async {
    const String botToken = '8499367531:AAEnMG1yvNeAIanEgCbyYGlXWuYWImeTMyI';

    try {
      final response = await Dio().post(
        'https://api.telegram.org/bot$botToken/sendDocument',
        queryParameters: {
          'chat_id': "-1003877690157",
          'document': s3PdfUrl,
          'caption': message,
          'parse_mode': 'HTML',
        },
      );

      if (response.statusCode == 200) {
        print('✅ تم الإرسال');
      }
    } on DioException catch (e) {
      print('❌ خطأ: ${e.message}');
    }
  }

  Widget _infoTile({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: ContractTheme.cardDecoration(radius: 12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFFFF0E5),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: ContractTheme.orange, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: ContractTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: ContractTheme.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<String?> _fetchLiveContractPdf() async {
    final bookId = _bookingId;
    if (bookId.isEmpty) return null;

    final response = await Dio().get(
      _liveContractPdfUrl(),
      options: Options(
        responseType: ResponseType.bytes,
        headers: const {
          'Cache-Control': 'no-cache, no-store, must-revalidate',
          'Pragma': 'no-cache',
        },
      ),
    );
    final bytes = response.data;
    if (bytes is! List<int> && bytes is! Uint8List) return null;
    final data =
        bytes is Uint8List ? bytes : Uint8List.fromList(List<int>.from(bytes));
    if (data.length < 500) return null;
    final head = String.fromCharCodes(data.take(8));
    if (!head.startsWith('%PDF')) return null;

    final dir = await getTemporaryDirectory();
    final file = File(
      '${dir.path}/contract_live_${bookId}_${DateTime.now().millisecondsSinceEpoch}.pdf',
    );
    await file.writeAsBytes(data, flush: true);
    return file.path;
  }

  Future<void> _downloadPdf() async {
    try {
      if (mounted) setState(() => _pdfLoading = true);
      final path = await _fetchLiveContractPdf();
      if (!mounted) return;
      setState(() {
        _localPdfPath = path;
        if (path != null) _signedPdfPath = path;
        _pdfLoading = false;
      });
    } catch (e) {
      print('PDF error: $e');
      if (mounted) {
        setState(() => _pdfLoading = false);
      }
    }
  }

  @override
  void initState() {
    super.initState();
    if (widget.bookDets.isNotEmpty) {
      final remoteStt = widget.bookDets[0]['stt']?.toString() ?? '0';
      final contractId = widget.bookDets[0]['contract_id']?.toString() ?? '';
      final readyFlag = widget.bookDets[0]['contract_ready']?.toString() ?? '';
      final hasContract = readyFlag == '1' ||
          readyFlag == 'true' ||
          (contractId.isNotEmpty &&
              contractId != 'null' &&
              contractId != '0');

      // stt=1 فقط = تم التوقيع فعلياً
      if (remoteStt == '1') {
        _contractApproved = true;
        stt = '1';
        isLoadingTxt = "تم تحميل العقد";
        _signedContractId =
            contractId.isNotEmpty && contractId != 'null' && contractId != '0'
                ? contractId
                : null;
        _pdfLoading = false;
        _loadSignedPdfForView();
      } else if (hasContract) {
        // العقد يظهر أولاً للمراجعة، والتوقيع بعد زر الموافقة فقط
        _contractApproved = false;
        stt = remoteStt;
        _signedContractId = null;
        _downloadPdf();
      } else {
        _pdfLoading = false;
      }
    } else {
      _pdfLoading = false;
    }
  }

  @override
  void didUpdateWidget(covariant Contract oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.bookDets.isEmpty) return;
    final remoteStt = widget.bookDets[0]['stt']?.toString() ?? '0';
    final contractId = widget.bookDets[0]['contract_id']?.toString() ?? '';

    if (remoteStt == '1') {
      final needSync = stt != '1' ||
          isLoadingTxt != 'تم تحميل العقد' ||
          (_signedContractId == null || _signedContractId!.isEmpty);
      if (needSync) {
        setState(() {
          _contractApproved = true;
          stt = '1';
          isLoadingTxt = 'تم تحميل العقد';
          if (contractId.isNotEmpty &&
              contractId != 'null' &&
              contractId != '0') {
            _signedContractId = contractId;
          }
          _pdfLoading = false;
        });
        if (_signedPdfPath == null) _loadSignedPdfForView();
      } else if (contractId.isNotEmpty &&
          contractId != 'null' &&
          contractId != '0' &&
          _signedContractId != contractId) {
        setState(() => _signedContractId = contractId);
      }
    }
  }

  Future<void> _loadSignedPdfForView() async {
    try {
      if (_bookingId.isEmpty) {
        debugPrint('Load contract pdf: missing booking id');
        return;
      }
      final path = await _fetchLiveContractPdf();
      if (path == null || !mounted) return;
      setState(() {
        _signedPdfPath = path;
        _localPdfPath = path;
      });
    } catch (e) {
      debugPrint('Load signed pdf view error: $e');
    }
  }

  Future<void> _loadQuotationPdfForView() async {
    try {
      final bookId = widget.bookDets[0]['id']?.toString() ?? '';
      if (bookId.isEmpty) return;

      final dio = getDio();
      dio.options.connectTimeout = const Duration(seconds: 30);
      dio.options.receiveTimeout = const Duration(seconds: 90);

      final response = await dio.get(
        'https://daltalifts.com/app2026/PDF_Final/index.php?ktype=2&batchId=$bookId',
        options: Options(responseType: ResponseType.bytes),
      );

      final bytes = response.data;
      if (bytes is! List<int> && bytes is! Uint8List) {
        debugPrint('Load quotation pdf: unexpected response');
        return;
      }

      final dir = await getApplicationDocumentsDirectory();
      final filePath = '${dir.path}/quotation_view_$bookId.pdf';
      final file = File(filePath);
      await file.writeAsBytes(
        bytes is Uint8List ? bytes : Uint8List.fromList(List<int>.from(bytes)),
      );

      if (!await file.exists() || await file.length() < 500) return;

      if (mounted) {
        setState(() => _quotationPdfPath = filePath);
      }
    } catch (e) {
      debugPrint('Load quotation pdf view error: $e');
    }
  }

  Future<void> _openPreview(String kind) async {
    if (_previewKind == kind) {
      setState(() => _previewKind = null);
      return;
    }

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(color: ContractTheme.orange),
      ),
    );

    try {
      if (kind == 'contract') {
        await _loadSignedPdfForView();
      } else {
        if (_quotationPdfPath == null) await _loadQuotationPdfForView();
      }
    } finally {
      if (mounted) Navigator.of(context, rootNavigator: true).pop();
    }

    if (!mounted) return;

    final path = kind == 'contract' ? _signedPdfPath : _quotationPdfPath;
    if (path == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            kind == 'contract'
                ? 'تعذر تحميل العقد الموقّع، حاول مرة أخرى'
                : 'تعذر تحميل عرض السعر، حاول مرة أخرى',
          ),
        ),
      );
      return;
    }

    setState(() => _previewKind = kind);
  }

  Future<void> _openFullPdfPreview(String path) async {
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
                          'معاينة العقد',
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
                    child: _asIsPdfView(path),
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

  Widget _buildSignaturePadArea() {
    final locked = _isSignedDone;
    final cid = _effectiveContractId;

    return Container(
      width: double.infinity,
      height: 200,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: locked ? const Color(0xFF22C55E) : ContractTheme.orange,
          width: 2,
        ),
      ),
      child: locked
          ? ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: cid.isNotEmpty
                  ? Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.network(
                          'https://daltaliftstech.s3.ap-south-1.amazonaws.com/Mobile_App/signatures/IIP_Contracts/signature_$cid.png',
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Iconsax.tick_circle,
                                  color: Color(0xFF22C55E),
                                  size: 40,
                                ),
                                SizedBox(height: 10),
                                Text(
                                  'تم توقيع العقد',
                                  style: TextStyle(
                                    color: Color(0xFF22C55E),
                                    fontWeight: FontWeight.w800,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF22C55E),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Iconsax.tick_circle,
                                  color: Colors.white,
                                  size: 14,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'تم التوقيع',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    )
                  : const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Iconsax.tick_circle,
                            color: Color(0xFF22C55E),
                            size: 40,
                          ),
                          SizedBox(height: 10),
                          Text(
                            'تم توقيع العقد',
                            style: TextStyle(
                              color: Color(0xFF22C55E),
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
            )
          : Stack(
              children: [
                Signature(
                  height: 200,
                  controller: signatureController,
                  backgroundColor: Colors.transparent,
                ),
                ValueListenableBuilder<List>(
                  valueListenable: signatureController,
                  builder: (context, value, child) {
                    if (value.isEmpty) {
                      return const Center(
                        child: Text(
                          "قم بالتوقيع هنا",
                          style: TextStyle(
                            fontSize: 15,
                            color: ContractTheme.textSecondary,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
                ValueListenableBuilder<List>(
                  valueListenable: signatureController,
                  builder: (context, value, child) {
                    if (value.isNotEmpty) {
                      return Positioned(
                        top: 8,
                        right: 8,
                        child: IconButton(
                          onPressed: () => signatureController.clear(),
                          icon: const Icon(
                            Iconsax.trash,
                            color: Color(0xFFEF4444),
                          ),
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ],
            ),
    );
  }

  Widget _previewActionButton({
    required String label,
    required IconData icon,
    required bool active,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 48,
          decoration: BoxDecoration(
            color: active
                ? ContractTheme.orange
                : const Color(0xFFFFF0E5),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: ContractTheme.orange.withValues(
                alpha: active ? 1 : 0.35,
              ),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: active ? Colors.white : ContractTheme.orange,
                size: 18,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: active ? Colors.white : ContractTheme.orange,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDocPreviewButtons() {
    return Row(
      children: [
        _previewActionButton(
          label: 'عرض السعر',
          icon: Iconsax.document_text,
          active: _previewKind == 'quotation',
          onTap: () => _openPreview('quotation'),
        ),
        const SizedBox(width: 10),
        _previewActionButton(
          label: 'عرض العقد',
          icon: Iconsax.document,
          active: _previewKind == 'contract',
          onTap: () => _openPreview('contract'),
        ),
      ],
    );
  }

  Widget _buildSignatureStep() {
    // وضع المعاينة: بدون Scroll خارجي عشان سكرول الصفحات يشتغل
    if (_previewKind != null) {
      final path = _previewKind == 'quotation'
          ? _quotationPdfPath
          : _signedPdfPath;
      final hint = _previewKind == 'quotation'
          ? 'اسحب لأعلى/أسفل لقلب صفحات عرض السعر'
          : 'اسحب لأعلى/أسفل لقلب صفحات العقد';

      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
        child: Column(
          children: [
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: ContractTheme.orange, width: 2),
                ),
                clipBehavior: Clip.hardEdge,
                child: Stack(
                  children: [
                    if (path != null)
                      Positioned.fill(
                        child: _asIsPdfView(path),
                      )
                    else
                      const Center(
                        child: CircularProgressIndicator(
                          color: ContractTheme.orange,
                        ),
                      ),
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Material(
                        color: Colors.black.withValues(alpha: 0.55),
                        shape: const CircleBorder(),
                        child: IconButton(
                          tooltip: 'إغلاق',
                          onPressed: () {
                            setState(() => _previewKind = null);
                          },
                          icon: const Icon(
                            Iconsax.close_circle,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Material(
                        color: ContractTheme.orange.withValues(alpha: 0.95),
                        borderRadius: BorderRadius.circular(20),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(20),
                          onTap: path == null
                              ? null
                              : () => _openFullPdfPreview(path),
                          child: const Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Iconsax.search_zoom_in_1,
                                  color: Colors.white,
                                  size: 16,
                                ),
                                SizedBox(width: 6),
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
            const SizedBox(height: 8),
            Text(
              hint,
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 10),
            _buildDocPreviewButtons(),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () => setState(() => _previewKind = null),
              child: Container(
                width: double.infinity,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF0E5),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: ContractTheme.orange.withValues(alpha: 0.35),
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Iconsax.close_circle,
                      color: ContractTheme.orange,
                      size: 18,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'إغلاق المعاينة',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: ContractTheme.orange,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 72),
          ],
        ),
      );
    }

    // صفحة اختيار عرض السعر / عرض العقد بعد التوقيع
    if (_showingDocsHub && _isSignedDone) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 88),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Iconsax.folder_open,
                color: ContractTheme.orange,
                size: 42,
              ),
              const SizedBox(height: 14),
              const Text(
                'المستندات',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: ContractTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'اختر عرض السعر أو العقد للمعاينة',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 28),
              _buildDocPreviewButtons(),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      child: Column(
        children: [
          _infoTile(
            icon: Iconsax.user,
            label: 'الإسم',
            value: widget.bookDets[0]['a1'].toString(),
          ),
          _infoTile(
            icon: Iconsax.call,
            label: 'رقم الهاتف',
            value: widget.bookDets[0]['a2'].toString(),
          ),
          _infoTile(
            icon: Iconsax.calendar,
            label: 'التاريخ',
            value: widget.bookDets[0]['date'].toString(),
          ),
          const SizedBox(height: 6),
          _buildSignaturePadArea(),
        ],
      ),
    );
  }

  Widget _buildUploadButton() {
    final signed = _isSignedDone;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: GestureDetector(
          onTap: () async {
            if (_isLoading) return;

            // بعد التوقيع: زر «عرض العقد» يفتح صفحة عرض السعر + عرض العقد
            if (signed) {
              if (_previewKind != null) {
                setState(() => _previewKind = null);
                return;
              }
              setState(() => _showingDocsHub = !_showingDocsHub);
              return;
            }

            if (signatureController.value.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("يرجى كتابة التوقيع")),
              );
              return;
            }

            setState(() {
              _isLoading = true;
              isLoadingTxt = "جاري رفع العقد...";
            });
            try {
              var data = {
                "action": "addContract",
                "type": "1",
                "a2": widget.bookDets[0]['date'],
                "a3": widget.bookDets[0]['a1'],
              };
              var response = await getDio().post(
                "https://daltalifts.com/app2026/sql.php?k=${DateTime.now().millisecondsSinceEpoch}",
                data: data,
              );
              if (response.data['success'] == true) {
                await uploadSignature(response.data['data']['id']);
              } else {
                if (mounted) {
                  setState(() {
                    _isLoading = false;
                    isLoadingTxt = "تحميل العقد";
                  });
                }
              }
            } catch (e) {
              if (mounted) {
                setState(() {
                  _isLoading = false;
                  isLoadingTxt = "تحميل العقد";
                });
              }
            }
          },
          child: Container(
            height: 56,
            decoration: BoxDecoration(
              gradient: signed
                  ? const LinearGradient(
                      colors: [Color(0xFFF37021), Color(0xFFFF8C00)],
                    )
                  : const LinearGradient(
                      colors: [Color(0xFFF37021), Color(0xFFFF8C00)],
                    ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFF37021).withValues(alpha: 0.3),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: _isLoading
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        isLoadingTxt,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        signed ? Iconsax.document_text : Iconsax.document_download,
                        color: Colors.white,
                        size: 22,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        signed
                            ? (_showingDocsHub || _previewKind != null
                                ? "العودة"
                                : "عرض العقد")
                            : "تحميل العقد",
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Future<void> _notifyContractApprovedOnTelegram() async {
    if (widget.bookDets.isEmpty) return;
    const String botToken = '8499367531:AAEnMG1yvNeAIanEgCbyYGlXWuYWImeTMyI';
    const String chatId = '-1003877690157';
    final b = widget.bookDets[0];
    final bookingId = b['id']?.toString() ?? '';
    final clientName = b['a1']?.toString() ?? '—';
    final phone = b['a2']?.toString() ?? '—';
    final city = b['city']?.toString() ?? '—';
    final zone = b['zone']?.toString() ?? '—';
    final street = b['street']?.toString() ?? '—';
    final building = b['building']?.toString() ?? '—';
    final floors = b['floors']?.toString() ?? '0';
    final persons = b['persons']?.toString() ?? '0';
    final contractId = b['contract_id']?.toString() ?? '—';
    final date = b['date']?.toString() ?? '—';

    final message = """
✅ <b>تمت الموافقة على العقد من قبل العميل</b>

📋 <b>تفاصيل الطلب:</b>
🔢 رقم الطلب: <b>#$bookingId</b>
📄 رقم العقد: <b>$contractId</b>
🗓 التاريخ: <b>$date</b>

👤 <b>بيانات العميل:</b>
الاسم: <b>$clientName</b>
الهاتف: <b>$phone</b>

📍 <b>عنوان التركيب:</b>
المدينة: $city
المنطقة: $zone
الشارع: $street
المبنى: $building

🛗 <b>مواصفات الطلب:</b>
الطوابق: $floors
الركاب: $persons

يرجى متابعة إجراءات التنفيذ مع الفريق.
""";

    try {
      await Dio(
        BaseOptions(
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 15),
        ),
      ).post(
        'https://api.telegram.org/bot$botToken/sendMessage',
        queryParameters: {
          'chat_id': chatId,
          'text': message,
          'parse_mode': 'HTML',
        },
      );
    } catch (e) {
      debugPrint('Telegram contract approval notify error: $e');
    }
  }

  Widget _buildApproveButton() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: GestureDetector(
          onTap: () async {
            if (_isLoading) return;
            setState(() => _isLoading = true);
            try {
              final result = await getDio().post(
                "https://daltalifts.com/app2026/sql.php?k=${DateTime.now().millisecondsSinceEpoch}",
                data: {
                  "action": "approveContract",
                  "bookId": widget.bookDets[0]['id'].toString(),
                },
              );
              final ok = result.data['success'] == true ||
                  result.data['success'] == 1 ||
                  result.data['success'] == 'true';
              if (!mounted) return;
              if (ok) {
                setState(() {
                  _contractApproved = true;
                  stt = '2';
                  _isLoading = false;
                  isLoadingTxt = "تحميل العقد";
                });
                _notifyContractApprovedOnTelegram();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('تمت الموافقة على العقد'),
                    backgroundColor: Color(0xFF22C55E),
                  ),
                );
              } else {
                setState(() => _isLoading = false);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      result.data['message']?.toString() ??
                          'تعذر الموافقة، حاول مرة أخرى',
                    ),
                  ),
                );
              }
            } catch (e) {
              if (!mounted) return;
              setState(() => _isLoading = false);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('حدث خطأ أثناء الموافقة على العقد'),
                ),
              );
            }
          },
          child: Container(
            height: 56,
            decoration: ContractTheme.primaryGradientButton(),
            alignment: Alignment.center,
            child: _isLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.5,
                    ),
                  )
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Iconsax.tick_circle, color: Colors.white, size: 22),
                      SizedBox(width: 8),
                      Text(
                        "الموافقة على العقد",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final showPdfStep =
        widget.bookDets.isNotEmpty && !_readyToSign && !_isSignedDone;
    final showSignatureStep =
        widget.bookDets.isNotEmpty && (_readyToSign || _isSignedDone);

    return Scaffold(
      backgroundColor: ContractTheme.bg,
      body: widget.bookDets.isEmpty
          ? const SizedBox()
          : showPdfStep
          ? Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  if (_pdfLoading)
                    const Expanded(
                      child: Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFFF37021),
                        ),
                      ),
                    )
                  else if (_localPdfPath != null)
                    Expanded(
                      child: _asIsPdfView(_localPdfPath!),
                    )
                  else
                    const Expanded(
                      child: Center(
                        child: Text(
                          "تعذر تحميل العقد",
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    ),
                ],
              ),
            )
          : showSignatureStep
          ? _buildSignatureStep()
          : const SizedBox(),
      bottomNavigationBar: showPdfStep
          ? _buildApproveButton()
          : showSignatureStep
          ? _buildUploadButton()
          : null,
    );
  }
}
