// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';

class AppBackground extends StatelessWidget {
  final Widget child;

  const AppBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFF6F3EE),
            Color(0xFFEFF4F2),
            Color(0xFFF4EEE6),
          ],
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          const _GlowBlob(
            alignment: Alignment(-1.2, -1.1),
            color: Color(0xFFBFE7E1),
            size: 220,
          ),
          const _GlowBlob(
            alignment: Alignment(1.2, -0.9),
            color: Color(0xFFF5D6A3),
            size: 200,
          ),
          const _GlowBlob(
            alignment: Alignment(1.1, 1.2),
            color: Color(0xFFC9DDF2),
            size: 240,
          ),
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
