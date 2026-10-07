import 'package:Delta/services/DioServiceCert.dart';
import 'package:Delta/services/OneSignalServices.dart';
import 'package:Delta/widgets/Order_Completed.dart';
import 'package:Delta/widgets/Order_Playing.dart';
import 'package:Delta/widgets/Order_Waiting.dart';
import 'package:Delta/widgets/order_stage_gallery.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  /// bookings.stl value (1..9)
  int get stageNumber => index + 1;
}

class _TimelineColors {
  static const orange = Color(0xFFF37021);
  static const green = Color(0xFF22C55E);
  static const greenBg = Color(0xFFEDFAF4);
  static const textPrimary = Color(0xFF1A1A2E);
  static const textSecondary = Color(0xFF888888);
  static const pendingGrey = Color(0xFFE5E7EB);
  static const border = Color(0xFFEBEBEB);
}

class OrderTimelineWidget extends StatefulWidget {
  final String currentStatus;
  final String bookId;
  final bool isAdmin;
  final ValueChanged<String>? onStageUpdated;

  const OrderTimelineWidget({
    super.key,
    required this.currentStatus,
    required this.bookId,
    this.isAdmin = false,
    this.onStageUpdated,
  });

  @override
  State<OrderTimelineWidget> createState() => _OrderTimelineWidgetState();
}

class _OrderTimelineWidgetState extends State<OrderTimelineWidget> {
  bool _sending = false;
  int? _sendingStage;

  int get _currentIndex => OrderStatus.values.indexWhere(
        (e) => e.name.toLowerCase() == widget.currentStatus.toLowerCase(),
      );

