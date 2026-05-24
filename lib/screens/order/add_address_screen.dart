import 'dart:convert';

import 'package:Delta/screens/order/addresses_list_screen.dart';
import 'package:Delta/services/DioServiceCert.dart';
import 'package:Delta/services/LocationService.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// استبدل القيمة بمفتاح HERE الفعلي من لوحة تحكم HERE.
const String kHereReverseGeocodeApiKey =
    'YqeR-dkt71LsuqVdKQpO9n_Ckq_xEvh6ptYhnF92SQY';

class AddressFormWidget extends StatefulWidget {
  final String? id;
  const AddressFormWidget({super.key, this.id});

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

  bool _hereReverseLoading = false;

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
    await locationService.getCurrentLocation();
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
    _autoFillFromLocation();
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

  String _osmAddressPart(Map<String, dynamic> address, List<String> keys) {
    for (final key in keys) {
      final v = address[key];
      if (v == null) continue;
      final s = v.toString().trim();
      if (s.isNotEmpty) return s;
    }
    return '';
  }

  Future<void> _autoFillFromLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }
      if (permission == LocationPermission.deniedForever) return;

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final url =
          'https://nominatim.openstreetmap.org/reverse'
          '?format=json'
          '&lat=${position.latitude}'
          '&lon=${position.longitude}'
          '&addressdetails=1'
          '&accept-language=ar';

      final response = await Dio().get(
        url,
        options: Options(headers: {'User-Agent': 'DeltaElevatorsApp/1.0'}),
      );

      if (response.statusCode != 200 || response.data == null) return;

      final data = response.data;
      if (data is! Map) return;
      final rawAddress = data['address'];
      if (rawAddress is! Map) return;

      final address = Map<String, dynamic>.from(
        rawAddress.map((k, v) => MapEntry(k.toString(), v)),
      );

      debugPrint('📍 OSM Address: $address');

      if (_zoneController.text.isEmpty) {
        final zone = _osmAddressPart(address, [
          'suburb',
          'quarter',
          'district',
          'neighbourhood',
        ]);
        if (zone.isNotEmpty) _zoneController.text = zone;
      }

      if (_streetController.text.isEmpty) {
        final street = _osmAddressPart(address, [
          'road',
          'street',
          'pedestrian',
        ]);
        if (street.isNotEmpty) _streetController.text = street;
      }

      if (_buildController.text.isEmpty) {
        final building = _osmAddressPart(address, ['house_number', 'building']);
        if (building.isNotEmpty) _buildController.text = building;
      }

      if (mounted) setState(() {});
      debugPrint(
        '✅ Auto-filled: zone=${_zoneController.text}, street=${_streetController.text}, building=${_buildController.text}',
      );
    } catch (e) {
      debugPrint('❌ Auto-fill error: $e');
    }
  }

  void _showCityPicker(FormFieldState<String> fieldState) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) => Directionality(
        textDirection: TextDirection.rtl,
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(sheetContext).padding.bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE0E0E0),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEEF4FF),
                        borderRadius: BorderRadius.circular(11),
                      ),
                      child: const Icon(
                        Icons.language_rounded,
                        color: Color(0xFF3B82F6),
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'اختر المدينة',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF1A1A2E),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: Color(0xFFF5F5F5)),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 380),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: cities.length,
                  itemBuilder: (context, index) {
                    final city = cities[index];
                    final isSelected = selectedCity == city;
                    return InkWell(
                      onTap: () {
                        setState(() => selectedCity = city);
                        fieldState.didChange(city);
                        Navigator.pop(sheetContext);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFFFFF8F4)
                              : Colors.transparent,
                          border: const Border(
                            bottom: BorderSide(color: Color(0xFFF5F5F5)),
                          ),
                        ),
                        child: Row(
                          children: [
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isSelected
                                    ? const Color(0xFFF37021)
                                    : Colors.transparent,
                                border: Border.all(
                                  color: isSelected
                                      ? const Color(0xFFF37021)
                                      : const Color(0xFFDDDDDD),
                                  width: 1.5,
                                ),
                              ),
                              child: isSelected
                                  ? const Icon(
                                      Icons.check_rounded,
                                      size: 12,
                                      color: Colors.white,
                                    )
                                  : null,
                            ),
                            const Spacer(),
                            Text(
                              city,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: isSelected
                                    ? FontWeight.w800
                                    : FontWeight.w500,
                                color: isSelected
                                    ? const Color(0xFFF37021)
                                    : const Color(0xFF1A1A2E),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _zoneController.dispose();
    _streetController.dispose();
    super.dispose();
  }

  Future<void> _updateLocationFromGps() async {
    LocationService locationService = LocationService();
    Position? position = await locationService.getCurrentLocation();

    if (position != null) {
      String address = await locationService.getAddressFromCoordinates(
        position.latitude,
        position.longitude,
      );
      setState(() {
        lat = position.latitude;
        lng = position.longitude;
        _locationController.text = address;
      });
    }
  }

  void _showHereSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: const Color(0xFFE53935),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  String? _matchCityFromHere(String? hereCity) {
    if (hereCity == null || hereCity.trim().isEmpty) return null;
    final t = hereCity.trim();
    for (final c in cities) {
      if (c == t) return c;
    }
    for (final c in cities) {
      if (c.contains(t) || t.contains(c)) return c;
    }
    return null;
  }

  String? _strFromHere(dynamic v) {
    if (v == null) return null;
    final s = v.toString().trim();
    return s.isEmpty ? null : s;
  }

  Future<void> _fillAddressFromHereReverseGeocode() async {
    setState(() => _hereReverseLoading = true);
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied) {
        _showHereSnack('تم رفض إذن الموقع');
        return;
      }
      if (permission == LocationPermission.deniedForever) {
        _showHereSnack('إذن الموقع غير متاح. فعّله من إعدادات التطبيق');
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final latStr = position.latitude.toString();
      final lngStr = position.longitude.toString();
      final uri = Uri.parse(
        'https://revgeocode.search.hereapi.com/v1/revgeocode'
        '?at=$latStr,$lngStr&lang=ar&apiKey=$kHereReverseGeocodeApiKey',
      );

      final response = await http.get(uri).timeout(const Duration(seconds: 25));

      if (response.statusCode != 200) {
        _showHereSnack('تعذر جلب العنوان (${response.statusCode})');
        return;
      }

      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        _showHereSnack('استجابة غير صالحة من الخادم');
        return;
      }
      final items = decoded['items'];
      if (items is! List || items.isEmpty) {
        _showHereSnack('لا توجد نتيجة عنوان لهذه الإحداثيات');
        return;
      }

      final first = items.first;
      if (first is! Map<String, dynamic>) {
        _showHereSnack('صيغة النتيجة غير متوقعة');
        return;
      }

      final addr = first['address'];
      if (addr is! Map<String, dynamic>) {
        _showHereSnack('لا يوجد حقل عنوان في النتيجة');
        return;
      }

      final houseNumber = _strFromHere(addr['houseNumber']);
      final street = _strFromHere(addr['street']);
      final district = _strFromHere(addr['district']);
      final cityHere = _strFromHere(addr['city']);
      final label = _strFromHere(addr['label']);

      final matchedCity = _matchCityFromHere(cityHere);

      setState(() {
        lat = position.latitude;
        lng = position.longitude;
        if (houseNumber != null) _buildController.text = houseNumber;
        if (street != null) _streetController.text = street;
        if (district != null) _zoneController.text = district;
        if (matchedCity != null) selectedCity = matchedCity;
        if (label != null) {
          _locationController.text = label;
        } else if (street != null || district != null) {
          _locationController.text = [
            if (district != null) district,
            if (street != null) street,
            if (houseNumber != null) houseNumber,
          ].join('، ');
        }
      });
    } catch (e) {
      _showHereSnack('تعذر جلب العنوان');
      debugPrint('HERE revgeocode error: $e');
    } finally {
      if (mounted) setState(() => _hereReverseLoading = false);
    }
  }

  Future<void> _onSubmitAddress() async {
    SharedPreferences prefx = await SharedPreferences.getInstance();
    if (_formKey.currentState!.validate()) {
      var data = {
        "action": widget.id != null ? "updateOneAddress" : "addNewAddress",
        "city": selectedCity,
        "zone": _zoneController.text.trim(),
        "street": _streetController.text.trim(),
        "building": _buildController.text.trim(),
        "latitude": lat,
        "longitude": lng,
        "uid": widget.id ?? prefx.getString("userId"),
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
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF2F3F7),
        body: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(14),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          _buildMapPreview(),
                          const SizedBox(height: 12),
                          _buildHereAutoLocationButton(),
                          const SizedBox(height: 12),
                          _buildCityField(),
                          const SizedBox(height: 12),
                          _buildAddressFields(),
                          const SizedBox(height: 12),
                          _buildLocationField(),
                          const SizedBox(height: 20),
                          _buildSubmitButton(),
                          const SizedBox(height: 30),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
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

  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF0F0F1A),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 20,
        bottom: 28,
        left: 16,
        right: 16,
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: -25,
            right: -15,
            child: Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFF37021).withOpacity(0.08),
              ),
            ),
          ),
          Positioned(
            bottom: -35,
            left: 10,
            child: Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFF37021).withOpacity(0.06),
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
                        color: Colors.white.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 15,
                        color: Colors.white.withOpacity(0.6),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'إضافة عنوان',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 20,
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
                'حدد موقع التركيب بدقة',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withOpacity(0.35),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMapPreview() {
    return GestureDetector(
      onTap: _updateLocationFromGps,
      child: Container(
        width: double.infinity,
        height: 120,
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A2E),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFF37021).withOpacity(0.25)),
        ),
        clipBehavior: Clip.hardEdge,
        child: Stack(
          fit: StackFit.expand,
          children: [
            CustomPaint(painter: _GridPainter()),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF37021),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFF37021).withOpacity(0.4),
                          blurRadius: 12,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.location_on_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              bottom: 8,
              left: 0,
              right: 0,
              child: Text(
                'اضغط لتحديد الموقع على الخريطة',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.white.withOpacity(0.45),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHereAutoLocationButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton(
        onPressed: _hereReverseLoading
            ? null
            : _fillAddressFromHereReverseGeocode,
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFFF37021),
          side: const BorderSide(color: Color(0xFFF37021), width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          backgroundColor: Colors.white,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_hereReverseLoading)
              const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Color(0xFFF37021),
                ),
              )
            else
              const Icon(Icons.my_location_rounded, size: 22),
            const SizedBox(width: 10),
            Text(
              'تحديد موقعي تلقائياً',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: _hereReverseLoading
                    ? const Color(0xFFF37021).withOpacity(0.6)
                    : const Color(0xFFF37021),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCityField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFEBEBEB)),
      ),
      child: _fieldRow(
        icon: Icons.language_rounded,
        iconBg: const Color(0xFFEEF4FF),
        iconColor: const Color(0xFF3B82F6),
        label: 'المدينة',
        child: _cityPickerFormField(),
      ),
    );
  }

  Widget _cityPickerFormField() {
    return FormField<String>(
      initialValue: selectedCity,
      validator: (_) {
        if (selectedCity == null || selectedCity!.isEmpty) {
          return 'هذا الحقل مطلوب';
        }
        return null;
      },
      builder: (fieldState) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => _showCityPicker(fieldState),
              child: Row(
                children: [
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        selectedCity ?? 'اختر المدينة',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: selectedCity != null
                              ? const Color(0xFF2C3E50)
                              : Colors.grey[400],
                        ),
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: Color(0xFFF37021),
                    size: 24,
                  ),
                ],
              ),
            ),
            if (fieldState.hasError)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    fieldState.errorText!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildAddressFields() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFEBEBEB)),
      ),
      child: Column(
        children: [
          _fieldRow(
            icon: Icons.grid_view_rounded,
            iconBg: const Color(0xFFFFF0E5),
            iconColor: const Color(0xFFF37021),
            label: 'المنطقة',
            child: _zoneTextFormField(),
          ),
          const Divider(
            height: 1,
            color: Color(0xFFF5F5F5),
            indent: 66,
            endIndent: 0,
          ),
          _fieldRow(
            icon: Icons.drag_handle_rounded,
            iconBg: const Color(0xFFEDFAF4),
            iconColor: const Color(0xFF22C55E),
            label: 'الشارع',
            child: _streetTextFormField(),
          ),
          const Divider(
            height: 1,
            color: Color(0xFFF5F5F5),
            indent: 66,
            endIndent: 0,
          ),
          _fieldRow(
            icon: Icons.home_rounded,
            iconBg: const Color(0xFFF3EEFF),
            iconColor: const Color(0xFF8B5CF6),
            label: 'المبنى',
            child: _buildingTextFormField(),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFEBEBEB)),
      ),
      child: _fieldRow(
        icon: Icons.near_me_rounded,
        iconBg: const Color(0xFFFFF8ED),
        iconColor: const Color(0xFFF59E0B),
        label: 'الموقع الجغرافي',
        child: _locationTextFormField(),
      ),
    );
  }

  InputDecoration _inlineFieldDecoration(String hint) {
    return InputDecoration(
      isDense: true,
      hintText: hint,
      hintStyle: TextStyle(
        color: Colors.grey[400],
        fontWeight: FontWeight.normal,
        fontSize: 15,
      ),
      filled: true,
      fillColor: Colors.transparent,
      border: InputBorder.none,
      enabledBorder: InputBorder.none,
      focusedBorder: InputBorder.none,
      errorBorder: InputBorder.none,
      focusedErrorBorder: InputBorder.none,
      contentPadding: EdgeInsets.zero,
    );
  }

  Widget _zoneTextFormField() {
    return TextFormField(
      keyboardType: TextInputType.number,
      controller: _zoneController,
      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
      decoration: _inlineFieldDecoration('أدخل رقم المنطقة'),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'هذا الحقل مطلوب';
        }
        return null;
      },
    );
  }

  Widget _streetTextFormField() {
    return TextFormField(
      keyboardType: TextInputType.number,
      controller: _streetController,
      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
      decoration: _inlineFieldDecoration('أدخل رقم الشارع'),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'هذا الحقل مطلوب';
        }
        return null;
      },
    );
  }

  Widget _buildingTextFormField() {
    return TextFormField(
      keyboardType: TextInputType.number,
      controller: _buildController,
      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
      decoration: _inlineFieldDecoration('أدخل رقم المبنى'),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'هذا الحقل مطلوب';
        }
        return null;
      },
    );
  }

  Widget _locationTextFormField() {
    return TextFormField(
      onTap: _updateLocationFromGps,
      readOnly: true,
      controller: _locationController,
      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
      decoration: _inlineFieldDecoration('إضغط لكي تضيف الموقع'),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'هذا الحقل مطلوب';
        }
        return null;
      },
    );
  }

  Widget _fieldRow({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String label,
    required Widget child,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 14,
            color: const Color(0xFFE0E0E0),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 4),
                Align(alignment: Alignment.centerRight, child: child),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return Container(
      width: double.infinity,
      height: 58,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.centerRight,
          end: Alignment.centerLeft,
          colors: [Color(0xFFF37021), Color(0xFFFF9A57)],
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFF37021).withOpacity(0.35),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: _onSubmitAddress,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.location_on_rounded,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                '${widget.id != null ? 'تعديل' : 'إضافة'} العنوان',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
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

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFF37021).withOpacity(0.12)
      ..strokeWidth = 0.5;
    const step = 20.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
