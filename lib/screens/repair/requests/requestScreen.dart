import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:Delta/constants/app_colors.dart';
import 'package:Delta/provider/app_provider.dart';
import 'package:Delta/screens/order/addresses_screen.dart';
import 'package:Delta/screens/repair/requests/camera_screen.dart';
import 'package:Delta/services/DioServiceCert.dart';
import 'package:dio/dio.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart' as intlx;

class RequestScreen extends StatefulWidget {
  final String type;
  const RequestScreen({super.key, required this.type});

  @override
  State<RequestScreen> createState() => _RequestScreenState();
}

class _RequestScreenState extends State<RequestScreen> {
  GlobalKey<FormState> globalKey = GlobalKey<FormState>();
  TextEditingController descController = TextEditingController();
  TextEditingController dateController = TextEditingController();
  TextEditingController timeController = TextEditingController();
  bool isLoading = false;
  String isLoadingTxt = "";
  String myAddId = "";
  List<File> myAllImg = [];

  Future getAddNow() async {
    SharedPreferences prefx = await SharedPreferences.getInstance();
    setState(() {
      myAddId = prefx.getString("addId") ?? "";
      dateController.text = intlx.DateFormat('yyyy-MM-dd').format(DateTime.now());
      timeController.text = intlx.DateFormat('hh:mm a').format(DateTime.now());
    });
  }

  Future<void> pickDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              secondary: Colors.amber,
              onSecondary: Colors.black,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(foregroundColor: AppColors.primary),
            ),
            dialogTheme: DialogThemeData(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(5),
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      dateController.text = "${picked.day}-${picked.month}-${picked.year}";
    }
  }

  Future<void> pickTime() async {
    TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              secondary: Colors.amber,
              onSecondary: Colors.black,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(foregroundColor: AppColors.primary),
            ),
            dialogTheme: DialogThemeData(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(5),
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      timeController.text =
          "${picked.period.name} ${picked.hourOfPeriod}:${picked.minute}";
    }
  }

