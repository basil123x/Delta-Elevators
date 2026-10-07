import 'package:Delta/screens/booking/contract/contract_theme.dart';
import 'package:Delta/screens/settings/Sales/SalesScreen.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

class ContractWait extends StatelessWidget {
  final String title;
  final String message;
  final bool showSalesButton;
  final bool showBackButton;
  final String footerHint;

  const ContractWait({
    super.key,
    this.title = 'في انتظار العقد',
    this.message =
        'جاري تجهيز عقد التوريد والتركيب من قبل الشركة. سيتم إشعارك فور جاهزية العقد للمراجعة والتوقيع.',
    this.showSalesButton = true,
    this.showBackButton = true,
    this.footerHint = 'يتم التحديث تلقائياً عند جاهزية العقد',
  });

  void _goBack(BuildContext context) {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: ContractTheme.bg,
        appBar: showBackButton
            ? AppBar(
                backgroundColor: ContractTheme.bg,
                elevation: 0,
                leading: IconButton(
                  icon: const Icon(
                    Iconsax.arrow_right_3,
                    color: ContractTheme.orange,
                  ),
                  onPressed: () => _goBack(context),
                ),
              )
            : null,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF0E5),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: ContractTheme.orange.withValues(alpha: 0.25),
                    ),
                  ),
                  child: const Icon(
                    Iconsax.document_text,
                    color: ContractTheme.orange,
                    size: 42,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: ContractTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  message,
                  style: const TextStyle(
                    fontSize: 15,
                    color: ContractTheme.textSecondary,
                    height: 1.6,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: ContractTheme.orange,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      footerHint,
                      style: const TextStyle(
                        fontSize: 12,
                        color: ContractTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                TextButton(
                  onPressed: () => _goBack(context),
                  child: const Text(
                    'سأكمل لاحقاً',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: ContractTheme.orange,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        bottomNavigationBar: showSalesButton
            ? SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SalesScreen(),
                        ),
                      );
                    },
                    child: Container(
                      height: 56,
                      decoration: ContractTheme.primaryGradientButton(),
                      alignment: Alignment.center,
                      child: const Text(
                        'تواصل مع قسم المبيعات',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              )
            : null,
      ),
    );
  }
}