  Future<void> _sendStage(OrderStatus status) async {
    if (!widget.isAdmin || _sending) return;
    final stage = status.stageNumber;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'تفعيل المرحلة',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
          ),
          content: Text(
            'هل تريد الانتقال إلى «${status.subTitle}» وإرسالها للعميل؟\nسيتحدّث التطبيق والسيستم فوراً ويصله إشعار.',
            style: const TextStyle(height: 1.5, fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('إلغاء', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _TimelineColors.orange,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () => Navigator.pop(context, true),
              child: const Text(
                'تأكيد',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() {
      _sending = true;
      _sendingStage = stage;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final uid = prefs.getString('userId') ?? '';
      final result = await getDio().post(
        'https://daltalifts.com/app2026/sql.php?k=${DateTime.now().millisecondsSinceEpoch}',
        data: {
          'action': 'updateBookingStage',
          'uid': uid,
          'bookId': widget.bookId,
          'stage': stage,
        },
      );
      final ok = result.data['success'] == true ||
          result.data['success'] == 1 ||
          result.data['success'] == 'true';
      if (!mounted) return;
      if (!ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result.data['message']?.toString() ?? 'فشل إرسال المرحلة',
            ),
          ),
        );
        return;
      }

      // Backup push from the app (in addition to server OneSignal)
      try {
        final data = result.data['data'];
        final players = data is Map ? data['playerIds'] : null;
        final title = data is Map
            ? (data['title']?.toString() ?? status.subTitle)
            : status.subTitle;
        final body = data is Map
            ? (data['content']?.toString() ?? status.description)
            : status.description;
        if (players is List) {
          for (final p in players) {
            final id = p?.toString() ?? '';
            if (id.isEmpty) continue;
            await OneSignalNotification.sendToUser(
              subscriptionId: id,
              title: title,
              message: body,
              extra: {
                'headings': {'en': title, 'ar': title},
                'contents': {'en': body, 'ar': body},
                'data': {
                  'type': 'booking_stage',
                  'bookId': widget.bookId,
                  'stage': '$stage',
                },
              },
            );
          }
        }
      } catch (e) {
        debugPrint('Stage push backup error: $e');
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تم تفعيل «${status.subTitle}» وإرسالها للعميل ✓'),
          backgroundColor: _TimelineColors.green,
        ),
      );
      widget.onStageUpdated?.call(status.name);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('حدث خطأ أثناء إرسال المرحلة')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _sending = false;
          _sendingStage = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = _currentIndex;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'مراحل التنفيذ',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: _TimelineColors.textPrimary,
                ),
              ),
            ),
            if (widget.isAdmin)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF0E5),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'وضع الأدمن',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: _TimelineColors.orange,
                  ),
                ),
              ),
          ],
        ),
        if (widget.isAdmin) ...[
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF7ED),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFFFE0C2)),
            ),
            child: const Text(
              'اضغط على الكارد أو الدائرة لأي مرحلة عشان تنتقل ليها وتتبعت للعميل تلقائي',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF9A3412),
                height: 1.45,
              ),
            ),
          ),
        ],
        const SizedBox(height: 16),
        ...OrderStatus.values.asMap().entries.map((entry) {
          final index = entry.key;
          final status = entry.value;
          final isLast = index == OrderStatus.values.length - 1;
          final isCompleted = currentIndex >= 0 && index < currentIndex;
          final isCurrent = index == currentIndex;
          // Admin can tap ANY stage (card or circle) to jump + notify.
          final canSend = widget.isAdmin;

          return _TimelineStep(
            status: status,
            isCompleted: isCompleted,
            isCurrent: isCurrent,
            isLast: isLast,
            bookId: widget.bookId,
            isAdmin: widget.isAdmin,
            canSend: canSend,
            sending: _sending && _sendingStage == status.stageNumber,
            onSend: canSend ? () => _sendStage(status) : null,
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
  final bool isAdmin;
  final bool canSend;
  final bool sending;
  final VoidCallback? onSend;

  const _TimelineStep({
    required this.status,
    required this.isCompleted,
    required this.isCurrent,
    required this.isLast,
    required this.bookId,
    this.isAdmin = false,
    this.canSend = false,
    this.sending = false,
    this.onSend,
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

    final circle = Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: bg,
        shape: BoxShape.circle,
        border: canSend && !isCompleted
            ? Border.all(color: _TimelineColors.orange, width: 2)
            : null,
      ),
      child: sending
          ? const Padding(
              padding: EdgeInsets.all(10),
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : Icon(icon, color: iconColor, size: 20),
    );

    if (!canSend) return circle;
    return GestureDetector(
      onTap: onSend,
      behavior: HitTestBehavior.opaque,
      child: circle,
    );
  }

  Widget _buildStageCard() {
    Widget? media;
    switch (status) {
      case OrderStatus.importing:
        media = OrderStageGallery(
          bookId: bookId,
          processType: 'importing',
          isAdmin: isAdmin,
        );
        break;
      case OrderStatus.installation:
        media = OrderStageGallery(
          bookId: bookId,
          processType: 'installation',
          isAdmin: isAdmin,
          maxImages: 1,
        );
        break;
      case OrderStatus.waiting:
        media = isAdmin ? null : OrderWaiting(bookId: bookId);
        break;
      case OrderStatus.playing:
        media = OrderPlaying(bookId: bookId, isAdmin: isAdmin);
        break;
      case OrderStatus.completed:
        media = isAdmin ? null : OrderCompleted(bookId: bookId);
        break;
      default:
        media = null;
    }

    final showMedia = (isCompleted || isCurrent) && media != null;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: canSend && !isCompleted
              ? _TimelineColors.orange.withValues(alpha: 0.45)
              : _TimelineColors.border,
          width: canSend && !isCompleted ? 1.5 : 1,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            status.title,
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontSize: 11,
              color: _TimelineColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            status.subTitle,
            textAlign: TextAlign.right,
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
          if (showMedia) ...[
            const SizedBox(height: 12),
            media,
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              _buildBadge(),
              if (canSend) ...[
                const Spacer(),
                sending
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          color: _TimelineColors.orange,
                        ),
                      )
                    : GestureDetector(
                        onTap: onSend,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: _TimelineColors.orange,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'إرسال للعميل',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(width: 4),
                              Icon(
                                Iconsax.send_2,
                                size: 14,
                                color: Colors.white,
                              ),
                            ],
                          ),
                        ),
                      ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBadge() {
    if (canSend && !isCompleted && !isCurrent) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF0E5),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Text(
          'اضغط للتفعيل',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: _TimelineColors.orange,
          ),
        ),
      );
    }
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
