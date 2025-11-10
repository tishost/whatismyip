import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/constants/app_constants.dart';

class AnimatedIpText extends StatelessWidget {
  final String text;
  final TextStyle? style;

  const AnimatedIpText({
    super.key,
    required this.text,
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: style,
    )
        .animate()
        .fadeIn(duration: AppConstants.typewriterDuration)
        .then()
        .shimmer(
          duration: const Duration(seconds: 2),
          color: Colors.white70,
        );
  }
}

