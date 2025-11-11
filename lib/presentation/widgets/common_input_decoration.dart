import 'package:flutter/material.dart';
import '../../../core/constants/colors.dart';

/// Common input decoration for TextFields across tool screens
class CommonInputDecoration {
  static InputDecoration textField({
    required String labelText,
    String? hintText,
    String? helperText,
  }) {
    return InputDecoration(
      labelText: labelText,
      labelStyle: TextStyle(
        color: Colors.white.withOpacity(0.7),
      ),
      hintText: hintText,
      hintStyle: TextStyle(
        color: Colors.white.withOpacity(0.5),
      ),
      helperText: helperText,
      helperStyle: TextStyle(
        color: Colors.white.withOpacity(0.6),
        fontSize: 12,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: Colors.white.withOpacity(0.3),
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: Colors.white.withOpacity(0.3),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: AppColors.neonBlue,
          width: 2,
        ),
      ),
    );
  }
}

