import 'package:Delta/constants/app_colors.dart';
import 'package:Delta/provider/app_provider.dart';
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

class AddressesDisplayList extends StatefulWidget {
  const AddressesDisplayList({Key? key}) : super(key: key);

  @override
  State<AddressesDisplayList> createState() => _AddressesDisplayListState();
}

class _AddressesDisplayListState extends State<AddressesDisplayList> {
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

  @override
  void initState() {
    getAddresses();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    print(addresses);
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Column(
        children: [
          Expanded(child: _buildAddressesList()),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildAddressesList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: addresses.length,
      itemBuilder: (context, index) {
        return _buildAddressCard(addresses, index);
      },
    );
  }

  Widget _buildAddressCard(List address, int index) {
    final currentAdd = Provider.of<AppProvider>(context);
    final gradients = [
      [const Color(0xFF667EEA), const Color(0xFF764BA2)],
      [const Color(0xFFF093FB), const Color(0xFFF5576C)],
      [const Color(0xFF4FACFE), const Color(0xFF00F2FE)],
      [const Color(0xFFFA709A), const Color(0xFFFEE140)],
      [const Color(0xFF30CFD0), const Color(0xFF330867)],
    ];

    final gradient = gradients[index % gradients.length];

    return addresses.isEmpty
        ? Column()
        : GestureDetector(
            onTap: () async {
              SharedPreferences prefx = await SharedPreferences.getInstance();
              setState(() {
                currentAddress = index;
                currentAddressId = address[index]['id'];
              });
              prefx.setString('addId', address[index]['id']);
              currentAdd.getCurrentAddress(address[index]['id']);
            },
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: currentAddressId == address[index]['id']
                      ? Border.all(color: AppColors.primary, width: 3)
                      : Border(),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Content
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          _buildAddressDetail(
                            icon: Icons.map,
                            label: 'المدينة',
                            value: address[index]['city'],
                            color: gradient[0],
                          ),
                          const SizedBox(height: 16),
                          _buildAddressDetail(
                            icon: Icons.map,
                            label: 'المنطقة',
                            value: address[index]['zone'],
                            color: gradient[0],
                          ),
                          const SizedBox(height: 16),
                          _buildAddressDetail(
                            icon: Icons.signpost,
                            label: 'الشارع',
                            value: address[index]['street'],
                            color: gradient[1],
                          ),
                          const SizedBox(height: 16),
                          _buildAddressDetail(
                            icon: Icons.signpost,
                            label: 'المبنى',
                            value: address[index]['building'],
                            color: gradient[1],
                          ),
                          const SizedBox(height: 20),
                          _buildActionButtons(address, gradient),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
  }

  Widget _buildAddressDetail({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.2), width: 1.5),
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
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
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

  Widget _buildActionButtons(List address, List<Color> gradient) {
    return _buildActionButton(
      icon: Icons.edit,
      label: 'تعديل',
      gradient: gradient,
      onTap: () {},
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
