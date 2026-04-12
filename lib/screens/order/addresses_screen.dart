import 'package:Delta/constants/app_colors.dart';
import 'package:Delta/provider/app_provider.dart';
import 'package:Delta/screens/order/add_address_screen.dart';
import 'package:Delta/screens/order/addresses_list_screen.dart';
import 'package:Delta/services/DioServiceCert.dart';
import 'package:dio/dio.dart';
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
  const AddressesDisplayWidget({Key? key}) : super(key: key);

  @override
  State<AddressesDisplayWidget> createState() => _AddressesDisplayWidgetState();
}

class _AddressesDisplayWidgetState extends State<AddressesDisplayWidget> {
  List oneAddress = [];

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

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Column(children: [Expanded(child: _buildAddressesList())]),
    );
  }

  Widget _buildAddressesList() {
    return oneAddress.isNotEmpty
        ? _buildAddressCard(oneAddress)
        : _buildAddressCardEmpty();
  }

  Widget _buildAddressCard(List address) {
    final gradients = [
      [const Color(0xFF667EEA), const Color(0xFF764BA2)],
      [const Color(0xFFF093FB), const Color(0xFFF5576C)],
      [const Color(0xFF4FACFE), const Color(0xFF00F2FE)],
      [const Color(0xFFFA709A), const Color(0xFFFEE140)],
      [const Color(0xFF30CFD0), const Color(0xFF330867)],
    ];

    final gradient = gradients[0 % gradients.length];

    return GestureDetector(
      onTap: () async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => AddressesListScreen()),
        );
        if (result == true) {
          await getOneAddress(); // ← هنا الحل
        }
      },
      child: Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Consumer<AppProvider>(
            builder: (context, app, child) {
              if (app.currentAdd.isNotEmpty && app.currentAdd != oneAddress[0]['id'].toString()) {
                Future.microtask(() => getOneAddress());
              }
              return Column(
                children: [
                  // Content
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        _buildAddressDetail(
                          icon: Iconsax.global,
                          label: 'المدينة',
                          value: address[0]['city'],
                          color: gradient[0],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _buildAddressDetail2(
                                icon: Iconsax.map,
                                label: 'المنطقة',
                                value: address[0]['zone'],
                                color: gradient[0],
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildAddressDetail2(
                                icon: Iconsax.signpost,
                                label: 'الشارع',
                                value: address[0]['street'],
                                color: gradient[1],
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildAddressDetail2(
                                icon: Iconsax.building,
                                label: 'المبنى',
                                value: address[0]['building'],
                                color: gradient[1],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 17),
                        _buildActionButtons(address, gradient),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildAddressCardEmpty() {
    final gradients = [
      [const Color(0xFF667EEA), const Color(0xFF764BA2)],
      [const Color(0xFFF093FB), const Color(0xFFF5576C)],
      [const Color(0xFF4FACFE), const Color(0xFF00F2FE)],
      [const Color(0xFFFA709A), const Color(0xFFFEE140)],
      [const Color(0xFF30CFD0), const Color(0xFF330867)],
    ];

    final gradient = gradients[0 % gradients.length];

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => AddressesListScreen()),
        );
      },
      child: Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Consumer<AppProvider>(
            builder: (context, app, child) {
              if (app.currentAdd.isNotEmpty && oneAddress.isEmpty) {
                Future.microtask(() => getOneAddress());
              }
              return Container(
                padding: EdgeInsets.all(10),
                child: Column(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: AppColors.primary,
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(
                          child: Text(
                            "Select Your Address",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 17),
                    _buildActionButtonsEmpty(gradient),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildAddressDetail({
    IconData? icon,
    String? label,
    String? value,
    Color? color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color!.withOpacity(0.2), width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label ?? "",
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value ?? "",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2C3E50),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddressDetail2({
    IconData? icon,
    String? label,
    String? value,
    Color? color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color!.withOpacity(0.2), width: 1.5),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  label ?? "",
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value ?? "",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2C3E50),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(address, List<Color> gradient) {
    return Row(
      children: [
        Expanded(
          child: _buildActionButton(
            icon: Icons.edit,
            label: 'تعديل',
            gradient: gradient,
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
          child: _buildActionButton(
            icon: Iconsax.add_circle,
            label: 'إضافة',
            gradient: [Colors.red[400]!, Colors.red[600]!],
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

  Widget _buildActionButtonsEmpty(List<Color> gradient) {
    return Container(
      height: 50,
      child: _buildActionButton(
        icon: Iconsax.add_circle,
        label: 'إضافة',
        gradient: [Colors.red[400]!, Colors.red[600]!],
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AddressFormWidget()),
          );
        },
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required List<Color> gradient,
    required VoidCallback onTap,
  }) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: gradient),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: gradient[0].withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
