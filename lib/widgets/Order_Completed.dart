import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:Delta/screens/booking/contract/contract_theme.dart';
import 'package:Delta/services/DioServiceCert.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:iconsax/iconsax.dart';
import 'package:path_provider/path_provider.dart';
import 'package:signature/signature.dart';

class OrderCompleted extends StatefulWidget {
  final String bookId;
  const OrderCompleted({super.key, required this.bookId});

  @override
  State<OrderCompleted> createState() => _OrderCompletedState();
}

class _OrderCompletedState extends State<OrderCompleted> {
  bool _pdfLoading = true;
  String? _localPdfPath;
  bool _isSigned = false;
  Timer? _liveTimer;

  String get pdfUrl =>
      "https://daltalifts.com/app2026/PDF_Final/index.php?ktype=3&batchId=${widget.bookId}";

  @override
  void initState() {
    super.initState();
    _checkDeliveryStatus();
    _loadPdfBytes();
    _liveTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      _checkDeliveryStatus(silent: true);
      if (_localPdfPath == null && !_pdfLoading) {
        _loadPdfBytes();
      }
    });
  }

  @override
  void dispose() {
    _liveTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadPdfBytes() async {
    try {
      final response = await Dio().get(
        'https://daltalifts.com/app2026/PDF_Final/index.php?ktype=3&batchId=${widget.bookId}',
        options: Options(responseType: ResponseType.bytes),
      );
      final bytes = Uint8List.fromList(response.data);
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/delivery_${widget.bookId}.pdf');
      await file.writeAsBytes(bytes);
      if (mounted) {
        setState(() {
          _localPdfPath = file.path;
          _pdfLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _pdfLoading = false);
    }
  }

  Future<void> _checkDeliveryStatus({bool silent = false}) async {
    try {
      final result = await Dio().post(
        "https://daltalifts.com/app2026/sql.php",
        data: {
          "action": "getDeliveryStatus",
          "bookId": widget.bookId,
        },
      );
      final signed = result.data['signed'] == true;
      if (!mounted) return;
      if (silent && signed == _isSigned) return;
      if (signed != _isSigned) {
        setState(() => _isSigned = signed);
      }
    } catch (e) {}
  }

  void _openPdfViewer() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PdfViewerScreen(pdfUrl: pdfUrl),
      ),
    );
  }

  void _openSigningFlow() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DeliverySigningScreen(
          localPdfPath: _localPdfPath,
          pdfLoading: _pdfLoading,
          bookId: widget.bookId,
          onSigned: () => setState(() => _isSigned = true),
        ),
      ),
    ).then((_) => _checkDeliveryStatus());
  }

  @override
  Widget build(BuildContext context) {
    if (_isSigned) {
      return GestureDetector(
        onTap: _openPdfViewer,
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.red.shade700,
            borderRadius: BorderRadius.circular(7),
          ),
          child: const Icon(Iconsax.document, color: Colors.white, size: 24),
        ),
      );
    }

    return GestureDetector(
      onTap: _openSigningFlow,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: ContractTheme.orange,
          borderRadius: BorderRadius.circular(7),
        ),
        child: const Icon(Iconsax.pen_add, color: Colors.white, size: 22),
      ),
    );
  }
}

class DeliverySigningScreen extends StatefulWidget {
  final String? localPdfPath;
  final bool pdfLoading;
  final String bookId;
  final VoidCallback onSigned;

  const DeliverySigningScreen({
    super.key,
    required this.localPdfPath,
    required this.pdfLoading,
    required this.bookId,
    required this.onSigned,
  });

  @override
  State<DeliverySigningScreen> createState() => _DeliverySigningScreenState();
}

class _DeliverySigningScreenState extends State<DeliverySigningScreen> {
  bool _approvedLocally = false;
  bool _isSigning = false;
  String _signingText = "تأكيد التوقيع";
  late SignatureController signatureController;

  @override
  void initState() {
    super.initState();
    signatureController = SignatureController(
      penStrokeWidth: 5,
      penColor: Colors.black,
      onDrawEnd: () {
        if (signatureController.value.isNotEmpty) setState(() {});
      },
    );
  }

  @override
  void dispose() {
    signatureController.dispose();
    super.dispose();
  }

