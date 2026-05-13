import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:Delta/provider/app_provider.dart';
import 'package:Delta/screens/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:provider/provider.dart';
import 'package:restart_app/restart_app.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shorebird_code_push/shorebird_code_push.dart';
import 'package:terminate_restart/terminate_restart.dart';

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
  }
}

void main() async {
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    debugPrint('🔴 FLUTTER ERROR: ${details.exception}');
    debugPrint('🔴 STACK: ${details.stack}');
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('🔴 PLATFORM ERROR: $error');
    debugPrint('🔴 STACK: $stack');
    return true; // true = اتعاملنا معاه، متوقفش
  };
  HttpOverrides.global = MyHttpOverrides();
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitDown,
    DeviceOrientation.portraitUp,
  ]);
  OneSignal.Debug.setLogLevel(OSLogLevel.verbose);
  OneSignal.initialize("aca3707d-a491-4e81-95eb-46ef15ea1ba4");
  OneSignal.Notifications.requestPermission(true);
  final prefs = await SharedPreferences.getInstance();
  final hasSeenOnboarding = prefs.getBool('seen_onboarding') ?? false;
  runApp(MyApp(hasSeenOnboarding: hasSeenOnboarding));
}

class MyApp extends StatefulWidget {
  const MyApp({super.key, this.hasSeenOnboarding = false});

  final bool hasSeenOnboarding;

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final updater = ShorebirdUpdater();
  Timer? _timer;
  static const _lastPatchKey = "last_applied_patch";

  Future<void> ensureDoubleRestart() async {
    if (!Platform.isAndroid) return;

    final prefs = await SharedPreferences.getInstance();
    final lastPatchNumber = prefs.getInt(_lastPatchKey) ?? 0;
    final currentPatch = await updater.readCurrentPatch();

    if (currentPatch != null && currentPatch.number != lastPatchNumber) {
      await prefs.setInt(_lastPatchKey, currentPatch.number);
      await Future.delayed(const Duration(seconds: 2));
      if (Platform.isIOS) {
        Restart.restartApp();
      } else {
        await TerminateRestart.instance.restartApp(
          options: const TerminateRestartOptions(terminate: true),
        );
      }
    }
  }

  Future<void> checkForUpdates() async {
    final status = await updater.checkForUpdate();

    if (status == UpdateStatus.outdated) {
      try {
        await updater.update();
        final prefs = await SharedPreferences.getInstance();
        final currentPatch = await updater.readCurrentPatch();
        if (currentPatch != null) {
          await prefs.setInt(_lastPatchKey, currentPatch.number - 1);
        }

        if (Platform.isIOS) {
          Restart.restartApp(
            notificationTitle: "إشعار هام",
            notificationBody: "قم بتحديث التطبيق الأن",
          );
        } else {
          await TerminateRestart.instance.restartApp(
            options: const TerminateRestartOptions(terminate: true),
          );
        }
      } on UpdateException catch (error) {
        print("Update failed: $error");
      }
    }
  }

  @override
  void initState() {
    ensureDoubleRestart();
    checkForUpdates();
    _timer = Timer.periodic(const Duration(minutes: 1), (timer) {
      checkForUpdates();
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => AppProvider(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(textTheme: GoogleFonts.cairoTextTheme()),
        home: SplashScreen(hasSeenOnboarding: widget.hasSeenOnboarding),
      ),
    );
  }
}

// os_v2_app_vsrxa7nesfhidfpli3xrl2q3uqpfybs3omouyufoxs7alm6ekptux4gof7wn5b4qezdrn2m6pkha46vw3hfrm74npa7pxc2kthgm4hq
// pfybs3omouyufoxs7alm6ekpt
