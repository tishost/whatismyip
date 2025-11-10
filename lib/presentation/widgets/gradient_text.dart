import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import '../../core/constants/colors.dart';

class GradientText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final Gradient? gradient;

  const GradientText(
    this.text, {
    super.key,
    this.style,
    this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (bounds) => (gradient ?? const LinearGradient(
        colors: [AppColors.neonBlue, AppColors.neonPurple],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      )).createShader(
        Rect.fromLTWH(0, 0, bounds.width, bounds.height),
      ),
      blendMode: BlendMode.srcATop,
      child: Text(
        text,
        style: (style ?? const TextStyle()).copyWith(
          color: Colors.white,
          shadows: [
            Shadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
      ),
    );
  }
}

