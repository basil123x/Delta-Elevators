import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:Delta/constants/app_colors.dart';
import 'package:Delta/provider/app_provider.dart';
import 'package:Delta/services/DioServiceCert.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:html_to_pdf/html_to_pdf.dart';
import 'package:http/http.dart' show MediaType;
import 'package:iconsax/iconsax.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';
import 'package:signature/signature.dart';
import 'package:pdf/widgets.dart' as pw;

class Contract extends StatefulWidget {
  final List bookDets;
  const Contract({super.key, required this.bookDets});

  @override
  State<Contract> createState() => _ContractState();
}

class _ContractState extends State<Contract> {
  String signText = "قم بالتوقيع هنا";
  String stt = "";
  TextEditingController batchController = TextEditingController();
  TextEditingController batchController1 = TextEditingController();
  TextEditingController batchController2 = TextEditingController();
  bool isLoading = false;
  String isLoadingTxt = "تحميل العقد";
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('من فضلك قم بالتوقيع أولاً')));
      return;
    }

    setState(() {
      isLoadingTxt = "جاري رفع التوقيع";
    });
    final Uint8List? signatureBytes = await signatureController.toPngBytes();

    String base64Signature = base64Encode(signatureBytes!);

    var response = await getDio().post(
      'https://daltalifts.com/app2026/sql.php',
      data: {
        'action': 'UploadSignature',
        'contractId': signId,
        'signature': base64Signature,
      },
    );

    if (response.data['success'] == true) {
      downloadAndUploadPdf(signId);
    } else {
      throw Exception(response.data['message'] ?? 'خطأ في الحفظ');
    }
  }

  Future uploadPdfToServer(String filePath, signId) async {
    try {
      setState(() {
        isLoadingTxt = "جاري رفع الملف";
      });
      var dio = Dio();

      // جهز الملف للرفع
      String fileName = filePath.split('/').last;
      FormData formData = FormData.fromMap({
        "file": await MultipartFile.fromFile(
          filePath,
          filename: fileName,
          contentType: MediaType('application', 'pdf'), // مهم!
        ),
        "id": signId,
        "booking_id": widget.bookDets[0]['id'],
      });

      // ارفع الملف
      var response = await dio.post(
        'https://daltalifts.com/app2026/upload.php',
        data: formData,
        onSendProgress: (int sent, int total) {
          print('Progress: ${(sent / total * 100).toStringAsFixed(0)}%');
        },
      );

      if (response.data['success'] == true) {
        setState(() {
          isLoading = false;
          isLoadingTxt = "إرسال العقد الى الواتس اب";
          stt = '1';
        });
        Provider.of<AppProvider>(context, listen: false).jumpToTabx(1);
      }

      return response.data;
    } catch (e) {
      print('Upload Error: $e');
      throw e;
    }
  }

  // استخدام كامل:
  Future downloadAndUploadPdf(signId) async {
    try {
      setState(() {
        isLoadingTxt = "جاري عمل بي دي اف";
      });
      var dio = Dio();

      // اطلب PDF مباشرة من السيرفر
      var response = await dio.get(
        'https://daltalifts.com/app2026/pdf/index.php?id=$signId&sign=1',
        options: Options(
          responseType: ResponseType.bytes, // ✅ مهم جداً
        ),
      );
      print(response.headers);

      // احفظ الملف
      Directory appDocDir = await getApplicationDocumentsDirectory();
      String filePath = '${appDocDir.path}/contract_$signId.pdf';

      File file = File(filePath);
      await file.writeAsBytes(response.data);

      print('PDF Size: ${file.lengthSync()} bytes');
      print('PDF saved to: $filePath');
      uploadPdfToServer(filePath, signId);
    } catch (e) {
      print('Error: $e');
    }
  }

  @override
  void initState() {
    widget.bookDets[0]['stt'] == '1'
        ? isLoadingTxt = "إرسال العقد الى الواتس اب"
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
    print(stt);
    return Scaffold(
      backgroundColor: Colors.white,
      body: widget.bookDets.isEmpty
          ? SizedBox()
          : Container(
              margin: EdgeInsets.all(13),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    ListTile(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadiusGeometry.circular(10),
                      ),
                      tileColor: Colors.grey.shade100,
                      title: Text("الإسم: ${widget.bookDets[0]['a1']}"),
                    ),
                    SizedBox(height: 10),
                    ListTile(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadiusGeometry.circular(10),
                      ),
                      tileColor: Colors.grey.shade100,
                      title: Text("رقم الهاتف: ${widget.bookDets[0]['a2']}"),
                    ),
                    SizedBox(height: 10),
                    ListTile(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadiusGeometry.circular(10),
                      ),
                      tileColor: Colors.grey.shade100,
                      title: Text("التاريخ: ${widget.bookDets[0]['date']}"),
                    ),
                    SizedBox(height: 10),
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
                    ClipRRect(
                      clipBehavior: Clip.none,
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        width: double.maxFinite,
                        height: 150,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: AppColors.primary,
                            width: 3,
                          ),
                        ),
                        padding: EdgeInsets.all(2),
                        child:
                            widget.bookDets[0]['stt'] == '1' ||
                                stt.toString() == '1'
                            ? Image.network(
                                "https://daltalifts.com/erp2026/assets/signatures/signature_${widget.bookDets[0]['contract_id']}.png",
                              )
                            : Stack(
                                children: [
                                  Positioned(
                                    top: 0,
                                    left: 0,
                                    right: 0,
                                    bottom: 0,
                                    child: Center(
                                      child: Text(
                                        signText,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),

                                  Signature(
                                    height: 150,
                                    controller: signatureController,
                                    backgroundColor: Colors.transparent,
                                  ),
                                  if (signText.isEmpty)
                                    IconButton(
                                      onPressed: () {
                                        setState(() {
                                          signText = "قم بالتوقيع هنا";
                                          signatureController.clear();
                                        });
                                      },
                                      icon: Icon(
                                        Iconsax.trash,
                                        color: Colors.red,
                                      ),
                                    ),
                                ],
                              ),
                      ),
                    ),
                    SizedBox(height: 100),
                  ],
                ),
              ),
            ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: GestureDetector(
        onTap: () async {
          if (isLoadingTxt == "إرسال العقد الى الواتس اب") {
            print("Go To Whatsapp");
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
                "action": "addContract",
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
                SnackBar(content: Text("يرجى كتابة الدفعات والتوقيع")),
              );
            }
          }
        },
        child: Container(
          width: double.maxFinite,
          height: 60,
          margin: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          padding: EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color:
                isLoadingTxt == "إرسال العقد الى الواتس اب" ||
                    widget.bookDets[0]['stt'] == '1'
                ? Color(0xFF189D0E)
                : AppColors.primary,
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: isLoading
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(width: 20),
                    Text(isLoadingTxt, style: TextStyle(color: Colors.white)),
                  ],
                )
              : Text(
                  isLoadingTxt,
                  style: TextStyle(fontSize: 18, color: Colors.white),
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
          hintStyle: TextStyle(color: AppColors.textHint, letterSpacing: 2),
          filled: true,
          fillColor: Colors.grey.shade100,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(9),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(9),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(9),
            borderSide: BorderSide.none,
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
