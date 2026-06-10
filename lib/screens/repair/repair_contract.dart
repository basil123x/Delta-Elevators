import 'dart:async';
import 'dart:typed_data';

import 'package:Delta/provider/app_provider.dart';
import 'package:Delta/screens/repair/repair_screen.dart';
import 'package:Delta/screens/repair/repair_theme.dart';
import 'package:Delta/services/DioServiceCert.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart' as intlx;
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
  List maintContSt = [];

  Future getUserProfile() async {
    SharedPreferences prefx = await SharedPreferences.getInstance();
    String uid = prefx.getString("userId") ?? "";
    var result = await getDio().post(
      "https://daltalifts.com/app2026/sql.php?k=${DateTime.now().millisecondsSinceEpoch}",
      data: {"action": "profile", "uid": uid},
    );
    setState(() {
      userName = result.data['data']['a1'];
      userPhone = result.data['data']['a2'];
      contractDate = intlx.DateFormat("yyyy-MM-dd").format(DateTime.now()).toString();
    });
  }

  Future getMaintContSt() async {
    SharedPreferences prefx = await SharedPreferences.getInstance();
    String uid = prefx.getString("userId") ?? "";
    var data = {
          "action": "getCurrentContractMaint",
          "userId": uid
      };
    var result = await getDio().post(
      "https://daltalifts.com/app2026/sql.php?k=${DateTime.now().millisecondsSinceEpoch}",
      data: data,
    );
    setState(() {
      maintContSt = result.data['data'];
      if (maintContSt.isNotEmpty) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => RepairScreen()));
      }
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
    getMaintContSt();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Directionality(
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
          body: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
            child: Column(
              children: [
                RepairTheme.infoTile(
                  icon: Iconsax.user,
                  label: "الإسم",
                  value: userName,
                ),
                RepairTheme.infoTile(
                  icon: Iconsax.call,
                  label: "رقم الهاتف",
                  value: userPhone,
                ),
                RepairTheme.infoTile(
                  icon: Iconsax.calendar,
                  label: "التاريخ",
                  value: contractDate,
                ),
                const SizedBox(height: 6),
                Container(
                  width: double.infinity,
                  height: 200,
                  decoration: BoxDecoration(
                    color: RepairTheme.cardBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: RepairTheme.orange,
                      width: 2,
                      style: BorderStyle.solid,
                    ),
                  ),
                  child: Stack(
                    clipBehavior: Clip.none,
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
                      Positioned(
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
              onTap: isLoading
                  ? null
                  : () async {
                      SharedPreferences prefx =
                          await SharedPreferences.getInstance();
                      if (isLoadingTxt == "إرسال العقد الى الشركة") {
                        String signId = Provider.of<AppProvider>(
                          context,
                          listen: false,
                        ).signId;
                        String msg = """
                🛗 <b>عقد صيانة مصاعد جديد</b>
          
                نُفيدكم بإصدار عقد صيانة دورية جديد ويستلزم متابعتكم.
          
                📋 <b>تفاصيل العقد:</b>
                🔢 رقم العقد: <b>$signId</b>
                👤 اسم العميل: <b>$userName</b>
                📞 الهاتف: <b>$userPhone</b>
                🗓 تاريخ بداية العقد: <b>$contractDate</b>
          
                يُرجى مراجعة العقد المرفق والتنسيق مع المسؤول لجدولة زيارات الصيانة.
                """;
                        var response = await Dio().get(
                          'https://daltalifts.com/app2026/pdf/index.php?contractId=$signId&sign=1&orderId=${prefx.getString("orderId")}&ktype=2',
                        );
                        sendTelegramMessageDocs(
                          s3PdfUrl: response.data['url'],
                          message: msg,
                        );
                      } else {
                        if (signatureController.value.isNotEmpty) {
                          setState(() {
                            isLoading = true;
                            isLoadingTxt = "جاري رفع العقد...";
                          });
                          var data = {
                            "action": "addMaintenanceContract",
                            "type": "5",
                            "a2": contractDate,
                            "a3": userName,
                            "a19": intlx.DateFormat("yyyy-MM-dd")
                                .format(DateTime.now())
                                .toString(),
                            "a20": intlx.DateFormat("yyyy-MM-dd")
                                .format(DateTime.now()
                                    .add(const Duration(days: 365)))
                                .toString(),
                            "a30": prefx.getString("userId"),
                          };

                          var response = await getDio().post(
                            "https://daltalifts.com/app2026/sql.php?k=${DateTime.now().millisecondsSinceEpoch}",
                            data: data,
                          );
                          if (response.data['success'] == true) {
                            Provider.of<AppProvider>(context, listen: false)
                                .getSignId(
                                    response.data['data']['id'].toString());
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
          hintStyle: RepairTheme.cairo(color: RepairTheme.hint, fontSize: 14),
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
