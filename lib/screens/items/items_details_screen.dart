import 'package:Delta/provider/app_provider.dart';
import 'package:Delta/screens/items/item_preview.dart';
import 'package:Delta/services/DioServiceCert.dart';
import 'package:Delta/services/quote_request.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:iconsax/iconsax.dart';

// Design tokens
const _bg = Color(0xFFFFFFFF);
const _cardBg = Color(0xFFFFFFFF);
const _appBarBg = Color(0xFFFFFFFF);
const _specBg = Color(0xFFF8F8F8);
const _orange = Color(0xFFF37021);
const _textPrimary = Color(0xFF1A1A2E);
const _textSecondary = Color(0xFF888888);
const _border = Color(0xFFEBEBEB);
const _placeholder = Color(0xFFF5F5F5);
const _appBarBorder = Color(0xFFEBEBEB);
const _cardShadow = BoxShadow(
  color: Color(0x0D000000),
  blurRadius: 8,
  offset: Offset(0, 2),
);

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

class ItemsDetailsScreen extends StatefulWidget {
  final String itmid;
  const ItemsDetailsScreen({super.key, required this.itmid});

  @override
  State<ItemsDetailsScreen> createState() => _ItemsDetailsScreenState();
}

class _ItemsDetailsScreenState extends State<ItemsDetailsScreen> {
  List itemDetails = [];
  List itemLabelsDet = [];
  List itemSela = [];
  List itemLiftsDet = [];
  bool isLoading = false;

  Future getItems() async {
    var request = await getDio().post(
      "https://daltalifts.com/app2026/sql.php?k=${DateTime.now().millisecondsSinceEpoch}",
      data: {"action": "oneItemDetails", "itmid": widget.itmid},
    );
    setState(() {
      itemDetails = request.data['data'];
    });
  }

  Future getLabelsLifts() async {
    var request = await getDio().post(
      "https://daltalifts.com/app2026/sql.php?k=${DateTime.now().millisecondsSinceEpoch}",
      data: {"action": "getLabelsLifts"},
    );
    setState(() {
      itemLabelsDet = request.data['data'];
    });
  }

  Future getItemSela() async {
    // var request = await getDio().post(
    //   "https://daltalifts.com/app2026/sql.php?k=${DateTime.now().millisecondsSinceEpoch}",
    //   data: {
    //     "action": "items",
    //     "grp": itemDetails[0]['a2'],
    //     "notId": widget.itmid,
    //   },
    // );
    // setState(() {
    //   itemSela = request.data['data'];
    // });
  }

  Future getLiftsDet() async {
    var request = await getDio().post(
      "https://daltalifts.com/app2026/sql.php?k=${DateTime.now().millisecondsSinceEpoch}",
      data: {"action": "getLiftsDet", "idlift": itemDetails[0]['liftid']},
    );
    setState(() {
      itemLiftsDet = request.data['data'];
    });
  }

  Future<void> _loadAllData() async {
    await getItems();
    await getItemSela();
    await getLabelsLifts();
    await getLiftsDet();
  }

  @override
  void initState() {
    _loadAllData();
    super.initState();
  }

