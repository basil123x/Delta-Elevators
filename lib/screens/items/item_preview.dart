import 'dart:ui';

import 'package:Delta/screens/items/items_details_screen.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

class ItemPreviewScreen extends StatefulWidget {
  final String id;
  const ItemPreviewScreen({super.key, required this.id});

  @override
  State<ItemPreviewScreen> createState() => _ItemPreviewScreenState();
}

class _ItemPreviewScreenState extends State<ItemPreviewScreen> {
  void _goBack() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => ItemsDetailsScreen(itmid: widget.id.toString()),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          fit: StackFit.expand,
          children: [
            InteractiveViewer(
              minScale: 1.0,
              maxScale: 4.0,
              child: Center(
                child: Image.network(
                  'https://daltaliftstech.s3.ap-south-1.amazonaws.com/Sys/items/${widget.id}/1.jpg',
                  fit: BoxFit.contain,
                  width: size.width,
                  height: size.height,
                ),
              ),
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: ClipRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                  child: Container(
                    height: 60 + MediaQuery.paddingOf(context).top,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0.7),
                          Colors.transparent,
                        ],
                      ),
                    ),
                    child: SafeArea(
                      bottom: false,
                      child: SizedBox(
                        height: 60,
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: GestureDetector(
                            onTap: _goBack,
                            behavior: HitTestBehavior.opaque,
                            child: const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 20),
                              child: Icon(
                                Iconsax.arrow_right_3,
                                color: Colors.white,
                                size: 22,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                height: 100,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.85),
                    ],
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  widget.id,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
