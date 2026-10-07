import 'package:Delta/screens/home/admin_search_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

class AdminSearchScreen extends StatelessWidget {
  final List results;

  const AdminSearchScreen({super.key, required this.results});

  static const _cardBg = Color(0xFFFFFFFF);
  static const _border = Color(0xFFEBEBEB);
  static const _textPrimary = Color(0xFF1A1A2E);
  static const _orange = Color(0xFFF37021);
  static const _cardShadow = BoxShadow(
    color: Color(0x0D000000),
    blurRadius: 8,
    offset: Offset(0, 2),
  );

  Color _statusColor(String key) {
    switch (key) {
      case 'done':
        return const Color(0xFF22C55E);
      case 'active':
        return _orange;
      case 'pending':
      default:
        return const Color(0xFF94A3B8);
    }
  }

  Color _typeColor(String type, String subtype) {
    if (type == 'booking') return const Color(0xFF3B82F6);
    if (subtype == 'Urgent') return const Color(0xFFEF4444);
    return _orange;
  }

  IconData _typeIcon(String type, String subtype) {
    if (type == 'booking') return Iconsax.calendar_1;
    if (subtype == 'Urgent') return Iconsax.warning_2;
    return Iconsax.setting_2;
  }

  @override
  Widget build(BuildContext context) {
    if (results.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Iconsax.search_status, size: 64, color: Color(0xFFCCCCCC)),
            SizedBox(height: 12),
            Text(
              'لا توجد نتائج',
              style: TextStyle(color: Color(0xFF888888), fontSize: 15),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: GridView.builder(
        shrinkWrap: false,
        physics: const AlwaysScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 0.68,
        ),
        itemCount: results.length,
        itemBuilder: (context, i) {
          final item = results[i] is Map
              ? Map<String, dynamic>.from(results[i] as Map)
              : <String, dynamic>{};
          final type = item['type']?.toString() ?? 'maintenance';
          final subtype = item['subtype']?.toString() ?? '';
          final title = item['title']?.toString() ?? '';
          final client = item['client_name']?.toString() ?? '';
          final location = item['location']?.toString() ?? '';
          final status = item['status']?.toString() ?? '';
          final statusKey = item['status_key']?.toString() ?? 'pending';
          final typeLabel = item['type_label']?.toString() ??
              (type == 'booking' ? 'حجز' : 'صيانة');
          final date = item['date']?.toString() ?? '';
          final typeColor = _typeColor(type, subtype);
          final statusColor = _statusColor(statusKey);

          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AdminSearchDetailScreen(item: item),
                ),
              );
            },
            child: Container(
              clipBehavior: Clip.hardEdge,
              decoration: BoxDecoration(
                color: _cardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _border),
                boxShadow: const [_cardShadow],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    flex: 3,
                    child: Container(
                      color: typeColor.withOpacity(0.10),
                      child: Stack(
                        children: [
                          Center(
                            child: Icon(
                              _typeIcon(type, subtype),
                              size: 42,
                              color: typeColor.withOpacity(0.85),
                            ),
                          ),
                          Positioned(
                            top: 10,
                            left: 10,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: typeColor,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                typeLabel,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ),
                          if (status.isNotEmpty)
                            Positioned(
                              top: 10,
                              right: 10,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 7,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: statusColor,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  status,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            title,
                            textAlign: TextAlign.right,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: _textPrimary,
                              fontWeight: FontWeight.w800,
                              fontSize: 12,
                            ),
                          ),
                          if (client.isNotEmpty) ...[
                            const SizedBox(height: 3),
                            Text(
                              client,
                              textAlign: TextAlign.right,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.black.withOpacity(0.55),
                                fontWeight: FontWeight.w600,
                                fontSize: 11,
                              ),
                            ),
                          ],
                          if (location.isNotEmpty) ...[
                            const SizedBox(height: 3),
                            Text(
                              location,
                              textAlign: TextAlign.right,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.black.withOpacity(0.40),
                                fontWeight: FontWeight.w500,
                                fontSize: 10,
                              ),
                            ),
                          ],
                          const Spacer(),
                          if (date.isNotEmpty)
                            Text(
                              date,
                              textAlign: TextAlign.right,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.black.withOpacity(0.35),
                                fontWeight: FontWeight.w500,
                                fontSize: 10,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
