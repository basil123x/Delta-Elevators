import 'dart:math';
import 'dart:typed_data';

import 'package:Delta/provider/app_provider.dart';
import 'package:Delta/screens/booking/contract/contract_theme.dart';
import 'package:Delta/services/DioServiceCert.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
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
  String signText = "قم بالتوقيع هنا";
  String stt = "";
  bool _isLoading = false;
  String isLoadingTxt = "تحميل العقد";
  String pdfSend = "";
  late SignatureController signatureController = SignatureController(
    penStrokeWidth: 5,
    penColor: Colors.black,
    onDrawStart: () {
      setState(() {
        signText = "";
      });
    },
  );

  @override
  void dispose() {
    signatureController.dispose();
    super.dispose();
  }

  Future<void> uploadSignature(signId) async {
    if (signatureController.value.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('من فضلك قم بالتوقيع أولاً')));
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
        'contractType': "1"
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
      setState(() {
        isLoadingTxt = "جاري عمل بي دي اف";
      });
      var dio = Dio();

      var response = await dio.get(
        'https://daltalifts.com/app2026/pdf/index.php?contractId=$signId&sign=1&orderId=$oid&ktype=1',
      );
      if (response.data['success'] == true) {
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

  @override
  void initState() {
    widget.bookDets[0]['stt'] == '1'
        ? isLoadingTxt = "إرسال العقد الى الشركة"
        : isLoadingTxt = "تحميل العقد";
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    print(widget.bookDets);
    return Scaffold(
      backgroundColor: ContractTheme.bg,
      body: widget.bookDets.isEmpty
          ? const SizedBox()
          : SingleChildScrollView(
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
                      border: Border.all(
                        color: ContractTheme.orange,
                        width: 2,
                      ),
                    ),
                    child: widget.bookDets[0]['stt'] == '1' ||
                            stt.toString() == '1'
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: Image.network(
                              "https://daltaliftstech.s3.ap-south-1.amazonaws.com/Mobile_App/signatures/IIP_Contracts/signature_${widget.bookDets[0]['contract_id']}.png",
                              fit: BoxFit.contain,
                            ),
                          )
                        : Stack(
                            children: [
                              if (signText.isNotEmpty)
                                Center(
                                  child: Text(
                                    signText,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      color: ContractTheme.textSecondary,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ),
                              Signature(
                                height: 200,
                                controller: signatureController,
                                backgroundColor: Colors.transparent,
                              ),
                              if (signText.isEmpty)
                                Positioned(
                                  top: 8,
                                  right: 8,
                                  child: IconButton(
                                    onPressed: () {
                                      setState(() {
                                        signText = "قم بالتوقيع هنا";
                                        signatureController.clear();
                                      });
                                    },
                                    icon: const Icon(
                                      Iconsax.trash,
                                      color: Color(0xFFEF4444),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                  ),
                ],
              ),
            ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: GestureDetector(
            onTap: () async {
              if (_isLoading) return;

              if (isLoadingTxt == "إرسال العقد الى الشركة") {
                setState(() => _isLoading = true);
                try {
                  String msg = """
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
                  "a3": widget.bookDets[0]['a1']
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
                        const Icon(
                          Iconsax.send_1,
                          color: Colors.white,
                          size: 22,
                        ),
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
      ),
    );
  }
}