  Future<void> _signAndUpload() async {
    if (signatureController.value.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('من فضلك قم بالتوقيع أولاً')),
      );
      return;
    }
    setState(() {
      _isSigning = true;
      _signingText = "جاري رفع التوقيع...";
    });
    try {
      // 1. Add contract
      final contractResponse = await getDio().post(
        "https://daltalifts.com/app2026/sql.php?k=${DateTime.now().millisecondsSinceEpoch}",
        data: {"action": "addContract", "type": "3", "a2": "", "a3": ""},
      );
      if (contractResponse.data['success'] != true) throw Exception('فشل');
      final contractId = contractResponse.data['data']['id'].toString();

      // 2. Get presigned URL
      final presignedRes = await getDio().post(
        'https://daltalifts.com/app2026/sql.php?k=${DateTime.now().millisecondsSinceEpoch}',
        data: {
          'action': 'getPresignedUrlS3',
          'contractId': contractId,
          'contractType': "3",
        },
      );
      final presignedUrl = presignedRes.data['url'];
      final s3Key = presignedRes.data['key'];

      // 3. Upload signature
      final Uint8List? signatureBytes = await signatureController.toPngBytes();
      await Dio().put(
        presignedUrl,
        data: signatureBytes,
        options: Options(headers: {
          'Content-Type': 'image/png',
          'Content-Length': signatureBytes!.length,
        }),
      );

      // 4. Save signature record
      await getDio().post(
        'https://daltalifts.com/app2026/sql.php',
        data: {
          'action': 'UploadSignature',
          'contractId': contractId,
          's3Key': s3Key,
        },
      );

      // 5. Save delivery contract to booking
      await Dio().post(
        "https://daltalifts.com/app2026/sql.php",
        data: {
          "action": "saveDeliveryContract",
          "bookId": widget.bookId,
          "contractId": contractId,
        },
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 8),
              Text("تم توقيع محضر التسليم ✓"),
            ]),
            backgroundColor: const Color(0xFF4CAF50),
            duration: const Duration(seconds: 4),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
        );
        widget.onSigned();
        Navigator.pop(context);
      }
    } catch (e) {
      print('Sign error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('حدث خطأ أثناء التوقيع')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSigning = false;
          _signingText = "تأكيد التوقيع";
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ContractTheme.bg,
      appBar: AppBar(
        title: Text(_approvedLocally ? 'توقيع الاستلام' : 'محضر التسليم'),
        backgroundColor: Colors.red.shade700,
        iconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: const TextStyle(color: Colors.white, fontSize: 18),
      ),
      body: !_approvedLocally
          ? Padding(
              padding: const EdgeInsets.all(16),
              child: widget.pdfLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                          color: Color(0xFFF37021)))
                  : widget.localPdfPath != null
                      ? PDFView(
                          filePath: widget.localPdfPath!,
                          enableSwipe: true,
                          swipeHorizontal: false,
                          autoSpacing: true,
                          pageFling: true,
                          fitEachPage: true,
                          fitPolicy: FitPolicy.BOTH,
                        )
                      : const Center(
                          child: Text("تعذر تحميل المحضر",
                              style: TextStyle(color: Colors.grey))),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              child: Column(children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: ContractTheme.cardDecoration(),
                  child: const Text(
                    "يرجى التوقيع على محضر استلام المصعد",
                    textAlign: TextAlign.right,
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: ContractTheme.textPrimary),
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: ContractTheme.orange, width: 2),
                  ),
                  child: Stack(children: [
                    Signature(
                        height: 200,
                        controller: signatureController,
                        backgroundColor: Colors.transparent),
                    ValueListenableBuilder<List>(
                      valueListenable: signatureController,
                      builder: (context, value, child) => value.isEmpty
                          ? const Center(
                              child: Text("قم بالتوقيع هنا",
                                  style: TextStyle(
                                      fontSize: 15,
                                      color: ContractTheme.textSecondary,
                                      fontStyle: FontStyle.italic)))
                          : const SizedBox.shrink(),
                    ),
                    ValueListenableBuilder<List>(
                      valueListenable: signatureController,
                      builder: (context, value, child) => value.isNotEmpty
                          ? Positioned(
                              top: 8,
                              right: 8,
                              child: IconButton(
                                  onPressed: () => signatureController.clear(),
                                  icon: const Icon(Iconsax.trash,
                                      color: Color(0xFFEF4444))))
                          : const SizedBox.shrink(),
                    ),
                  ]),
                ),
              ]),
            ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: !_approvedLocally
              ? GestureDetector(
                  onTap: () => setState(() => _approvedLocally = true),
                  child: Container(
                    height: 56,
                    decoration: ContractTheme.primaryGradientButton(),
                    alignment: Alignment.center,
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Iconsax.tick_circle,
                            color: Colors.white, size: 22),
                        SizedBox(width: 8),
                        Text("الموافقة على الاستلام",
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: Colors.white)),
                      ],
                    ),
                  ),
                )
              : GestureDetector(
                  onTap: _isSigning ? null : _signAndUpload,
                  child: Container(
                    height: 56,
                    decoration: ContractTheme.primaryGradientButton(),
                    alignment: Alignment.center,
                    child: _isSigning
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                      color: Colors.white, strokeWidth: 2.5)),
                              const SizedBox(width: 12),
                              Text(_signingText,
                                  style: const TextStyle(color: Colors.white)),
                            ])
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Iconsax.pen_add,
                                  color: Colors.white, size: 22),
                              SizedBox(width: 8),
                              Text("تأكيد التوقيع",
                                  style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white)),
                            ]),
                  ),
                ),
        ),
      ),
    );
  }
}

class PdfViewerScreen extends StatefulWidget {
  final String pdfUrl;
  const PdfViewerScreen({super.key, required this.pdfUrl});

  @override
  State<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends State<PdfViewerScreen> {
  String? localPath;
  bool isLoading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _downloadPdf();
  }

  Future<void> _downloadPdf() async {
    try {
      final response = await Dio().get(
        widget.pdfUrl,
        options: Options(responseType: ResponseType.bytes),
      );
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/delivery_view.pdf');
      await file.writeAsBytes(response.data);
      if (!mounted) return;
      setState(() {
        localPath = file.path;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        error = 'فشل تحميل الملف';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('محضر التسليم'),
        backgroundColor: Colors.red.shade700,
        iconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: const TextStyle(color: Colors.white, fontSize: 18),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : error != null
              ? Center(
                  child: Text(error!, style: const TextStyle(color: Colors.red)),
                )
              : PDFView(
                  filePath: localPath!,
                  enableSwipe: true,
                  swipeHorizontal: false,
                  autoSpacing: true,
                  pageFling: true,
                ),
    );
  }
}
