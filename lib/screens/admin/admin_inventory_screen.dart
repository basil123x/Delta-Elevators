import 'package:Delta/screens/admin/admin_inventory_item_detail.dart';
import 'package:Delta/services/catalog_items_api.dart';
import 'package:Delta/widgets/catalog_product_card.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

/// Admin inventory & spare parts screen.
///
/// TODO: Replace elevator catalog data source (`CatalogItemsApi` / groups+items)
/// with real spare-parts inventory (quantities, stock levels, part-specific
/// fields). Keep [CatalogItemsGrid] and search filtering decoupled so the UI
/// can swap data sources without a full rewrite.
class AdminInventoryScreen extends StatefulWidget {
  const AdminInventoryScreen({super.key});

  @override
  State<AdminInventoryScreen> createState() => _AdminInventoryScreenState();
}

class _AdminInventoryScreenState extends State<AdminInventoryScreen> {
  static const _bg = Color(0xFFF2F3F7);
  static const _cardBg = Color(0xFFFFFFFF);
  static const _blue = Color(0xFF3B82F6);
  static const _textPrimary = Color(0xFF1A1A2E);
  static const _border = Color(0xFFEBEBEB);
  static const _chipBorder = Color.fromRGBO(59, 130, 246, 0.35);
  static const _badgeBg = Color(0xFFEEF4FF);

  final _searchController = TextEditingController();

  List _groups = [];
  List _allItems = [];
  List _visibleItems = [];
  int _currentGroup = -1;
  String _currentGroupName = 'الكل';
  bool _loading = true;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _loadInitial();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadInitial() async {
    setState(() => _loading = true);
    try {
      final groups = await CatalogItemsApi.fetchGroups();
      final items = await CatalogItemsApi.fetchItems();
      if (!mounted) return;
      setState(() {
        _groups = groups;
        _allItems = items;
        _applyFilter();
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _groups = [];
        _allItems = [];
        _visibleItems = [];
        _loading = false;
      });
    }
  }

  Future<void> _loadItems({String? groupName}) async {
    setState(() => _loading = true);
    try {
      final items = await CatalogItemsApi.fetchItems(groupName: groupName);
      if (!mounted) return;
      setState(() {
        _allItems = items;
        _applyFilter();
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _allItems = [];
        _visibleItems = [];
        _loading = false;
      });
    }
  }

  void _applyFilter() {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) {
      _visibleItems = List.from(_allItems);
      return;
    }
    _visibleItems = _allItems.where((raw) {
      if (raw is! Map) return false;
      final code = raw['a1']?.toString().toLowerCase() ?? '';
      final desc = raw['a3']?.toString().toLowerCase() ?? '';
      final id = raw['id']?.toString().toLowerCase() ?? '';
      final grp = raw['a2']?.toString().toLowerCase() ?? '';
      return code.contains(q) ||
          desc.contains(q) ||
          id.contains(q) ||
          grp.contains(q);
    }).toList();
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
          color: isActive ? _blue : _cardBg,
          borderRadius: BorderRadius.circular(20),
          border: isActive ? null : Border.all(color: _chipBorder, width: 1),
        ),
        child: Text(
          label,
          style: GoogleFonts.cairo(
            fontSize: 13,
            fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
            color: isActive ? Colors.white : _textPrimary,
          ),
        ),
      ),
    );
  }

  Widget _buildSearchField() {
    return Container(
      height: 46,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Row(
        children: [
          const Icon(Iconsax.search_normal, color: Color(0xFFCCCCCC), size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _searchController,
              textAlign: TextAlign.right,
              onChanged: (val) {
                setState(() {
                  _query = val;
                  _applyFilter();
                });
              },
              decoration: const InputDecoration(
                hintText: 'ابحث بالاسم أو الكود...',
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
                hintStyle: TextStyle(color: Color(0xFFCCCCCC), fontSize: 13),
              ),
            ),
          ),
          if (_query.isNotEmpty)
            GestureDetector(
              onTap: () {
                _searchController.clear();
                setState(() {
                  _query = '';
                  _applyFilter();
                });
              },
              child: const Icon(
                Iconsax.close_circle,
                color: Color(0xFFCCCCCC),
                size: 18,
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
      child: Scaffold(
        backgroundColor: _bg,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          scrolledUnderElevation: 0,
          surfaceTintColor: Colors.white,
          centerTitle: true,
          iconTheme: const IconThemeData(color: _textPrimary),
          leading: IconButton(
            icon: const Icon(Iconsax.arrow_right_3, color: _blue, size: 20),
            onPressed: () => Navigator.maybePop(context),
          ),
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: _badgeBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Iconsax.box, size: 16, color: _blue),
              ),
              const SizedBox(width: 8),
              Text(
                'المخزون وقطع الغيار',
                style: GoogleFonts.cairo(
                  color: _textPrimary,
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          bottom: const PreferredSize(
            preferredSize: Size.fromHeight(1),
            child: Divider(height: 1, thickness: 1, color: _border),
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildSearchField(),
              const SizedBox(height: 12),
              SizedBox(
                height: 44,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  reverse: true,
                  children: [
                    _buildChip(
                      label: 'الكل',
                      isActive: _currentGroup == -1,
                      onTap: () {
                        setState(() {
                          _currentGroup = -1;
                          _currentGroupName = 'الكل';
                        });
                        _loadItems();
                      },
                    ),
                    ...List.generate(_groups.length, (i) {
                      final label = _groups[i]['a2']?.toString() ?? '';
                      return _buildChip(
                        label: label,
                        isActive: _currentGroup == i,
                        onTap: () {
                          setState(() {
                            _currentGroup = i;
                            _currentGroupName = label;
                          });
                          _loadItems(groupName: label);
                        },
                      );
                    }),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    width: 4,
                    height: 20,
                    decoration: BoxDecoration(
                      color: _blue,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'العناصر - $_currentGroupName',
                      style: GoogleFonts.cairo(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: _textPrimary,
                      ),
                    ),
                  ),
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
                      '${_visibleItems.length}',
                      style: GoogleFonts.cairo(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: _blue,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: _loading
                    ? const Center(
                        child: CircularProgressIndicator(color: _blue),
                      )
                    : CatalogItemsGrid(
                        items: _visibleItems,
                        accent: _blue,
                        imageUrlBuilder: CatalogItemsApi.itemImageUrl,
                        onItemTap: (item) {
                          final id = item['id']?.toString() ?? '';
                          if (id.isEmpty) return;
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  AdminInventoryItemDetailScreen(itemId: id),
                            ),
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
