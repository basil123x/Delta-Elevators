import 'package:Delta/screens/booking/contract/contract_theme.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

class QuantityCounter extends StatefulWidget {
  final int initialValue;
  final int min;
  final int max;
  final ValueChanged<int>? onChanged;

  const QuantityCounter({
    super.key,
    this.initialValue = 0,
    this.min = 0,
    this.max = 99,
    this.onChanged,
  });

  @override
  State<QuantityCounter> createState() => _QuantityCounterState();
}

class _QuantityCounterState extends State<QuantityCounter>
    with SingleTickerProviderStateMixin {
  late int _value;
  late AnimationController _controller;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _value = widget.initialValue;
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
    _scaleAnim = Tween(
      begin: 1.0,
      end: 1.25,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _change(int delta) {
    final next = (_value + delta).clamp(widget.min, widget.max);
    if (next == _value) return;
    setState(() => _value = next);
    widget.onChanged?.call(_value);
    _controller.forward(from: 0).then((_) => _controller.reverse());
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _CounterButton(
          icon: Iconsax.minus,
          onTap: () => _change(-1),
          enabled: _value > widget.min,
        ),
        const SizedBox(width: 16),
        ScaleTransition(
          scale: _scaleAnim,
          child: Container(
            width: 64,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFFFFF0E5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: ContractTheme.border),
            ),
            alignment: Alignment.center,
            child: Text(
              '$_value',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: ContractTheme.orange,
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        _CounterButton(
          icon: Iconsax.add,
          onTap: () => _change(1),
          enabled: _value < widget.max,
        ),
      ],
    );
  }
}

class _CounterButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool enabled;

  const _CounterButton({
    required this.icon,
    required this.onTap,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: enabled ? 1.0 : 0.35,
      duration: const Duration(milliseconds: 150),
      child: GestureDetector(
        onTap: enabled ? onTap : null,
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFFFFF0E5),
            border: Border.all(
              color: ContractTheme.orange.withOpacity(0.35),
              width: 1.5,
            ),
          ),
          child: Icon(icon, size: 22, color: ContractTheme.orange),
        ),
      ),
    );
  }
}
