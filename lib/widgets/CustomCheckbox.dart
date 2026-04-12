import 'package:flutter/material.dart';

class CustomCheckbox extends StatefulWidget {
  final String label;
  final bool initialValue;
  final ValueChanged<bool>? onChanged;

  const CustomCheckbox({
    super.key,
    required this.label,
    this.initialValue = false,
    this.onChanged,
  });

  @override
  State<CustomCheckbox> createState() => _CustomCheckboxState();
}

class _CustomCheckboxState extends State<CustomCheckbox>
    with SingleTickerProviderStateMixin {
  late bool _checked;
  late AnimationController _controller;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    _checked = widget.initialValue;
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.85).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() async {
    await _controller.forward();
    await _controller.reverse();
    setState(() => _checked = !_checked);
    widget.onChanged?.call(_checked);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _toggle,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            // الـ Checkbox
            ScaleTransition(
              scale: _scaleAnim,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: _checked ? const Color(0xFF1D9E75) : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: _checked
                        ? const Color(0xFF1D9E75)
                        : Colors.grey.shade400,
                    width: 2,
                  ),
                ),
                child: _checked
                    ? const Icon(Icons.check, color: Colors.white, size: 16)
                    : null,
              ),
            ),
            const SizedBox(width: 12),
            // النص
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.label,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w600)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}