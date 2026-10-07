import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

/// Shared product card used by catalog-style grids (admin inventory interim).
/// Decoupled from any data source — pass display fields + onTap only.
class CatalogProductCard extends StatefulWidget {
  const CatalogProductCard({
    super.key,
    required this.name,
    required this.imageUrl,
    required this.onTap,
    this.accent = const Color(0xFFF37021),
  });

  final String name;
  final String imageUrl;
  final VoidCallback onTap;
  final Color accent;

  @override
  State<CatalogProductCard> createState() => _CatalogProductCardState();
}

class _CatalogProductCardState extends State<CatalogProductCard> {
  static const _cardBg = Color(0xFFFFFFFF);
  static const _border = Color(0xFFEBEBEB);
  static const _textPrimary = Color(0xFF1A1A2E);
  static const _placeholder = Color(0xFFF5F5F5);
  static const _cardShadow = BoxShadow(
    color: Color(0x0D000000),
    blurRadius: 8,
    offset: Offset(0, 2),
  );

  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOut,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(16),
            splashColor: widget.accent.withValues(alpha: 0.2),
            highlightColor: widget.accent.withValues(alpha: 0.08),
            child: Ink(
              decoration: BoxDecoration(
                color: _cardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _border, width: 1),
                boxShadow: const [_cardShadow],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    flex: 65,
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(16),
                      ),
                      child: Image.network(
                        widget.imageUrl,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        loadingBuilder: (context, child, progress) {
                          if (progress == null) return child;
                          return Container(
                            color: _placeholder,
                            child: Center(
                              child: SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: widget.accent,
                                ),
                              ),
                            ),
                          );
                        },
                        errorBuilder: (_, __, ___) => Container(
                          color: _placeholder,
                          child: const Icon(
                            Iconsax.image,
                            color: Color(0xFFCCCCCC),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 35,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 8,
                      ),
                      child: Center(
                        child: Text(
                          widget.name,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.cairo(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: _textPrimary,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Grid of catalog-style cards. Data-source agnostic — pass any list of maps
/// with `id` + display name key (default `a1`).
class CatalogItemsGrid extends StatelessWidget {
  const CatalogItemsGrid({
    super.key,
    required this.items,
    required this.onItemTap,
    this.nameKey = 'a1',
    this.imageUrlBuilder,
    this.accent = const Color(0xFFF37021),
    this.padding = EdgeInsets.zero,
  });

  final List items;
  final void Function(Map item) onItemTap;
  final String nameKey;
  final String Function(dynamic itemId)? imageUrlBuilder;
  final Color accent;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const Center(
        child: Text(
          'لا توجد عناصر',
          style: TextStyle(color: Color(0xFF888888), fontSize: 14),
        ),
      );
    }

    return GridView.builder(
      padding: padding,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.72,
      ),
      itemCount: items.length,
      itemBuilder: (context, i) {
        final raw = items[i];
        final item = raw is Map
            ? Map<String, dynamic>.from(raw)
            : <String, dynamic>{};
        final id = item['id'];
        final name = item[nameKey]?.toString() ?? '';
        final imageUrl = imageUrlBuilder != null
            ? imageUrlBuilder!(id)
            : 'https://daltaliftstech.s3.ap-south-1.amazonaws.com/Sys/items/$id/1.jpg';

        return CatalogProductCard(
          name: name,
          imageUrl: imageUrl,
          accent: accent,
          onTap: () => onItemTap(item),
        );
      },
    );
  }
}
