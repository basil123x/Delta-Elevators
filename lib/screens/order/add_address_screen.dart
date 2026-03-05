import 'package:Delta/screens/order/addresses_list_screen.dart';
import 'package:Delta/screens/order/addresses_screen.dart';
import 'package:Delta/services/DioServiceCert.dart';
import 'package:Delta/services/LocationService.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:iconsax/iconsax.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AddressFormWidget extends StatefulWidget {
  final String? id;
  const AddressFormWidget({Key? key, this.id}) : super(key: key);

  @override
  State<AddressFormWidget> createState() => _AddressFormWidgetState();
}

class _AddressFormWidgetState extends State<AddressFormWidget>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _zoneController = TextEditingController();
  final _streetController = TextEditingController();
  final _buildController = TextEditingController();
  final _locationController = TextEditingController();

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  Future getOneAddress() async {
    var result = await getDio().post(
      "https://daltalifts.com/app2026/sql.php",
      data: {"action": "getOneAddress", "id": widget.id},
    );
    setState(() {
      selectedCity = result.data['data'][0]['city'];
      _zoneController.text = result.data['data'][0]['zone'];
      _streetController.text = result.data['data'][0]['street'];
      _buildController.text = result.data['data'][0]['building'];
    });
    LocationService locationService = LocationService();
    Position? position = await locationService.getCurrentLocation();
    String address = await locationService.getAddressFromCoordinates(
      double.parse(result.data['data'][0]['latitude']),
      double.parse(result.data['data'][0]['longitude']),
    );
    _locationController.text = address;
    lat = double.parse(result.data['data'][0]['latitude']);
    lng = double.parse(result.data['data'][0]['longitude']);
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    getOneAddress();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutCubic,
          ),
        );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _zoneController.dispose();
    _streetController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          forceMaterialTransparency: true,
          backgroundColor: Colors.white,
          title: Text("إضافة عنوان"),
          centerTitle: true,
        ),
        backgroundColor: Colors.white,
        body: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [_buildAddressCard(), const SizedBox(height: 52)],
                  ),
                ),
              ),
            ),
          ),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
        floatingActionButton: Container(
          margin: EdgeInsets.symmetric(horizontal: 10),
          child: _buildSubmitButton(),
        ),
      ),
    );
  }

  String? selectedCity;
  double lat = 0.0;
  double lng = 0.0;
  final List<String> cities = [
    'الدوحة',
    'الخور',
    'الوكرة',
    'الخوير',
    'الرويس',
    'الريان',
    'رأس لفان',
    'دخان',
    'أم سعيد',
    'أم صلال علي',
    'أم باب',
    'أم صلال محمد',
    'مدينة الشمال',
    'مدينة الزبارة',
  ];

  Widget _buildAddressCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            _buildDropdownField(
              value: selectedCity,
              items: cities,
              label: 'المدينة',
              icon: Iconsax.global,
              hint: 'اختر المدينة',
              gradientColors: [
                const Color(0xFF667EEA),
                const Color(0xFF764BA2),
              ],
              onChanged: (value) {
                setState(() {
                  selectedCity = value;
                });
              },
            ),
            const SizedBox(height: 24),
            _buildTextField(
              myKeyboard: TextInputType.number,
              controller: _zoneController,
              label: 'المنطقة',
              icon: Iconsax.map,
              hint: 'أدخل رقم المنطقة',
              gradientColors: [
                const Color(0xFFF093FB),
                const Color(0xFFF5576C),
              ],
            ),
            const SizedBox(height: 24),
            _buildTextField(
              myKeyboard: TextInputType.number,
              controller: _streetController,
              label: 'الشارع',
              icon: Iconsax.signpost,
              hint: 'أدخل رقم الشارع',
              gradientColors: [
                const Color(0xFF4FACFE),
                const Color(0xFF00F2FE),
              ],
            ),
            const SizedBox(height: 24),
            _buildTextField(
              myKeyboard: TextInputType.number,
              controller: _buildController,
              label: 'المبنى',
              icon: Iconsax.building,
              hint: 'أدخل رقم المبنى',
              gradientColors: [
                const Color(0xFF4FACFE),
                const Color(0xFF00F2FE),
              ],
            ),
            const SizedBox(height: 24),
            _buildTextField(
              onTaped: () async {
                LocationService locationService = LocationService();
                Position? position = await locationService.getCurrentLocation();

                if (position != null) {
                  String address = await locationService
                      .getAddressFromCoordinates(
                        position.latitude,
                        position.longitude,
                      );
                  setState(() {
                    lat = position.latitude;
                    lng = position.longitude;
                  });

                  setState(() {
                    _locationController.text = address;
                  });
                }
              },
              isRead: true,
              controller: _locationController,
              label: 'الموقع',
              icon: Iconsax.location,
              hint: 'إضغط لكي تضيف الموقع',
              gradientColors: [
                const Color(0xFF4FACFE),
                const Color(0xFF00F2FE),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String hint,
    required List<Color> gradientColors,
    Function()? onTaped,
    bool? isRead,
    TextInputType? myKeyboard,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: gradientColors),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2C3E50),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.withOpacity(0.2), width: 2),
          ),
          child: TextFormField(
            keyboardType: myKeyboard,
            onTap: onTaped,
            controller: controller,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            readOnly: isRead ?? false,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                color: Colors.grey[400],
                fontWeight: FontWeight.normal,
              ),
              filled: true,
              fillColor: const Color(0xFFF8F9FA),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: gradientColors[0], width: 2),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 18,
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'هذا الحقل مطلوب';
              }
              return null;
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField({
    required String? value,
    required List<String> items,
    required String label,
    required IconData icon,
    required String hint,
    required List<Color> gradientColors,
    required Function(String?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: gradientColors),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2C3E50),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.withOpacity(0.2), width: 2),
          ),
          child: DropdownButtonFormField<String>(
            value: value,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                color: Colors.grey[400],
                fontWeight: FontWeight.normal,
              ),
              filled: true,
              fillColor: const Color(0xFFF8F9FA),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: gradientColors[0], width: 2),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 18,
              ),
            ),
            icon: Icon(
              Icons.keyboard_arrow_down_rounded,
              color: gradientColors[0],
              size: 28,
            ),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Color(0xFF2C3E50),
            ),
            dropdownColor: Colors.white,
            borderRadius: BorderRadius.circular(16),
            items: items.map((String item) {
              return DropdownMenuItem<String>(value: item, child: Text(item));
            }).toList(),
            onChanged: onChanged,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'هذا الحقل مطلوب';
              }
              return null;
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return Container(
      height: 60,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFF8E53), Color(0xFFFF6B6B)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF6B6B).withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () async {
            SharedPreferences prefx = await SharedPreferences.getInstance();
            if (_formKey.currentState!.validate()) {
              var data = {
                "action": widget.id != null
                    ? "updateOneAddress"
                    : "addNewAddress",
                "city": selectedCity,
                "zone": _zoneController.text.trim(),
                "street": _streetController.text.trim(),
                "building": _buildController.text.trim(),
                "latitude": lat,
                "longitude": lng,
                "uid": widget.id != null
                    ? widget.id
                    : prefx.getString("userId"),
              };
              print(data);
              await getDio().post(
                "https://daltalifts.com/app2026/sql.php?k=${DateTime.now().millisecondsSinceEpoch}",
                data: data,
              );
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text(
                    'تم حفظ العنوان بنجاح! ✓',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  backgroundColor: const Color(0xFF4CAF50),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  margin: const EdgeInsets.all(16),
                ),
              );
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => AddressesListScreen()),
              );
            }
          },
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${widget.id != null ? 'تعديل' : 'إضافة'} عنوان',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
