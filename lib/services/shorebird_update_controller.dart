import 'dart:async';
import 'dart:io';

import 'package:Delta/services/store_update_config.dart';
import 'package:flutter/foundation.dart';
import 'package:restart_app/restart_app.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shorebird_code_push/shorebird_code_push.dart';
import 'package:terminate_restart/terminate_restart.dart';

/// Downloads a Shorebird patch and restarts twice so the new patch is the one running.
class ShorebirdUpdateController {
  ShorebirdUpdateController._();

  static final ShorebirdUpdateController instance = ShorebirdUpdateController._();

  static const _patchKey = 'shorebird_last_patch';
  static const _secondRestartKey = 'shorebird_needs_second_restart';

  final ShorebirdUpdater _updater = ShorebirdUpdater();
  Timer? _timer;
  bool _busy = false;

  void startLiveChecks() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) {
      checkNow();
    });
  }

  void stopLiveChecks() {
    _timer?.cancel();
    _timer = null;
  }

  /// Cold start: second restart if a patch just landed, otherwise download one.
  Future<bool> prepareOnLaunch() async {
    if (!await _ready()) return false;
    if (_busy) return false;
    _busy = true;
    try {
      if (await _secondRestartIfNeeded()) return Platform.isAndroid;
      final restarting = await _downloadAndRestartIfNeeded();
      return restarting && Platform.isAndroid;
    } finally {
      _busy = false;
    }
  }

  /// While the app is open, or when it returns to the foreground.
  Future<void> checkNow() async {
    if (StoreUpdateWatcher.instance.blocking) return;
    if (!await _ready()) return;
    if (_busy) return;
    _busy = true;
    try {
      await _downloadAndRestartIfNeeded();
    } finally {
      _busy = false;
    }
  }

  Future<bool> _ready() async {
    try {
      return _updater.isAvailable;
    } catch (e) {
      debugPrint('Shorebird unavailable: $e');
      return false;
    }
  }

  Future<bool> _secondRestartIfNeeded() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_secondRestartKey) != true) return false;

    final current = await _updater.readCurrentPatch();
    final last = prefs.getInt(_patchKey);
    if (current != null && current.number != last) {
      await prefs.setInt(_patchKey, current.number);
      await prefs.setBool(_secondRestartKey, false);
      await _restart();
      return true;
    }

    await prefs.setBool(_secondRestartKey, false);
    return false;
  }

  Future<bool> _downloadAndRestartIfNeeded() async {
    try {
      final status = await _updater.checkForUpdate().timeout(
        const Duration(seconds: 12),
      );
      if (status == UpdateStatus.outdated) {
        await _updater.update().timeout(const Duration(seconds: 30));
      } else if (status != UpdateStatus.restartRequired) {
        return false;
      }

      final prefs = await SharedPreferences.getInstance();
      final current = await _updater.readCurrentPatch();
      if (current != null) {
        await prefs.setInt(_patchKey, current.number);
      }
      await prefs.setBool(_secondRestartKey, true);
      await _restart();
      return true;
    } on UpdateException catch (error) {
      debugPrint('Shorebird update failed: $error');
    } catch (e) {
      debugPrint('Shorebird update check skipped: $e');
    }
    return false;
  }

  Future<void> _restart() async {
    if (Platform.isIOS) {
      Restart.restartApp(
        notificationTitle: 'إشعار هام',
        notificationBody: 'تم تنزيل تحديث. افتح التطبيق عشان يكتمل.',
      );
      return;
    }
    await TerminateRestart.instance.restartApp(
      options: const TerminateRestartOptions(terminate: true),
    );
  }
}
