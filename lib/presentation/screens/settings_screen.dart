import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/theme_provider.dart';
import '../providers/notification_provider.dart';
import '../../core/services/notification_service.dart';
import '../widgets/glass_card.dart';
import '../widgets/gradient_text.dart';
import '../../core/utils/app_theme.dart';
import '../../core/constants/colors.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (!didPop) {
          context.go('/');
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
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Expanded(
                        child: GradientText(
                          'Settings',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildThemeSection(context, ref),
                        const SizedBox(height: 16),
                        _buildNotificationSection(context, ref),
                        const SizedBox(height: 16),
                        _buildAboutSection(context),
                        const SizedBox(height: 24), // Extra space for scrolling
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildThemeSection(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);
    final themeNotifier = ref.read(themeProvider.notifier);
    
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const GradientText(
            'Appearance',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Column(
            children: [
              _buildRadioTile(
                'System Default',
                ThemeMode.system,
                themeMode,
                (mode) => themeNotifier.setThemeMode(mode),
              ),
              _buildRadioTile(
                'Light Mode',
                ThemeMode.light,
                themeMode,
                (mode) => themeNotifier.setThemeMode(mode),
              ),
              _buildRadioTile(
                'Dark Mode',
                ThemeMode.dark,
                themeMode,
                (mode) => themeNotifier.setThemeMode(mode),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationSection(BuildContext context, WidgetRef ref) {
    final notificationsEnabled = ref.watch(notificationProvider);
    final notificationNotifier = ref.read(notificationProvider.notifier);
    
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const GradientText(
            'Notifications',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          SwitchListTile(
            title: const Text(
              'IP Change Notifications',
              style: TextStyle(color: Colors.white),
            ),
            subtitle: Text(
              'Get notified when your IP address changes',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 12,
              ),
            ),
            value: notificationsEnabled,
            onChanged: (value) async {
              if (value) {
                // Request permission when enabling
                final hasPermission = await NotificationService.instance.requestNotificationPermission();
                if (!hasPermission) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Notification permission is required'),
                        backgroundColor: Colors.orange,
                      ),
                    );
                  }
                  return;
                }
              }
              await notificationNotifier.setNotificationsEnabled(value);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      value 
                        ? 'Notifications enabled' 
                        : 'Notifications disabled',
                    ),
                    backgroundColor: value ? Colors.green : Colors.grey,
                    duration: const Duration(seconds: 2),
                  ),
                );
              }
            },
            activeColor: AppColors.neonBlue,
          ),
        ],
      ),
    );
  }

  Widget _buildAboutSection(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const GradientText(
            'About',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          // App Logo with proper constraints to prevent overflow
          Center(
            child: Container(
              constraints: const BoxConstraints(
                maxWidth: 120,
                maxHeight: 120,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.asset(
                  'assets/images/app_logo.png',
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(
                      Icons.network_check,
                      size: 80,
                      color: Colors.white70,
                    );
                  },
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildInfoRow('Version', '1.0.0'),
          _buildInfoRow('Build', '1'),
          const SizedBox(height: 16),
          const Text(
            'What Is My IP - A modern network information and tools app.',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              'Powered by digdns.io',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRadioTile<T>(
    String title,
    T value,
    T groupValue,
    ValueChanged<T> onChanged,
  ) {
    return RadioListTile<T>(
      title: Text(
        title,
        style: const TextStyle(color: Colors.white),
      ),
      value: value,
      groupValue: groupValue,
      onChanged: (val) => onChanged(val as T),
      activeColor: AppColors.neonBlue,
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
