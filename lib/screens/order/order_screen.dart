import 'package:Delta/constants/app_colors.dart';
import 'package:Delta/provider/app_provider.dart';
import 'package:Delta/screens/items/items_screen.dart';
import 'package:Delta/screens/order/add_address_screen.dart';
import 'package:Delta/screens/order/addresses_list_screen.dart';
import 'package:Delta/services/DioServiceCert.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OrderScreen extends StatefulWidget {
  const OrderScreen({super.key});

  @override
  State<OrderScreen> createState() => _OrderScreenState();
}

class _OrderScreenState extends State<OrderScreen> {
  TextEditingController nameController = TextEditingController();
  TextEditingController mobileController = TextEditingController();
  List myOrders = [];
  bool isLoading = false;
  String? addId;
  List oneAddress = [];

  Future getUserProfile() async {
    SharedPreferences prefx = await SharedPreferences.getInstance();
    String uid = prefx.getString("userId") ?? "";
    print({"action": "profile", "uid": uid});
    var result = await getDio().post(
      "https://daltalifts.com/app2026/sql.php?k=${DateTime.now().millisecondsSinceEpoch}",
      data: {"action": "profile", "uid": uid},
    );
      setState(() {
        nameController.text = result.data['data']['a1'];
        mobileController.text = result.data['data']['a2'];
        addId = prefx.getString("addId") ?? "";
      });
  }

  

  Future getOneAddress() async {
    SharedPreferences prefx = await SharedPreferences.getInstance();
    var result = await getDio().post(
      "https://daltalifts.com/app2026/sql.php?k=${DateTime.now().millisecondsSinceEpoch}",
      data: {"action": "getOneAddress", "id": prefx.getString("addId") ?? ''},
    );
    setState(() {
      oneAddress = result.data['data'];
    });
  }

  Future getMyOrders() async {
    SharedPreferences prefx = await SharedPreferences.getInstance();
    String uid = prefx.getString("userId") ?? "";
    print({"action": "getOrders", "uid": uid});
    var result = await getDio().post(
      "https://daltalifts.com/app2026/sql.php?k=${DateTime.now().millisecondsSinceEpoch}",
      data: {"action": "getOrders", "uid": uid},
    );
      setState(() {
        myOrders = result.data['data'];
      });
  }

      Future<void> sendQuotationRequestToTelegram({
        required String clientName,
        required String phone,
        required String city,
        required String zone,
        required String street,
        required String building,
        required String latitude,
        required String longitude,
        required List items,
      }) async {
        const String botToken = '8499367531:AAEnMG1yvNeAIanEgCbyYGlXWuYWImeTMyI';
        const String chatId = '-1003877690157';

        // 1. الرسالة النصية
        await Dio().post(
          'https://api.telegram.org/bot$botToken/sendMessage',
          queryParameters: {
            'chat_id': chatId,
            'text': """
      🛗 <b>طلب عرض سعر جديد</b>

      👤 <b>العميل:</b> $clientName
      📞 <b>الهاتف:</b> $phone

      📍 <b>العنوان:</b>
      🏙 المدينة: $city
      🗺 المنطقة: $zone
      🛣 الشارع: $street
      🏢 المبنى: $building

      🛒 <b>الطلبات:</b> ${items.length} منتج
      """,
            'parse_mode': 'HTML',
          },
        );

        // 2. صور المنتجات
        for (var item in items) {
          await Dio().post(
            'https://api.telegram.org/bot$botToken/sendPhoto',
            queryParameters: {
              'chat_id': chatId,
              'photo': "https://daltaliftstech.s3.ap-south-1.amazonaws.com/Sys/items/${item['id']}/1.jpg",
              'caption': '🛗 ${item['a1']} - ${item['a3']}',
            },
          );
        }

        // 3. الموقع
        await Dio().post(
          'https://api.telegram.org/bot$botToken/sendLocation',
          queryParameters: {
            'chat_id': chatId,
            'latitude': latitude,
            'longitude': longitude,
          },
        );
      }

