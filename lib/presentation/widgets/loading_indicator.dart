import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';

/// Reusable loading indicator widget
class CommonLoadingIndicator extends StatelessWidget {
  final Color? color;
  final double? size;

  const CommonLoadingIndicator({
    super.key,
    this.color,
    this.size,
  });

  @override
  Widget build(BuildContext context) {
    if (size != null) {
      return SizedBox(
        width: size,
        height: size,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(
            color ?? AppColors.neonBlue,
          ),
        ),
      );
    }
    return CircularProgressIndicator(
      color: color ?? AppColors.neonBlue,
    );
  }
}

