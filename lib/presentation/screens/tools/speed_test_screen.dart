import 'package:flutter/material.dart';
import 'dart:math';

import '../../widgets/glass_card.dart';
import '../../widgets/gradient_text.dart';
import '../../../core/utils/app_theme.dart';
import '../../../core/constants/colors.dart';

class SpeedTestScreen extends StatefulWidget {
  const SpeedTestScreen({super.key});

  @override
  State<SpeedTestScreen> createState() => _SpeedTestScreenState();
}

class _SpeedTestScreenState extends State<SpeedTestScreen> {
  bool _isTesting = false;
  double _downloadSpeed = 0; // Mbps
  double _uploadSpeed = 0; // Mbps
  double _ping = 0; // ms
  String _status = 'Ready to test';

  Future<void> _startSpeedTest() async {
    setState(() {
      _isTesting = true;
      _downloadSpeed = 0;
      _uploadSpeed = 0;
      _ping = 0;
      _status = 'Testing ping...';
    });

    // Simulate ping test
    await Future.delayed(const Duration(seconds: 2));
    setState(() {
      _ping = 20 + Random().nextDouble() * 30;
      _status = 'Testing download speed...';
    });

    // Simulate download test
    for (int i = 0; i < 10; i++) {
      await Future.delayed(const Duration(milliseconds: 300));
      setState(() {
        _downloadSpeed = (i + 1) * 5.0 + Random().nextDouble() * 2;
      });
    }

    setState(() {
      _status = 'Testing upload speed...';
    });

    // Simulate upload test
    for (int i = 0; i < 10; i++) {
      await Future.delayed(const Duration(milliseconds: 300));
      setState(() {
        _uploadSpeed = (i + 1) * 2.0 + Random().nextDouble() * 1;
      });
    }

    setState(() {
      _isTesting = false;
      _status = 'Test completed!';
    });

    // Note: This is a simulation. For real speed test, integrate with:
    // - Fast.com API
    // - Speedtest.net API
    // - Or implement your own backend
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: AppTheme.gradientBackground(),
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(),
              Expanded(
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GlassCard(
                        child: Column(
                          children: [
                            Text(
                              _status,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 24),
                            ElevatedButton.icon(
                              onPressed: _isTesting ? null : _startSpeedTest,
                              icon: _isTesting
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                                Colors.white),
                                      ),
                                    )
                                  : const Icon(Icons.speed),
                              label: Text(_isTesting
                                  ? 'Testing...'
                                  : 'Start Speed Test'),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      _buildSpeedCard(
                        'Download Speed',
                        _downloadSpeed,
                        'Mbps',
                        Icons.download,
                        Colors.green,
                      ),
                      const SizedBox(height: 16),
                      _buildSpeedCard(
                        'Upload Speed',
                        _uploadSpeed,
                        'Mbps',
                        Icons.upload,
                        Colors.blue,
                      ),
                      const SizedBox(height: 16),
                      _buildSpeedCard(
                        'Ping',
                        _ping,
                        'ms',
                        Icons.network_ping,
                        Colors.orange,
                      ),
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

  Widget _buildSpeedCard(
    String title,
    double value,
    String unit,
    IconData icon,
    Color color,
  ) {
    return GlassCard(
      child: Column(
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 32),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${value.toStringAsFixed(2)} $unit',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (_isTesting && value > 0) ...[
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: value / 100,
              backgroundColor: Colors.white.withOpacity(0.2),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          Expanded(
            child: GradientText(
              'Speed Test',
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
