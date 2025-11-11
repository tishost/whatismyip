import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'gradient_text.dart';

/// Reusable AppBar widget for tool screens
class ToolAppBar extends StatelessWidget {
  final String title;
  final VoidCallback? onBackPressed;

  const ToolAppBar({
    super.key,
    required this.title,
    this.onBackPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: onBackPressed ?? () => context.go('/'),
          ),
          Expanded(
            child: GradientText(
              title,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

