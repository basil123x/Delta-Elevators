import 'dart:async';
import 'dart:io';

import 'package:Delta/screens/Update/update_screen.dart';
import 'package:Delta/screens/auth/login/login_screen.dart';
import 'package:Delta/screens/boarding/boarding_screen.dart';
import 'package:Delta/screens/main/main_screen.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key, this.hasSeenOnboarding = false});

  /// When true, unauthenticated users skip [BoardingScreen] and go to login.
  final bool hasSeenOnboarding;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  String? userId;

  Future getLogin() async {
    SharedPreferences _prefx = await SharedPreferences.getInstance();
    setState(() {
      userId = _prefx.getString('userId');
    });
  }

  _timer() async {
    Timer.periodic(Duration(seconds: 5), (timer) {
      final Widget next = userId != null
          ? MainScreen()
          : (widget.hasSeenOnboarding
              ? LoginScreen()
              : BoardingScreen());
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => next),
      );
    });
  }

  Future<void> checkForForceUpdate() async {
    try {
      final dio = Dio();
      String platform = "";
      final plugin = DeviceInfoPlugin();
      final android = await plugin.androidInfo;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Manufacturer Is: ${android.manufacturer}")));
      if (Platform.isIOS) {
        setState(() {
          platform = "IOS";
        });
      } else if (android.manufacturer == 'HUAWEI') {
        setState(() {
          platform = "HUAWEI";
        });
      } else {
        setState(() {
          platform = "Android";
        });
      }

      final response = await dio.post(
        'https://daltalifts.com/app2026/sql.php?k=${DateTime.now().millisecondsSinceEpoch}',
        data: {"action": "getUpdates", "platform": platform},
      );

      if (response.statusCode == 200) {
        final data = response.data;
        final latestVersion = data['latest_version'];
        final forceUpdate = data['force_update'].toString() == "1";
        final message = data['message'];
        final storeUrl = data['store_link'];

        final packageInfo = await PackageInfo.fromPlatform();
        final currentVersion = packageInfo.version;

        if (forceUpdate && currentVersion != latestVersion) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) {
                return ForceUpdateScreen(message: message, storeUrl: storeUrl);
              },
            ),
          );
        }
      }
    } catch (e) {
      print("Error while checking for update: $e");
    }
  }

  @override
  void initState() {
    checkForForceUpdate();
    getLogin();
    _timer();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: Center(child: Image.asset('assets/img/Logo.gif')));
  }
}
