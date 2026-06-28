import 'dart:math';

import 'package:Delta/provider/app_provider.dart';
import 'package:Delta/screens/order/add_address_screen.dart';
import 'package:Delta/services/DioServiceCert.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:iconsax/iconsax.dart';

// Premium addresses palette
const _bgScreen = Color(0xFFF7F8FA);
const _textPrimary = Color(0xFF1A1A2E);
const _textMuted = Color(0xFF9E9EBE);

class AddressesScreen extends StatefulWidget {
  final bool returnMode;
  const AddressesScreen({super.key, this.returnMode = false});

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
    final loaded = result.data['data'] as List;
    setState(() {
      addresses = loaded;
      final savedId = prefx.getString("addId");
      if (loaded.isNotEmpty) {
        // find index of saved address, fallback to 0
        final savedIndex = loaded.indexWhere((a) => a['id'] == savedId);
        currentAddress = savedIndex >= 0 ? savedIndex : 0;
        currentAddressId = loaded[currentAddress]['id'];
      }
    });
    if (loaded.isNotEmpty &&
        (prefx.getString("addId") == null ||
            prefx.getString("addId")!.isEmpty)) {
      await prefx.setString('addId', loaded[0]['id']);
      if (!mounted) return;
      Provider.of<AppProvider>(
        context,
        listen: false,
      ).getCurrentAddress(loaded[0]['id']);
    }
  }

  bool isLoading = false;

  @override
  void initState() {
    getAddresses();
    super.initState();
  }

  TextStyle _cairo({
    double fontSize = 14,
    FontWeight fontWeight = FontWeight.w400,
    Color color = _textPrimary,
  }) {
    return GoogleFonts.cairo(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
    );
  }

  Future<void> _selectAddress(int i) async {
    SharedPreferences prefx = await SharedPreferences.getInstance();
    setState(() {
      currentAddress = i;
      currentAddressId = addresses[i]['id'];
    });
    prefx.setString('addId', addresses[i]['id']);
    Provider.of<AppProvider>(
      context,
      listen: false,
    ).getCurrentAddress(addresses[i]['id']);
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _bgScreen,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          scrolledUnderElevation: 0,
          surfaceTintColor: Colors.white,
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Iconsax.arrow_right_3, color: Color(0xFFF37021)),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'العناوين',
            style: _cairo(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: _textPrimary,
            ),
          ),
        ),
        body: addresses.isEmpty
            ? _buildEmptyState()
            : AnimationLimiter(
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(0, 8, 0, 100),
                  itemCount: addresses.length,
                  itemBuilder: (context, i) {
                    final isSelected = currentAddressId == addresses[i]['id'];
                    return AnimationConfiguration.staggeredList(
                      position: i,
                      duration: const Duration(milliseconds: 380),
                      delay: Duration(milliseconds: 100 * i),
                      child: SlideAnimation(
                        verticalOffset: 36,
                        child: FadeInAnimation(
                          child: _buildAddressCard(
                            index: i,
                            isSelected: isSelected,
                            onSelect: () => _selectAddress(i),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
        floatingActionButton: SafeArea(
          minimum: const EdgeInsets.only(bottom: 4),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _ScaleTapButton(
              onTap: () async {
                if (addresses.isEmpty) {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AddressFormWidget(),
                    ),
                  );
                  await getAddresses();
                  return;
                }
                setState(() {
                  isLoading = true;
                });
                if (widget.returnMode) {
                  Navigator.pop(context, currentAddressId);
                } else {
                  Navigator.pop(context);
                }
              },
              child: Container(
                height: 58,
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFF37021), Color(0xFFFF8C00)],
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
                child: isLoading
                    ? const Center(
                        child: SizedBox(
                          width: 26,
                          height: 26,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            addresses.isEmpty
                                ? Iconsax.location_add
                                : Iconsax.location_tick,
                            color: Colors.white,
                            size: 22,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            addresses.isEmpty
                                ? 'إضافة عنوان جديد'
                                : 'إختيار العنوان',
                            style: _cairo(
                              fontSize: 17,
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
          Text(
            'لا يوجد عنوان الآن',
            style: _cairo(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF1A1A2E),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'قم بإضافة عنوان جديد',
            style: _cairo(fontSize: 14, color: const Color(0xFF888888)),
          ),
        ],
      ),
    );
  }

  Widget _buildAddressCard({
    required int index,
    required bool isSelected,
    required VoidCallback onSelect,
  }) {
    final addr = addresses[index];
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFFFFFAF7) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isSelected ? const Color(0xFFF37021) : const Color(0xFFEBEBEB),
          width: isSelected ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isSelected
                ? const Color(0x33F37021)
                : const Color(0x14000000),
            blurRadius: isSelected ? 16 : 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: onSelect,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildFieldRow(
                        label: 'المدينة',
                        value: '${addr['city'] ?? ''}',
                        icon: Iconsax.building,
                      ),
                      const SizedBox(height: 12),
                      _buildFieldRow(
                        label: 'المنطقة',
                        value: '${addr['zone'] ?? ''}',
                        icon: Iconsax.map,
                      ),
                      const SizedBox(height: 12),
                      _buildFieldRow(
                        label: 'الشارع',
                        value: '${addr['street'] ?? ''}',
                        icon: Iconsax.signpost,
                      ),
                      const SizedBox(height: 12),
                      _buildFieldRow(
                        label: 'المبنى',
                        value: '${addr['building'] ?? ''}',
                        icon: Iconsax.building,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const Divider(height: 1, color: Color(0xFFF0EEF8)),
                const SizedBox(height: 12),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    splashColor: Colors.transparent,
                    highlightColor: Colors.transparent,
                    onTap: () {},
                    child: Ink(
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF5B4FCF), Color(0xFF9C42F5)],
                        ),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Iconsax.edit,
                            color: Colors.white,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'تعديل',
                            style: _cairo(
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
              ],
            ),
          ),
          if (isSelected)
            const Positioned(top: -6, left: -6, child: _SelectedAddressBadge()),
        ],
      ),
    );
  }

  Widget _buildFieldRow({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: const Color(0xFFFFF0E5),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: const Color(0xFFF37021), size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                label,
                style: _cairo(
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: _textMuted,
                ),
                textAlign: TextAlign.right,
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: _cairo(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: _textPrimary,
                ),
                textAlign: TextAlign.right,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
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
      child: const Icon(Iconsax.tick_circle, color: Colors.white, size: 14),
    );
  }
}

/// Scale-down feedback on press (0.97).
class _ScaleTapButton extends StatefulWidget {
  const _ScaleTapButton({required this.onTap, required this.child});

  final Future<void> Function() onTap;
  final Widget child;

  @override
  State<_ScaleTapButton> createState() => _ScaleTapButtonState();
}

class _ScaleTapButtonState extends State<_ScaleTapButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOut,
        child: widget.child,
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
