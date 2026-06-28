import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:Delta/provider/app_provider.dart';
import 'package:Delta/screens/booking/contract/contract_theme.dart';
import 'package:Delta/services/DioServiceCert.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:iconsax/iconsax.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
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
  late SignatureController signatureController = SignatureController(
    penStrokeWidth: 5,
    penColor: Colors.black,
  );

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
        ),
      );

      var response = await getDio().post(
        'https://daltalifts.com/app2026/sql.php',
        data: {
          'action': 'UploadSignature',
          'contractId': signId,
          's3Key': s3Key,
        },
      );

      if (response.data['success'] == true) {
        downloadAndUploadPdf(signId);
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
    String? oid = prefx.getString("orderId");
    try {
      setState(() => isLoadingTxt = "جاري عمل بي دي اف");

      var dio = Dio();
      var response = await dio.get(
        'https://daltalifts.com/app2026/pdf/index.php?contractId=$signId&sign=1&orderId=$oid&ktype=1',
      );

      if (response.data['success'] == true) {
        String pdfUrl = response.data['url'];

        setState(() => isLoadingTxt = "جاري تحميل العقد");

        final directory = await getApplicationDocumentsDirectory();
        final filePath = '${directory.path}/contract_$signId.pdf';

        await dio.download(pdfUrl, filePath);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 8),
                  Text("تم تحميل العقد على جهازك ✓"),
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
        }

        setState(() {
          prefx.setString(
            "orderId",
            (1000 + Random().nextInt(9000)).toString(),
          );
          _isLoading = false;
          isLoadingTxt = "إرسال العقد الى الشركة";
          stt = '1';
        });
        Provider.of<AppProvider>(context, listen: false).jumpToTabx(1);
      }
    } catch (e) {
      print('Error: $e');
      if (mounted) setState(() => _isLoading = false);
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

  Future<void> _downloadPdf() async {
    try {
      if (!_contractApproved) setState(() => _pdfLoading = true);

      final response = await Dio().get(
        'https://daltalifts.com/app2026/PDF_Final/index.php?ktype=1&batchId=${widget.bookDets[0]['id']}',
        options: Options(responseType: ResponseType.bytes),
      );
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/contract_${widget.bookDets[0]['id']}.pdf');
      await file.writeAsBytes(response.data);

      if (mounted) {
        setState(() {
          _localPdfPath = file.path;
          if (!_contractApproved) _pdfLoading = false;
        });
      }
    } catch (e) {
      print('PDF error: $e');
      if (mounted && !_contractApproved) {
        setState(() => _pdfLoading = false);
      }
    }
  }

  @override
  void initState() {
    super.initState();
    if (widget.bookDets.isNotEmpty) {
      _contractApproved =
          widget.bookDets[0]['stt'] == '1' || widget.bookDets[0]['stt'] == '2';
      if (!_contractApproved) {
        _downloadPdf();
      }
      if (widget.bookDets[0]['stt'] == '1') {
        isLoadingTxt = "تحميل العقد";
      }
    }
  }

  Widget _buildSignatureStep() {
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
          Container(
            width: double.infinity,
            height: 200,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: ContractTheme.orange, width: 2),
            ),
            child: widget.bookDets[0]['stt'] == '1' || stt.toString() == '1'
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.network(
                      "https://daltaliftstech.s3.ap-south-1.amazonaws.com/Mobile_App/signatures/IIP_Contracts/signature_${widget.bookDets[0]['contract_id']}.png",
                      fit: BoxFit.contain,
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
          ),
        ],
      ),
    );
  }

  Widget _buildUploadButton() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: GestureDetector(
          onTap: () async {
            if (_isLoading) return;

            if (isLoadingTxt == "إرسال العقد الى الشركة") {
              setState(() => _isLoading = true);
              try {
                String msg =
                    """
                          🔔 <b>تنبيه داخلي — عقد جديد للتنفيذ</b>

                          نُفيدكم بأنه تم إصدار عقد توريد وتركيب مصعد جديد ويستلزم متابعتكم.

                          📋 <b>تفاصيل العقد:</b>
                          🔢 رقم العقد: <b>${widget.bookDets[0]['contract_id']}</b>
                          👤 اسم العميل: <b>${widget.bookDets[0]['a1']}</b>
                          📍 موقع التركيب: <b>${widget.bookDets[0]['city']}</b>
                          🗓 تاريخ البدء: <b>${widget.bookDets[0]['date']}</b>

                          يُرجى مراجعة العقد المرفق والتنسيق مع المسؤول لجدولة أعمال التركيب.
                          """;
                var response = await Dio().get(
                  'https://daltalifts.com/app2026/pdf/index.php?contractId=${widget.bookDets[0]['contract_id']}&sign=1&orderId=${widget.bookDets[0]['orderId']}&ktype=1',
                );
                await sendTelegramMessageDocs(
                  s3PdfUrl: response.data['url'],
                  message: msg,
                );
              } finally {
                if (mounted) setState(() => _isLoading = false);
              }
              return;
            }

            if (widget.bookDets[0]['stt'] == '1' || stt == '1') {
              setState(() => _isLoading = true);
              try {
                final contractId = widget.bookDets[0]['contract_id'];
                final orderId = widget.bookDets[0]['orderId'];

                var response = await Dio().get(
                  'https://daltalifts.com/app2026/pdf/index.php?contractId=$contractId&sign=1&orderId=$orderId&ktype=1',
                );

                if (response.data['success'] == true) {
                  String pdfUrl = response.data['url'];

                  setState(() => isLoadingTxt = "جاري التحميل...");

                  if (Platform.isAndroid) {
                    await Permission.storage.request();
                  }

                  Directory? dir;
                  if (Platform.isAndroid) {
                    dir = Directory('/storage/emulated/0/Download');
                  } else {
                    dir = await getApplicationDocumentsDirectory();
                  }

                  final file =
                      File('${dir.path}/delta_contract_$contractId.pdf');
                  await Dio().download(pdfUrl, file.path);

                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Row(
                          children: [
                            const Icon(Icons.check_circle, color: Colors.white),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                "تم تحميل العقد في Downloads ✓",
                                style: const TextStyle(color: Colors.white),
                              ),
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
                    setState(() {
                      _isLoading = false;
                      isLoadingTxt = "تحميل العقد";
                    });
                  }
                }
              } catch (e) {
                print('Download error: $e');
                if (mounted) setState(() => _isLoading = false);
              }
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
                if (mounted) setState(() => _isLoading = false);
              }
            } catch (e) {
              if (mounted) setState(() => _isLoading = false);
            }
          },
          child: Container(
            height: 56,
            decoration: ContractTheme.primaryGradientButton(),
            alignment: Alignment.center,
            child: _isLoading
                ? (isLoadingTxt == "تحميل العقد" ||
                          isLoadingTxt == "إرسال العقد الى الشركة"
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : Row(
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
                              style: const TextStyle(color: Colors.white),
                            ),
                          ],
                        ))
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Iconsax.send_1, color: Colors.white, size: 22),
                      const SizedBox(width: 8),
                      Text(
                        isLoadingTxt,
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

  Widget _buildApproveButton() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: GestureDetector(
          onTap: () async {
            await Dio().post(
              "https://daltalifts.com/app2026/sql.php",
              data: {
                "action": "approveContract",
                "bookId": widget.bookDets[0]['id'].toString(),
              },
            );
            setState(() => _contractApproved = true);
          },
          child: Container(
            height: 56,
            decoration: ContractTheme.primaryGradientButton(),
            alignment: Alignment.center,
            child: const Row(
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
        widget.bookDets.isNotEmpty &&
        !_contractApproved &&
        widget.bookDets[0]['stt'] != '1';
    final showSignatureStep =
        widget.bookDets.isNotEmpty &&
        (_contractApproved || widget.bookDets[0]['stt'] == '1');

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
