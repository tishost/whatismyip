import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/utils/app_theme.dart';
import 'tool_app_bar.dart';

/// Reusable wrapper for tool screens with common structure
class ToolScreenWrapper extends StatelessWidget {
  final String title;
  final Widget child;
  final VoidCallback? onBackPressed;
  final bool showAppBar;

  const ToolScreenWrapper({
    super.key,
    required this.title,
    required this.child,
    this.onBackPressed,
    this.showAppBar = true,
  });

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (!didPop) {
          if (onBackPressed != null) {
            onBackPressed!();
          } else {
            context.go('/');
          }
        }
      },
      child: Scaffold(
        body: Container(
          decoration: AppTheme.gradientBackground(
            brightness: Theme.of(context).brightness,
          ),
          child: SafeArea(
            child: Column(
              children: [
                if (showAppBar)
                  ToolAppBar(
                    title: title,
                    onBackPressed: onBackPressed,
                  ),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: child,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

