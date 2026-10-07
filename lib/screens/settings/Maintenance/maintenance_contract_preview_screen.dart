import 'dart:io';

import 'package:Delta/screens/repair/repair_theme.dart';
import 'package:Delta/services/DioServiceCert.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:iconsax/iconsax.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Full-screen preview of a signed maintenance contract PDF.
class MaintenanceContractPreviewScreen extends StatefulWidget {
  const MaintenanceContractPreviewScreen({
    super.key,
    required this.contractId,
    this.bookingId = '',
    this.title,
  });

  final String contractId;
  final String bookingId;
  final String? title;

  @override
  State<MaintenanceContractPreviewScreen> createState() =>
      _MaintenanceContractPreviewScreenState();
}

class _MaintenanceContractPreviewScreenState
    extends State<MaintenanceContractPreviewScreen> {
  static const _endpoint = 'https://daltalifts.com/app2026/sql.php';

  bool _loading = true;
  String? _error;
  String? _localPath;

  @override
  void initState() {
    super.initState();
    _loadPdf();
  }

  Future<void> _loadPdf() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final prefs = await SharedPreferences.getInstance();
      final uid = prefs.getString('userId') ?? '';
      final res = await getDio().post(
        '$_endpoint?k=${DateTime.now().millisecondsSinceEpoch}',
        data: {
          'action': 'getMaintenanceContractPdf',
          'contractId': widget.contractId,
          'bookingId': widget.bookingId,
          'uid': uid,
        },
      );
      final data = res.data;
      if (data is! Map || data['success'] != true) {
        throw Exception(
          (data is Map ? data['message']?.toString() : null) ??
              'تعذر تحميل العقد',
        );
      }
      final url = data['url']?.toString() ?? '';
      if (url.isEmpty) {
        throw Exception('رابط العقد غير متوفر');
      }

      final dio = Dio(
        BaseOptions(
          connectTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 90),
        ),
      );
      final dir = await getTemporaryDirectory();
      final file = File(
        '${dir.path}/maint_preview_${widget.contractId}.pdf',
      );
      await dio.download(url, file.path);
      if (!mounted) return;
      setState(() {
        _localPath = file.path;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.title ?? 'عقد صيانة #${widget.contractId}';
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: RepairTheme.bg,
        appBar: AppBar(
          backgroundColor: RepairTheme.cardBg,
          elevation: 0,
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Iconsax.arrow_right_3, color: RepairTheme.orange),
            onPressed: () => Navigator.maybePop(context),
          ),
          title: Text(
            title,
            style: RepairTheme.cairo(
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        body: _loading
            ? const Center(
                child: CircularProgressIndicator(color: RepairTheme.orange),
              )
            : _error != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Iconsax.document_text,
                            size: 48,
                            color: Color(0xFF9CA3AF),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            _error!,
                            textAlign: TextAlign.center,
                            style: RepairTheme.cairo(
                              fontSize: 14,
                              color: RepairTheme.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 18),
                          TextButton.icon(
                            onPressed: _loadPdf,
                            icon: const Icon(Iconsax.refresh,
                                color: RepairTheme.orange),
                            label: Text(
                              'إعادة المحاولة',
                              style: RepairTheme.cairo(
                                fontWeight: FontWeight.w700,
                                color: RepairTheme.orange,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : Padding(
                    padding: const EdgeInsets.all(12),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: PDFView(
                        filePath: _localPath!,
                        enableSwipe: true,
                        swipeHorizontal: false,
                        autoSpacing: true,
                        pageFling: true,
                        fitEachPage: true,
                        fitPolicy: FitPolicy.BOTH,
                      ),
                    ),
                  ),
      ),
    );
  }
}
