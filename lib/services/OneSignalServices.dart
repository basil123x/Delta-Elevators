import 'dart:convert';
import 'package:http/http.dart' as http;

/// OneSignal Notification Helper
/// ==============================
/// كل methods ارسال الاشعارات بفلاتر مختلفة

class OneSignalNotification {
  static const String androidDefaultChannelId = 'OneSignal_messages';
  static const String _appId = "aca3707d-a491-4e81-95eb-46ef15ea1ba4";
  static const String _apiKey =
      "Key os_v2_app_vsrxa7nesfhidfpli3xrl2q3uqpfybs3omouyufoxs7alm6ekpt2onv6q67w54eg3nftc2txuxhomriqfrqhzpe7fgasw2hebbpav7a";
  static const String _apiUrl = "https://api.onesignal.com/notifications";

  // =========================================================
  // METHOD المساعد - بيبعت الـ Request لـ OneSignal
  // =========================================================
  static Future<Map<String, dynamic>> _send(Map<String, dynamic> data) async {
    try {
      final payload = {
        ...data,
        if (!data.containsKey('existing_android_channel_id') &&
            !data.containsKey('android_channel_id'))
          'existing_android_channel_id': androidDefaultChannelId,
      };
      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {
          "Content-Type": "application/json; charset=utf-8",
          "Authorization": _apiKey,
        },
        body: jsonEncode(payload),
      );

      return {
        "status": response.statusCode,
        "response": jsonDecode(response.body),
      };
    } catch (e) {
      return {
        "status": 500,
        "response": {"error": e.toString()},
      };
    }
  }

  // =========================================================
  // 1. ارسال لمستخدم واحد عن طريق Subscription ID
  // =========================================================
  static Future<Map<String, dynamic>> sendToUser({
    required String subscriptionId,
    required String title,
    required String message,
    Map<String, dynamic> extra = const {},
  }) async {
    final data = {
      "app_id": _appId,
      "target_channel": "push",
      "headings": {"en": title},
      "contents": {"en": message},
      "include_subscription_ids": [subscriptionId],
      ...extra,
    };
    return _send(data);
  }

  // =========================================================
  // 2. ارسال لمجموعة مستخدمين عن طريق Subscription IDs
  // =========================================================
  static Future<Map<String, dynamic>> sendToMultipleUsers({
    required List<String> subscriptionIds,
    required String title,
    required String message,
    Map<String, dynamic> extra = const {},
  }) async {
    final data = {
      "app_id": _appId,
      "target_channel": "push",
      "headings": {"en": title},
      "contents": {"en": message},
      "include_subscription_ids": subscriptionIds,
      ...extra,
    };
    return _send(data);
  }

  // =========================================================
  // 3. ارسال لكل المستخدمين (All Users)
  // =========================================================
  static Future<Map<String, dynamic>> sendToAll({
    required String title,
    required String message,
    Map<String, dynamic> extra = const {},
  }) async {
    final data = {
      "app_id": _appId,
      "target_channel": "push",
      "headings": {"en": title},
      "contents": {"en": message},
      "included_segments": ["All"],
      ...extra,
    };
    return _send(data);
  }

  // =========================================================
  // 4. ارسال لـ Segment معين (مثلاً Active Users)
  // =========================================================
  static Future<Map<String, dynamic>> sendToSegment({
    required String segment,
    required String title,
    required String message,
    Map<String, dynamic> extra = const {},
  }) async {
    final data = {
      "app_id": _appId,
      "target_channel": "push",
      "headings": {"en": title},
      "contents": {"en": message},
      "included_segments": [segment],
      ...extra,
    };
    return _send(data);
  }

  // =========================================================
  // 5. ارسال بـ External User ID (ID المستخدم في DB بتاعك)
  // =========================================================
  static Future<Map<String, dynamic>> sendToExternalId({
    required String externalUserId,
    required String title,
    required String message,
    Map<String, dynamic> extra = const {},
  }) async {
    final data = {
      "app_id": _appId,
      "target_channel": "push",
      "headings": {"en": title},
      "contents": {"en": message},
      "include_aliases": {
        "external_id": [externalUserId],
      },
      ...extra,
    };
    return _send(data);
  }

  // =========================================================
  // 6. ارسال لمجموعة External User IDs
  // =========================================================
  static Future<Map<String, dynamic>> sendToExternalIds({
    required List<String> externalUserIds,
    required String title,
    required String message,
    Map<String, dynamic> extra = const {},
  }) async {
    final data = {
      "app_id": _appId,
      "target_channel": "push",
      "headings": {"en": title},
      "contents": {"en": message},
      "include_aliases": {"external_id": externalUserIds},
      ...extra,
    };
    return _send(data);
  }

  // =========================================================
  // 7. ارسال مجدول في وقت معين
  // =========================================================
  static Future<Map<String, dynamic>> sendScheduled({
    required List<String> subscriptionIds,
    required String title,
    required String message,
    required String sendAfter, // "2026-03-01 09:00:00 UTC"
    Map<String, dynamic> extra = const {},
  }) async {
    final data = {
      "app_id": _appId,
      "target_channel": "push",
      "headings": {"en": title},
      "contents": {"en": message},
      "include_subscription_ids": subscriptionIds,
      "send_after": sendAfter,
      ...extra,
    };
    return _send(data);
  }

  // =========================================================
  // 8. ارسال مع صورة (Big Picture)
  // =========================================================
  static Future<Map<String, dynamic>> sendWithImage({
    required List<String> subscriptionIds,
    required String title,
    required String message,
    required String imageUrl,
    Map<String, dynamic> extra = const {},
  }) async {
    final data = {
      "app_id": _appId,
      "target_channel": "push",
      "headings": {"en": title},
      "contents": {"en": message},
      "include_subscription_ids": subscriptionIds,
      "big_picture": imageUrl,
      "ios_attachments": {"image": imageUrl},
      ...extra,
    };
    return _send(data);
  }

  // =========================================================
  // 9. ارسال مع URL (لما المستخدم يضغط يروح صفحة معينة)
  // =========================================================
  static Future<Map<String, dynamic>> sendWithUrl({
    required List<String> subscriptionIds,
    required String title,
    required String message,
    required String url,
    Map<String, dynamic> extra = const {},
  }) async {
    final data = {
      "app_id": _appId,
      "target_channel": "push",
      "headings": {"en": title},
      "contents": {"en": message},
      "include_subscription_ids": subscriptionIds,
      "url": url,
      ...extra,
    };
    return _send(data);
  }

  // =========================================================
  // 10. ارسال مع Data إضافية للـ App
  // =========================================================
  static Future<Map<String, dynamic>> sendWithData({
    required List<String> subscriptionIds,
    required String title,
    required String message,
    required Map<String, dynamic> customData,
    Map<String, dynamic> extra = const {},
  }) async {
    final data = {
      "app_id": _appId,
      "target_channel": "push",
      "headings": {"en": title},
      "contents": {"en": message},
      "include_subscription_ids": subscriptionIds,
      "data": customData,
      ...extra,
    };
    return _send(data);
  }

  // =========================================================
  // 11. ارسال Silent Notification (من غير صوت)
  // =========================================================
  static Future<Map<String, dynamic>> sendSilent({
    required List<String> subscriptionIds,
    required String title,
    required String message,
    Map<String, dynamic> extra = const {},
  }) async {
    final data = {
      "app_id": _appId,
      "target_channel": "push",
      "headings": {"en": title},
      "contents": {"en": message},
      "include_subscription_ids": subscriptionIds,
      "android_sound": "nil",
      "ios_sound": "nil",
      ...extra,
    };
    return _send(data);
  }

  // =========================================================
  // 12. ارسال لـ Web فقط
  // =========================================================
  static Future<Map<String, dynamic>> sendToWebOnly({
    required List<String> subscriptionIds,
    required String title,
    required String message,
    Map<String, dynamic> extra = const {},
  }) async {
    return sendToMultipleUsers(
      subscriptionIds: subscriptionIds,
      title: title,
      message: message,
      extra: {"isAnyWeb": true, ...extra},
    );
  }

  // =========================================================
  // 13. ارسال لـ Mobile فقط
  // =========================================================
  static Future<Map<String, dynamic>> sendToMobileOnly({
    required List<String> subscriptionIds,
    required String title,
    required String message,
    Map<String, dynamic> extra = const {},
  }) async {
    return sendToMultipleUsers(
      subscriptionIds: subscriptionIds,
      title: title,
      message: message,
      extra: {"isAndroid": true, "isIos": true, ...extra},
    );
  }

  // =========================================================
  // 14. ارسال بـ Priority عالية (مهم جداً)
  // =========================================================
  static Future<Map<String, dynamic>> sendHighPriority({
    required List<String> subscriptionIds,
    required String title,
    required String message,
    Map<String, dynamic> extra = const {},
  }) async {
    final data = {
      "app_id": _appId,
      "target_channel": "push",
      "headings": {"en": title},
      "contents": {"en": message},
      "include_subscription_ids": subscriptionIds,
      "priority": 10,
      "android_channel_id": "high_priority",
      ...extra,
    };
    return _send(data);
  }

  // =========================================================
  // 15. ارسال مع Action Buttons
  // =========================================================
  static Future<Map<String, dynamic>> sendWithButtons({
    required List<String> subscriptionIds,
    required String title,
    required String message,
    required List<Map<String, String>> buttons,
    // مثال: [{"id": "btn1", "text": "قبول"}, {"id": "btn2", "text": "رفض"}]
    Map<String, dynamic> extra = const {},
  }) async {
    final data = {
      "app_id": _appId,
      "target_channel": "push",
      "headings": {"en": title},
      "contents": {"en": message},
      "include_subscription_ids": subscriptionIds,
      "buttons": buttons,
      "web_buttons": buttons,
      ...extra,
    };
    return _send(data);
  }
}


