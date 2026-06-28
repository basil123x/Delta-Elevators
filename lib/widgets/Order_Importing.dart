import 'package:flutter/material.dart';

class OrderImporting extends StatefulWidget {
  final String bookId;
  const OrderImporting({super.key, required this.bookId});

  @override
  State<OrderImporting> createState() => _OrderImportingState();
}

class _OrderImportingState extends State<OrderImporting> {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ImagePreview(bookId: widget.bookId),
              ),
            );
          },
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.green,
              borderRadius: BorderRadius.circular(7),
              image: DecorationImage(
                image: NetworkImage(
                  "https://daltaliftstech.s3.ap-south-1.amazonaws.com/Mobile_App/Processing/${widget.bookId}/importing/1.png",
                ),
                fit: BoxFit.cover,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class ImagePreview extends StatefulWidget {
  final String bookId;
  const ImagePreview({super.key, required this.bookId});

  @override
  State<ImagePreview> createState() => _ImagePreviewState();
}

class _ImagePreviewState extends State<ImagePreview> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: Image.network(
          "https://daltaliftstech.s3.ap-south-1.amazonaws.com/Mobile_App/Processing/${widget.bookId}/importing/1.png",
        ),
      ),
    );
  }
}
