import 'package:Delta/provider/app_provider.dart';
import 'package:Delta/screens/items/items_details_screen.dart';
import 'package:Delta/services/DioServiceCert.dart';
import 'package:Delta/services/quote_request.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';

// Design tokens
const _bg = Color(0xFFF2F3F7);
const _cardBg = Color(0xFFFFFFFF);
const _appBarBg = Color(0xFFFFFFFF);
const _orange = Color(0xFFF37021);
const _textPrimary = Color(0xFF1A1A2E);
const _border = Color(0xFFEBEBEB);
const _chipBorder = Color.fromRGBO(243, 112, 33, 0.4);
const _appBarBorder = Color(0xFFEBEBEB);
const _placeholder = Color(0xFFF5F5F5);
const _badgeBg = Color(0xFFFFF0E5);
const _cardShadow = BoxShadow(
  color: Color(0x0D000000),
  blurRadius: 8,
  offset: Offset(0, 2),
);

TextStyle _cairo({
  double fontSize = 14,
  FontWeight fontWeight = FontWeight.w400,
  Color color = _textPrimary,
}) {
  return GoogleFonts.cairo(
    fontSize: fontSize,
    fontWeight: fontWeight,
    color: color,
  );
}

class ItemsScreen extends StatefulWidget {
  const ItemsScreen({super.key});

  @override
  State<ItemsScreen> createState() => _ItemsScreenState();
}

class _ItemsScreenState extends State<ItemsScreen> {
  int currentGroup = -1;
  List groups = [];
  List items = [];
  String currentGrpname = "الكل";

  Future getGroups() async {
    try {
      var request = await getDio().post(
        "https://daltalifts.com/app2026/sql.php?k=${DateTime.now().millisecondsSinceEpoch}",
        data: {"action": "groups"},
      );
      final raw = request.data is Map ? request.data['data'] : null;
      if (!mounted) return;
      setState(() {
        groups = raw is List ? List.from(raw) : [];
      });
    } catch (e) {
      debugPrint('getGroups error: $e');
    }
  }

  Future getItems({String? grpx}) async {
    try {
      var request = await getDio().post(
        "https://daltalifts.com/app2026/sql.php?k=${DateTime.now().millisecondsSinceEpoch}",
        data: {"action": "items", "grp": grpx},
      );
      final raw = request.data is Map ? request.data['data'] : null;
      if (!mounted) return;
      setState(() {
        items = raw is List ? List.from(raw) : [];
      });
    } catch (e) {
      debugPrint('getItems error: $e');
    }
  }

  Set<String> _addingIds = {};
  Set<String> _addedIds = {};

  @override
  void initState() {
    getGroups();
    getItems();
    _loadQuotedItems();
    super.initState();
  }

  Future<void> _loadQuotedItems() async {
    try {
      final ids = await fetchQuoteItemIds();
      if (!mounted) return;
      setState(() => _addedIds = ids);
    } catch (e) {
      debugPrint('loadQuotedItems error: $e');
    }
  }

