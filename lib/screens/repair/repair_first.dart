import 'dart:math';

import 'package:Delta/screens/delta_customer_login_screen.dart';
import 'package:Delta/screens/repair/new_client_flow.dart';
import 'package:Delta/screens/repair/repair_screen.dart';
import 'package:Delta/screens/repair/repair_theme.dart';
import 'package:Delta/screens/settings/Addresses/Addresses_Screen.dart';
import 'package:Delta/screens/settings/Maintenance/maintenance_contracts_screen.dart';
import 'package:Delta/services/DioServiceCert.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Prefs keys for resuming the maintenance onboarding flow.
class MaintFlowPrefs {
  static const typeKey = 'maint_customer_type'; // 'delta' | 'new'
  static const bookingIdKey = 'maint_booking_id';
  static const deltaVerifiedKey = 'maint_delta_verified';
  /// ERP physical contract id only — never reuse elevator `contract_id`.
  static const erpContractIdKey = 'maint_erp_contract_id';

  static String approvedKey(String bookingId) => 'contractApproved_$bookingId';
}

class RepairFirst extends StatefulWidget {
  const RepairFirst({super.key});

  @override
  State<RepairFirst> createState() => _RepairFirstState();
}

class _RepairFirstState extends State<RepairFirst> {
  int currentCard = 0;
  String selectCard = "من تختار؟";
  bool isLoading = false;
  bool _resuming = true;

  static const String _endpoint = "https://daltalifts.com/app2026/sql.php";

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final prefs = await SharedPreferences.getInstance();
    final savedType = prefs.getString(MaintFlowPrefs.typeKey) ?? '';
    final savedCard = prefs.getInt('currentCard') ?? 0;

    // Prefer explicit saved type; fall back to last selected card.
    if (savedType == 'delta' || savedCard == 1) {
      await _resumeDeltaFlow(prefs);
      return;
    }
    if (savedType == 'new' || savedCard == 2) {
      await _resumeNewClientFlow(prefs);
      return;
    }

