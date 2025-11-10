import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/theme_provider.dart';
import '../widgets/glass_card.dart';
import '../widgets/gradient_text.dart';
import '../../core/utils/app_theme.dart';
import '../../core/constants/colors.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: AppTheme.gradientBackground(),
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
                      _buildThemeSection(context),
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
    );
  }

  Widget _buildThemeSection(BuildContext context) {
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
          Consumer<ThemeProvider>(
            builder: (context, themeProvider, child) {
              return Column(
                children: [
                  _buildRadioTile(
                    'System Default',
                    ThemeMode.system,
                    themeProvider.themeMode,
                    (mode) => themeProvider.setThemeMode(mode),
                  ),
                  _buildRadioTile(
                    'Light Mode',
                    ThemeMode.light,
                    themeProvider.themeMode,
                    (mode) => themeProvider.setThemeMode(mode),
                  ),
                  _buildRadioTile(
                    'Dark Mode',
                    ThemeMode.dark,
                    themeProvider.themeMode,
                    (mode) => themeProvider.setThemeMode(mode),
                  ),
                ],
              );
            },
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
