import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class LocationService {
  /// التحقق من الصلاحيات
  Future<bool> checkPermissions() async {
    bool serviceEnabled;
    LocationPermission permission;

    // تحقق من تفعيل خدمات الموقع
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return false;
    }

    // تحقق من الصلاحية
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // المستخدم رفض نهائياً - وجهه للإعدادات
      return false;
    }

    return true;
  }

  /// الحصول على الموقع الحالي
  Future<Position?> getCurrentLocation() async {
    try {
      bool hasPermission = await checkPermissions();
      if (!hasPermission) return null;

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      return position;
    } catch (e) {
      print('خطأ في الحصول على الموقع: $e');
      return null;
    }
  }

  /// تحويل الموقع لعنوان (Reverse Geocoding)
  Future<String> getAddressFromCoordinates(
    double latitude,
    double longitude,
  ) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        latitude,
        longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];

        String address = '';
        if (place.street != null) address += '${place.street!}, ';
        if (place.subLocality != null) address += '${place.subLocality!}, ';
        if (place.locality != null) address += '${place.locality!}, ';
        if (place.country != null) address += place.country!;

        return address;
      }
      return 'لم يتم العثور على العنوان';
    } catch (e) {
      print('خطأ في تحويل الموقع: $e');
      return 'خطأ في الحصول على العنوان';
    }
  }

  /// تحويل العنوان لإحداثيات (Geocoding)
  Future<Position?> getCoordinatesFromAddress(String address) async {
    try {
      List<Location> locations = await locationFromAddress(address);

      if (locations.isNotEmpty) {
        return Position(
          latitude: locations[0].latitude,
          longitude: locations[0].longitude,
          timestamp: DateTime.now(),
          accuracy: 0,
          altitude: 0,
          heading: 0,
          speed: 0,
          speedAccuracy: 0,
          altitudeAccuracy: 0,
          headingAccuracy: 0,
        );
      }
      return null;
    } catch (e) {
      print('خطأ في تحويل العنوان: $e');
      return null;
    }
  }

  /// فتح إعدادات الموقع
  Future<void> openLocationSettings() async {
    await Geolocator.openLocationSettings();
  }

  /// فتح إعدادات التطبيق
  Future<void> openAppSettings() async {
    await Geolocator.openAppSettings();
  }
}

// مثال للاستخدام في Widget
class LocationExample extends StatefulWidget {
  const LocationExample({super.key});

  @override
  _LocationExampleState createState() => _LocationExampleState();
}

class _LocationExampleState extends State<LocationExample> {
  final LocationService _locationService = LocationService();
  String _currentAddress = 'اضغط للحصول على موقعك';
  bool _loading = false;

  Future<void> _getCurrentLocation() async {
    setState(() => _loading = true);

    Position? position = await _locationService.getCurrentLocation();

    if (position != null) {
      String address = await _locationService.getAddressFromCoordinates(
        position.latitude,
        position.longitude,
      );

      setState(() {
        _currentAddress = address;
        _loading = false;
      });
    } else {
      setState(() {
        _currentAddress = 'فشل الحصول على الموقع';
        _loading = false;
      });

      // اعرض رسالة للمستخدم
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('صلاحية الموقع مطلوبة'),
          content: Text('يرجى تفعيل صلاحية الموقع للتطبيق'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('إلغاء'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _locationService.openAppSettings();
              },
              child: Text('الإعدادات'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('مثال الموقع')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_loading)
              CircularProgressIndicator()
            else
              Text(
                _currentAddress,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18),
              ),
            SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _getCurrentLocation,
              icon: Icon(Icons.location_on),
              label: Text('احصل على موقعي'),
            ),
          ],
        ),
      ),
    );
  }
}
