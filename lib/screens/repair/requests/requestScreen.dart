import 'dart:convert';
import 'dart:io';

import 'package:Delta/provider/app_provider.dart';
import 'package:Delta/screens/order/addresses_screen.dart';
import 'package:Delta/screens/repair/repair_theme.dart';
import 'package:Delta/screens/repair/requests/camera_screen.dart';
import 'package:Delta/services/DioServiceCert.dart';
import 'package:dio/dio.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/cupertino.dart';
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
  DateTime selectedDate = DateTime.now();
  DateTime selectedTime = DateTime.now();

  Future getAddNow() async {
    SharedPreferences prefx = await SharedPreferences.getInstance();
    final now = DateTime.now();
    setState(() {
      myAddId = prefx.getString("addId") ?? "";
      selectedDate = now;
      selectedTime = now;
      dateController.text = intlx.DateFormat('yyyy-MM-dd').format(now);
      timeController.text = intlx.DateFormat('hh:mm a').format(now);
    });
  }

  Future<void> _showPickerSheet({
    required String title,
    required Widget picker,
    required VoidCallback onConfirm,
  }) async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        return Container(
          height: 320,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: RepairTheme.cairo(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: RepairTheme.textPrimary,
                ),
              ),
              Expanded(child: picker),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () {
                      onConfirm();
                      Navigator.pop(sheetContext);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: RepairTheme.orange,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      'تأكيد',
                      style: RepairTheme.cairo(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> pickDate() async {
    DateTime temp = selectedDate;
    await _showPickerSheet(
      title: 'اختر التاريخ',
      picker: StatefulBuilder(
        builder: (context, setSheetState) {
          return CupertinoDatePicker(
            mode: CupertinoDatePickerMode.date,
            initialDateTime: temp,
            minimumDate: DateTime(2020),
            maximumDate: DateTime(2030, 12, 31),
            onDateTimeChanged: (val) {
              setSheetState(() => temp = val);
            },
          );
        },
      ),
      onConfirm: () {
        setState(() {
          selectedDate = temp;
          dateController.text = "${temp.day}-${temp.month}-${temp.year}";
        });
      },
    );
  }

  Future<void> pickTime() async {
    DateTime temp = selectedTime;
    await _showPickerSheet(
      title: 'اختر الوقت',
      picker: StatefulBuilder(
        builder: (context, setSheetState) {
          return CupertinoDatePicker(
            mode: CupertinoDatePickerMode.time,
            use24hFormat: false,
            initialDateTime: temp,
            onDateTimeChanged: (val) {
              setSheetState(() => temp = val);
            },
          );
        },
      ),
      onConfirm: () {
        setState(() {
          selectedTime = temp;
          timeController.text = intlx.DateFormat('hh:mm a').format(temp);
        });
      },
    );
  }

  Widget _buildDateTimeField({
    required TextEditingController controller,
    required IconData icon,
    required VoidCallback? onTap,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      readOnly: true,
      onTap: onTap,
      validator: validator,
      textAlign: TextAlign.right,
      style: RepairTheme.cairo(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: RepairTheme.textPrimary,
      ),
      decoration: InputDecoration(
        filled: true,
        fillColor: RepairTheme.cardBg,
        prefixIcon: Icon(icon, color: RepairTheme.orange, size: 22),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
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
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFEF4444)),
        ),
      ),
    );
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
          'type': widget.type,
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
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("تم إضافة طلب صيانة جديد")));
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
        backgroundColor: RepairTheme.bg,
        body: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 320, child: AddressesDisplayWidget()),
              const SizedBox(height: 12),
              if (widget.type == 'Urgent') ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF3E0),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: RepairTheme.orange, width: 1.5),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Iconsax.timer_1,
                            color: RepairTheme.orange,
                            size: 22,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              "الصيانة العاجلة من 30 الى 60 دقيقة",
                              style: RepairTheme.cairo(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: RepairTheme.orange,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(
                            Iconsax.money,
                            color: RepairTheme.orange,
                            size: 22,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              "سعر الصيانة العاجلة 200 ريال",
                              style: RepairTheme.cairo(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: RepairTheme.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ] else ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F7FF),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Color(0xFF3B82F6), width: 1.5),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Iconsax.money,
                        color: Color(0xFF3B82F6),
                        size: 22,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          "سعر الصيانة العادية 100 ريال",
                          style: RepairTheme.cairo(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF3B82F6),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],
              Container(
                padding: const EdgeInsets.all(14),
                decoration: RepairTheme.cardDecoration(radius: 12),
                child: MyInputCustom(
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
              ),
              const SizedBox(height: 12),
              _buildDateTimeField(
                controller: dateController,
                icon: Iconsax.calendar,
                onTap: widget.type == 'Urgent' ? null : pickDate,
                validator: widget.type == 'Urgent'
                    ? null
                    : (val) {
                        if (val == null || val.isEmpty) {
                          return 'برجاء قم بتحديد التاريخ هنا';
                        }
                        return null;
                      },
              ),
              const SizedBox(height: 12),
              _buildDateTimeField(
                controller: timeController,
                icon: Iconsax.clock,
                onTap: widget.type == 'Urgent' ? null : pickTime,
                validator: widget.type == 'Urgent'
                    ? null
                    : (val) {
                        if (val == null || val.isEmpty) {
                          return 'برجاء قم بتحديد الوقت هنا';
                        }
                        return null;
                      },
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => CameraWorking()),
                  );
                },
                child: DottedBorder(
                  options: RectDottedBorderOptions(
                    dashPattern: const [9, 5],
                    color: RepairTheme.orange,
                    strokeWidth: 2,
                  ),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 28),
                    decoration: BoxDecoration(
                      color: RepairTheme.cardBg,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        const Icon(
                          Iconsax.camera,
                          color: RepairTheme.orange,
                          size: 36,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          "صورة أو فيديو للعطل (إختياري)",
                          style: RepairTheme.cairo(
                            fontSize: 14,
                            color: RepairTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Consumer<AppProvider>(
                builder: (context, app, child) {
                  if (app.allImagesList.isEmpty) {
                    return const SizedBox.shrink();
                  }
                  return SizedBox(
                    height: 88,
                    child: ListView.separated(
                      clipBehavior: Clip.none,
                      padding: const EdgeInsets.only(top: 8, right: 8),
                      scrollDirection: Axis.horizontal,
                      itemCount: app.allImagesList.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 12),
                      itemBuilder: (context, i) {
                        return Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Container(
                              width: 72,
                              height: 72,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: RepairTheme.border),
                                image: DecorationImage(
                                  image: FileImage(File(app.allImagesList[i])),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            Positioned(
                              top: -6,
                              right: -6,
                              child: GestureDetector(
                                onTap: () {
                                  app.allImagesList.removeAt(i);
                                  app.notifyListeners();
                                },
                                child: Container(
                                  width: 24,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEF4444),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 2,
                                    ),
                                  ),
                                  child: const Icon(
                                    Iconsax.close_circle,
                                    color: Colors.white,
                                    size: 14,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  );
                },
              ),
            ],
          ),
        ),
        bottomNavigationBar: Consumer<AppProvider>(
          builder: (context, app, child) {
            return SafeArea(
              child: Container(
                color: RepairTheme.cardBg,
                padding: const EdgeInsets.only(bottom: 4),
                child: RepairTheme.primaryButton(
                  label: isLoading ? isLoadingTxt : "تأكيد الطلب",
                  loading: isLoading,
                  onTap: isLoading
                      ? null
                      : () async {
                          if (globalKey.currentState!.validate()) {
                            SharedPreferences prefx =
                                await SharedPreferences.getInstance();
                            String uid = prefx.getString("userId") ?? "";
                            setState(() {
                              isLoading = true;
                              isLoadingTxt = "جاري رفع طلب الصيانة";
                            });
                            var result = await getDio().post(
                              "https://daltalifts.com/app2026/sql.php?k=${DateTime.now().millisecondsSinceEpoch}",
                              data: {
                                "action": "addMaintenRequest",
                                "addressId": prefx.getString('addId'),
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

                                for (
                                  var i = 0;
                                  i < app.allImagesList.length;
                                  i++
                                ) {
                                  myAllImg.add(File(app.allImagesList[i]));
                                }
                                uploadImages(
                                  myAllImg,
                                  result.data['data']['mainId'].toString(),
                                );
                              } else {
                                setState(() {
                                  isLoading = false;
                                });
                              }
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
    this.initVx,
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
        fillColor: RepairTheme.cardBg,
        hintStyle: RepairTheme.cairo(fontSize: 14, color: RepairTheme.hint),
        hintText: iHint,
        prefixIcon: iPref != null
            ? Icon(iPref, color: RepairTheme.orange, size: 22)
            : null,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
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
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFEF4444)),
        ),
      ),
    );
  }
}
