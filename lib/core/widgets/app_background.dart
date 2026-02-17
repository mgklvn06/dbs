// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';

class AppBackground extends StatelessWidget {
  final Widget child;

  const AppBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final gradientColors = isDark
        ? const [Color(0xFF0D141B), Color(0xFF0F1B1A), Color(0xFF1A1410)]
        : const [Color(0xFFF6F3EE), Color(0xFFEFF4F2), Color(0xFFF4EEE6)];
    final blobA = isDark ? const Color(0xFF1F4D46) : const Color(0xFFBFE7E1);
    final blobB = isDark ? const Color(0xFF5A4124) : const Color(0xFFF5D6A3);
    final blobC = isDark ? const Color(0xFF253A55) : const Color(0xFFC9DDF2);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradientColors,
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          _GlowBlob(alignment: Alignment(-1.2, -1.1), color: blobA, size: 220),
          _GlowBlob(alignment: Alignment(1.2, -0.9), color: blobB, size: 200),
          _GlowBlob(alignment: Alignment(1.1, 1.2), color: blobC, size: 240),
          child,
        ],
      ),
    );
  }
}

class _GlowBlob extends StatelessWidget {
  final Alignment alignment;
  final Color color;
  final double size;

  const _GlowBlob({
    required this.alignment,
    required this.color,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color.withOpacity(0.35),
          borderRadius: BorderRadius.circular(size),
        ),
      ),
    );
  }
}
