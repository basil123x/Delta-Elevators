import 'dart:io';
import 'dart:ui';

import 'package:Delta/app_navigator.dart';
import 'package:Delta/provider/app_provider.dart';
import 'package:Delta/screens/admin/engineer_task_scope.dart';
import 'package:Delta/screens/booking/contract/ContractScreen.dart';
import 'package:Delta/screens/settings/Maintenance/MaintenanceDetails.dart';
import 'package:Delta/screens/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:provider/provider.dart';
import 'package:Delta/services/shorebird_update_controller.dart';
import 'package:Delta/services/store_update_config.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sms_autofill/sms_autofill.dart';

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
    return true;
  };
  HttpOverrides.global = MyHttpOverrides();
  WidgetsFlutterBinding.ensureInitialized();

  if (Platform.isAndroid) {
    await const MethodChannel(
      'com.delta_elevator/notifications',
    ).invokeMethod<String>('ensureDefaultChannel');
  }

  // TEMPORARY - get app signature hash for WhatsApp (use real Android device; see debug console)
  try {
    if (Platform.isAndroid) {
      final signature = await SmsAutoFill().getAppSignature;
      debugPrint('=============================');
      debugPrint('APP SIGNATURE HASH: $signature');
      debugPrint('=============================');
    }
  } catch (e, st) {
    debugPrint('sms_autofill getAppSignature: $e\n$st');
  }

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitDown,
    DeviceOrientation.portraitUp,
  ]);
  OneSignal.Debug.setLogLevel(OSLogLevel.verbose);
  OneSignal.initialize("aca3707d-a491-4e81-95eb-46ef15ea1ba4");
  OneSignal.Notifications.requestPermission(true);
  final prefs = await SharedPreferences.getInstance();
  final savedUid = prefs.getString('userId') ?? '';
  if (savedUid.isNotEmpty) {
    try {
      await OneSignal.login(savedUid);
    } catch (_) {}
  }
  OneSignal.Notifications.addClickListener((event) {
    final data = event.notification.additionalData;
    if (data == null) return;
    final type = data['type']?.toString() ?? '';
    if (type == 'task_assigned') {
      final bookingId = data['booking_id']?.toString() ?? '';
      EngineerTaskScope.clearTasksCache();
      if (bookingId.isEmpty) return;
      appNavigatorKey.currentState?.push(
        MaterialPageRoute<void>(
          builder: (_) => ContractScreen(orderId: bookingId),
        ),
      );
      return;
    }
    final id = data['maintenanceId']?.toString() ?? '';
    if (id.isEmpty) return;
    if (type != 'maintenance_tech' && type != 'maintenance') return;
    appNavigatorKey.currentState?.push(
      MaterialPageRoute<void>(
        builder: (_) => MaintenanceDetailScreen(maintenanceId: id),
      ),
    );
  });
  final hasSeenOnboarding = prefs.getBool('seen_onboarding') ?? false;
  runApp(MyApp(hasSeenOnboarding: hasSeenOnboarding));
}

class MyApp extends StatefulWidget {
  const MyApp({super.key, this.hasSeenOnboarding = false});

  final bool hasSeenOnboarding;

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    ShorebirdUpdateController.instance.startLiveChecks();
    StoreUpdateWatcher.instance.start();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    ShorebirdUpdateController.instance.stopLiveChecks();
    StoreUpdateWatcher.instance.stop();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ShorebirdUpdateController.instance.checkNow();
      StoreUpdateWatcher.instance.checkAndBlock();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => AppProvider(),
      child: MaterialApp(
        navigatorKey: appNavigatorKey,
        debugShowCheckedModeBanner: false,
        theme: ThemeData(textTheme: GoogleFonts.cairoTextTheme()),
        home: SplashScreen(hasSeenOnboarding: widget.hasSeenOnboarding),
      ),
    );
  }
}

// os_v2_app_vsrxa7nesfhidfpli3xrl2q3uqpfybs3omouyufoxs7alm6ekptux4gof7wn5b4qezdrn2m6pkha46vw3hfrm74npa7pxc2kthgm4hq
// pfybs3omouyufoxs7alm6ekpt
