import 'dart:math';
import 'dart:typed_data';

import 'package:Delta/constants/app_colors.dart';
import 'package:Delta/provider/app_provider.dart';
import 'package:Delta/screens/repair/repair_theme.dart';
import 'package:Delta/services/DioServiceCert.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:signature/signature.dart';

class RepairContract extends StatefulWidget {
  final List bookDets;
  const RepairContract({super.key, required this.bookDets});

  @override
  State<RepairContract> createState() => _RepairContractState();
}

class _RepairContractState extends State<RepairContract> {
  String signText = "قم بالتوقيع هنا";
  String stt = "";
  TextEditingController batchController = TextEditingController();
  TextEditingController batchController1 = TextEditingController();
  TextEditingController batchController2 = TextEditingController();
  bool isLoading = false;
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

  final Uint8List? signatureBytes = await signatureController.toPngBytes();

  // 1. اجيب presigned URL من السيرفر
  var res = await getDio().post(
    'https://daltalifts.com/app2026/sql.php?k=${DateTime.now().millisecondsSinceEpoch}',
    data: {'action': 'getPresignedUrlS3', 'RepairContractId': signId},
  );

  String presignedUrl = res.data['url'];
  String s3Key = res.data['key'];

  // 2. ارفع على S3 مباشرة
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

  // 3. ابعت الـ key للسيرفر عشان يحفظه في DB
  var response = await getDio().post(
    'https://daltalifts.com/app2026/sql.php',
    data: {
      'action': 'UploadSignature',
      'RepairContractId': signId,
      's3Key': s3Key,
    },
  );

