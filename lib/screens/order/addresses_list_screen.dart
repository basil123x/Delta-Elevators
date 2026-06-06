import 'package:Delta/screens/order/add_address_screen.dart';
import 'package:Delta/screens/order/addresses_display_screen.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

class AddressesListScreen extends StatefulWidget {
  const AddressesListScreen({super.key});

  @override
  State<AddressesListScreen> createState() => _AddressesListScreenState();
}

class _AddressesListScreenState extends State<AddressesListScreen> {
  final GlobalKey<AddressesDisplayListState> _displayKey = GlobalKey();
  bool _addressesEmpty = true;

  void _onAddressesChanged(bool isEmpty) {
    if (_addressesEmpty != isEmpty) {
      setState(() => _addressesEmpty = isEmpty);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.white,
        centerTitle: true,
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(Iconsax.arrow_right_3, color: Color(0xFFF37021)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'العناوين',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: Color(0xFF1A1A2E),
          ),
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, thickness: 1, color: Color(0xFFEEEEEE)),
        ),
      ),
      body: AddressesDisplayList(
        key: _displayKey,
        onAddressesChanged: _onAddressesChanged,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: GestureDetector(
        onTap: () async {
          if (_addressesEmpty) {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const AddressFormWidget(),
              ),
            );
            await _displayKey.currentState?.getAddresses();
            return;
          }
          Navigator.pop(context, true);
        },
        child: Container(
          width: double.infinity,
          height: 58,
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFF37021), Color(0xFFFF8C00)],
              begin: Alignment.centerRight,
              end: Alignment.centerLeft,
            ),
            borderRadius: BorderRadius.circular(18),
            boxShadow: const [
              BoxShadow(
                color: Color(0x33F37021),
                blurRadius: 20,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _addressesEmpty ? Iconsax.location_add : Iconsax.location_tick,
                color: Colors.white,
                size: 22,
              ),
              const SizedBox(width: 10),
              Text(
                _addressesEmpty ? 'إضافة عنوان جديد' : 'إختيار العنوان',
                style: const TextStyle(
                  fontSize: 17,
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
