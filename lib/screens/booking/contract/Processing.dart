import 'dart:async';

import 'package:Delta/screens/booking/contract/contract_theme.dart';
import 'package:Delta/services/DioServiceCert.dart';
import 'package:Delta/widgets/Order_Timeline.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Processing extends StatefulWidget {
  final List bookDets;
  const Processing({super.key, required this.bookDets});

  @override
  State<Processing> createState() => _ProcessingState();
}

class _ProcessingState extends State<Processing> {
  Timer? _pollingTimer;
  String _currentStl = '';
  String caseTitle = '';
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    if (widget.bookDets.isNotEmpty) {
      _currentStl = widget.bookDets[0]['stl']?.toString() ?? '0';
      _applyCaseTitle(_currentStl);
      _detectAdmin();
      _pollingTimer = Timer.periodic(
        const Duration(seconds: 2),
        (_) => _fetchLatestStl(),
      );
    }
  }

  Future<void> _detectAdmin() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // Fast path: cached from HomeScreen dashboard.
      final cached = prefs.getBool('is_app_manager') ?? false;
      if (cached && mounted) {
        setState(() => _isAdmin = true);
      }

      final uid = prefs.getString('userId') ?? '';
      if (uid.isEmpty) return;

      final result = await getDio().post(
        'https://daltalifts.com/app2026/sql.php?k=${DateTime.now().millisecondsSinceEpoch}',
        data: {'action': 'getDashboard', 'uid': uid},
      );
      final data = result.data['data'];
      if (data is! Map) return;
      final flag = data['is_app_manager'];
      final isAdmin =
          flag?.toString() == '1' || flag == 1 || flag == true;
      await prefs.setBool('is_app_manager', isAdmin);
      if (mounted) setState(() => _isAdmin = isAdmin);
    } catch (e) {
      debugPrint('Admin detect error: $e');
    }
  }

  void _applyCaseTitle(String stl) {
    switch (stl) {
      case '1':
        caseTitle = 'contracting';
        break;
      case '2':
        caseTitle = 'ordering';
        break;
      case '3':
        caseTitle = 'manufacturing';
        break;
      case '4':
        caseTitle = 'readyForDelivery';
        break;
      case '5':
        caseTitle = 'importing';
        break;
      case '6':
        caseTitle = 'installation';
        break;
      case '7':
        caseTitle = 'waiting';
        break;
      case '8':
        caseTitle = 'playing';
        break;
      case '9':
        caseTitle = 'completed';
        break;
      default:
        caseTitle = '';
    }
  }

  Future<void> _fetchLatestStl() async {
    try {
      final result = await Dio().post(
        'https://daltalifts.com/app2026/sql.php',
        data: {
          'action': 'getMyBookingOne',
          'bookid': widget.bookDets[0]['id'].toString(),
        },
      );
      if (result.data['success'] == true &&
          result.data['data'] != null &&
          result.data['data'].isNotEmpty) {
        final newStl = result.data['data'][0]['stl']?.toString() ?? '0';
        if (newStl != _currentStl && mounted) {
          setState(() {
            _currentStl = newStl;
            _applyCaseTitle(newStl);
          });
        }
      }
    } catch (e) {
      debugPrint('Polling error: $e');
    }
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ContractTheme.bg,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 600),
              transitionBuilder: (child, animation) => FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.1),
                    end: Offset.zero,
                  ).animate(animation),
                  child: child,
                ),
              ),
              child: OrderTimelineWidget(
                key: ValueKey('$caseTitle-$_isAdmin'),
                currentStatus: caseTitle,
                bookId: widget.bookDets[0]['id'].toString(),
                isAdmin: _isAdmin,
                onStageUpdated: (statusName) {
                  setState(() {
                    caseTitle = statusName;
                    final idx = OrderStatus.values.indexWhere(
                      (e) => e.name == statusName,
                    );
                    if (idx >= 0) {
                      _currentStl = (idx + 1).toString();
                    }
                  });
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
