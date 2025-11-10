import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../constants/colors.dart';

class AnimationUtils {
  static Widget fadeIn({
    required Widget child,
    Duration duration = const Duration(milliseconds: 500),
  }) {
    return child.animate().fadeIn(duration: duration);
  }

  static Widget slideIn({
    required Widget child,
    Duration duration = const Duration(milliseconds: 500),
    Offset begin = const Offset(0, 0.1),
  }) {
    return child.animate().slide(begin: begin, duration: duration);
  }

  static Widget shimmer({
    required Widget child,
    Duration duration = const Duration(seconds: 2),
  }) {
    return child.animate().shimmer(
      duration: duration,
      color: AppColors.neonBlue.withOpacity(0.3),
    );
  }

  static Widget scale({
    required Widget child,
    Duration duration = const Duration(milliseconds: 300),
    double begin = 0.8,
  }) {
    return child.animate().scale(
      begin: Offset(begin, begin),
      duration: duration,
    );
  }
}