  Future<void> _addToQuote(dynamic itemId) async {
    final id = itemId?.toString() ?? '';
    if (id.isEmpty || _addingIds.contains(id)) return;
    setState(() => _addingIds.add(id));
    try {
      final ok = await addItemToQuoteRequest(
        id,
        app: context.read<AppProvider>(),
      );
      if (!mounted) return;
      setState(() {
        _addingIds.remove(id);
        if (ok) _addedIds.add(id);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            ok
                ? 'تمت إضافة المنتج لطلب العرض'
                : 'تعذر إضافة المنتج، حاول مرة أخرى',
            style: _cairo(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white),
          ),
          backgroundColor: ok ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      debugPrint('addToQuote error: $e');
      if (!mounted) return;
      setState(() => _addingIds.remove(id));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'تعذر إضافة المنتج، حاول مرة أخرى',
            style: _cairo(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white),
          ),
          backgroundColor: const Color(0xFFDC2626),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _openQuoteTab() {
    context.read<AppProvider>().jumpToPagex(2);
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  Widget _buildChip({
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(left: 8),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? _orange : _cardBg,
          borderRadius: BorderRadius.circular(20),
          border: isActive ? null : Border.all(color: _chipBorder, width: 1),
        ),
        child: Text(
          label,
          style: _cairo(
            fontSize: 13,
            fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
            color: isActive ? Colors.white : _textPrimary,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
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
              color: _orange,
              size: 20,
            ),
            onPressed: () => Navigator.maybePop(context),
          ),
          title: Text(
            'منتجاتنا',
            style: _cairo(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: _textPrimary,
            ),
          ),
          actions: [
            IconButton(
              tooltip: 'تقديم طلب العرض',
              onPressed: _openQuoteTab,
              icon: const Icon(Iconsax.clipboard_text, color: _orange, size: 22),
            ),
          ],
          bottom: const PreferredSize(
            preferredSize: Size.fromHeight(1),
            child: Divider(height: 1, thickness: 1, color: _appBarBorder),
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 44,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  reverse: true,
                  children: [
                    _buildChip(
                      label: 'الكل',
                      isActive: currentGroup == -1,
                      onTap: () {
                        setState(() {
                          currentGroup = -1;
                          currentGrpname = "الكل";
                          getItems();
                        });
                      },
                    ),
                    ...List.generate(groups.length, (i) {
                      return _buildChip(
                        label: groups[i]['a2'],
                        isActive: currentGroup == i,
                        onTap: () {
                          setState(() {
                            currentGroup = i;
                            currentGrpname = groups[i]['a2'];
                            getItems(grpx: currentGrpname);
                          });
                        },
                      );
                    }),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 4,
                        height: 20,
                        decoration: BoxDecoration(
                          color: _orange,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'المنتجات - $currentGrpname',
                        style: _cairo(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: _textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _badgeBg,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${items.length}',
                      style: _cairo(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: _orange,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.72,
                  ),
                  itemCount: items.length,
                  itemBuilder: (context, i) {
                    final itemId = items[i]['id']?.toString() ?? '';
                    return _ProductCard(
                      name: items[i]['a1']?.toString() ?? '',
                      imageUrl:
                          'https://daltaliftstech.s3.ap-south-1.amazonaws.com/Sys/items/$itemId/1.jpg',
                      adding: _addingIds.contains(itemId),
                      added: _addedIds.contains(itemId),
                      onAdd: () => _addToQuote(itemId),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                ItemsDetailsScreen(itmid: itemId),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProductCard extends StatefulWidget {
  const _ProductCard({
    required this.name,
    required this.imageUrl,
    required this.onTap,
    required this.onAdd,
    this.adding = false,
    this.added = false,
  });

  final String name;
  final String imageUrl;
  final VoidCallback onTap;
  final VoidCallback onAdd;
  final bool adding;
  final bool added;

  @override
  State<_ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<_ProductCard> {
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
            splashColor: _orange.withOpacity(0.2),
            highlightColor: _orange.withOpacity(0.08),
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
                    child: Stack(
                      children: [
                        Positioned.fill(
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
                                  child: const Center(
                                    child: SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: _orange,
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
                        Positioned(
                          top: 8,
                          left: 8,
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: widget.adding
                                  ? null
                                  : () {
                                      widget.onAdd();
                                    },
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                width: 34,
                                height: 34,
                                decoration: BoxDecoration(
                                  color: widget.added
                                      ? const Color(0xFF16A34A)
                                      : _orange,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.12),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                alignment: Alignment.center,
                                child: widget.adding
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : Icon(
                                        widget.added
                                            ? Iconsax.tick_circle
                                            : Iconsax.add,
                                        color: Colors.white,
                                        size: 18,
                                      ),
                              ),
                            ),
                          ),
                        ),
                      ],
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
                          style: _cairo(
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
