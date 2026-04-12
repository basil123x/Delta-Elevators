import 'package:Delta/screens/booking/contract/ContractWait.dart';
import 'package:Delta/widgets/Order_Timeline.dart';
import 'package:flutter/material.dart';

class Processing extends StatefulWidget {
  final List bookDets;
  const Processing({super.key, required this.bookDets});

  @override
  State<Processing> createState() => _ProcessingState();
}

class _ProcessingState extends State<Processing> {
  String caseTitle = "";
  

  @override
  Widget build(BuildContext context) {
    switch (widget.bookDets[0]['stl']) {
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
    }
    return Scaffold(
      backgroundColor: Colors.white,
      body:SingleChildScrollView(
              child: Column(
                children: [OrderTimelineWidget(currentStatus: caseTitle, bookId: widget.bookDets[0]['id'])],
              ),
            ),
    );
  }
}
