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
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.black45,
              image: DecorationImage(
                image: NetworkImage(
                  "https://daltalifts.com/erp2026/assets/items/${widget.id}/images/1.jpg",
                ),
                fit: BoxFit.contain,
              ),
            ),
          ),
          Positioned(
            top: 40,
            right: 10,
            child: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
              child: IconButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          ItemsDetailsScreen(itmid: widget.id.toString()),
                    ),
                  );
                },
                icon: Icon(Iconsax.arrow_circle_right, size: 30),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
