import 'package:Delta/screens/items/items_details_screen.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

class SearchScreen extends StatefulWidget {
  final List searchItemsList;
  const SearchScreen({super.key, required this.searchItemsList});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  static const _cardBg = Color(0xFFFFFFFF);
  static const _border = Color(0xFFEBEBEB);
  static const _textPrimary = Color(0xFF1A1A2E);
  static const _placeholder = Color(0xFFF5F5F5);
  static const _cardShadow = BoxShadow(
    color: Color(0x0D000000),
    blurRadius: 8,
    offset: Offset(0, 2),
  );

  Widget _imagePlaceholder() {
    return Container(
      color: _placeholder,
      alignment: Alignment.center,
      child: const Icon(
        Iconsax.image,
        color: Color(0xFFCCCCCC),
        size: 32,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.searchItemsList.isEmpty) {
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
          childAspectRatio: 0.78,
        ),
        itemCount: widget.searchItemsList.length,
        itemBuilder: (context, i) {
          final id = widget.searchItemsList[i]['id'];
          final name = widget.searchItemsList[i]['a1'];
          final imageUrl =
              'https://daltaliftstech.s3.ap-south-1.amazonaws.com/Sys/items/$id/1.jpg';

          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ItemsDetailsScreen(itmid: id),
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
                    child: Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      loadingBuilder: (context, child, progress) {
                        if (progress == null) return child;
                        return _imagePlaceholder();
                      },
                      errorBuilder: (_, __, ___) => _imagePlaceholder(),
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: Container(
                      color: _cardBg,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 6,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        name,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: _textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
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
