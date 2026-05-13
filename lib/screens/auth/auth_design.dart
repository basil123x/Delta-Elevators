import 'dart:convert';

import 'package:flutter/material.dart';

/// Shared visual tokens for auth screens.
abstract final class AuthDesign {
  static const Color background = Colors.white;
  static const Color orange = Color(0xFFF37021);
  static const Color textDark = Color(0xFF1A1A2E);
  static const Color fieldFill = Color(0xFFF7F7F7);
  static const double fieldRadius = 16;
  static const String logoAsset = 'assets/images/logo.png';
}

/// Normalizes Dio `result.data` to a Map so `['success']` never uses a String as list index.
Map<String, dynamic> authResponseAsMap(dynamic data) {
  if (data is Map<String, dynamic>) return data;
  if (data is Map) return Map<String, dynamic>.from(data);
  if (data is String) {
    try {
      final decoded = jsonDecode(data);
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
    } catch (_) {}
  }
  if (data is List && data.isNotEmpty && data.first is Map) {
    return Map<String, dynamic>.from(data.first as Map);
  }
  return {};
}

/// Safe row index when API returns `id` as String.
class AuthEnterAnimation extends StatefulWidget {
  const AuthEnterAnimation({super.key, required this.child});

  final Widget child;

  @override
  State<AuthEnterAnimation> createState() => _AuthEnterAnimationState();
}

class _AuthEnterAnimationState extends State<AuthEnterAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 300),
  );
  late final Animation<double> _fade = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOut,
  );
  late final Animation<Offset> _slide = Tween<Offset>(
    begin: const Offset(0, 0.06),
    end: Offset.zero,
  ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

  @override
  void initState() {
    super.initState();
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(position: _slide, child: widget.child),
    );
  }
}