// =========================================================
// أمثلة الاستخدام
// =========================================================

// void main() async {
//   // 1. ابعت لمستخدم واحد
//   await OneSignalNotification.sendToUser(
//     subscriptionId: "SUBSCRIPTION_ID_هنا",
//     title: "مرحباً!",
//     message: "عندك إشعار جديد",
//   );

//   // 2. ابعت لكل المستخدمين
//   await OneSignalNotification.sendToAll(
//     title: "إشعار عام",
//     message: "رسالة لكل المستخدمين",
//   );

//   // 3. ابعت مع URL
//   await OneSignalNotification.sendWithUrl(
//     subscriptionIds: ["SUBSCRIPTION_ID_1", "SUBSCRIPTION_ID_2"],
//     title: "طلب جديد",
//     message: "تم استلام طلبك",
//     url: "https://www.daltalifts.com/orders/123",
//   );

//   // 4. ابعت مجدول
//   await OneSignalNotification.sendScheduled(
//     subscriptionIds: ["SUBSCRIPTION_ID_هنا"],
//     title: "تذكير",
//     message: "لا تنسى موعدك",
//     sendAfter: "2026-03-01 09:00:00 UTC",
//   );

//   // 5. ابعت مع بيانات إضافية
//   await OneSignalNotification.sendWithData(
//     subscriptionIds: ["SUBSCRIPTION_ID_هنا"],
//     title: "طلب جديد",
//     message: "تم تأكيد طلبك",
//     customData: {"order_id": 123, "status": "confirmed"},
//   );

//   // 6. ابعت مع أزرار
//   await OneSignalNotification.sendWithButtons(
//     subscriptionIds: ["SUBSCRIPTION_ID_هنا"],
//     title: "طلب جديد",
//     message: "هل تريد قبول الطلب؟",
//     buttons: [
//       {"id": "accept", "text": "قبول"},
//       {"id": "reject", "text": "رفض"},
//     ],
//   );

//   // 7. ابعت بأولوية عالية
//   await OneSignalNotification.sendHighPriority(
//     subscriptionIds: ["SUBSCRIPTION_ID_هنا"],
//     title: "تنبيه عاجل!",
//     message: "يوجد طلب طارئ",
//   );
// }