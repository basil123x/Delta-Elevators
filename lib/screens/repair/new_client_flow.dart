import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:Delta/screens/booking/contract/ContractWait.dart';
import 'package:Delta/screens/repair/repair_screen.dart';
import 'package:Delta/screens/repair/repair_theme.dart';
import 'package:Delta/services/DioServiceCert.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart' as intlx;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:signature/signature.dart';

/// Step 1 of the new-client maintenance flow: collect the client's details,
/// register the account, create an address + booking, then move on to the
/// contract signing screen.
class NewClientDataScreen extends StatefulWidget {
  const NewClientDataScreen({super.key});

  @override
  State<NewClientDataScreen> createState() => _NewClientDataScreenState();
}

class _NewClientDataScreenState extends State<NewClientDataScreen> {
  bool _hasError = false;

  static const String _endpoint = "https://daltalifts.com/app2026/sql.php";

  @override
  void initState() {
    super.initState();
    _startFlow();
  }

  Future<void> _startFlow() async {
    if (_hasError && mounted) setState(() => _hasError = false);

    try {
      // 1. Fetch the user profile.
      final prefs = await SharedPreferences.getInstance();
      final uid = prefs.getString("userId") ?? "";
      await getDio().post(_endpoint, data: {"action": "profile", "uid": uid});

      // 2. Immediately create the maintenance booking.
      final oid = (1000 + Random().nextInt(9000)).toString();
      final bookingResult = await getDio().post(
        _endpoint,
        data: {
          "action": "addMaintenanceBooking",
          "uid": uid,
          "oid": oid,
          "addId": "0",
        },
      );
      final bookingId = bookingResult.data['bookingId'].toString();

      // 3. Navigate straight to the contract + signature screen.
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => NewClientContractScreen(bookingId: bookingId),
        ),
      );
    } catch (e) {
      print('New client flow error: $e');
      if (mounted) setState(() => _hasError = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: RepairTheme.bg,
        body: Center(
          child: _hasError
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "حدث خطأ، حاول مرة أخرى",
                      style: RepairTheme.cairo(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: RepairTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    RepairTheme.gradientButton(
                      label: "إعادة المحاولة",
                      colors: const [Color(0xFFF37021), Color(0xFFFF8C00)],
                      icon: Iconsax.refresh,
                      onTap: _startFlow,
                    ),
                  ],
                )
              : const CircularProgressIndicator(color: Color(0xFFF37021)),
        ),
      ),
    );
  }
}

/// Step 2 of the new-client maintenance flow:
/// Wait until ERP sets contract_ready=1, then preview PDF (ktype=4),
/// approve, sign, upload with contractType="4", continue to repair request.
class NewClientContractScreen extends StatefulWidget {
  final String bookingId;
  final bool startFromSignature;
  const NewClientContractScreen({
    super.key,
    required this.bookingId,
    this.startFromSignature = false,
  });

  @override
  State<NewClientContractScreen> createState() =>
      _NewClientContractScreenState();
}

class _NewClientContractScreenState extends State<NewClientContractScreen> {
  /// false = waiting ERP approval, true = approved & preparing contract.
  bool _erpApproved = false;
  bool _contractReady = false;
  bool _contractApproved = false;
  bool _pdfLoading = false;
  String? _localPdfPath;
  bool _isLoading = false;
  String isLoadingTxt = "جاري رفع التوقيع...";
  Timer? _pollTimer;
  late String _bookingId;

  late SignatureController signatureController = SignatureController(
    penStrokeWidth: 5,
    penColor: Colors.black,
  );

  static const String _endpoint = "https://daltalifts.com/app2026/sql.php";

  @override
  void initState() {
    super.initState();
    _bookingId = widget.bookingId;
    _initResumeState();
  }

  Future<void> _initResumeState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('maint_customer_type', 'new');
    await prefs.setInt('currentCard', 2);

    // Resolve the real booking id from server (fixes stale/null local ids).
    await _resolveBookingId(prefs);
    await prefs.setString('maint_booking_id', _bookingId);

    final approved =
        prefs.getBool('contractApproved_$_bookingId') ?? false;
    _contractApproved = widget.startFromSignature || approved;

    if (widget.startFromSignature) {
      if (!mounted) return;
      setState(() {
        _erpApproved = true;
        _contractReady = true;
      });
      await _downloadPdf();
      return;
    }

