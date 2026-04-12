import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class OrderCompleted extends StatefulWidget {
  final String bookId;
  const OrderCompleted({super.key, required this.bookId});

  @override
  State<OrderCompleted> createState() => _OrderCompletedState();
}

class _OrderCompletedState extends State<OrderCompleted> {
  String get pdfUrl =>
      "https://daltalifts.com/app2026/PDF_Final/index.php?ktype=3&batchId=${widget.bookId}";

  void _openPdf() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PdfViewerScreen(pdfUrl: pdfUrl),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _openPdf,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.red.shade700,
          borderRadius: BorderRadius.circular(7),
        ),
        child: const Icon(Icons.picture_as_pdf, color: Colors.white, size: 24),
      ),
    );
  }
}

// ── شاشة الـ PDF Viewer ──────────────────────────────
class PdfViewerScreen extends StatefulWidget {
  final String pdfUrl;
  const PdfViewerScreen({super.key, required this.pdfUrl});

  @override
  State<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends State<PdfViewerScreen> {
  String? localPath;
  bool isLoading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _downloadPdf();
  }

  Future<void> _downloadPdf() async {
    try {
      final response = await http.get(Uri.parse(widget.pdfUrl));
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/temp.pdf');
      await file.writeAsBytes(response.bodyBytes);
      if (!mounted) return;
      setState(() {
        localPath = file.path;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        error = 'فشل تحميل الملف';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('عرض الملف'),
        backgroundColor: Colors.red.shade700,
        iconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: const TextStyle(color: Colors.white, fontSize: 18),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : error != null
              ? Center(child: Text(error!, style: const TextStyle(color: Colors.red)))
              : PDFView(
                  filePath: localPath!,
                  enableSwipe: true,
                  swipeHorizontal: false,
                  autoSpacing: true,
                  pageFling: true,
                ),
    );
  }
}