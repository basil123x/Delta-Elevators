import 'package:Delta/services/catalog_items_api.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

/// Read-only item detail for admin inventory (no quote / order CTA).
class AdminInventoryItemDetailScreen extends StatefulWidget {
  final String itemId;

  const AdminInventoryItemDetailScreen({super.key, required this.itemId});

  @override
  State<AdminInventoryItemDetailScreen> createState() =>
      _AdminInventoryItemDetailScreenState();
}

class _AdminInventoryItemDetailScreenState
    extends State<AdminInventoryItemDetailScreen> {
  static const _bg = Color(0xFFFFFFFF);
  static const _appBarBg = Color(0xFFFFFFFF);
  static const _specBg = Color(0xFFF8F8F8);
  static const _blue = Color(0xFF3B82F6);
  static const _textPrimary = Color(0xFF1A1A2E);
  static const _textSecondary = Color(0xFF888888);
  static const _border = Color(0xFFEBEBEB);
  static const _placeholder = Color(0xFFF5F5F5);
  static const _appBarBorder = Color(0xFFEBEBEB);

  List itemDetails = [];
  List itemLabelsDet = [];
  List itemLiftsDet = [];
  bool _loading = true;

  TextStyle _cairo({
    double fontSize = 14,
    FontWeight fontWeight = FontWeight.w400,
    Color color = _textPrimary,
    double? height,
  }) {
    return GoogleFonts.cairo(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      height: height,
    );
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final details = await CatalogItemsApi.fetchOneItemDetails(widget.itemId);
      List labels = [];
      List lifts = [];
      if (details.isNotEmpty) {
        labels = await CatalogItemsApi.fetchLabelsLifts();
        final liftId = details[0]['liftid'];
        if (liftId != null) {
          lifts = await CatalogItemsApi.fetchLiftsDet(liftId);
        }
      }
      if (!mounted) return;
      setState(() {
        itemDetails = details;
        itemLabelsDet = labels;
        itemLiftsDet = lifts;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Widget _buildSpecRow(String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: _specBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border, width: 1),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.left,
              style: _cairo(fontSize: 13, color: _textSecondary),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              textAlign: TextAlign.right,
              style: _cairo(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: _textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: _loading
          ? const Scaffold(
              backgroundColor: _bg,
              body: Center(child: CircularProgressIndicator(color: _blue)),
            )
          : itemDetails.isEmpty
              ? Scaffold(
                  backgroundColor: _bg,
                  appBar: AppBar(
                    backgroundColor: _appBarBg,
                    elevation: 0,
                    leading: IconButton(
                      icon: const Icon(
                        Iconsax.arrow_right_3,
                        color: _blue,
                        size: 20,
                      ),
                      onPressed: () => Navigator.maybePop(context),
                    ),
                  ),
                  body: const Center(child: Text('تعذر تحميل التفاصيل')),
                )
              : Scaffold(
                  backgroundColor: _bg,
                  appBar: AppBar(
                    backgroundColor: _appBarBg,
                    elevation: 0,
                    scrolledUnderElevation: 0,
                    surfaceTintColor: _appBarBg,
                    centerTitle: true,
                    leading: IconButton(
                      icon: const Icon(
                        Iconsax.arrow_right_3,
                        color: _blue,
                        size: 20,
                      ),
                      onPressed: () => Navigator.maybePop(context),
                    ),
                    title: Text(
                      itemDetails[0]['a1']?.toString() ?? '',
                      style: _cairo(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    bottom: const PreferredSize(
                      preferredSize: Size.fromHeight(1),
                      child: Divider(
                        height: 1,
                        thickness: 1,
                        color: _appBarBorder,
                      ),
                    ),
                  ),
                  body: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(
                          width: double.infinity,
                          height: 260,
                          child: Image.network(
                            CatalogItemsApi.itemImageUrl(
                              itemDetails[0]['id'] ?? widget.itemId,
                            ),
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, progress) {
                              if (progress == null) return child;
                              return Container(
                                color: _placeholder,
                                child: const Center(
                                  child: CircularProgressIndicator(
                                    color: _blue,
                                  ),
                                ),
                              );
                            },
                            errorBuilder: (_, __, ___) => Container(
                              color: _placeholder,
                              child: const Icon(
                                Iconsax.image,
                                color: Color(0xFFCCCCCC),
                                size: 48,
                              ),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                itemDetails[0]['a1']?.toString() ?? '',
                                textAlign: TextAlign.right,
                                style: _cairo(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              if ((itemDetails[0]['a3']?.toString() ?? '')
                                  .isNotEmpty) ...[
                                const SizedBox(height: 16),
                                Text(
                                  'الوصف',
                                  textAlign: TextAlign.right,
                                  style: _cairo(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: _blue,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  itemDetails[0]['a3'].toString(),
                                  textAlign: TextAlign.right,
                                  style: _cairo(
                                    fontSize: 14,
                                    color: _textSecondary,
                                    height: 1.6,
                                  ),
                                ),
                              ],
                              if (itemLabelsDet.isNotEmpty &&
                                  itemLiftsDet.isNotEmpty) ...[
                                const SizedBox(height: 20),
                                Text(
                                  'المواصفات',
                                  textAlign: TextAlign.right,
                                  style: _cairo(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: _blue,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                ...List.generate(itemLabelsDet.length, (i) {
                                  final value =
                                      itemLiftsDet[0]['a${i + 1}']?.toString();
                                  if (value == null || value.isEmpty) {
                                    return const SizedBox.shrink();
                                  }
                                  return _buildSpecRow(
                                    itemLabelsDet[i]['arb']?.toString() ?? '',
                                    value,
                                  );
                                }),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }
}
