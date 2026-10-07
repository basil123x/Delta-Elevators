import 'package:Delta/screens/Update/update_screen.dart';
import 'package:Delta/screens/auth/login/login_screen.dart';
import 'package:Delta/screens/boarding/boarding_screen.dart';
import 'package:Delta/screens/main/main_screen.dart';
import 'package:Delta/services/shorebird_update_controller.dart';
import 'package:Delta/services/store_update_config.dart';
import 'package:flutter/material.dart';
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

  Future<void> getLogin() async {
    final prefs = await SharedPreferences.getInstance();
    userId = prefs.getString('userId');
  }

  Future<void> _boot() async {
    final minSplash = Future<void>.delayed(const Duration(milliseconds: 1200));
    await getLogin();
    if (!mounted) return;

    final requirement = await StoreUpdateWatcher.instance.loadRequirement();
    if (!mounted) return;
    if (requirement != null) {
      StoreUpdateWatcher.instance.blocking = true;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute<void>(
          builder: (_) => ForceUpdateScreen(
            message: requirement.message,
            storeUrl: requirement.storeUrl,
          ),
        ),
      );
      return;
    }

    final restarting =
        await ShorebirdUpdateController.instance.prepareOnLaunch();
    if (restarting || !mounted) return;

    await minSplash;
    if (!mounted) return;
    final Widget next = userId != null
        ? MainScreen()
        : (widget.hasSeenOnboarding ? LoginScreen() : BoardingScreen());
    Navigator.pushReplacement(
      context,
      MaterialPageRoute<void>(builder: (context) => next),
    );
  }

  @override
  void initState() {
    super.initState();
    _boot();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: Center(child: Image.asset('assets/img/Logo.gif')));
  }
}