  if (response.data['success'] == true) {
    downloadAndUploadPdf(signId);
  } else {
    throw Exception(response.data['message'] ?? 'خطأ في الحفظ');
  }
}

  // استخدام كامل:
  Future downloadAndUploadPdf(signId) async {
    SharedPreferences prefx = await SharedPreferences.getInstance();
    String? oid = prefx.getString("orderId");
    try {
      setState(() {
        isLoadingTxt = "جاري عمل بي دي اف";
      });
      var dio = Dio();

      // اطلب PDF مباشرة من السيرفر
      var response = await dio.get(
        'https://daltalifts.com/app2026/pdf/index.php?RepairContractId=$signId&sign=1&orderId=$oid&ktype=1',
      );
      print(response.data);
      if (response.data['success'] == true) {
        setState(() {
          prefx.setString(
            "orderId",
            (1000 + Random().nextInt(9000)).toString(),
          );
          isLoading = false;
          isLoadingTxt = "إرسال العقد الى الشركة";
          stt = '1';
        });
        Provider.of<AppProvider>(context, listen: false).jumpToTabx(1);
      }
 
    } catch (e) {
      print('Error: $e');
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

  @override
  void initState() {
    widget.bookDets[0]['stt'] == '1'
        ? isLoadingTxt = "إرسال العقد الى الشركة"
        : isLoadingTxt = "تحميل العقد";
    if (widget.bookDets[0]['stt'] == '1') {
      batchController.text = widget.bookDets[0]['a16'];
      batchController1.text = widget.bookDets[0]['a17'];
      batchController2.text = widget.bookDets[0]['a18'];
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: RepairTheme.bg,
        appBar: AppBar(
          backgroundColor: RepairTheme.cardBg,
          elevation: 0,
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(
              Iconsax.arrow_right_3,
              color: RepairTheme.orange,
            ),
            onPressed: () => Navigator.maybePop(context),
          ),
          title: Text(
            "توقيع العقد",
            style: RepairTheme.cairo(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: RepairTheme.textPrimary,
            ),
          ),
        ),
        body: widget.bookDets.isEmpty
            ? const SizedBox()
            : SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                child: Column(
                  children: [
                    RepairTheme.infoTile(
                      icon: Iconsax.user,
                      label: "الإسم",
                      value: widget.bookDets[0]['a1'].toString(),
                    ),
                    RepairTheme.infoTile(
                      icon: Iconsax.call,
                      label: "رقم الهاتف",
                      value: widget.bookDets[0]['a2'].toString(),
                    ),
                    RepairTheme.infoTile(
                      icon: Iconsax.calendar,
                      label: "التاريخ",
                      value: widget.bookDets[0]['date'].toString(),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: BatchInp(
                            batchController: batchController,
                            text: "الاولى",
                            isEnabled:
                                widget.bookDets[0]['stt'] != '1' &&
                                    stt.toString() != '1'
                                ? true
                                : false,
                          ),
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: BatchInp(
                            batchController: batchController1,
                            text: "الثانية",
                            isEnabled:
                                widget.bookDets[0]['stt'] != '1' &&
                                    stt.toString() != '1'
                                ? true
                                : false,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 10),
                    BatchInp(
                      batchController: batchController2,
                      text: "الثالثة",
                      isEnabled:
                          widget.bookDets[0]['stt'] != '1' &&
                              stt.toString() != '1'
                          ? true
                          : false,
                    ),
                    SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      height: 200,
                      decoration: BoxDecoration(
                        color: RepairTheme.cardBg,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: RepairTheme.orange,
                          width: 2,
                        ),
                      ),
                      child: widget.bookDets[0]['stt'] == '1' ||
                              stt.toString() == '1'
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(14),
                              child: Image.network(
                                "https://daltaliftstech.s3.ap-south-1.amazonaws.com/Mobile_App/signatures/signature_${widget.bookDets[0]['RepairContract_id']}.png",
                                fit: BoxFit.contain,
                              ),
                            )
                          : Stack(
                              children: [
                                if (signText.isNotEmpty)
                                  Center(
                                    child: Text(
                                      signText,
                                      style: RepairTheme.cairo(
                                        fontSize: 15,
                                        color: RepairTheme.textSecondary,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ),
                                Signature(
                                  height: 200,
                                  controller: signatureController,
                                  backgroundColor: Colors.transparent,
                                ),
                                const Positioned(
                                  top: 8,
                                  left: 8,
                                  child: Icon(
                                    Iconsax.edit_2,
                                    color: RepairTheme.orange,
                                    size: 22,
                                  ),
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
          child: RepairTheme.primaryButton(
          label: isLoadingTxt,
          loading: isLoading,
          icon: Iconsax.document_download,
          gradient: isLoadingTxt == "إرسال العقد الى الشركة" ||
                  widget.bookDets[0]['stt'] == '1'
              ? const LinearGradient(
                  colors: [Color(0xFF189D0E), Color(0xFF22C55E)],
                )
              : RepairTheme.primaryGradient,
          onTap: isLoading ? null : () async {
            if (isLoadingTxt == "إرسال العقد الى الشركة") {
              String msg = """
                          🔔 <b>تنبيه داخلي — عقد جديد للتنفيذ</b>

                          نُفيدكم بأنه تم إصدار عقد توريد وتركيب مصعد جديد ويستلزم متابعتكم.

                          📋 <b>تفاصيل العقد:</b>
                          🔢 رقم العقد: <b>${widget.bookDets[0]['RepairContract_id']}</b>
                          👤 اسم العميل: <b>${widget.bookDets[0]['a1']}</b>
                          📍 موقع التركيب: <b>${widget.bookDets[0]['city']}</b>
                          🗓 تاريخ البدء: <b>${widget.bookDets[0]['date']}</b>

                          يُرجى مراجعة العقد المرفق والتنسيق مع المسؤول لجدولة أعمال التركيب.
                          """;
              var response = await Dio().get(
                'https://daltalifts.com/app2026/pdf/index.php?RepairContractId=${widget.bookDets[0]['RepairContract_id']}&sign=1&orderId=${widget.bookDets[0]['orderId']}&ktype=1',
              );
              sendTelegramMessageDocs(
                s3PdfUrl: response.data['url'],
                message: msg,
              );
            } else {
              if (batchController.text.trim().isNotEmpty &&
                  batchController1.text.trim().isNotEmpty &&
                  batchController2.text.trim().isNotEmpty &&
                  signatureController.value.isNotEmpty) {
                setState(() {
                  isLoading = true;
                  isLoadingTxt = "جاري رفع العقد...";
                });
                var data = {
                  "action": "addRepairContract",
                  "a2": widget.bookDets[0]['date'],
                  "a3": widget.bookDets[0]['a1'],
                  "a16": batchController.text.trim(),
                  "a17": batchController1.text.trim(),
                  "a18": batchController2.text.trim(),
                };
                var response = await getDio().post(
                  "https://daltalifts.com/app2026/sql.php?k=${DateTime.now().millisecondsSinceEpoch}",
                  data: data,
                );
                if (response.data['success'] == true) {
                  uploadSignature(response.data['data']['id']);
                }
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("يرجى كتابة الدفعات والتوقيع"),
                  ),
                );
              }
            }
          },
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
        ),
      ),
    );
  }
}

class BatchInp extends StatelessWidget {
  final TextEditingController batchController;
  final String text;
  final bool isEnabled;
  const BatchInp({
    super.key,
    required this.batchController,
    required this.text,
    required this.isEnabled,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(16)),
      child: TextField(
        controller: batchController,
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        enabled: isEnabled,
        decoration: InputDecoration(
          hintText: text,
          hintStyle: RepairTheme.cairo(
            color: RepairTheme.hint,
            fontSize: 14,
          ),
          filled: true,
          fillColor: RepairTheme.cardBg,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: RepairTheme.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: RepairTheme.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: RepairTheme.orange, width: 1.5),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 20,
          ),
        ),
      ),
    );
  }
}
