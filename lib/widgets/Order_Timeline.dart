import 'package:Delta/widgets/Order_Completed.dart';
import 'package:Delta/widgets/Order_Importing.dart';
import 'package:Delta/widgets/Order_Installation.dart';
import 'package:Delta/widgets/Order_Playing.dart';
import 'package:Delta/widgets/Order_Waiting.dart';
import 'package:flutter/material.dart';

// ═══════════════════════════════════════════
//  نموذج البيانات
// ═══════════════════════════════════════════
enum OrderStatus {
  contracting(
    title: 'المرحلة الأولى',
    subTitle: 'مرحلة التعاقد',
    description: 'تم توقيع العقد وجاري مراجعة كافة البنود والمتطلبات',
  ),
  ordering(
    title: 'المرحلة الثانية',
    subTitle: 'طلب المصعد من المصنع',
    description: 'تم إرسال طلب التصنيع للمصنع بكافة المواصفات المطلوبة',
  ),
  manufacturing(
    title: 'المرحلة الثالثة',
    subTitle: 'تصنيع المصعد',
    description: 'المصنع يقوم حالياً بتصنيع مصعدك وفق المواصفات المتفق عليها',
  ),
  readyForDelivery(
    title: 'المرحلة الرابعة',
    subTitle: 'شحن المصعد',
    description: 'تم الانتهاء من التصنيع وجاري شحن المصعد من المصنع إلى الموقع',
  ),
  importing(
    title: 'المرحلة الخامسة',
    subTitle: 'توريد المصعد',
    description:
        'وصل المصعد إلى الموقع وجاري استلام كافة المكونات والتحقق منها',
  ),
  installation(
    title: 'المرحلة السادسة',
    subTitle: 'تركيب المصعد ميكانيكياً',
    description: 'يقوم فريقنا الفني بتركيب جميع الأجزاء الميكانيكية للمصعد',
  ),
  waiting(
    title: 'المرحلة السابعة',
    subTitle: 'انتظار دخول الكهرباء للعقار',
    description:
        'اكتمل التركيب الميكانيكي وننتظر توصيل الكهرباء للعقار لاستكمال التشغيل',
  ),
  playing(
    title: 'المرحلة الثامنة',
    subTitle: 'تشغيل المصعد',
    description: 'جاري تشغيل المصعد واختباره والتأكد من سلامة كافة الأنظمة',
  ),
  completed(
    title: 'المرحلة النهائية',
    subTitle: 'تسليم المصعد',
    description:
        'تم تسليم المصعد بنجاح ويعمل بكفاءة تامة، نتمنى لكم تجربة موفقة',
  );

  final String title;
  final String subTitle;
  final String description;

  const OrderStatus({
    required this.title,
    required this.subTitle,
    required this.description,
  });
}
bool isEnabled = false;
// ═══════════════════════════════════════════
//  الألوان
// ═══════════════════════════════════════════
class AppColors {
  static const Color primary = Color(0xFF5C6BC0); // بنفسجي مثل الـ mockup
  static const Color doneColor = Color(0xFF4CAF82); // أخضر
  static const Color grayColor = Color(0xFF9E9E9E);
  static const Color pendingBg = Color(0xFFF5F5F5);
  static const Color doneBg = Color(0xFFEDF7F2);
}

