import 'package:flutter/material.dart';
import '../theme/colors.dart';

class NCLogo extends StatelessWidget {
  final double size;
  final bool glowing;

  const NCLogo({
    super.key,
    this.size = 36.0,
    this.glowing = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: [
            AppColors.primary,
            AppColors.accent,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: glowing
            ? [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.5),
                  blurRadius: 10,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
      alignment: Alignment.center,
      child: Text(
        'NC',
        style: TextStyle(
          color: Colors.white,
          fontSize: size * 0.42,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

