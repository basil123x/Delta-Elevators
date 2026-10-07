import 'dart:async';

import 'package:Delta/screens/booking/contract/Contract.dart';
import 'package:Delta/screens/booking/contract/ContractWait.dart';
import 'package:Delta/screens/booking/contract/Processing.dart';
import 'package:Delta/screens/booking/contract/Quotation.dart';
import 'package:Delta/screens/booking/contract/contract_theme.dart';
import 'package:Delta/services/DioServiceCert.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ContractScreen extends StatefulWidget {
  final String orderId;
  const ContractScreen({super.key, required this.orderId});

  @override
  State<ContractScreen> createState() => _ContractScreenState();
}

class _ContractScreenState extends State<ContractScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int currentPage = 0;
  Timer? _timer;

  List bookDet = [];
  List myBooking = [];
  bool _isAdmin = false;
  bool _didJumpToProcessing = false;
  bool _roleReady = false;

  @override
  void initState() {
    super.initState();
    _loadAdmin();
    getMyBookings();
    getBookingDet();
    _tabController = TabController(length: 2, vsync: this);
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) {
      getMyBookings();
      getBookingDet();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAdmin() async {
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getBool('is_app_manager') ?? false;
    if (!mounted) return;
    setState(() {
      _isAdmin = cached;
      _roleReady = true;
    });
  }

  String get _stx {
    if (myBooking.isEmpty) return '0';
    return myBooking[0]['stx']?.toString() ?? '0';
  }

  String get _stt {
    if (bookDet.isNotEmpty) {
      return bookDet[0]['stt']?.toString() ?? '0';
    }
    if (myBooking.isEmpty) return '0';
    return myBooking[0]['stt']?.toString() ?? '0';
  }

  bool get _isQuoteStage => _stx == '0' || _stx == '1';

  /// العميل وقّع فعلياً (stt=1). الموافقة بدون توقيع تبقى معلّقة للأدمن.
  bool get _customerSigned => _stt == '1';

  Widget _adminPendingWait() {
    return ContractWait(
      title: 'معلق',
      message: _isQuoteStage
          ? 'الطلب معلّق بانتظار إكمال العميل لبيانات عرض السعر وتوقيع العقد. ستظهر مراحل التنفيذ هنا بعد توقيع العميل.'
          : 'الطلب معلّق بانتظار توقيع العميل على العقد. ستظهر مراحل التنفيذ هنا بعد التوقيع.',
      showSalesButton: false,
      showBackButton: false,
      footerHint: 'يتم التحديث تلقائياً بعد توقيع العميل',
    );
  }

  Future getBookingDet() async {
    var response = await getDio().post(
      "https://daltalifts.com/app2026/sql.php?k=${DateTime.now().millisecondsSinceEpoch}",
      data: {"action": "getMyBookingDet", "bookId": widget.orderId},
    );
    if (!mounted) return;
    final data = response.data['data'];
    if (data is! List || data.isEmpty) return;
    setState(() {
      bookDet = data;
    });
  }

  Future getMyBookings() async {
    var result = await getDio().post(
      "https://daltalifts.com/app2026/sql.php?k=${DateTime.now().millisecondsSinceEpoch}",
      data: {"action": "getMyBookingOne", "bookid": widget.orderId},
    );
    if (!mounted) return;
    final data = result.data['data'];
    if (data is! List || data.isEmpty) return;
    setState(() {
      myBooking = data;
      if (_isAdmin) {
        if (_customerSigned) {
          _timer?.cancel();
        }
      } else if (myBooking.isNotEmpty &&
          myBooking[0]['stx']?.toString() != "0" &&
          myBooking[0]['stt']?.toString() != "0") {
        // نوقف الـ polling بعد التوقيع فقط
        _timer?.cancel();
      }
      if (_isAdmin &&
          _customerSigned &&
          !_didJumpToProcessing &&
          _tabController.index == 0) {
        _didJumpToProcessing = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _tabController.animateTo(1);
        });
      }
    });
  }

  bool get _hasContractReady {
    if (bookDet.isEmpty && myBooking.isEmpty) return false;
    final row = bookDet.isNotEmpty ? bookDet[0] : myBooking[0];
    // السيستم بيعلّم contract_ready=1 لما يبعت العقد للعميل
    final ready = row['contract_ready']?.toString() ?? '';
    if (ready == '1' || ready == 'true') return true;
    final contractId = row['contract_id']?.toString() ?? '';
    return contractId.isNotEmpty &&
        contractId != 'null' &&
        contractId != '0';
  }

  Widget getSwitchPage1() {
    if (_isAdmin) {
      if (!_customerSigned) return _adminPendingWait();
      if (bookDet.isEmpty) {
        return const Center(
          child: CircularProgressIndicator(color: ContractTheme.orange),
        );
      }
      final dets = bookDet.isNotEmpty ? bookDet : myBooking;
      if (!_hasContractReady) {
        return Processing(bookDets: dets);
      }
      return Contract(
        key: ValueKey(
          'contract_${widget.orderId}_${dets[0]['stt']}_${dets[0]['contract_id']}',
        ),
        bookDets: dets,
      );
    }
    final stx = _stx;
    // عرض السعر يحتاج stb/floors/persons من getMyBookingDet
    if ((stx == '0' || stx == '1') && bookDet.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: ContractTheme.orange),
      );
    }
    final dets = bookDet.isNotEmpty ? bookDet : myBooking;
    switch (stx) {
      case "0":
        // طلب جديد: اختيار الطوابق والركاب، وبعد الإرسال يظهر انتظار الشركة
        return QuotationScreen(
          key: ValueKey('quote_${widget.orderId}'),
          bookDets: bookDet,
        );
      case "1":
        return QuotationScreen(
          key: ValueKey('quote_${widget.orderId}'),
          bookDets: bookDet,
        );
      case "2":
        // مرحلة العقد: لا تُظهر العقد إلا بعد ما السيستم يجهّزه ويرسله
        if (bookDet.isEmpty) {
          return const Center(
            child: CircularProgressIndicator(color: ContractTheme.orange),
          );
        }
        if (!_hasContractReady) {
          return const ContractWait(
            title: 'في انتظار العقد',
            message:
                'جاري تجهيز عقد التوريد والتركيب من قبل الشركة. سيظهر العقد هنا تلقائياً فور اعتماده وإرساله لمراجعتك وتوقيعه.',
          );
        }
        return Contract(
          key: ValueKey(
            'contract_${widget.orderId}_${dets[0]['stt']}_${dets[0]['contract_id']}',
          ),
          bookDets: dets,
        );
      default:
        if (bookDet.isEmpty || !_hasContractReady) {
          return const ContractWait(
            title: 'في انتظار العقد',
            message:
                'جاري تجهيز عقد التوريد والتركيب من قبل الشركة. سيظهر العقد هنا تلقائياً فور اعتماده وإرساله لمراجعتك وتوقيعه.',
          );
        }
        return Contract(bookDets: dets);
    }
  }

  Widget getSwitchPage2() {
    if (_isAdmin) {
      if (!_customerSigned) return _adminPendingWait();
      return Processing(
        bookDets: bookDet.isNotEmpty ? bookDet : myBooking,
      );
    }
    final stx = _stx;
    if (stx == '0' || stx == '1') {
      if (bookDet.isEmpty) {
        return const Center(
          child: CircularProgressIndicator(color: ContractTheme.orange),
        );
      }
      return QuotationScreen(
        key: ValueKey('quote2_${widget.orderId}'),
        bookDets: bookDet,
      );
    }
    // مراحل التنفيذ بعد جاهزية العقد وتوقيعه
    if (!_hasContractReady) {
      return const ContractWait(
        title: 'في انتظار العقد',
        message:
            'مراحل التنفيذ ستظهر بعد تجهيز العقد من الشركة وتوقيعه من طرفك.',
        showSalesButton: false,
      );
    }
    final stt = bookDet.isNotEmpty ? bookDet[0]['stt']?.toString() : null;
    if (stt == null || stt == '0') {
      return const ContractWait(
        title: 'في انتظار توقيع العقد',
        message:
            'مراحل التنفيذ ستظهر بعد مراجعة العقد وتوقيعه.',
        showSalesButton: false,
      );
    }
    return Processing(
      bookDets: bookDet.isNotEmpty ? bookDet : myBooking,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: myBooking.isEmpty || !_roleReady
          ? Scaffold(backgroundColor: ContractTheme.bg)
          : GestureDetector(
              onTap: () => FocusScope.of(context).unfocus(),
              child: Scaffold(
                backgroundColor: ContractTheme.bg,
                appBar: AppBar(
                  leading: IconButton(
                    icon: const Icon(
                      Iconsax.arrow_right_3,
                      color: ContractTheme.orange,
                    ),
                    onPressed: () => Navigator.maybePop(context),
                  ),
                  title: Text(
                    _isAdmin
                        ? "طلب رقم ${widget.orderId}"
                        : (_isQuoteStage
                            ? "طلب عرض سعر"
                            : "طلب رقم ${widget.orderId}"),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: ContractTheme.textPrimary,
                    ),
                  ),
                  centerTitle: true,
                  backgroundColor: Colors.white,
                  elevation: 0,
                  bottom: (_isAdmin && !_customerSigned) || _isQuoteStage
                      ? null
                      : PreferredSize(
                          preferredSize: const Size.fromHeight(49),
                          child: Column(
                            children: [
                              TabBar(
                                onTap: (index) {
                                  if (index == 1 &&
                                      myBooking[0]['stt'] == "0") {
                                    _tabController.animateTo(0);
                                  }
                                },
                                controller: _tabController,
                                labelColor: ContractTheme.orange,
                                unselectedLabelColor:
                                    ContractTheme.textSecondary,
                                indicatorColor: ContractTheme.orange,
                                indicatorWeight: 3,
                                dividerColor: ContractTheme.border,
                                dividerHeight: 1,
                                labelStyle: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                ),
                                unselectedLabelStyle: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                                tabs: [
                                  const Tab(text: "توقيع العقد"),
                                  Tab(
                                    child: Opacity(
                                      opacity: myBooking[0]['stt'] == "0"
                                          ? 0.3
                                          : 1.0,
                                      child: const Text("مراحل التنفيذ"),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                ),
                body: _isAdmin && !_customerSigned
                    ? _adminPendingWait()
                    : TabBarView(
                        physics: const NeverScrollableScrollPhysics(),
                        controller: _tabController,
                        children: [
                          getSwitchPage1(),
                          getSwitchPage2(),
                        ],
                      ),
              ),
            ),
    );
  }
}
