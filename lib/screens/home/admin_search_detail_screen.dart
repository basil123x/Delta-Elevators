import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

class AdminSearchDetailScreen extends StatelessWidget {
  final Map item;

  const AdminSearchDetailScreen({super.key, required this.item});

  static const Color _orange = Color(0xFFF37021);
  static const Color _textPrimary = Color(0xFF1A1A2E);

  bool get _isBooking => item['type']?.toString() == 'booking';
  bool get _isUrgent => item['subtype']?.toString() == 'Urgent';

  @override
  Widget build(BuildContext context) {
    final title = item['title']?.toString() ?? '';
    final client = item['client_name']?.toString() ?? '';
    final status = item['status']?.toString() ?? '';
    final date = item['date']?.toString() ?? '';
    final location = item['location']?.toString() ?? '';
    final description = item['description']?.toString() ?? '';
    final typeLabel = item['type_label']?.toString() ?? '';
    final id = item['id']?.toString() ?? '';

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF2F3F7),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          iconTheme: const IconThemeData(color: _textPrimary),
          title: Text(
            _isBooking ? 'تفاصيل الحجز' : 'تفاصيل طلب الصيانة',
            style: const TextStyle(
              color: _textPrimary,
              fontWeight: FontWeight.w800,
              fontSize: 17,
            ),
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFEBEBEB)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: _orange.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          _isBooking
                              ? Iconsax.calendar_1
                              : (_isUrgent
                                    ? Iconsax.warning_2
                                    : Iconsax.setting_2),
                          color: _orange,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title.isNotEmpty
                                  ? title
                                  : (_isBooking
                                        ? 'حجز #$id'
                                        : 'صيانة #$id'),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: _textPrimary,
                              ),
                            ),
                            if (typeLabel.isNotEmpty || status.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Text(
                                [
                                  if (typeLabel.isNotEmpty) typeLabel,
                                  if (status.isNotEmpty) status,
                                ].join(' • '),
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: _orange.withOpacity(0.95),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  _row('العميل', client.isEmpty ? '—' : client),
                  if (location.isNotEmpty) _row('العنوان', location),
                  if (date.isNotEmpty) _row('التاريخ', date),
                  if (description.isNotEmpty) _row('الوصف', description),
                  _row('المعرف', '#$id'),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF7ED),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFFFE0C2)),
              ),
              child: const Text(
                'شاشة تفاصيل مبدئية — سيتم ربط الإجراءات الكاملة لاحقاً.',
                style: TextStyle(
                  fontSize: 13,
                  color: Color(0xFF9A3412),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.black.withOpacity(0.45),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              color: _textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
