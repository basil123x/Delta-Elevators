import 'package:Delta/provider/app_provider.dart';
import 'package:Delta/screens/order/add_address_screen.dart';
import 'package:Delta/screens/order/addresses_list_screen.dart';
import 'package:Delta/services/DioServiceCert.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Model for Address
class Address {
  final String id;
  final String city;
  final String region;
  final String street;
  final bool isDefault;

  Address({
    required this.id,
    required this.city,
    required this.region,
    required this.street,
    this.isDefault = false,
  });
}

class AddressesDisplayWidget extends StatefulWidget {
  const AddressesDisplayWidget({super.key});

  @override
  State<AddressesDisplayWidget> createState() => _AddressesDisplayWidgetState();
}

class _AddressesDisplayWidgetState extends State<AddressesDisplayWidget> {
  static const Color _orange = Color(0xFFF37021);
  static const Color _textDark = Color(0xFF1A1A2E);

  List oneAddress = [];

  BoxDecoration get _outerCardDecoration => BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(20),
    border: Border.all(color: const Color(0xFFEBEBEB)),
    boxShadow: const [
      BoxShadow(color: Color(0x0D000000), blurRadius: 8, offset: Offset(0, 2)),
    ],
  );

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

  @override
  void initState() {
    getOneAddress();
    super.initState();
  }

  Widget _sectionHeader() {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Icon(Iconsax.location, color: _orange, size: 20),
        SizedBox(width: 8),
        Text(
          'عنوان التركيب',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: _textDark,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Container(
          clipBehavior: Clip.none,
          decoration: _outerCardDecoration,
          padding: const EdgeInsets.all(12),
          child: _buildAddressesList(),
        ),
      ),
    );
  }

  Widget _buildAddressesList() {
    return oneAddress.isNotEmpty
        ? _buildAddressCard(oneAddress)
        : _buildAddressCardEmpty();
  }

  Widget _buildAddressCard(List address) {
    return GestureDetector(
      onTap: () async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => AddressesListScreen()),
        );
        if (result == true) {
          await getOneAddress();
        }
      },
      child: Consumer<AppProvider>(
        builder: (context, app, child) {
          if (app.currentAdd.isNotEmpty &&
              app.currentAdd != oneAddress[0]['id'].toString()) {
            Future.microtask(() => getOneAddress());
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _sectionHeader(),
              const SizedBox(height: 12),
              _buildCityCard(address[0]['city'].toString()),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _buildSmallField(
                      icon: Iconsax.home_2,
                      label: 'المنطقة',
                      value: address[0]['zone'].toString(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildSmallField(
                      icon: Iconsax.map,
                      label: 'الشارع',
                      value: address[0]['street'].toString(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildSmallField(
                      icon: Iconsax.building,
                      label: 'المبنى',
                      value: address[0]['building'].toString(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildActionButtons(address),
            ],
          );
        },
      ),
    );
  }

  Widget _buildAddressCardEmpty() {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => AddressesListScreen()),
        );
      },
      child: Consumer<AppProvider>(
        builder: (context, app, child) {
          if (app.currentAdd.isNotEmpty && oneAddress.isEmpty) {
            Future.microtask(() => getOneAddress());
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _sectionHeader(),
              const SizedBox(height: 12),
              _buildCityCard('اختر العنوان'),
              const SizedBox(height: 12),
              _buildActionButtonsEmpty(),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCityCard(String city) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEBEBEB)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFFFF0E5),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Iconsax.global, color: _orange, size: 20),
          ),
          const Spacer(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text(
                'المدينة المحددة',
                style: TextStyle(
                  fontSize: 11,
                  color: Color(0xFF888888),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                city,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: _textDark,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSmallField({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEBEBEB)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: _orange, size: 18),
          const SizedBox(height: 8),
          Text(
            value,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: _textDark,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF888888),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(address) {
    return Row(
      children: [
        Expanded(
          child: _buildFlatActionButton(
            icon: Iconsax.edit_2,
            label: 'تعديل',
            backgroundColor: const Color(0xFFF3EEFF),
            textColor: const Color(0xFF6366F1),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AddressFormWidget(id: address[0]['id']),
                ),
              );
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildFlatActionButton(
            icon: Iconsax.add_circle,
            label: 'إضافة',
            backgroundColor: const Color(0xFFFFEEEE),
            textColor: const Color(0xFFEF4444),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AddressFormWidget()),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtonsEmpty() {
    return SizedBox(
      height: 44,
      child: _buildFlatActionButton(
        icon: Iconsax.add_circle,
        label: 'إضافة',
        backgroundColor: const Color(0xFFFFEEEE),
        textColor: const Color(0xFFEF4444),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AddressFormWidget()),
          );
        },
      ),
    );
  }

  Widget _buildFlatActionButton({
    required IconData icon,
    required String label,
    required Color backgroundColor,
    required Color textColor,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          height: 44,
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: textColor, size: 18),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
