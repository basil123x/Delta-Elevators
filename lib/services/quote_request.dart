import 'package:Delta/provider/app_provider.dart';
import 'package:Delta/services/DioServiceCert.dart';
import 'package:shared_preferences/shared_preferences.dart';

bool _isOk(dynamic data) {
  if (data is! Map) return false;
  return data['success'] == true ||
      data['success'] == 1 ||
      data['success'] == 'true';
}

Future<bool> addItemToQuoteRequest(String itemId, {AppProvider? app}) async {
  if (itemId.isEmpty) return false;
  final prefs = await SharedPreferences.getInstance();
  final result = await getDio().post(
    'https://daltalifts.com/app2026/sql.php?k=${DateTime.now().millisecondsSinceEpoch}',
    data: {
      'action': 'addOneItem',
      'itmid': itemId,
      'uid': prefs.getString('userId'),
      'oid': prefs.getString('orderId'),
    },
  );
  final data = result.data;
  final already = data is Map &&
      (data['message']?.toString() ?? '').contains('موجود');
  final ok = _isOk(data) || already;
  if (ok) app?.bumpQuoteCart();
  return ok;
}

Future<Set<String>> fetchQuoteItemIds() async {
  final prefs = await SharedPreferences.getInstance();
  final uid = prefs.getString('userId') ?? '';
  if (uid.isEmpty) return {};
  final result = await getDio().post(
    'https://daltalifts.com/app2026/sql.php?k=${DateTime.now().millisecondsSinceEpoch}',
    data: {'action': 'getOrders', 'uid': uid},
  );
  final raw = result.data is Map ? result.data['data'] : null;
  if (raw is! List) return {};
  return raw
      .whereType<Map>()
      .map((e) => e['id']?.toString() ?? '')
      .where((id) => id.isNotEmpty)
      .toSet();
}
