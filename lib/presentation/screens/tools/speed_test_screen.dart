import 'package:flutter/material.dart';
import 'dart:async';

import '../../widgets/glass_card.dart';
import '../../widgets/tool_screen_wrapper.dart';
import '../../widgets/loading_indicator.dart';
import '../../../core/services/speed_test_service.dart';

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

    try {
      if (!mounted) return;
      
      // Test Ping
      final pingResult = await SpeedTestService.testPing('google.com');
      if (!mounted) return;
      
      if (pingResult > 0) {
        setState(() {
          _ping = pingResult;
          _status = 'Testing download speed...';
        });
      } else {
        setState(() {
          _ping = 0;
          _status = 'Ping test failed, continuing...';
        });
      }

      // Test Download Speed
      final downloadResult = await SpeedTestService.testDownloadSpeedSimple(
        onProgress: (speed) {
          if (mounted) {
            setState(() {
              _downloadSpeed = speed;
            });
          }
        },
        durationSeconds: 10,
      );

      if (!mounted) return;

      if (downloadResult > 0) {
        setState(() {
          _downloadSpeed = downloadResult;
          _status = 'Testing upload speed...';
        });
      } else {
        setState(() {
          _status = 'Download test completed with limited data';
        });
      }

      // Test Upload Speed
      final uploadResult = await SpeedTestService.testUploadSpeed(
        onProgress: (speed) {
          if (mounted) {
            setState(() {
              _uploadSpeed = speed;
            });
          }
        },
        durationSeconds: 10,
      );

      if (!mounted) return;

      if (uploadResult > 0) {
        setState(() {
          _uploadSpeed = uploadResult;
        });
      }

      if (mounted) {
        setState(() {
          _isTesting = false;
          _status = 'Test completed!';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isTesting = false;
          _status = 'Test failed: ${e.toString()}';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ToolScreenWrapper(
      title: 'Speed Test',
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
                                  ? const CommonLoadingIndicator(
                                      size: 20,
                                      color: Colors.white,
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

}
