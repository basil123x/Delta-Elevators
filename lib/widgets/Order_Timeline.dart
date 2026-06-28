import 'package:Delta/widgets/Order_Completed.dart';
import 'package:Delta/widgets/Order_Importing.dart';
import 'package:Delta/widgets/Order_Installation.dart';
import 'package:Delta/widgets/Order_Playing.dart';
import 'package:Delta/widgets/Order_Waiting.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

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

class _TimelineColors {
  static const orange = Color(0xFFF37021);
  static const green = Color(0xFF22C55E);
  static const greenBg = Color(0xFFEDFAF4);
  static const textPrimary = Color(0xFF1A1A2E);
  static const textSecondary = Color(0xFF888888);
  static const pendingGrey = Color(0xFFE5E7EB);
  static const border = Color(0xFFEBEBEB);
}

class OrderTimelineWidget extends StatelessWidget {
  final String currentStatus;
  final String bookId;

  const OrderTimelineWidget({
    super.key,
    required this.currentStatus,
    required this.bookId,
  });

  @override
  Widget build(BuildContext context) {
    final currentIndex = OrderStatus.values.indexWhere(
      (e) => e.name.toLowerCase() == currentStatus.toLowerCase(),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'مراحل التنفيذ',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: _TimelineColors.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        ...OrderStatus.values.asMap().entries.map((entry) {
          final index = entry.key;
          final status = entry.value;
          final isLast = index == OrderStatus.values.length - 1;
          final isCompleted = currentIndex >= 0 && index < currentIndex;
          final isCurrent = index == currentIndex;

          return _TimelineStep(
            status: status,
            isCompleted: isCompleted,
            isCurrent: isCurrent,
            isLast: isLast,
            bookId: bookId,
          );
        }),
      ],
    );
  }
}

class _TimelineStep extends StatelessWidget {
  final OrderStatus status;
  final bool isCompleted;
  final bool isCurrent;
  final bool isLast;
  final String bookId;

  const _TimelineStep({
    required this.status,
    required this.isCompleted,
    required this.isCurrent,
    required this.isLast,
    required this.bookId,
  });

  bool get _isPending => !isCompleted && !isCurrent;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              _buildCircle(),
              if (!isLast)
                Expanded(child: _TimelineConnector(solidGreen: isCompleted)),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _buildStageCard(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCircle() {
    Color bg;
    IconData icon;
    Color iconColor = Colors.white;

    if (isCompleted) {
      bg = _TimelineColors.green;
      icon = Iconsax.tick_circle;
    } else if (isCurrent) {
      bg = _TimelineColors.orange;
      icon = Iconsax.clock;
    } else {
      bg = _TimelineColors.pendingGrey;
      icon = Iconsax.minus_cirlce;
      iconColor = _TimelineColors.textSecondary;
    }

    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
      child: Icon(icon, color: iconColor, size: 20),
    );
  }

  Widget _buildStageCard() {
    Widget caseContainer = const SizedBox.shrink();
    switch (status.toString()) {
      case 'OrderStatus.importing':
        isEnabled = true;
        caseContainer = OrderImporting(bookId: bookId);
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
        caseContainer = OrderCompleted(bookId: bookId);
        break;
      default:
        isEnabled = false;
    }

    final showActions = (isCompleted || isCurrent) && isEnabled;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _TimelineColors.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            status.title,
            style: const TextStyle(
              fontSize: 11,
              color: _TimelineColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            status.subTitle,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: _isPending
                  ? _TimelineColors.textSecondary
                  : _TimelineColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            status.description,
            style: const TextStyle(
              fontSize: 13,
              color: _TimelineColors.textSecondary,
              height: 1.5,
            ),
            textAlign: TextAlign.right,
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _buildBadge(),
              if (showActions) ...[
                const SizedBox(width: 10),
                Flexible(child: caseContainer),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBadge() {
    final done = isCompleted || isCurrent;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: done ? _TimelineColors.greenBg : const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        done ? 'اكتمل' : 'قيد الانتظار',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: done ? _TimelineColors.green : _TimelineColors.textSecondary,
        ),
      ),
    );
  }
}

class _TimelineConnector extends StatelessWidget {
  final bool solidGreen;

  const _TimelineConnector({required this.solidGreen});

  @override
  Widget build(BuildContext context) {
    if (solidGreen) {
      return Container(
        width: 2,
        margin: const EdgeInsets.symmetric(vertical: 4),
        color: _TimelineColors.green,
      );
    }
    return CustomPaint(
      painter: _DashedLinePainter(color: _TimelineColors.pendingGrey),
      child: Container(
        width: 2,
        margin: const EdgeInsets.symmetric(vertical: 4),
      ),
    );
  }
}

class _DashedLinePainter extends CustomPainter {
  final Color color;

  _DashedLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    const dashHeight = 6.0;
    const gap = 4.0;
    double y = 0;
    while (y < size.height) {
      canvas.drawLine(
        Offset(size.width / 2, y),
        Offset(size.width / 2, y + dashHeight),
        paint,
      );
      y += dashHeight + gap;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
