import 'dart:async';

import 'package:Delta/screens/booking/contract/contract_theme.dart';
import 'package:Delta/widgets/Order_Timeline.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

class Processing extends StatefulWidget {
  final List bookDets;
  const Processing({super.key, required this.bookDets});

  @override
  State<Processing> createState() => _ProcessingState();
}

class _ProcessingState extends State<Processing> {
  Timer? _pollingTimer;
  String _currentStl = '';
  String caseTitle = "";

  @override
  void initState() {
    super.initState();
    if (widget.bookDets.isNotEmpty) {
      _currentStl = widget.bookDets[0]['stl']?.toString() ?? '0';
      _pollingTimer = Timer.periodic(
        const Duration(seconds: 10),
        (_) => _fetchLatestStl(),
      );
    }
  }

  Future<void> _fetchLatestStl() async {
    try {
      final result = await Dio().post(
        "https://daltalifts.com/app2026/sql.php",
        data: {
          "action": "getMyBookingOne",
          "bookid": widget.bookDets[0]['id'].toString(),
        },
      );
      if (result.data['success'] == true &&
          result.data['data'] != null &&
          result.data['data'].isNotEmpty) {
        final newStl = result.data['data'][0]['stl']?.toString() ?? '0';
        if (newStl != _currentStl && mounted) {
          setState(() => _currentStl = newStl);
        }
      }
    } catch (e) {
      print('Polling error: $e');
    }
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    switch (_currentStl) {
      case "1":
        caseTitle = "contracting";
        break;
      case "2":
        caseTitle = "ordering";
        break;
      case "3":
        caseTitle = "manufacturing";
        break;
      case "4":
        caseTitle = "readyForDelivery";
        break;
      case "5":
        caseTitle = "importing";
        break;
      case "6":
        caseTitle = "installation";
        break;
      case "7":
        caseTitle = "waiting";
        break;
      case "8":
        caseTitle = "playing";
        break;
      case "9":
        caseTitle = "completed";
        break;
      default:
        caseTitle = "";
    }
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
                key: ValueKey(caseTitle),
                currentStatus: caseTitle,
                bookId: widget.bookDets[0]['id'].toString(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
