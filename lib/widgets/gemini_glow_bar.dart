import 'package:flutter/material.dart';
import '../theme/colors.dart';

class GeminiGlowBar extends StatefulWidget {
  final bool isAnimated;
  final double height;

  const GeminiGlowBar({
    super.key,
    this.isAnimated = true,
    this.height = 3.5,
  });

  @override
  State<GeminiGlowBar> createState() => _GeminiGlowBarState();
}

class _GeminiGlowBarState extends State<GeminiGlowBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isAnimated) {
      return Container(
        height: widget.height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(widget.height),
          gradient: const LinearGradient(
            colors: AppColors.geminiRainbow,
          ),
        ),
      );
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.height),
            gradient: LinearGradient(
              colors: const [
                Color(0xFF4285F4), // Blue
                Color(0xFF9B72CB), // Purple
                Color(0xFFD96570), // Red/Pink
                Color(0xFFF4A261), // Orange/Gold
                Color(0xFF4285F4), // Loop back
              ],
              stops: const [0.0, 0.25, 0.5, 0.75, 1.0],
              transform: GradientRotation(_controller.value * 2 * 3.14159),
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF9B72CB).withOpacity(0.5),
                blurRadius: 8,
                spreadRadius: 1,
              ),
              BoxShadow(
                color: const Color(0xFF4285F4).withOpacity(0.4),
                blurRadius: 14,
                spreadRadius: 2,
              ),
            ],
          ),
        );
      },
    );
  }
}