// ═══════════════════════════════════════════
//  الشاشة الرئيسية - مثال للاستخدام
// ═══════════════════════════════════════════
void main() {
  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(fontFamily: 'Cairo'),
      home: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          backgroundColor: const Color(0xFFF0F2FF),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // مثال: المرحلة الثانية هي الحالية
                  OrderTimelineWidget(currentStatus: 'processing', bookId: '0',),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

// ═══════════════════════════════════════════
//  الويدجت الرئيسي للمراحل
// ═══════════════════════════════════════════
class OrderTimelineWidget extends StatelessWidget {
  /// currentStatus: اسم الـ enum مثلاً 'processing' أو 'completed'
  final String currentStatus;
  final String bookId;

  const OrderTimelineWidget({super.key, required this.currentStatus, required this.bookId});

  @override
  Widget build(BuildContext context) {
    
    // إيجاد الـ index الحالي
    final currentIndex = OrderStatus.values.indexWhere(
      (e) => e.name.toLowerCase() == currentStatus.toLowerCase(),
    );

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // عنوان القسم
          const Text(
            'مراحل التنفيذ',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1A1A2E),
            ),
          ),
          const SizedBox(height: 20),

          // المراحل
          ...OrderStatus.values.asMap().entries.map((entry) {
            final index = entry.key;
            final status = entry.value;
            final isActive = index <= currentIndex;
            final isCurrent = index == currentIndex;
            final isLast = index == OrderStatus.values.length - 1;

            return _TimelineStep(
              status: status,
              isActive: isActive,
              isCurrent: isCurrent,
              isLast: isLast,
              bookId: bookId
            );
          }),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════
//  كل خطوة في الـ Timeline
// ═══════════════════════════════════════════
class _TimelineStep extends StatelessWidget {
  final OrderStatus status;
  final bool isActive;
  final bool isCurrent;
  final bool isLast;
  final String bookId;

  const _TimelineStep({
    required this.status,
    required this.isActive,
    required this.isCurrent,
    required this.isLast,
    required this.bookId,
  });

  @override
  Widget build(BuildContext context) {
    
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ═══ العمود اليمين: الأيقونة + الخط ═══
          Column(
            children: [
              // الأيقونة الدائرية
              _buildIcon(),

              // الخط الواصل (إلا في الخطوة الأخيرة)
              if (!isLast)
              
                Expanded(
                  child: Container(
                    width: 2.5,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    decoration: BoxDecoration(
                      gradient: isActive
                          ? const LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [AppColors.doneColor, Color(0xFFB2DFDB)],
                            )
                          : null,
                      color: isActive ? null : const Color(0xFFE0E0E0),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(width: 16),

          // ═══ العمود الشمال: المحتوى ═══
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: _buildContent(bookId),
            ),
          ),
        ],
      ),
    );
  }

  // ── الأيقونة ──
  Widget _buildIcon() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: isActive ? AppColors.doneColor : Colors.white,
        border: isActive
            ? null
            : Border.all(color: const Color(0xFFDDDDDD), width: 2),
        borderRadius: BorderRadius.circular(14),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: AppColors.doneColor.withOpacity(0.35),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ]
            : [],
      ),
      child: Icon(
        isActive ? Icons.check_rounded : Icons.arrow_back_ios_rounded,
        color: isActive ? Colors.white : AppColors.grayColor,
        size: 18,
      ),
    );
  }

  // ── المحتوى ──
  Widget _buildContent(bookId) {
    Widget caseContainer = Container();
    switch (status.toString()) {
      case 'OrderStatus.importing':
        isEnabled = true;
        caseContainer = OrderImporting(bookId: bookId,);
        break;
      case 'OrderStatus.installation':
        isEnabled = true;
        caseContainer = OrderInstallation(bookId: bookId);
        break;
      case 'OrderStatus.waiting':
        isEnabled = true;
        caseContainer = OrderWaiting(bookId: bookId);
        break;
      case 'OrderStatus.playing':
        isEnabled = true;
        caseContainer = OrderPlaying(bookId: bookId);
        break;
      case 'OrderStatus.completed':
        isEnabled = true;
        caseContainer = OrderCompleted(bookId: bookId,);
        break;
      default:
        isEnabled = false;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // العنوان الصغير (المرحلة الأولى، الثانية...)
        Text(
          status.title,
          style: TextStyle(
            fontSize: 12,
            color: isActive ? AppColors.doneColor : AppColors.grayColor,
            fontWeight: FontWeight.w500,
          ),
        ),

        const SizedBox(height: 2),

        // العنوان الرئيسي
        Text(
          status.subTitle,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: isActive ? const Color(0xFF1A1A2E) : AppColors.grayColor,
          ),
        ),

        const SizedBox(height: 4),

        // الوصف
        Text(
          status.description,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.grayColor,
            height: 1.5,
          ),
        ),

        const SizedBox(height: 10),

        // الـ Badge (اكتمل / قيد الانتظار)
        Row(
          children: [
            _buildBadge(),
            SizedBox(width: 10,),
            Visibility(
              visible: isActive && isEnabled,
              child: caseContainer)
          ],
        )
      ],
    );
  }

  // ── الـ Badge ──
  Widget _buildBadge() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: isActive
            ? AppColors.doneColor.withOpacity(0.08)
            : AppColors.pendingBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isActive
              ? AppColors.doneColor.withOpacity(0.2)
              : const Color(0xFFEEEEEE),
          width: 1,
        ),
      ),
      child: Text(
        isActive ? 'اكتمل' : 'قيد الانتظار',
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: isActive ? AppColors.doneColor : AppColors.grayColor,
        ),
      ),
    );
  }
}
