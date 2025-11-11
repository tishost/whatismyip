import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class BackButtonState {
  final DateTime? lastBackPressTime;
  final bool isHandlingBackPress;
  final List<String> protectedRoutes;

  BackButtonState({
    this.lastBackPressTime,
    this.isHandlingBackPress = false,
    List<String>? protectedRoutes,
  }) : protectedRoutes = protectedRoutes ?? ['/', '/home'];

  BackButtonState copyWith({
    DateTime? lastBackPressTime,
    bool? isHandlingBackPress,
    List<String>? protectedRoutes,
  }) {
    return BackButtonState(
      lastBackPressTime: lastBackPressTime ?? this.lastBackPressTime,
      isHandlingBackPress: isHandlingBackPress ?? this.isHandlingBackPress,
      protectedRoutes: protectedRoutes ?? this.protectedRoutes,
    );
  }
}

class BackButtonNotifier extends StateNotifier<BackButtonState> {
  BackButtonNotifier() : super(BackButtonState());

  /// Handle back button press with double-tap-to-exit logic
  /// Returns true if back press was handled (should prevent default behavior)
  /// Returns false if app should exit (double-tap confirmed)
  Future<bool> handleBackPress(
    BuildContext context,
    String currentPath, {
    StatefulNavigationShell? navigationShell,
  }) async {
    if (state.isHandlingBackPress) {
      return true;
    }

    state = state.copyWith(isHandlingBackPress: true);

    try {
      // If not on home tab, navigate to home tab
      if (navigationShell != null) {
        final currentIndex = navigationShell.currentIndex;
        if (currentIndex != 0) {
          navigationShell.goBranch(0);
          return true;
        }
      }

      // Check if Navigator can pop (e.g., from a dialog or another screen)
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
        return true;
      }

      // Check if current route is protected (requires double-tap to exit)
      if (state.protectedRoutes.contains(currentPath)) {
        final now = DateTime.now();

        // First press or more than 2 seconds since last press - show snackbar
        if (state.lastBackPressTime == null ||
            now.difference(state.lastBackPressTime!) > const Duration(seconds: 2)) {
          state = state.copyWith(lastBackPressTime: now);

          // Show snackbar on first press
          if (context.mounted) {
            final messenger = ScaffoldMessenger.maybeOf(context);
            if (messenger != null) {
              messenger.removeCurrentSnackBar();
              messenger.showSnackBar(
                SnackBar(
                  content: const Text('Press back again to exit'),
                  duration: const Duration(seconds: 2),
                  backgroundColor: Colors.orange,
                  behavior: SnackBarBehavior.floating,
                  margin: const EdgeInsets.all(20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              );
            }
          }

          return true; // Prevent default system back behavior
        }

        // Second press within 2 seconds - allow exit
        return false; // Allow system exit (double-tap confirmed)
      }

      // Not a protected route - allow default behavior
      return false;
    } finally {
      // Reset flag after a short delay
      Future.delayed(const Duration(milliseconds: 100), () {
        state = state.copyWith(isHandlingBackPress: false);
      });
    }
  }

  /// Reset the last back press time (useful when navigating away)
  void resetLastBackPressTime() {
    state = state.copyWith(lastBackPressTime: null);
  }

  /// Add a protected route that requires double-tap to exit
  void addProtectedRoute(String route) {
    if (!state.protectedRoutes.contains(route)) {
      final updatedRoutes = List<String>.from(state.protectedRoutes)..add(route);
      state = state.copyWith(protectedRoutes: updatedRoutes);
    }
  }

  /// Remove a protected route
  void removeProtectedRoute(String route) {
    final updatedRoutes = List<String>.from(state.protectedRoutes)..remove(route);
    state = state.copyWith(protectedRoutes: updatedRoutes);
  }
}

final backButtonProvider = StateNotifierProvider<BackButtonNotifier, BackButtonState>((ref) {
  return BackButtonNotifier();
});
