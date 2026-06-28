import 'dart:math';

import 'package:Delta/screens/delta_customer_login_screen.dart';
import 'package:Delta/screens/repair/new_client_flow.dart';
import 'package:Delta/screens/repair/repair_screen.dart';
import 'package:Delta/screens/repair/repair_theme.dart';
import 'package:Delta/screens/settings/Addresses/Addresses_Screen.dart';
import 'package:Delta/screens/settings/Maintenance/maintenScreen.dart';
import 'package:Delta/services/DioServiceCert.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RepairFirst extends StatefulWidget {
  const RepairFirst({super.key});

  @override
  State<RepairFirst> createState() => _RepairFirstState();
}

class _RepairFirstState extends State<RepairFirst> {
  int currentCard = 0;
  String selectCard = "من تختار؟";
  bool isLoading = false;

  static const String _endpoint = "https://daltalifts.com/app2026/sql.php";

  /// New-client maintenance flow: create/get a maintenance booking, make sure
  /// it has an address (reusing [AddressesScreen] in return mode if needed),
  /// then continue to the contract + signature screen.
  Future<void> _startNewClientFlow() async {
    setState(() => isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final uid = prefs.getString("userId") ?? "";

      // CHECK FIRST: does this uid already have a contract?
      final statusResult = await getDio().post(
        _endpoint,
        data: {"action": "checkMaintenanceStatus", "uid": uid},
      );
      final status = statusResult.data['status'];

      if (status == 'completed') {
        // Already has a contract! Show warning dialog
        if (!mounted) return;
        setState(() => isLoading = false);
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => Directionality(
            textDirection: TextDirection.rtl,
            child: AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Row(
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
                  child: Text(
                    "إلغاء",
                    style: TextStyle(fontFamily: 'Cairo', color: Colors.grey),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFFF37021),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () {
                    Navigator.pop(context); // close dialog
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => MaintenanceScreen()),
                    );
                  },
                  child: Text(
                    "عرض العقود",
                    style: TextStyle(fontFamily: 'Cairo', color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        );
        return;
      }

      final oid = (1000 + Random().nextInt(9000)).toString();

      // 1. Get or create the maintenance booking.
      final bookingResult = await getDio().post(
        _endpoint,
        data: {"action": "addMaintenanceBooking", "uid": uid, "oid": oid},
      );
      final bookingId = bookingResult.data['bookingId'].toString();

      // 2. Check whether the booking already has an address.
      final bookDet = await getDio().post(
        _endpoint,
        data: {"action": "getMyBookingDet", "bookId": bookingId},
      );
      final addressId = bookDet.data['data'][0]['addressId'];

      // 3. If no address yet, let the user pick one and attach it.
      if (addressId == null || addressId == '0' || addressId == 0) {
        if (!mounted) return;
        final selectedId = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const AddressesScreen(returnMode: true),
          ),
        );

        // If the user pressed back without selecting an address, stop here
        // instead of continuing to the contract screen.
        if (selectedId == null) {
          if (mounted) setState(() => isLoading = false);
          return;
        }

        // 4. Attach the chosen address to the booking.
        await getDio().post(
          _endpoint,
          data: {
            "action": "updateBookingAddress",
            "bookingId": bookingId,
            "addressId": selectedId,
          },
        );

        // 5. Continue to the contract
        if (!mounted) return;
        await prefs.remove("currentCard");
        setState(() => isLoading = false); // stop loading BEFORE push
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => NewClientContractScreen(bookingId: bookingId),
          ),
        );
        return; // EXIT here so finally doesn't interfere
      }

      // Booking already has an address
      if (!mounted) return;
      await prefs.remove("currentCard");
      setState(() => isLoading = false);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => NewClientContractScreen(bookingId: bookingId),
        ),
      );
      return;
    } catch (e) {
      print('New client flow error: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("حدث خطأ، حاول مرة أخرى")));
      }
    } finally {
      // Only reset loading if still mounted AND not already navigated
      if (mounted && isLoading) setState(() => isLoading = false);
    }
  }

  Future getSharedSettings() async {
    SharedPreferences prefx = await SharedPreferences.getInstance();
    await prefx.remove("currentCard");

    String uid = prefx.getString("userId") ?? "";
    if (uid.isEmpty) return;

    // If user just logged out and logged back in, show selection screen
    final justLoggedIn = prefx.getBool('just_logged_in') ?? false;
    if (justLoggedIn) {
      await prefx.remove('just_logged_in');
      return; // show RepairFirst selection screen
    }

    try {
      final result = await getDio().post(
        _endpoint,
        data: {"action": "checkMaintenanceStatus", "uid": uid},
      );
      final status = result.data['status'];
      if (status == 'completed') {
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => RepairScreen()),
        );
      }
    } catch (e) {
      print('Status check error: $e');
    }
  }

  @override
  void initState() {
    getSharedSettings();
    super.initState();
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
                        SharedPreferences prefx =
                            await SharedPreferences.getInstance();
                        prefx.setInt("currentCard", currentCard);
                        if (currentCard == 1) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const DeltaCustomerLoginScreen(),
                            ),
                          );
                          setState(() {});
                        } else {
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
