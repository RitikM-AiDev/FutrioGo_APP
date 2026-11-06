import 'package:flutter/material.dart';
import '../theme/colors.dart';
import 'nc_logo.dart';

class ThinkingBubble extends StatefulWidget {
  const ThinkingBubble({super.key});

  @override
  State<ThinkingBubble> createState() => _ThinkingBubbleState();
}

class _ThinkingBubbleState extends State<ThinkingBubble>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _buildDot(int index, Color color) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final delay = index * 0.25;
        final value = (_controller.value - delay) % 1.0;
        final scale = 0.5 + 0.5 * (1.0 - (value - 0.5).abs() * 2.0);
        final opacity = 0.3 + 0.7 * (1.0 - (value - 0.5).abs() * 2.0);

        return Transform.scale(
          scale: scale.clamp(0.6, 1.2),
          child: Container(
            width: 7,
            height: 7,
            margin: const EdgeInsets.symmetric(horizontal: 2.5),
            decoration: BoxDecoration(
              color: color.withValues(alpha: opacity.clamp(0.3, 1.0)),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.5),
                  blurRadius: 4,
                  spreadRadius: 0.5,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Padding(
            padding: EdgeInsets.only(right: 8.0),
            child: NCLogo(size: 28, glowing: true),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
            decoration: BoxDecoration(
              color: AppColors.cardSurface,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
                bottomLeft: Radius.circular(4),
                bottomRight: Radius.circular(16),
              ),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.4),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  blurRadius: 10,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDot(0, const Color(0xFF4285F4)),
                _buildDot(1, const Color(0xFF9B72CB)),
                _buildDot(2, const Color(0xFFD96570)),
                const SizedBox(width: 8),
                const Text(
                  'Thinking...',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

