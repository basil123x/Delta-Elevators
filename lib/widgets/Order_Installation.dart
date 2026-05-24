import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

class OrderInstallation extends StatefulWidget {
  final String bookId;
  const OrderInstallation({super.key, required this.bookId});

  @override
  State<OrderInstallation> createState() => _OrderInstallationState();
}

class _OrderInstallationState extends State<OrderInstallation> {
  final int imageCount = 4;
  List images = [];

  Future getInstallationImages() async {
    var request = await Dio().post("https://daltalifts.com/app2026/sql.php?k=${DateTime.now().millisecondsSinceEpoch}", data: {
      "action": "getProcessingImages",
      "bookId": widget.bookId,
      "processType": "installation"
    });
    setState(() {
      images = request.data['images'];
    });
  }

  @override
  void initState() {
    getInstallationImages();
    super.initState();
  }
  @override
  Widget build(BuildContext context) {
    return Expanded(child: SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: images.length,
        itemBuilder: (context, i) {
        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ImagePreview(images: images, index: i),
              ),
            );
          },
          child: Container(
            width: 40,
            height: 30,
            margin: EdgeInsets.only(
              right: 10
            ),
            decoration: BoxDecoration(
              color: Colors.green,
              borderRadius: BorderRadius.circular(7),
              image: DecorationImage(image: NetworkImage(images[i]), fit: BoxFit.cover),
            ),
          ),
        );
      }),
    ));
  }
}


class ImagePreview extends StatefulWidget {
  final List images;
  final int index;
  const ImagePreview({super.key, required this.images, required this.index});

  @override
  State<ImagePreview> createState() => _ImagePreviewState();
}

class _ImagePreviewState extends State<ImagePreview> {
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: widget.index);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: PageView.builder(
        controller: _pageController,
        itemCount: widget.images.length,
        itemBuilder: (context, i) {
          return Image.network(widget.images[i]);
        },
      ),
    );
  }
}