    await _pollBookingState();
    _pollTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (!_contractReady) _pollBookingState();
    });
  }

  Future<void> _resolveBookingId(SharedPreferences prefs) async {
    final uid = prefs.getString('userId') ?? '';
    final current = _bookingId.trim();
    final looksBad = current.isEmpty ||
        current == 'null' ||
        current == '0' ||
        int.tryParse(current) == null;

    if (!looksBad && uid.isEmpty) return;

    try {
      if (uid.isEmpty) return;
      final result = await getDio().post(
        "$_endpoint?k=${DateTime.now().millisecondsSinceEpoch}",
        data: {"action": "checkMaintenanceStatus", "uid": uid},
      );
      final data = result.data;
      if (data is! Map || data['success'] != true) return;
      final serverId = data['bookingId']?.toString() ?? '';
      if (serverId.isNotEmpty && serverId != 'null') {
        _bookingId = serverId;
      }
    } catch (e) {
      debugPrint('resolve booking id error: $e');
    }
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    signatureController.dispose();
    super.dispose();
  }

  Future<void> _pollBookingState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final uid = prefs.getString('userId') ?? '';

      // Primary: status by uid (authoritative for approval / contract_ready).
      if (uid.isNotEmpty) {
        final statusResult = await getDio().post(
          "$_endpoint?k=${DateTime.now().millisecondsSinceEpoch}",
          data: {"action": "checkMaintenanceStatus", "uid": uid},
        );
        final statusData = statusResult.data;
        if (statusData is Map && statusData['success'] == true) {
          final serverId = statusData['bookingId']?.toString() ?? '';
          if (serverId.isNotEmpty && serverId != 'null') {
            _bookingId = serverId;
            await prefs.setString('maint_booking_id', _bookingId);
          }

          final status = statusData['status']?.toString() ?? '';
          final stx = statusData['stx']?.toString() ?? '0';
          final readyFlag = statusData['contract_ready']?.toString() ?? '';
          final erpApproved = stx == '1' ||
              stx == '2' ||
              status == 'pending_prepare' ||
              status == 'pending_contract' ||
              status == 'completed';
          final ready = readyFlag == '1' ||
              readyFlag == 'true' ||
              status == 'pending_contract' ||
              status == 'completed';

          if (!mounted) return;
          await _applyPollState(
            erpApproved: erpApproved,
            ready: ready,
            prefs: prefs,
          );
          return;
        }
      }

      // Fallback: direct booking row.
      if (_bookingId.isEmpty || _bookingId == 'null') return;
      final result = await getDio().post(
        "$_endpoint?k=${DateTime.now().millisecondsSinceEpoch}",
        data: {
          "action": "getMyBookingOne",
          "bookid": _bookingId,
        },
      );
      final data = result.data['data'];
      if (data is! List || data.isEmpty) {
        return;
      }
      final row = data[0];
      final stx = row['stx']?.toString() ?? '0';
      final erpApproved = stx == '1' || stx == '2';
      final readyFlag = row['contract_ready']?.toString() ?? '';
      final ready = readyFlag == '1' || readyFlag == 'true';

      if (!mounted) return;
      await _applyPollState(
        erpApproved: erpApproved,
        ready: ready,
        prefs: prefs,
      );
    } catch (e) {
      debugPrint('Maintenance contract state poll error: $e');
    }
  }

  Future<void> _applyPollState({
    required bool erpApproved,
    required bool ready,
    required SharedPreferences prefs,
  }) async {
    if (ready && !_contractReady) {
      final localApproved =
          prefs.getBool('contractApproved_$_bookingId') ?? false;
      setState(() {
        _erpApproved = true;
        _contractReady = true;
        _pdfLoading = true;
        if (localApproved) _contractApproved = true;
      });
      _pollTimer?.cancel();
      await _downloadPdf();
      return;
    }

    if (erpApproved != _erpApproved || ready != _contractReady) {
      setState(() {
        _erpApproved = erpApproved;
        // Only flip ready via the branch above (needs PDF download).
        if (!ready) _contractReady = false;
      });
    }
  }

  Future<void> _downloadPdf() async {
    try {
      final response = await Dio().get(
        'https://daltalifts.com/app2026/PDF_Final/index.php?ktype=4&batchId=$_bookingId',
        options: Options(responseType: ResponseType.bytes),
      );
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/maint_contract_$_bookingId.pdf');
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

  Future<void> _signAndUpload() async {
    if (signatureController.value.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("يرجى التوقيع أولاً")));
      return;
    }

    setState(() {
      _isLoading = true;
      isLoadingTxt = "جاري رفع التوقيع...";
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final uid = prefs.getString("userId") ?? "";
      final profileResult = await getDio().post(
        _endpoint,
        data: {"action": "profile", "uid": uid},
      );
      final profile = profileResult.data is Map
          ? (profileResult.data['data'] is Map
              ? profileResult.data['data'] as Map
              : {})
          : {};
      final userName = profile['a1']?.toString() ?? '';
      final userPhone = profile['a2']?.toString() ?? '';

      // 1. Create the maintenance contract record (type 4 = app maint PDF).
      final contractRes = await getDio().post(
        "$_endpoint?k=${DateTime.now().millisecondsSinceEpoch}",
        data: {
          "action": "addContract",
          "type": "4",
          "a2": intlx.DateFormat("yyyy-MM-dd").format(DateTime.now()),
          "a3": userName,
        },
      );
      if (contractRes.data['success'] != true) {
        throw Exception(contractRes.data['message'] ?? 'فشل إنشاء العقد');
      }
      final String contractId = contractRes.data['data']['id'].toString();

      // 2. Presigned upload URL → Maintenance_Contracts_New
      final presignedRes = await getDio().post(
        '$_endpoint?k=${DateTime.now().millisecondsSinceEpoch}',
        data: {
          'action': 'getPresignedUrlS3',
          'contractId': contractId,
          'contractType': "4",
          'bookingId': _bookingId,
          'bookId': _bookingId,
        },
      );
      final String? presignedUrl = presignedRes.data['url']?.toString();
      final String? s3Key = presignedRes.data['key']?.toString();
      if (presignedUrl == null ||
          presignedUrl.isEmpty ||
          s3Key == null ||
          s3Key.isEmpty) {
        throw Exception('تعذر تجهيز رفع التوقيع');
      }
      if (!s3Key.contains('Maintenance_Contracts_New')) {
        debugPrint('Unexpected signature key: $s3Key');
      }

      // 3. Upload signature PNG to S3
      final Uint8List? signatureBytes = await signatureController.toPngBytes();
      if (signatureBytes == null || signatureBytes.isEmpty) {
        throw Exception('تعذر قراءة التوقيع');
      }
      await Dio().put(
        presignedUrl,
        data: signatureBytes,
        options: Options(
          headers: {
            'Content-Type': 'image/png',
            'Content-Length': signatureBytes.length,
          },
          validateStatus: (code) => code != null && code >= 200 && code < 300,
        ),
      );

      // 4. Wait until signature is readable on S3
      final publicSignUrl =
          'https://daltaliftstech.s3.ap-south-1.amazonaws.com/$s3Key';
      var signatureReady = false;
      for (var i = 0; i < 8; i++) {
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
        debugPrint('Signature not publicly readable yet for $contractId');
      }

      // 5. Persist signature key + link booking
      final upRes = await getDio().post(
        _endpoint,
        data: {
          'action': 'UploadSignature',
          'contractId': contractId,
          's3Key': s3Key,
          'bookingId': _bookingId,
          'bookId': _bookingId,
        },
      );
      if (upRes.data is Map && upRes.data['success'] != true) {
        throw Exception(upRes.data['message'] ?? 'فشل حفظ التوقيع');
      }

      await getDio().post(
        _endpoint,
        data: {
          'action': 'saveMaintenanceContract',
          'bookId': _bookingId,
          'bookingId': _bookingId,
          'contractId': contractId,
          'uid': uid,
        },
      );

      // 6. Generate signed PDF (retry)
      setState(() => isLoadingTxt = "جاري إنشاء العقد...");
      final pdfDio = Dio(
        BaseOptions(
          connectTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 90),
          validateStatus: (code) => code != null && code < 600,
        ),
      );

      Map? pdfPayload;
      for (var attempt = 1; attempt <= 3; attempt++) {
        final pdfResponse = await pdfDio.get(
          'https://daltalifts.com/app2026/pdf/index.php'
          '?contractId=$contractId&sign=1'
          '&ktype=4&batchId=$_bookingId',
        );
        if (pdfResponse.statusCode == 200 && pdfResponse.data is Map) {
          pdfPayload = Map<String, dynamic>.from(pdfResponse.data as Map);
          if (pdfPayload['success'] == true ||
              pdfPayload['success'] == 1 ||
              pdfPayload['success'] == 'true') {
            break;
          }
        }
        pdfPayload = null;
        await Future.delayed(Duration(milliseconds: 700 * attempt));
      }

      final pdfUrl = pdfPayload?['url']?.toString() ?? '';
      if (pdfUrl.isEmpty) {
        final err = pdfPayload?['error']?.toString() ?? '';
        throw Exception(
          err.isNotEmpty ? err : 'فشل إنشاء ملف العقد الموقّع',
        );
      }

      // 7. Download PDF locally
      setState(() => isLoadingTxt = "جاري تحميل العقد...");
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/maintenance_contract_$contractId.pdf');
      await pdfDio.download(pdfUrl, file.path);

      // 8. Telegram: prefer uploading the local signed file
      setState(() => isLoadingTxt = "جاري الإرسال...");
      try {
        const botToken =
            '8499367531:AAEnMG1yvNeAIanEgCbyYGlXWuYWImeTMyI';
        const chatId = '-1003877690157';
        final caption = """
🔧 <b>عقد صيانة جديد (موقّع)</b>

📋 <b>رقم العقد:</b> $contractId
🔢 <b>رقم الطلب:</b> $_bookingId
👤 <b>العميل:</b> $userName
📞 <b>الهاتف:</b> $userPhone
🗓 <b>التاريخ:</b> ${DateTime.now().toString().substring(0, 10)}
""";
        await Dio().post(
          'https://api.telegram.org/bot$botToken/sendDocument',
          data: FormData.fromMap({
            'chat_id': chatId,
            'caption': caption,
            'parse_mode': 'HTML',
            'document': await MultipartFile.fromFile(
              file.path,
              filename: 'maintenance_contract_$contractId.pdf',
            ),
          }),
        );
      } catch (e) {
        // Fallback: send by public S3 URL
        try {
          await Dio().post(
            'https://api.telegram.org/bot8499367531:AAEnMG1yvNeAIanEgCbyYGlXWuYWImeTMyI/sendDocument',
            queryParameters: {
              'chat_id': '-1003877690157',
              'document': pdfUrl,
              'caption': 'عقد صيانة #$contractId - $userName',
              'parse_mode': 'HTML',
            },
          );
        } catch (e2) {
          debugPrint('Telegram send skipped: $e2');
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text("تم توقيع العقد وتحميله ✓"),
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

        final p = await SharedPreferences.getInstance();
        await p.remove('contractApproved_$_bookingId');
        await p.remove('maint_booking_id');

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const RepairScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      debugPrint('Sign error: $e');
      if (mounted) {
        final msg = e.toString().replaceFirst('Exception: ', '');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              msg.isNotEmpty && msg != 'null'
                  ? msg
                  : "حدث خطأ أثناء التوقيع",
            ),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildSignatureStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: RepairTheme.cardDecoration(),
            child: Text(
              "يرجى التوقيع على عقد الصيانة",
              textAlign: TextAlign.right,
              style: RepairTheme.cairo(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: RepairTheme.textPrimary,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            height: 200,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: RepairTheme.orange, width: 2),
            ),
            child: Stack(
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
                      return Center(
                        child: Text(
                          "قم بالتوقيع هنا",
                          style: RepairTheme.cairo(
                            fontSize: 15,
                            color: RepairTheme.textSecondary,
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
          ),
        ],
      ),
    );
  }

  Widget _buildApproveButton() {
    return SafeArea(
      child: RepairTheme.primaryButton(
        label: "الموافقة على العقد",
        icon: Iconsax.tick_circle,
        onTap: () async {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('contractApproved_$_bookingId', true);
          if (!mounted) return;
          setState(() => _contractApproved = true);
        },
      ),
    );
  }

  Widget _buildUploadButton() {
    return SafeArea(
      child: RepairTheme.primaryButton(
        label: "تأكيد التوقيع",
        icon: Iconsax.pen_add,
        loading: _isLoading,
        onTap: _isLoading ? null : _signAndUpload,
        loadingChild: Row(
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
              style: RepairTheme.cairo(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_contractReady) {
      // Stage 1: waiting ERP approval of the request
      // Stage 2: approved → preparing contract (still no PDF)
      if (_erpApproved) {
        return const ContractWait(
          title: 'جاري تجهيز العقد',
          message:
              'تمت الموافقة على طلبك. جاري تجهيز عقد الصيانة من قبل الشركة. سيظهر العقد هنا تلقائياً فور إرساله لمراجعتك وتوقيعه.',
        );
      }
      return const ContractWait(
        title: 'في انتظار الموافقة',
        message:
            'تم استلام طلبك بنجاح. في انتظار موافقة الشركة على طلب الصيانة. بعد الموافقة سيبدأ تجهيز العقد.',
      );
    }

    final showPdfStep = !_contractApproved;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: RepairTheme.bg,
        appBar: AppBar(
          backgroundColor: RepairTheme.cardBg,
          elevation: 0,
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Iconsax.arrow_right_3, color: RepairTheme.orange),
            onPressed: () => Navigator.maybePop(context),
          ),
          title: Text(
            showPdfStep ? "عقد الصيانة" : "توقيع العقد",
            style: RepairTheme.cairo(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: RepairTheme.textPrimary,
            ),
          ),
        ),
        body: showPdfStep
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
                        child: PDFView(
                          filePath: _localPdfPath!,
                          enableSwipe: true,
                          swipeHorizontal: false,
                          autoSpacing: true,
                          pageFling: true,
                          fitEachPage: true,
                          fitPolicy: FitPolicy.BOTH,
                        ),
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
            : _buildSignatureStep(),
        bottomNavigationBar: showPdfStep
            ? _buildApproveButton()
            : _buildUploadButton(),
      ),
    );
  }
}
