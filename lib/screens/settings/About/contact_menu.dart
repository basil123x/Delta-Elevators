import 'package:url_launcher/url_launcher.dart';

class UrlHelper {
  // فتح موقع
  static Future<void> openWebsite(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  // فتح إيميل
  static Future<void> openEmail({
    required String email,
    String subject = '',
    String body = '',
  }) async {
    final uri = Uri(
      scheme: 'mailto',
      path: email,
      queryParameters: {'subject': subject, 'body': body},
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  // فتح رقم تليفون
  static Future<void> openPhone(String phone) async {
    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  // فتح واتساب
  static Future<void> openWhatsApp(String phone, String message) async {
    String cleanedPhone = phone.replaceAll(RegExp(r'[^0-9]'), '');

    // أضف كود قطر لو الرقم أقل من 11 رقم
    if (cleanedPhone.length <= 8) {
      cleanedPhone = '974$cleanedPhone';
    }

    final uri = Uri.parse(
      'https://wa.me/$cleanedPhone?text=${Uri.encodeComponent(message)}',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
