import 'dart:math';

import 'package:Delta/constants/app_colors.dart';
import 'package:Delta/provider/app_provider.dart';
import 'package:Delta/services/DioServiceCert.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AddressesScreen extends StatefulWidget {
  const AddressesScreen({super.key});

  @override
  State<AddressesScreen> createState() => _AddressesScreenState();
}

class _AddressesScreenState extends State<AddressesScreen> {
  TextEditingController userController = TextEditingController();
  TextEditingController mobile = TextEditingController();
  TextEditingController otpController = TextEditingController();
  int otp = 100000 + Random().nextInt(900000);
  String mobilex = "";

  List addresses = [];
  int currentAddress = 0;
  String? currentAddressId;

  Future getAddresses() async {
    SharedPreferences prefx = await SharedPreferences.getInstance();
    var result = await getDio().post(
      "https://daltalifts.com/app2026/sql.php?k=${DateTime.now().millisecondsSinceEpoch}",
      data: {"action": "getAddresses", "uid": prefx.getString("userId")},
    );
    setState(() {
      addresses = result.data['data'];
      currentAddressId = prefx.getString("addId");
    });
  }

  bool isLoading = false;

  @override
  void initState() {
    getAddresses();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final currentAdd = Provider.of<AppProvider>(context);
    final screenHeight = MediaQuery.of(context).size.height;
    print(addresses);
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.primary,
        appBar: AppBar(
          title: Text("العناوين", style: TextStyle(color: Colors.white)),
          centerTitle: true,
          forceMaterialTransparency: true,
          backgroundColor: AppColors.primary,
          iconTheme: IconThemeData(color: Colors.white),
        ),
        body: Stack(
          children: [
            Positioned(
              top: screenHeight * 0.18,
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(25),
                    topRight: Radius.circular(25),
                  ),
                ),
                child: Column(
                  children: [
                    SizedBox(height: 50),
                    // ===== Grid الأيقونات =====
                    Expanded(
                      child: Container(
                        margin: EdgeInsets.all(15),
                        child: SingleChildScrollView(
                          child: Column(
                            children: [
                              ...List.generate(addresses.length, (i) {
                                return GestureDetector(
                                  onTap: () async {
                                    SharedPreferences prefx =
                                        await SharedPreferences.getInstance();
                                    setState(() {
                                      currentAddress = i;
                                      currentAddressId = addresses[i]['id'];
                                    });
                                    prefx.setString(
                                      'addId',
                                      addresses[i]['id'],
                                    );
                                    currentAdd.getCurrentAddress(
                                      addresses[i]['id'],
                                    );
                                  },
                                  child: Column(
                                    children: [
                                      Container(
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                          border:
                                              currentAddressId ==
                                                  addresses[i]['id']
                                              ? Border.all(
                                                  color: AppColors.primary,
                                                  width: 3,
                                                )
                                              : Border(),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withOpacity(
                                                0.08,
                                              ),
                                              blurRadius: 20,
                                              offset: const Offset(0, 8),
                                            ),
                                          ],
                                        ),
                                        clipBehavior: Clip.antiAlias,
                                        child: Column(
                                          children: [
                                            Container(
                                              width: double.maxFinite,
                                              height: 200,
                                              color: Color(0xFF304B90),
                                              child: Column(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  Text(
                                                    "رقم المبنى",
                                                    style: TextStyle(
                                                      fontSize: 40,
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                  SizedBox(height: 14),
                                                  Text(
                                                    addresses[i]['building'],
                                                    style: TextStyle(
                                                      fontSize: 35,
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            SizedBox(height: 5),
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: Container(
                                                    width: double.maxFinite,
                                                    height: 100,
                                                    color: Color(0xFF304B90),
                                                    child: Column(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .center,
                                                      children: [
                                                        Text(
                                                          "منطقة",
                                                          style: TextStyle(
                                                            fontSize: 25,
                                                            color: Colors.white,
                                                          ),
                                                        ),
                                                        SizedBox(height: 14),
                                                        Text(
                                                          addresses[i]['zone'],
                                                          style: TextStyle(
                                                            fontSize: 20,
                                                            color: Colors.white,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                                SizedBox(width: 5),
                                                Expanded(
                                                  child: Container(
                                                    width: double.maxFinite,
                                                    height: 100,
                                                    color: Color(0xFF304B90),
                                                    child: Column(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .center,
                                                      children: [
                                                        Text(
                                                          "شارع",
                                                          style: TextStyle(
                                                            fontSize: 25,
                                                            color: Colors.white,
                                                          ),
                                                        ),
                                                        SizedBox(height: 14),
                                                        Text(
                                                          addresses[i]['street'],
                                                          style: TextStyle(
                                                            fontSize: 20,
                                                            color: Colors.white,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      SizedBox(height: 20),
                                    ],
                                  ),
                                );
                              }),
                              SizedBox(height: 80),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ===== صورة البروفايل في المنتصف =====
            Positioned(
              top: screenHeight * 0.11,
              left: 0,
              right: 0,
              child: Center(
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: Colors.white,
                      child: CircleAvatar(
                        radius: 36,
                        backgroundColor: AppColors.primary.withOpacity(0.2),
                        child: Icon(
                          Iconsax.location,
                          size: 30,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
        floatingActionButton: GestureDetector(
          onTap: () async {
            setState(() {
              isLoading = true;
            });
            Navigator.pop(context);
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
                ? Center(child: CircularProgressIndicator(color: Colors.white))
                : Text(
                    "إختر عنوان",
                    style: TextStyle(fontSize: 20, color: Colors.white),
                  ),
          ),
        ),
      ),
    );
  }
}

class MyInputCustom extends StatelessWidget {
  final String iHint;
  final IconData? iPref;
  final TextEditingController? iController;
  final bool? isEditingArea;
  final TextInputType? isTyping;
  final Function(String)? iChanged;
  final int? iLength;
  const MyInputCustom({
    super.key,
    required this.iHint,
    this.iPref,
    this.iController,
    this.isEditingArea,
    this.isTyping,
    this.iChanged,
    this.iLength,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: iController,
      keyboardType: isTyping,
      onChanged: iChanged,
      maxLength: iLength,

      decoration: InputDecoration(
        counterText: "",
        enabled: isEditingArea ?? false,
        filled: true,
        fillColor: Colors.grey.shade200,
        border: OutlineInputBorder(
          borderSide: BorderSide.none,
          borderRadius: BorderRadius.circular(10),
        ),
        hintText: iHint,
        prefixIcon: Icon(iPref),
      ),
    );
  }
}
