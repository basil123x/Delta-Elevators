import 'package:Delta/services/DioServiceCert.dart';

/// Shared catalog elevator fetch helpers used by customer ItemsScreen
/// and admin inventory (interim). Keep API calls here so screens stay thin.
class CatalogItemsApi {
  CatalogItemsApi._();

  static const _base =
      'https://daltalifts.com/app2026/sql.php';

  static String _url() =>
      '$_base?k=${DateTime.now().millisecondsSinceEpoch}';

  static String itemImageUrl(dynamic itemId) =>
      'https://daltaliftstech.s3.ap-south-1.amazonaws.com/Sys/items/$itemId/1.jpg';

  static Future<List<dynamic>> fetchGroups() async {
    final request = await getDio().post(_url(), data: {'action': 'groups'});
    final data = request.data['data'];
    return data is List ? data : <dynamic>[];
  }

  static Future<List<dynamic>> fetchItems({String? groupName}) async {
    final request = await getDio().post(
      _url(),
      data: {'action': 'items', 'grp': groupName},
    );
    final data = request.data['data'];
    return data is List ? data : <dynamic>[];
  }

  static Future<List<dynamic>> fetchOneItemDetails(String itemId) async {
    final request = await getDio().post(
      _url(),
      data: {'action': 'oneItemDetails', 'itmid': itemId},
    );
    final data = request.data['data'];
    return data is List ? data : <dynamic>[];
  }

  static Future<List<dynamic>> fetchLabelsLifts() async {
    final request =
        await getDio().post(_url(), data: {'action': 'getLabelsLifts'});
    final data = request.data['data'];
    return data is List ? data : <dynamic>[];
  }

  static Future<List<dynamic>> fetchLiftsDet(dynamic liftId) async {
    final request = await getDio().post(
      _url(),
      data: {'action': 'getLiftsDet', 'idlift': liftId},
    );
    final data = request.data['data'];
    return data is List ? data : <dynamic>[];
  }
}
