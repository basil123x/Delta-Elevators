import 'dart:async';
import 'dart:math';
import 'dart:typed_data';

import 'package:Delta/constants/app_colors.dart';
import 'package:Delta/provider/app_provider.dart';
import 'package:Delta/services/DioServiceCert.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:signature/signature.dart';

class RepairContract extends StatefulWidget {
  const RepairContract({super.key});

  @override
  State<RepairContract> createState() => _RepairContractState();
}

class _RepairContractState extends State<RepairContract> {
  String signText = "قم بالتوقيع هنا";
  String stt = "";
  String stx = "";
  String signId = "";
  
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

  String userName = "";
  String userPhone = "";
  String contractDate = "";

  Future getUserProfile() async {
    SharedPreferences _prefx = await SharedPreferences.getInstance();
    String uid = _prefx.getString("userId") ?? "";
    var result = await getDio().post(
      "https://daltalifts.com/app2026/sql.php?k=${DateTime.now().millisecondsSinceEpoch}",
      data: {"action": "profile", "uid": uid},
    );
    setState(() {
      userName = result.data['data']['a1'];
      userPhone = result.data['data']['a2'];
      contractDate = DateFormat("yyyy-MM-dd").format(DateTime.now()).toString();
    });
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
    data: {'action': 'getPresignedUrlS3', 'contractId': signId, 'contractType': "2"},
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
      'contractId': signId,
      's3Key': s3Key,
      
    },
  );

  if (response.data['success'] == true) {
    downloadAndUploadPdf(signId);
  } else {
    throw Exception(response.data['message'] ?? 'خطأ في الحفظ');
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

      // اطلب PDF مباشرة من السيرفر
      var response = await dio.get(
        'https://daltalifts.com/app2026/pdf/index.php?contractId=$signId&sign=1&orderId=$oid&ktype=2',
      );
      print(response.data);
      if (response.data['success'] == true) {
        setState(() {
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
      
      await Dio().post(
        'https://daltalifts.com/app2026/sql.php?k=${DateTime.now().millisecondsSinceEpoch}',
        data: {
          "action": "updateMaintenanceContract",
          "contractId": Provider.of<AppProvider>(context, listen: false).signId
        }
      );
      print('✅ تم الإرسال');
    }
  } on DioException catch (e) {
    print('❌ خطأ: ${e.message}');
  }
}

  @override
  void initState() {
    getUserProfile();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Container(
                margin: EdgeInsets.all(13),
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      ListTile(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadiusGeometry.circular(10),
                        ),
                        tileColor: Colors.grey.shade100,
                        title: Text("الإسم: $userName"),
                      ),
                      SizedBox(height: 10),
                      ListTile(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadiusGeometry.circular(10),
                        ),
                        tileColor: Colors.grey.shade100,
                        title: Text("رقم الهاتف: $userPhone"),
                      ),
                      SizedBox(height: 10),
                      ListTile(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadiusGeometry.circular(10),
                        ),
                        tileColor: Colors.grey.shade100,
                        title: Text("التاريخ: $contractDate"),
                      ),
                      SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: BatchInp(
                              batchController: batchController,
                              text: "الاولى",
                              isEnabled:true,
                            ),
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: BatchInp(
                              batchController: batchController1,
                              text: "الثانية",
                              isEnabled:true,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 10),
                      BatchInp(
                        batchController: batchController2,
                        text: "الثالثة",
                        isEnabled:true,
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
                          child: Stack(
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
            SharedPreferences prefx = await SharedPreferences.getInstance();
            if (isLoadingTxt == "إرسال العقد الى الشركة") {
              int totalbatches = int.parse(batchController.text.trim())+int.parse(batchController1.text.trim())+int.parse(batchController2.text.trim());
              String signId = Provider.of<AppProvider>(context, listen: false).signId;
              String msg = """
                🛗 <b>عقد صيانة مصاعد جديد</b>
    
                نُفيدكم بإصدار عقد صيانة دورية جديد ويستلزم متابعتكم.
    
                📋 <b>تفاصيل العقد:</b>
                🔢 رقم العقد: <b>$signId</b>
                👤 اسم العميل: <b>$userName</b>
                📞 الهاتف: <b>$userPhone</b>
                🗓 تاريخ بداية العقد: <b>$contractDate</b>
    
                💰 <b>قيمة العقد:</b>
                - الدفعة الأولى: <b>${batchController.text.trim()} ر.ق</b>
                - الدفعة الثانية: <b>${batchController1.text.trim()} ر.ق</b>
                - الدفعة الثالثة: <b>${batchController2.text.trim()} ر.ق</b>
                - الإجمالي: <b>$totalbatches ر.ق</b>
    
                يُرجى مراجعة العقد المرفق والتنسيق مع المسؤول لجدولة زيارات الصيانة.
                """;
              var response = await Dio().get(
                'https://daltalifts.com/app2026/pdf/index.php?contractId=$signId&sign=1&orderId=${prefx.getString("orderId")}&ktype=2',
              );
              sendTelegramMessageDocs(
                s3PdfUrl: response.data['url'],
                message: msg
              );
            } else {
            if (batchController.text.trim().isNotEmpty &&
                  batchController1.text.trim().isNotEmpty &&
                  batchController2.text.trim().isNotEmpty &&
                  signatureController.value.isNotEmpty) {
                  SharedPreferences prefx = await SharedPreferences.getInstance();
                  
                setState(() {
                  isLoading = true;
                  isLoadingTxt = "جاري رفع العقد...";
                });
                var data = {
                  "action": "addMaintenanceContract",
                  "type": "5",
                  "a2": contractDate,
                  "a3": userName,
                  "a16": batchController.text.trim(),
                  "a17": batchController1.text.trim(),
                  "a18": batchController2.text.trim(),
                  "a19": DateFormat("yyyy-MM-dd").format(DateTime.now()).toString(),
                  "a20": DateFormat("yyyy-MM-dd").format(DateTime.now().add(Duration(days: 365))).toString(),
                  "a30": prefx.getString("userId"),
                  
                };

                var response = await getDio().post(
                  "https://daltalifts.com/app2026/sql.php?k=${DateTime.now().millisecondsSinceEpoch}",
                  data: data,
                );
                if (response.data['success'] == true) {
                  Provider.of<AppProvider>(context, listen: false).getSignId(response.data['data']['id'].toString());
                  uploadSignature(response.data['data']['id']);
                }
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("يرجى كتابة الدفعات والتوقيع")),
                );
              }}
          },
          child: Container(
            width: double.maxFinite,
            height: 60,
            margin: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            padding: EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color:
                   AppColors.primary,
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
