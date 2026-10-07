import 'package:Delta/services/DioServiceCert.dart';
import 'package:flutter/material.dart';

class OrderImporting extends StatefulWidget {
  final String bookId;
  const OrderImporting({super.key, required this.bookId});

  @override
  State<OrderImporting> createState() => _OrderImportingState();
}

class _OrderImportingState extends State<OrderImporting> {
  List<String> _images = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadImages();
  }

  Future<void> _loadImages() async {
    try {
      final request = await getDio().post(
        'https://daltalifts.com/app2026/sql.php?k=${DateTime.now().millisecondsSinceEpoch}',
        data: {
          'action': 'getProcessingImages',
          'bookId': widget.bookId,
          'processType': 'importing',
        },
      );
      final raw = request.data['images'];
      final list = <String>[];
      if (raw is List) {
        for (final item in raw) {
          final url = item?.toString() ?? '';
          if (url.isNotEmpty) list.add(url);
        }
      }
      if (!mounted) return;
      setState(() {
        _images = list;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _images = [];
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading || _images.isEmpty) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _images.length,
        itemBuilder: (context, i) {
          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ImportingImagePreview(
                    images: _images,
                    index: i,
                  ),
                ),
              );
            },
            child: Container(
              width: 40,
              height: 40,
              margin: const EdgeInsets.only(left: 8),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(7),
                image: DecorationImage(
                  image: NetworkImage(_images[i]),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class ImportingImagePreview extends StatefulWidget {
  final List<String> images;
  final int index;
  const ImportingImagePreview({
    super.key,
    required this.images,
    required this.index,
  });

  @override
  State<ImportingImagePreview> createState() => _ImportingImagePreviewState();
}

class _ImportingImagePreviewState extends State<ImportingImagePreview> {
  late final PageController _pageController;
  late int _current;

  @override
  void initState() {
    super.initState();
    _current = widget.index;
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
        title: Text(
          '${_current + 1} / ${widget.images.length}',
          style: const TextStyle(color: Colors.white, fontSize: 16),
        ),
        centerTitle: true,
      ),
      body: PageView.builder(
        controller: _pageController,
        itemCount: widget.images.length,
        onPageChanged: (i) => setState(() => _current = i),
        itemBuilder: (context, i) {
          return InteractiveViewer(
            child: Center(
              child: Image.network(
                widget.images[i],
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.broken_image_outlined,
                  color: Colors.white54,
                  size: 48,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
