import 'package:Delta/provider/app_provider.dart';
import 'package:Delta/screens/order/add_address_screen.dart';
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

class AddressesDisplayList extends StatefulWidget {
  final void Function(bool isEmpty)? onAddressesChanged;

  const AddressesDisplayList({super.key, this.onAddressesChanged});

  @override
  State<AddressesDisplayList> createState() => AddressesDisplayListState();
}

class AddressesDisplayListState extends State<AddressesDisplayList> {
  List addresses = [];
  int currentAddress = 0;
  String? currentAddressId;

  Future getAddresses() async {
    SharedPreferences prefx = await SharedPreferences.getInstance();
    var result = await getDio().post(
      "https://daltalifts.com/app2026/sql.php?k=${DateTime.now().millisecondsSinceEpoch}",
      data: {"action": "getAddresses", "uid": prefx.getString("userId")},
    );
    if (!mounted) return;
    final loaded = (result.data['data'] as List?) ?? [];
    setState(() {
      addresses = loaded;
      final savedId = prefx.getString("addId") ?? '';
      if (loaded.isNotEmpty) {
        final savedIndex = loaded.indexWhere(
          (a) => a['id']?.toString() == savedId,
        );
        currentAddress = savedIndex >= 0 ? savedIndex : 0;
        currentAddressId = loaded[currentAddress]['id']?.toString();
      } else {
        currentAddress = 0;
        currentAddressId = null;
      }
    });
    widget.onAddressesChanged?.call(loaded.isEmpty);

    if (loaded.isNotEmpty &&
        (prefx.getString("addId") == null ||
            prefx.getString("addId")!.isEmpty)) {
      final firstId = loaded[0]['id'].toString();
      await prefx.setString('addId', firstId);
      if (!mounted) return;
      Provider.of<AppProvider>(
        context,
        listen: false,
      ).getCurrentAddress(firstId);
    }
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

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: const BoxDecoration(
              color: Color(0xFFFFF0E5),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Iconsax.location_slash,
              color: Color(0xFFF37021),
              size: 36,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'لا يوجد عنوان الآن',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1A1A2E),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'قم بإضافة عنوان جديد',
            style: TextStyle(fontSize: 14, color: Color(0xFF888888)),
          ),
        ],
      ),
    );
  }

  Widget _buildAddressesList() {
    if (addresses.isEmpty) {
      return _buildEmptyState();
    }
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
    const cityGradient = [Color(0xFFF37021), Color(0xFFFF8C00)];

    final isSelected = currentAddressId?.toString() == address[index]['id']?.toString();

    return addresses.isEmpty
        ? Column()
        : GestureDetector(
            onTap: () async {
              SharedPreferences prefx = await SharedPreferences.getInstance();
              final selectedId = address[index]['id'].toString();

              setState(() {
                currentAddress = index;
                currentAddressId = selectedId;
              });

              await prefx.setString('addId', selectedId);
              currentAdd.getCurrentAddress(selectedId);
            },
            child: Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFFFFFAF7)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFFF37021)
                            : const Color(0xFFEBEBEB),
                        width: isSelected ? 2 : 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: isSelected
                              ? const Color(0x33F37021)
                              : const Color(0x10000000),
                          blurRadius: isSelected ? 16 : 24,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            children: [
                              _buildAddressDetail(
                                icon: Iconsax.map,
                                label: 'المدينة',
                                value: address[index]['city'],
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildCompactDetail(
                                      icon: Iconsax.category,
                                      label: 'المنطقة',
                                      value: address[index]['zone'],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: _buildCompactDetail(
                                      icon: Iconsax.signpost,
                                      label: 'الشارع',
                                      value: address[index]['street'],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: _buildCompactDetail(
                                      icon: Iconsax.building,
                                      label: 'المبنى',
                                      value: address[index]['building'],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              _buildActionButtons(address, index, cityGradient),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isSelected)
                    const Positioned(
                      top: -6,
                      left: -6,
                      child: _SelectedAddressBadge(),
                    ),
                ],
              ),
            ),
          );
  }

  Widget _buildAddressDetail({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEBEBEB), width: 1),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF9E9EBE),
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1A1A2E),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFFFF0E5),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: const Color(0xFFF37021), size: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactDetail({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEBEBEB), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xFFF37021), size: 14),
              const SizedBox(width: 4),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 10,
                  color: Color(0xFF9E9EBE),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1A1A2E),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(
    List address,
    int index,
    List<Color> gradient,
  ) {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: _buildActionButton(
            icon: Iconsax.edit,
            label: 'تعديل',
            gradient: gradient,
            onTap: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AddressFormWidget(
                    id: address[index]['id'].toString(),
                  ),
                ),
              );
              if (result == true && mounted) {
                await getAddresses();
              }
            },
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          flex: 1,
          child: _buildDeleteButton(address, index),
        ),
      ],
    );
  }

  Widget _buildDeleteButton(List address, int index) {
    return GestureDetector(
      onTap: () async {
        final confirm = await showDialog<bool>(
          context: context,
          builder: (ctx) => Directionality(
            textDirection: TextDirection.rtl,
            child: AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: const Text(
                'حذف العنوان',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              content: const Text('هل تريد حذف هذا العنوان؟'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text(
                    'إلغاء',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text(
                    'حذف',
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );

        if (confirm == true) {
          SharedPreferences prefx = await SharedPreferences.getInstance();
          var result = await getDio().post(
            "https://daltalifts.com/app2026/sql.php?k=${DateTime.now().millisecondsSinceEpoch}",
            data: {
              "action": "deleteAddress",
              "id": address[index]['id'],
              "uid": prefx.getString("userId"),
            },
          );
          if (result.data['status'] == 'success') {
            getAddresses();
          }
        }
      },
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: const Color(0xFFFFEEEE),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.red.withOpacity(0.3), width: 1),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Iconsax.trash, color: Colors.red, size: 20),
            SizedBox(width: 6),
            Text(
              'حذف',
              style: TextStyle(
                color: Colors.red,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
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
      height: 50,
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: gradient),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: gradient[0].withOpacity(0.35),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
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

class _SelectedAddressBadge extends StatelessWidget {
  const _SelectedAddressBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      decoration: const BoxDecoration(
        color: Color(0xFFF37021),
        shape: BoxShape.circle,
      ),
      child: const Icon(
        Iconsax.tick_circle,
        color: Colors.white,
        size: 14,
      ),
    );
  }
}