    if (mounted) setState(() => _resuming = false);
  }

  Future<void> _resumeDeltaFlow(SharedPreferences prefs) async {
    await prefs.setString(MaintFlowPrefs.typeKey, 'delta');
    await prefs.setInt('currentCard', 1);

    final verified = prefs.getBool(MaintFlowPrefs.deltaVerifiedKey) ?? false;
    final erpContractId =
        prefs.getString(MaintFlowPrefs.erpContractIdKey) ?? '';

    if (!mounted) return;
    // Only skip phone verify when we already verified an ERP physical contract
    // for maintenance — never treat elevator `contract_id` as enough.
    if (verified && erpContractId.isNotEmpty) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const RepairScreen()),
      );
      return;
    }

    // Chose Delta but hasn't finished phone/contract verification yet.
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const DeltaCustomerLoginScreen()),
    );
  }

  Future<void> _resumeNewClientFlow(SharedPreferences prefs) async {
    await prefs.setString(MaintFlowPrefs.typeKey, 'new');
    await prefs.setInt('currentCard', 2);
    if (!mounted) return;
    setState(() {
      _resuming = true;
      isLoading = true;
    });
    await _startNewClientFlow(resumeOnly: true);
  }

  /// New-client maintenance flow: create/get booking and resume exact step.
  ///
  /// Server statuses from `checkMaintenanceStatus`:
  /// none | pending_address | pending_approval | pending_prepare | pending_contract | completed
  Future<void> _startNewClientFlow({bool resumeOnly = false}) async {
    setState(() => isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final uid = prefs.getString("userId") ?? "";
      if (uid.isEmpty) {
        throw Exception('missing uid');
      }
      await prefs.setString(MaintFlowPrefs.typeKey, 'new');
      await prefs.setInt('currentCard', 2);

      final statusResult = await getDio().post(
        _endpoint,
        data: {"action": "checkMaintenanceStatus", "uid": uid},
      );
      final statusData = statusResult.data;
      if (statusData is! Map || statusData['success'] != true) {
        throw Exception(statusData is Map
            ? (statusData['message']?.toString() ?? 'check failed')
            : 'check failed');
      }
      var status = statusData['status']?.toString() ?? 'none';
      var bookingId =
          statusData['bookingId']?.toString() ??
          prefs.getString(MaintFlowPrefs.bookingIdKey) ??
          '';

      if (status == 'completed') {
        if (!mounted) return;
        setState(() {
          isLoading = false;
          _resuming = false;
        });
        if (resumeOnly) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const RepairScreen()),
          );
          return;
        }
        await _showAlreadyHasContractDialog();
        return;
      }

      // Create booking only when there is none yet.
      if (status == 'none' || bookingId.isEmpty || bookingId == 'null') {
        final oid = (1000 + Random().nextInt(9000)).toString();
        final bookingResult = await getDio().post(
          _endpoint,
          data: {"action": "addMaintenanceBooking", "uid": uid, "oid": oid},
        );
        final bookingData = bookingResult.data;
        if (bookingData is! Map ||
            bookingData['success'] != true ||
            (bookingData['bookingId']?.toString().isEmpty ?? true)) {
          throw Exception(bookingData is Map
              ? (bookingData['message']?.toString() ?? 'create failed')
              : 'create failed');
        }
        bookingId = bookingData['bookingId'].toString();
        status = 'pending_address';
      }

      await prefs.setString(MaintFlowPrefs.bookingIdKey, bookingId);

      // Trust server status: only ask for address when it is still missing.
      if (status == 'pending_address') {
        if (!mounted) return;
        final selectedId = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const AddressesScreen(returnMode: true),
          ),
        );

        if (selectedId == null ||
            selectedId.toString().isEmpty ||
            selectedId.toString() == '0') {
          // Keep flow prefs; leave so next open resumes at address.
          if (mounted) Navigator.maybePop(context);
          return;
        }

        final addrResult = await getDio().post(
          _endpoint,
          data: {
            "action": "updateBookingAddress",
            "bookingId": bookingId,
            "addressId": selectedId.toString(),
          },
        );
        final addrData = addrResult.data;
        if (addrData is! Map || addrData['success'] != true) {
          throw Exception(addrData is Map
              ? (addrData['message']?.toString() ?? 'address update failed')
              : 'address update failed');
        }
        await prefs.setString('addId', selectedId.toString());
        // After address → waiting for ERP approval.
        status = 'pending_approval';
      }

      // pending_approval / pending_prepare / pending_contract
      // → wait screens or PDF (NewClientContractScreen polls stx + contract_ready).
      final ready = status == 'pending_contract';
      final approved =
          prefs.getBool(MaintFlowPrefs.approvedKey(bookingId)) ?? false;

      if (!mounted) return;
      setState(() {
        isLoading = false;
        _resuming = false;
      });

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => NewClientContractScreen(
            bookingId: bookingId,
            startFromSignature: ready && approved,
          ),
        ),
      );
    } catch (e) {
      debugPrint('New client flow error: $e');
      if (mounted) {
        setState(() {
          isLoading = false;
          _resuming = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("حدث خطأ، حاول مرة أخرى")),
        );
      }
    }
  }

  Future<void> _showAlreadyHasContractDialog() async {
    if (!mounted) return;
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Row(
            children: [
              Icon(Iconsax.warning_2, color: Color(0xFFF37021)),
              SizedBox(width: 8),
              Text(
                "عقد مسجل بالفعل",
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          content: Text(
            "لديك عقد صيانة مسجل بالفعل.\nيمكنك مراجعة عقودك من صفحة الإعدادات.",
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 14,
              color: Colors.grey[700],
              height: 1.6,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                "إلغاء",
                style: TextStyle(fontFamily: 'Cairo', color: Colors.grey),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF37021),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const MaintenanceContractsScreen(),
                  ),
                );
              },
              child: const Text(
                "عرض العقود",
                style: TextStyle(fontFamily: 'Cairo', color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _selectionCard({
    required int cardId,
    required String label,
    required Widget icon,
  }) {
    final selected = currentCard == cardId;
    return GestureDetector(
      onTap: () {
        setState(() {
          currentCard = cardId;
          selectCard = cardId == 1 ? "عملاء دلتا" : "عميل جديد";
        });
      },
      child: Container(
        decoration: BoxDecoration(
          color: RepairTheme.cardBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? RepairTheme.orange : RepairTheme.border,
            width: selected ? 2 : 1,
          ),
          boxShadow: const [RepairTheme.cardShadow],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            icon,
            const SizedBox(height: 12),
            Text(
              label,
              style: RepairTheme.cairo(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: RepairTheme.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_resuming) {
      return const Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          backgroundColor: RepairTheme.bg,
          body: Center(
            child: CircularProgressIndicator(color: Color(0xFFF37021)),
          ),
        ),
      );
    }

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: RepairTheme.bg,
        body: Column(
          children: [
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Color(0xFFF37021),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(28),
                  bottomRight: Radius.circular(28),
                ),
              ),
              padding: EdgeInsets.fromLTRB(
                16,
                MediaQuery.paddingOf(context).top + 12,
                16,
                28,
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.maybePop(context),
                    child: const Icon(
                      Iconsax.arrow_right_3,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      "إختر من يريد طلب الصيانة",
                      textAlign: TextAlign.center,
                      style: RepairTheme.cairo(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 22),
                ],
              ),
            ),
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 160,
                          child: _selectionCard(
                            cardId: 2,
                            label: "عميل جديد",
                            icon: const Icon(
                              Iconsax.user_add,
                              size: 48,
                              color: RepairTheme.orange,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: SizedBox(
                          height: 160,
                          child: _selectionCard(
                            cardId: 1,
                            label: "عملاء دلتا",
                            icon: Image.asset(
                              'assets/img/brand_logo_big.png',
                              width: 48,
                              height: 48,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SafeArea(
              top: false,
              child: RepairTheme.primaryButton(
                label: selectCard,
                loading: isLoading,
                onTap: currentCard == 0 || isLoading
                    ? null
                    : () async {
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.setInt("currentCard", currentCard);
                        if (currentCard == 1) {
                          await prefs.setString(
                            MaintFlowPrefs.typeKey,
                            'delta',
                          );
                          if (!mounted) return;
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const DeltaCustomerLoginScreen(),
                            ),
                          );
                        } else {
                          await prefs.setString(MaintFlowPrefs.typeKey, 'new');
                          await _startNewClientFlow();
                        }
                      },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
