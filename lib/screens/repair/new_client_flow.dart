import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

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

/// Step 2 of the new-client maintenance flow: preview the maintenance contract
/// PDF (ktype=4), approve it, sign it, upload the signature to S3 with
/// contractType="4", then continue to the repair request screen.
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
  bool _contractApproved = false;
  bool _pdfLoading = true;
  String? _localPdfPath;
  bool _isLoading = false;
  String isLoadingTxt = "جاري رفع التوقيع...";

  late SignatureController signatureController = SignatureController(
    penStrokeWidth: 5,
    penColor: Colors.black,
  );

  static const String _endpoint = "https://daltalifts.com/app2026/sql.php";

  @override
  void initState() {
    super.initState();
    _contractApproved = widget.startFromSignature;
    _downloadPdf();
  }

  @override
  void dispose() {
    signatureController.dispose();
    super.dispose();
  }

  Future<void> _downloadPdf() async {
    try {
      final response = await Dio().get(
        'https://daltalifts.com/app2026/PDF_Final/index.php?ktype=4&batchId=${widget.bookingId}',
        options: Options(responseType: ResponseType.bytes),
      );
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/maint_contract_${widget.bookingId}.pdf');
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
      // 1. Create the maintenance contract record.
      final contractRes = await getDio().post(
        "$_endpoint?k=${DateTime.now().millisecondsSinceEpoch}",
        data: {
          "action": "addContract",
          "type": "4",
          "a2": intlx.DateFormat(
            "yyyy-MM-dd",
          ).format(DateTime.now()).toString(),
          "a3": "",
        },
      );
      if (contractRes.data['success'] != true) {
        throw Exception(contractRes.data['message'] ?? 'فشل إنشاء العقد');
      }
      final String contractId = contractRes.data['data']['id'].toString();

      // 2. Get a presigned upload URL (contractType 4 ->
      //    Maintenance_Contracts_New on the server).
      final presignedRes = await getDio().post(
        '$_endpoint?k=${DateTime.now().millisecondsSinceEpoch}',
        data: {
          'action': 'getPresignedUrlS3',
          'contractId': contractId,
          'contractType': "4",
        },
      );
      final String presignedUrl = presignedRes.data['url'];
      final String s3Key = presignedRes.data['key'];

      // 3. Upload the signature image to S3.
      final Uint8List? signatureBytes = await signatureController.toPngBytes();
      await Dio().put(
        presignedUrl,
        data: signatureBytes,
        options: Options(
          headers: {
            'Content-Type': 'image/png',
            'Content-Length': signatureBytes!.length,
          },
        ),
      );

      // 4. Persist the signature key on the server.
      await getDio().post(
        _endpoint,
        data: {
          'action': 'UploadSignature',
          'contractId': contractId,
          's3Key': s3Key,
        },
      );

      // 5. Save contract to booking.
      final saveResult = await getDio().post(
        _endpoint,
        data: {
          'action': 'saveMaintenanceContract',
          'bookId': widget.bookingId,
          'contractId': contractId,
        },
      );
      print("DEBUG step5 save: ${saveResult.data}");

      // 6. Generate PDF with signature and upload to S3.
      setState(() => isLoadingTxt = "جاري إنشاء العقد...");
      final prefs = await SharedPreferences.getInstance();
      final orderId = prefs.getString("orderId") ?? "";
      final pdfResponse = await Dio().get(
        'https://daltalifts.com/app2026/pdf/index.php?contractId=$contractId&sign=1&orderId=$orderId&ktype=4&batchId=${widget.bookingId}',
      );
      final pdfUrl = pdfResponse.data['url'];
      print("DEBUG pdfResponse: ${pdfResponse.data}");
      print("DEBUG pdfUrl: $pdfUrl");

      // 7. Download PDF to device Downloads folder.
      setState(() => isLoadingTxt = "جاري تحميل العقد...");
      final dir = Platform.isAndroid
          ? Directory('/storage/emulated/0/Download')
          : await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/maintenance_contract_$contractId.pdf');
      await Dio().download(pdfUrl, file.path);
      print("DEBUG file path: ${file.path}");
      print("DEBUG file exists: ${await file.exists()}");

      // 8. Send to Telegram.
      setState(() => isLoadingTxt = "جاري الإرسال...");
      final profileResult = await getDio().post(
        _endpoint,
        data: {"action": "profile", "uid": prefs.getString("userId") ?? ""},
      );
      final userName = profileResult.data['data']['a1'] ?? '';
      final userPhone = profileResult.data['data']['a2'] ?? '';
      await Dio().post(
        'https://api.telegram.org/bot8499367531:AAEnMG1yvNeAIanEgCbyYGlXWuYWImeTMyI/sendDocument',
        queryParameters: {
          'chat_id': '-1003877690157',
          'document': pdfUrl,
          'caption':
              """
🔧 <b>عقد صيانة جديد</b>

📋 <b>رقم العقد:</b> $contractId
👤 <b>العميل:</b> $userName
📞 <b>الهاتف:</b> $userPhone
🗓 <b>التاريخ:</b> ${DateTime.now().toString().substring(0, 10)}
    """,
          'parse_mode': 'HTML',
        },
      );

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

        // Clear approval flag.
        final p = await SharedPreferences.getInstance();
        await p.remove('contractApproved_${widget.bookingId}');

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => RepairScreen()),
          (route) => false, // removes everything including RepairFirst
        );
      }
    } catch (e) {
      print('Sign error: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("حدث خطأ أثناء التوقيع")));
        setState(() => _isLoading = false);
      }
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
          await prefs.setBool('contractApproved_${widget.bookingId}', true);
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
