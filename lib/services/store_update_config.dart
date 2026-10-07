import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:Delta/app_navigator.dart';
import 'package:Delta/screens/Update/update_screen.dart';
import 'package:Delta/services/DioServiceCert.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Remote store gate. Edit `server_files/app_config.json` on the server.
const storeConfigUrl = 'https://daltalifts.com/app2026/app_config.php';

class StoreUpdateRequirement {
  const StoreUpdateRequirement({
    required this.message,
    required this.storeUrl,
  });

  final String message;
  final String storeUrl;
}

class StoreUpdateWatcher {
  StoreUpdateWatcher._();

  static final StoreUpdateWatcher instance = StoreUpdateWatcher._();

  bool blocking = false;
  bool _checking = false;
  Timer? _timer;

  void start() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(minutes: 3), (_) {
      checkAndBlock();
    });
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  Future<StoreUpdateRequirement?> loadRequirement() async {
    final json = await _fetchConfig();
    if (json != null) return _fromConfig(json);
    return _legacyRequirement();
  }

  Future<Map<String, dynamic>?> _fetchConfig() async {
    try {
      final response = await getDio().get<dynamic>(
        storeConfigUrl,
        queryParameters: {
          'k': DateTime.now().millisecondsSinceEpoch.toString(),
        },
        options: Options(
          responseType: ResponseType.json,
          headers: {
            'Cache-Control': 'no-cache',
            'Pragma': 'no-cache',
          },
        ),
      );
      if (response.statusCode != 200) return null;
      return _asMap(response.data);
    } catch (e) {
      debugPrint('Store config check skipped: $e');
      return null;
    }
  }

  Future<StoreUpdateRequirement?> _fromConfig(Map<String, dynamic> json) async {
    final force = json['force']?.toString().toLowerCase();
    if (json['force'] == false || force == '0' || force == 'false') {
      return null;
    }

    final requiredVersion = (json['version'] ?? json['latest_version'] ?? '')
        .toString()
        .trim();
    final requiredBuild =
        (json['build'] ?? json['build_number'] ?? '').toString().trim();
    if (requiredVersion.isEmpty) return null;

    final info = await PackageInfo.fromPlatform();
    final versionDiffers = info.version.trim() != requiredVersion;
    final buildDiffers =
        requiredBuild.isNotEmpty && info.buildNumber.trim() != requiredBuild;
    if (!versionDiffers && !buildDiffers) return null;

    final stores = _asMap(json['stores']) ?? json;
    final platform = await _storePlatform();
    final storeUrl = (stores[platform] ?? '').toString().trim();
    final message = (json['message'] ?? '').toString().trim();
    return StoreUpdateRequirement(
      message: message.isEmpty
          ? 'يوجد إصدار جديد من التطبيق. حدّث الآن من المتجر عشان تكمل الاستخدام.'
          : message,
      storeUrl: storeUrl,
    );
  }

  /// Previous database gate, used only when the JSON file is not on the server yet.
  Future<StoreUpdateRequirement?> _legacyRequirement() async {
    try {
      final platform = await _storePlatform();
      final response = await getDio().post<dynamic>(
        'https://daltalifts.com/app2026/sql.php',
        queryParameters: {
          'k': DateTime.now().millisecondsSinceEpoch.toString(),
        },
        data: {'action': 'getUpdates', 'platform': platform},
      );
      final data = _asMap(response.data);
      if (data == null) return null;
      if (data['force_update']?.toString() != '1') return null;
      final latestVersion = data['latest_version']?.toString().trim() ?? '';
      if (latestVersion.isEmpty) return null;
      final info = await PackageInfo.fromPlatform();
      if (info.version.trim() == latestVersion) return null;
      return StoreUpdateRequirement(
        message: (data['message'] ?? '').toString(),
        storeUrl: (data['store_link'] ?? '').toString(),
      );
    } catch (e) {
      debugPrint('Legacy store update check skipped: $e');
      return null;
    }
  }

  Future<void> checkAndBlock() async {
    if (blocking || _checking) return;
    _checking = true;
    try {
      final requirement = await loadRequirement();
      if (requirement == null) return;
      final nav = appNavigatorKey.currentState;
      if (nav == null) return;
      blocking = true;
      nav.pushAndRemoveUntil(
        MaterialPageRoute<void>(
          builder: (_) => ForceUpdateScreen(
            message: requirement.message,
            storeUrl: requirement.storeUrl,
          ),
        ),
        (_) => false,
      );
    } finally {
      _checking = false;
    }
  }

  Future<String> _storePlatform() async {
    if (Platform.isIOS) return 'ios';
    if (Platform.isAndroid) {
      final android = await DeviceInfoPlugin().androidInfo;
      final brand = '${android.manufacturer} ${android.brand}'.toUpperCase();
      if (brand.contains('HUAWEI') || brand.contains('HONOR')) return 'huawei';
    }
    return 'android';
  }

  Map<String, dynamic>? _asMap(dynamic data) {
    if (data is Map) return Map<String, dynamic>.from(data);
    if (data is String && data.trim().isNotEmpty) {
      final decoded = jsonDecode(data);
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
    }
    return null;
  }
}