  Widget _sectionTitle(String title) {
    return Row(
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
          title,
          style: _cairo(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: _textPrimary,
          ),
        ),
      ],
    );
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
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Row(
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
          Positioned(
            right: -14,
            top: 0,
            bottom: 0,
            child: Center(
              child: Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: _orange,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentTab = Provider.of<AppProvider>(context);
    return Directionality(
      textDirection: TextDirection.rtl,
      child: itemDetails.isEmpty
          ? const Scaffold(
              backgroundColor: _bg,
              body: Center(child: CircularProgressIndicator(color: _orange)),
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
                    color: _orange,
                    size: 20,
                  ),
                  onPressed: () => Navigator.maybePop(context),
                ),
                title: Text(
                  itemDetails[0]['a1'] ?? '',
                  style: _cairo(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: _textPrimary,
                  ),
                ),
                bottom: const PreferredSize(
                  preferredSize: Size.fromHeight(1),
                  child: Divider(height: 1, thickness: 1, color: _appBarBorder),
                ),
              ),
              body: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    GestureDetector(
                      onTap: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ItemPreviewScreen(
                              id: itemDetails[0]['id'].toString(),
                            ),
                          ),
                        );
                      },
                      child: Stack(
                        children: [
                          SizedBox(
                            width: double.infinity,
                            height: 260,
                            child: Image.network(
                              'https://daltaliftstech.s3.ap-south-1.amazonaws.com/Sys/items/${itemDetails[0]['id'] ?? ''}/1.jpg',
                              fit: BoxFit.cover,
                              loadingBuilder: (context, child, progress) {
                                if (progress == null) return child;
                                return Container(
                                  color: _placeholder,
                                  child: const Center(
                                    child: CircularProgressIndicator(
                                      color: _orange,
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
                          Positioned(
                            left: 0,
                            right: 0,
                            bottom: 0,
                            height: 100,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [Colors.transparent, Colors.white],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: 8),
                          Text(
                            itemDetails[0]['a1'],
                            textAlign: TextAlign.right,
                            style: _cairo(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: _textPrimary,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              Container(
                                width: 4,
                                height: 18,
                                decoration: BoxDecoration(
                                  color: _orange,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'الوصف',
                                style: _cairo(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: _orange,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            itemDetails[0]['a3'] ?? '',
                            textAlign: TextAlign.right,
                            style: _cairo(
                              fontSize: 14,
                              color: _textSecondary,
                              height: 1.6,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Visibility(
                            visible: itemSela.isNotEmpty ? true : false,
                            child: _sectionTitle('منتجات ذات صلة'),
                          ),
                          Visibility(
                            visible: itemSela.isNotEmpty ? true : false,
                            child: SizedBox(
                              height: 160,
                              child: ListView(
                                scrollDirection: Axis.horizontal,
                                reverse: true,
                                children: List.generate(itemSela.length, (i) {
                                  return GestureDetector(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              ItemsDetailsScreen(
                                                itmid: itemSela[i]['id'],
                                              ),
                                        ),
                                      );
                                    },
                                    child: Container(
                                      width: 130,
                                      height: 160,
                                      margin: const EdgeInsets.only(left: 12),
                                      decoration: BoxDecoration(
                                        color: _cardBg,
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: _border,
                                          width: 1,
                                        ),
                                        boxShadow: const [_cardShadow],
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.stretch,
                                        children: [
                                          Expanded(
                                            child: ClipRRect(
                                              borderRadius:
                                                  const BorderRadius.vertical(
                                                    top: Radius.circular(16),
                                                  ),
                                              child: Image.network(
                                                'https://daltalifts.com/erp2026/assets/items/${itemSela[i]['id']}/images/1.jpg',
                                                fit: BoxFit.cover,
                                                width: double.infinity,
                                                errorBuilder: (_, __, ___) =>
                                                    Container(
                                                      color: _placeholder,
                                                      child: const Icon(
                                                        Icons
                                                            .image_not_supported_outlined,
                                                        color: Color(
                                                          0xFFCCCCCC,
                                                        ),
                                                      ),
                                                    ),
                                              ),
                                            ),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.all(8),
                                            child: Text(
                                              itemSela[i]['a1'],
                                              textAlign: TextAlign.center,
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                              style: _cairo(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w700,
                                                color: _textPrimary,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          if (itemLabelsDet.isNotEmpty &&
                              itemLiftsDet.isNotEmpty)
                            ...List.generate(itemLabelsDet.length, (i) {
                              return Visibility(
                                visible: itemLiftsDet[0]['a${i + 1}'] != null
                                    ? true
                                    : false,
                                child: _buildSpecRow(
                                  itemLabelsDet[i]['arb'],
                                  itemLiftsDet[0]['a${i + 1}'].toString(),
                                ),
                              );
                            }),
                          const SizedBox(height: 105),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              floatingActionButtonLocation:
                  FloatingActionButtonLocation.centerFloat,
              floatingActionButton: GestureDetector(
                onTap: isLoading
                    ? null
                    : () async {
                        setState(() => isLoading = true);
                        try {
                          final ok = await addItemToQuoteRequest(
                            itemDetails[0]['id']?.toString() ?? '',
                            app: currentTab,
                          );
                          if (!mounted) return;
                          setState(() => isLoading = false);
                          if (!ok) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('تعذر إضافة المنتج، حاول مرة أخرى'),
                              ),
                            );
                            return;
                          }
                          currentTab.jumpToPagex(2);
                          Navigator.of(context).popUntil((route) => route.isFirst);
                        } catch (_) {
                          if (!mounted) return;
                          setState(() => isLoading = false);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('تعذر إضافة المنتج، حاول مرة أخرى'),
                            ),
                          );
                        }
                      },
                child: Container(
                  width: double.maxFinite,
                  height: 58,
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFF37021), Color(0xFFFF8C00)],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFF37021).withOpacity(0.4),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          'طلب العرض',
                          style: _cairo(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ),
    );
  }
}