  @override
  void initState() {
    getUserProfile();
    getMyOrders();
    getOneAddress();
    super.initState();
  }

  String _addrVal(String key) {
    if (oneAddress.isEmpty) return '—';
    final v = oneAddress[0][key];
    if (v == null || v.toString().isEmpty) return '—';
    return v.toString();
  }

  Future<void> _openAddressPicker() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddressesListScreen()),
    );
    if (result == true && mounted) {
      await getOneAddress();
    }
  }

  Widget _buildHeader() {
    return Container(
      color: const Color(0xFFF37021),
      width: double.infinity,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 12,
        bottom: 24,
        left: 16,
        right: 16,
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: -20,
            right: -20,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.10),
              ),
            ),
          ),
          Positioned(
            bottom: -30,
            left: -10,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.08),
              ),
            ),
          ),
          Column(
            children: [
              Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.maybePop(context),
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.20),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.30),
                        ),
                      ),
                      child: const Icon(
                        Iconsax.arrow_left_3,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
                  const Expanded(
                    child: Text(
                      'تقديم طلب',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 38),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'أدخل بيانات طلبك بدقة',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withOpacity(0.75),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(
    IconData icon,
    Color iconBg,
    Color iconColor,
    String title,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w900,
              color: Color(0xFF1A1A2E),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 16),
          ),
        ],
      ),
    );
  }

  Widget _addressCell(
    IconData icon,
    Color bg,
    Color color,
    String label,
    String value,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEBEBEB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(7),
            ),
            child: Icon(icon, size: 12, color: color),
          ),
          const SizedBox(height: 5),
          Text(
            value,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              color: Color(0xFF1A1A2E),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 9,
              color: Colors.grey,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddressSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _sectionTitle(
          Iconsax.location,
          const Color(0xFFFFF0E5),
          const Color(0xFFF37021),
          'عنوان التركيب',
        ),
        Consumer<AppProvider>(
          builder: (context, app, _) {
            if (app.currentAdd.isNotEmpty &&
                oneAddress.isNotEmpty &&
                app.currentAdd != oneAddress[0]['id'].toString()) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) getOneAddress();
              });
            }
            if (app.currentAdd.isNotEmpty && oneAddress.isEmpty) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) getOneAddress();
              });
            }
            final selectedCity = oneAddress.isEmpty
                ? 'اختر العنوان'
                : _addrVal('city');
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _openAddressPicker,
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A1A2E),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF37021)
                                  .withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(13),
                              border: Border.all(
                                color: const Color(0xFFF37021)
                                    .withValues(alpha: 0.3),
                              ),
                            ),
                            child: const Icon(
                              Iconsax.global,
                              color: Color(0xFFF37021),
                              size: 20,
                            ),
                          ),
                          const Spacer(),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                'المدينة المحددة',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.white.withValues(alpha: 0.4),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                selectedCity,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _addressCell(
                        Iconsax.category,
                        const Color(0xFFFFF0E5),
                        const Color(0xFFF37021),
                        'المنطقة',
                        _addrVal('zone'),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: _addressCell(
                        Iconsax.menu,
                        const Color(0xFFEEF4FF),
                        const Color(0xFF3B82F6),
                        'الشارع',
                        _addrVal('street'),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: _addressCell(
                        Iconsax.home,
                        const Color(0xFFEDFAF4),
                        const Color(0xFF22C55E),
                        'المبنى',
                        _addrVal('building'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const AddressFormWidget(),
                            ),
                          );
                        },
                        child: Container(
                          height: 40,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF0F0),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Iconsax.add_circle,
                                size: 15,
                                color: Color(0xFFFF4B4B),
                              ),
                              SizedBox(width: 5),
                              Text(
                                'إضافة',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFFFF4B4B),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          if (oneAddress.isEmpty) return;
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AddressFormWidget(
                                id: oneAddress[0]['id'].toString(),
                              ),
                            ),
                          );
                        },
                        child: Container(
                          height: 40,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0EEFF),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Iconsax.edit,
                                size: 15,
                                color: oneAddress.isEmpty
                                    ? Colors.grey
                                    : const Color(0xFF8B5CF6),
                              ),
                              const SizedBox(width: 5),
                              Text(
                                'تعديل',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: oneAddress.isEmpty
                                      ? Colors.grey
                                      : const Color(0xFF8B5CF6),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _clientFieldRow({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String label,
    required TextEditingController controller,
    required String hint,
    required TextInputType keyboardType,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 3),
                TextField(
                  controller: controller,
                  keyboardType: keyboardType,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1A1A2E),
                  ),
                  decoration: InputDecoration(
                    hintText: hint,
                    hintStyle: TextStyle(color: AppColors.textHint),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClientSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _sectionTitle(
          Iconsax.user,
          const Color(0xFFEDFAF4),
          const Color(0xFF22C55E),
          'بيانات العميل',
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFEBEBEB)),
          ),
          child: Column(
            children: [
              _clientFieldRow(
                icon: Iconsax.user,
                iconBg: const Color(0xFFEDFAF4),
                iconColor: const Color(0xFF22C55E),
                label: 'الاسم الكامل',
                controller: nameController,
                hint: 'قم بإدخال إسمك الشخصي',
                keyboardType: TextInputType.name,
              ),
              const Divider(height: 1, color: Color(0xFFF5F5F5)),
              _clientFieldRow(
                icon: Iconsax.call,
                iconBg: const Color(0xFFFFF0E5),
                iconColor: const Color(0xFFF37021),
                label: 'رقم الهاتف',
                controller: mobileController,
                hint: 'قم بإدخال رقمك الشخصي',
                keyboardType: TextInputType.phone,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProductSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _sectionTitle(
          Iconsax.box,
          const Color(0xFFFFF8ED),
          const Color(0xFFF59E0B),
          'المنتج المطلوب',
        ),
        if (myOrders.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFEBEBEB)),
            ),
            child: Column(
              children: [
                ...List.generate(myOrders.length, (i) {
                  return Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 52,
                                  height: 52,
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade200,
                                    borderRadius: BorderRadius.circular(10),
                                    image: DecorationImage(
                                      image: NetworkImage(
                                        'https://daltaliftstech.s3.ap-south-1.amazonaws.com/Sys/items/${myOrders[i]['id']}/1.jpg',
                                      ),
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  myOrders[i]['a1']?.toString() ?? '',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF1A1A2E),
                                  ),
                                ),
                              ],
                            ),
                            GestureDetector(
                              onTap: () async {
                                await getDio().post(
                                  'https://daltalifts.com/app2026/sql.php?k=${DateTime.now().millisecondsSinceEpoch}',
                                  data: {
                                    'action': 'deleteMyOrders',
                                    'id': myOrders[i]['oid'],
                                  },
                                );
                                getMyOrders();
                                setState(() {});
                              },
                              child: Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: const Color(0xFFEBEBEB),
                                  ),
                                ),
                                child: Icon(
                                  Iconsax.trash,
                                  color: Colors.red,
                                  size: 18,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (i < myOrders.length - 1)
                        const Divider(height: 1, color: Color(0xFFF5F5F5)),
                    ],
                  );
                }),
              ],
            ),
          ),
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ItemsScreen()),
            );
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFFF37021),
                width: 1.5,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFFF0E5),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Iconsax.add,
                    color: Color(0xFFF37021),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                const Text(
                  'إضافة منتج',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFFF37021),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _submitOrder(AppProvider currentTab) async {
    if (addId != '' &&
        (nameController.text.trim() != '' &&
            mobileController.text.trim() != '') &&
        myOrders.isNotEmpty) {
      setState(() {
        isLoading = true;
      });
      final SharedPreferences prefx = await SharedPreferences.getInstance();
      final String? addIdPref = prefx.getString('addId');
      final String? uid = prefx.getString('userId');
      final String? oid = prefx.getString('orderId');

      final result = await getDio().post(
        'https://daltalifts.com/app2026/sql.php?k=${DateTime.now().millisecondsSinceEpoch}',
        data: {
          'action': 'addMyBookings',
          'addId': addIdPref,
          'uid': uid,
          'oid': oid,
        },
      );

      if (result.data['success'] == true) {
        setState(() {
          isLoading = false;
        });
        await sendQuotationRequestToTelegram(
          clientName: nameController.text.trim(),
          phone: mobileController.text.trim(),
          city: oneAddress[0]['city'],
          zone: oneAddress[0]['zone'],
          street: oneAddress[0]['street'],
          building: oneAddress[0]['building'],
          latitude: oneAddress[0]['latitude'],
          longitude: oneAddress[0]['longitude'],
          items: myOrders,
        );
        currentTab.jumpToPagex(1);
        if (!mounted) return;
        showModalBottomSheet(
          context: context,
          backgroundColor: Colors.transparent,
          isScrollControlled: true,
          builder: (context) {
            return Container(
              width: double.maxFinite,
              padding: EdgeInsets.only(
                top: 20,
                left: 20,
                right: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'عرض الطلب',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Divider(color: Colors.grey.shade300),
                    const SizedBox(height: 20),
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Iconsax.tick_circle,
                        color: Colors.green,
                        size: 60,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'تم عرض الطلب بنجاح',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 15),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Text(
                        'يمكنك متابعة حالة الطلب في سجل الحجوزات لديك وشكرا لاستخدامك تطبيق دلتا',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade700,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 25),
                    _buildButton(
                      text: 'سجل الحجوزات',
                      color: AppColors.primary,
                      onTap: () {
                        Navigator.pop(context);
                      },
                    ),
                    const SizedBox(height: 12),
                    _buildOutlineButton(
                      text: 'الرئيسية',
                      color: AppColors.primary,
                      onTap: () {
                        Navigator.pop(context);
                        currentTab.jumpToPagex(0);
                      },
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
            );
          },
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('من فضلك أكمل المطلوب')),
      );
    }
  }

  Widget _buildSubmitButton(AppProvider currentTab) {
    return Container(
      width: double.infinity,
      height: 54,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.centerRight,
          end: Alignment.centerLeft,
          colors: [Color(0xFFF37021), Color(0xFFFF9A57)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFF37021).withValues(alpha: 0.35),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: isLoading ? null : () => _submitOrder(currentTab),
          child: Center(
            child: isLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Iconsax.send, color: Colors.white, size: 18),
                      SizedBox(width: 10),
                      Text(
                        'تقديم الطلب',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
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
    final currentTab = Provider.of<AppProvider>(context);
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF37021),
        body: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: Color(0xFFF2F3F7),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(28),
                    topRight: Radius.circular(28),
                  ),
                ),
                clipBehavior: Clip.hardEdge,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildAddressSection(),
                      const SizedBox(height: 12),
                      _buildClientSection(),
                      const SizedBox(height: 12),
                      _buildProductSection(),
                      const SizedBox(height: 14),
                      _buildSubmitButton(currentTab),
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Widget _buildButton({
  required String text,
  required Color color,
  required VoidCallback onTap,
}) {
  return GestureDetector(
    onTap: onTap,
    child: Container(
      width: double.maxFinite,
      padding: EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      alignment: Alignment.center,
      child: Text(
        text,
        style: TextStyle(
          fontSize: 18,
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
  );
}

// زر Outline
Widget _buildOutlineButton({
  required String text,
  required Color color,
  required VoidCallback onTap,
}) {
  return GestureDetector(
    onTap: onTap,
    child: Container(
      width: double.maxFinite,
      padding: EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color, width: 2),
      ),
      alignment: Alignment.center,
      child: Text(
        text,
        style: TextStyle(
          fontSize: 18,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
  );
}