Future<void> uploadImages(List<File> imageFiles, String maintenanceId) async {
  SharedPreferences prefx = await SharedPreferences.getInstance();
  final dio = Dio();
  dio.options.connectTimeout = const Duration(seconds: 60);
  dio.options.receiveTimeout = const Duration(seconds: 60);

  for (int i = 0; i < imageFiles.length; i++) {
    final ext = imageFiles[i].path.split('.').last;

    final presignRes = await dio.post(
      "https://daltalifts.com/app2026/sql.php",
      data: jsonEncode({
        'action': 'getPresignedMaintenanceImageUrl',
        'maintenanceId': maintenanceId,
        'userId': prefx.getString("userId"),
        'index': i + 1,
        'ext': ext,
        'type': widget.type
      }),
      options: Options(contentType: 'application/json'),
    );

    final presignData = presignRes.data is String
        ? jsonDecode(presignRes.data)
        : presignRes.data;

    if (!presignData['success']) continue;

    final uploadUrl = presignData['url'];

    final bytes = await imageFiles[i].readAsBytes();
    await dio.put(
      uploadUrl,
      data: Stream.fromIterable([bytes]),
      options: Options(
        headers: {
          'Content-Type': 'image/jpeg',
          'Content-Length': bytes.length,
        },
      ),
    );
  }

    
  myAllImg.clear();
  Provider.of<AppProvider>(context, listen: false).allImagesList.clear();
  descController.clear();
  dateController.text = intlx.DateFormat('yyyy-MM-dd').format(DateTime.now());
  timeController.text = intlx.DateFormat('hh:mm a').format(DateTime.now());
  isLoading = false;
  setState(() {});
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text("تم إضافة طلب صيانة جديد")),
  );
}

  @override
  void initState() {
    getAddNow();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    print(myAllImg);
    return Form(
      key: globalKey,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SingleChildScrollView(
          child: Container(
            margin: EdgeInsets.all(10),
            child: Column(
              children: [
                SizedBox(height: 320, child: AddressesDisplayWidget()),
                MyInputCustom(
                  iMax: 4,
                  iController: descController,
                  iHint: "قم بكتابة وصف طلبك",
                  isTyping: TextInputType.name,
                  iValid: (val) {
                    if (val == '') {
                      return 'برجاء إكتب وصفك هنا';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 10),
                widget.type == 'Urgent' ? MyInputCustom(
                  iController: dateController,
                  iHint: "حدد التاريخ",
                  iEnabled: true,
                ) : MyInputCustom(
                  iController: dateController,
                  iHint: "حدد التاريخ",
                  isTyping: TextInputType.name,
                  iEnabled: true,
                  iTab: () {
                    pickDate();
                  },
                  iValid: (val) {
                    if (val == '') {
                      return 'برجاء قم بتحديد التاريخ هنا';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 10),
                widget.type == 'Urgent' ? MyInputCustom(
                  iController: timeController,
                  iHint: "حدد الوقت",
                  iEnabled: true,
                ) : MyInputCustom(
                  iController: timeController,
                  iHint: "حدد الوقت",
                  isTyping: TextInputType.name,
                  iEnabled: true,
                  iTab: () {
                    pickTime();
                  },
                  iValid: (val) {
                    if (val == '') {
                      return 'برجاء قم بتحديد الوقت هنا';
                    }
                    return null;
                  },
                ),
                Container(
                  alignment: Alignment.centerRight,
                  padding: EdgeInsets.symmetric(vertical: 15),
                  child: Text(
                    "صورة أو فيديو للعطل (إختياري)",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(vertical: 10),
                  child: Row(
                    children: [
                      // زر الكاميرا
                      GestureDetector(
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => CameraWorking(),
                            ),
                          );
                        },
                        child: DottedBorder(
                          options: RectDottedBorderOptions(
                            dashPattern: [9, 5],
                            color: AppColors.primary,
                            strokeWidth: 2,
                          ),
                          child: Container(
                            width: 65,
                            height: 65,
                            child: Center(child: Icon(Iconsax.camera)),
                          ),
                        ),
                      ),

                      SizedBox(width: 12),

                      // قائمة الصور
                      Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          padding: EdgeInsets.only(
                            top: 10,
                            bottom: 10,
                            right: 10,
                          ),
                          child: Consumer<AppProvider>(
                            builder: (context, app, child) {
                              return Row(
                                children: List.generate(
                                  app.allImagesList.length,
                                  (i) {
                                    return Padding(
                                      padding: EdgeInsets.only(
                                        left: i == app.allImagesList.length - 1
                                            ? 0
                                            : 12, // ✅ عدّلت الشرط
                                      ),
                                      child: Stack(
                                        clipBehavior: Clip.none,
                                        children: [
                                          // الصورة
                                          Container(
                                            width: 65,
                                            height: 65,
                                            decoration: BoxDecoration(
                                              color: Colors.grey[200],
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              image: DecorationImage(
                                                image: FileImage(
                                                  File(app.allImagesList[i]),
                                                ),
                                                fit: BoxFit.cover,
                                              ),
                                            ),
                                          ),

                                          // زر الحذف
                                          Positioned(
                                            top: -8,
                                            right: -8,
                                            child: GestureDetector(
                                              onTap: () {
                                                // حذف الصورة
                                                app.allImagesList.removeAt(i);
                                                app.notifyListeners(); 
                                              },
                                              child: Container(
                                                width: 24,
                                                height: 24,
                                                decoration: BoxDecoration(
                                                  color: Colors.red,
                                                  shape: BoxShape.circle,
                                                  border: Border.all(
                                                    color: Colors.white,
                                                    width: 2,
                                                  ),
                                                ),
                                                child: Icon(
                                                  Icons.close_rounded,
                                                  color: Colors.white,
                                                  size: 14,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 100),
              ],
            ),
          ),
        ),
        floatingActionButtonLocation:
            FloatingActionButtonLocation.miniCenterDocked,
        floatingActionButton: Consumer<AppProvider>(
          builder: (context, app, child) {
            return Container(
              width: double.maxFinite,
              color: Colors.white,
              child: GestureDetector(
                onTap: () async {
                  if (globalKey.currentState!.validate()) {
                    SharedPreferences _prefx =
                        await SharedPreferences.getInstance();
                    String uid = _prefx.getString("userId") ?? "";
                    setState(() {
                      isLoading = true;
                      isLoadingTxt = "جاري رفع طلب الصيانة";
                    });
                    var result = await getDio().post(
                      "https://daltalifts.com/app2026/sql.php?k=${DateTime.now().millisecondsSinceEpoch}",
                      data: {
                        "action": "addMaintenRequest",
                        "addressId": myAddId,
                        "descController": descController.text,
                        "dateController": dateController.text,
                        "timeController": timeController.text,
                        "type": widget.type,
                        "uid": uid,
                      },
                    );
                    if (result.data['success'] == true) {
                      if (app.allImagesList.isNotEmpty) {
                        setState(() {
                          isLoadingTxt = "جاري رفع صور أعطال الصيانة";
                        });
                        
                        for (var i = 0; i < app.allImagesList.length; i++) {
                          myAllImg.add(File(app.allImagesList[i]));
                        }
                        uploadImages(myAllImg, result.data['data']['mainId'].toString());
                      } else {
                        setState(() {
                          isLoading = false;
                        });
                      }
                    }
                  }
                },
                child: Container(
                  width: double.maxFinite,
                  height: 60,
                  margin: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  padding: EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  alignment: Alignment.center,
                  child: isLoading
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(color: Colors.white),
                            SizedBox(width: 20),
                            Text(
                              isLoadingTxt,
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        )
                      : Text(
                          "تأكيد الطلب",
                          style: TextStyle(fontSize: 20, color: Colors.white),
                        ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class MyInputCustom extends StatelessWidget {
  final String iHint;
  final IconData? iPref;
  final TextEditingController? iController;
  final TextInputType? isTyping;
  final Function(String)? iChanged;
  final int? iLength;
  final int? iMax;
  final String? Function(String?)? iValid;
  final Function()? iTab;
  final bool? iEnabled;
  final String? initVx;
  const MyInputCustom({
    super.key,
    required this.iHint,
    this.iPref,
    this.iController,
    this.isTyping,
    this.iChanged,
    this.iLength,
    this.iMax,
    this.iValid,
    this.iTab,
    this.iEnabled,
    this.initVx
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      initialValue: initVx,
      validator: iValid,
      controller: iController,
      keyboardType: isTyping,
      onChanged: iChanged,
      maxLength: iLength,
      maxLines: iMax,
      readOnly: iEnabled ?? false,
      onTap: iTab,
      decoration: InputDecoration(
        counterText: "",
        filled: true,
        fillColor: Colors.grey.shade200,
        border: OutlineInputBorder(
          borderSide: BorderSide.none,
          borderRadius: BorderRadius.circular(10),
        ),
        hintText: iHint,
        prefixIcon: iPref != null ? Icon(iPref) : null,
      ),
    );
  }
}
