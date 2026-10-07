import 'package:shared_preferences/shared_preferences.dart';

/// Engineer assignment scope for «مهامي» only.
class EngineerTaskScope {
  static const isEngineerKey = 'is_engineer';
  static const engineerUserIdKey = 'engineer_user_id';
  static const tasksCacheKey = 'cached_admin_tasks';
  static const tasksReloadKey = 'tasks_reload_token';

  static bool parseFlag(dynamic value) =>
      value?.toString() == '1' || value == 1 || value == true;

  static Future<void> persistFromPayload(
    Map payload,
    SharedPreferences prefs,
  ) async {
    final isEngineer = parseFlag(payload['is_engineer']);
    final engineerUserId = payload['engineer_user_id']?.toString() ?? '';
    await prefs.setBool(isEngineerKey, isEngineer);
    if (engineerUserId.isNotEmpty) {
      await prefs.setString(engineerUserIdKey, engineerUserId);
    } else if (!isEngineer) {
      await prefs.remove(engineerUserIdKey);
    }
  }

  static Future<void> clearTasksCache([SharedPreferences? prefs]) async {
    final store = prefs ?? await SharedPreferences.getInstance();
    await store.remove(tasksCacheKey);
    await store.setInt(
      tasksReloadKey,
      DateTime.now().millisecondsSinceEpoch,
    );
  }

  static Future<void> clearSession(SharedPreferences prefs) async {
    await prefs.remove(isEngineerKey);
    await prefs.remove(engineerUserIdKey);
    await clearTasksCache(prefs);
  }

  static bool isAssignedToCurrentEngineer(
    dynamic row, {
    required String uid,
    required String engineerUserId,
  }) {
    final appUid = row['assigned_app_uid']?.toString() ?? '';
    final assignedTo = row['assigned_to']?.toString() ?? '';
    if (uid.isNotEmpty && appUid.isNotEmpty && appUid == uid) return true;
    if (engineerUserId.isNotEmpty &&
        assignedTo.isNotEmpty &&
        assignedTo == engineerUserId) {
      return true;
    }
    return false;
  }
}
