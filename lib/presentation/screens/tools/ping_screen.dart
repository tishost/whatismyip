import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../widgets/glass_card.dart';
import '../../widgets/gradient_text.dart';
import '../../../core/utils/app_theme.dart';
import '../../../core/constants/colors.dart';

class PingScreen extends StatefulWidget {
  const PingScreen({super.key});

  @override
  State<PingScreen> createState() => _PingScreenState();
}

class _PingScreenState extends State<PingScreen> {
  final TextEditingController _hostController = TextEditingController();
  final List<String> _pingResults = [];
  bool _isPinging = false;
  Timer? _pingTimer;
  int _packetsSent = 0;
  int _packetsReceived = 0;
  double _minTime = double.infinity;
  double _maxTime = 0;
  double _avgTime = 0;

  @override
  void dispose() {
    _hostController.dispose();
    _pingTimer?.cancel();
    super.dispose();
  }

  Future<void> _startPing() async {
    final host = _hostController.text.trim();
    if (host.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a host or IP address')),
      );
      return;
    }

    setState(() {
      _isPinging = true;
      _pingResults.clear();
      _packetsSent = 0;
      _packetsReceived = 0;
      _minTime = double.infinity;
      _maxTime = 0;
      _avgTime = 0;
    });

    _pingTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      if (!_isPinging) {
        timer.cancel();
        return;
      }

      _packetsSent++;
      final stopwatch = Stopwatch()..start();

      try {
        final result = await InternetAddress.lookup(host);
        stopwatch.stop();
        final time = stopwatch.elapsedMilliseconds.toDouble();

        setState(() {
          _packetsReceived++;
          _minTime = _minTime == double.infinity
              ? time
              : (_minTime < time ? _minTime : time);
          _maxTime = _maxTime > time ? _maxTime : time;
          _avgTime =
              ((_avgTime * (_packetsReceived - 1)) + time) / _packetsReceived;

          _pingResults.add(
            'Reply from ${result.first.address}: time=${time}ms',
          );
        });
      } catch (e) {
        setState(() {
          _pingResults.add('Request timed out');
        });
      }
    });
  }

  void _stopPing() {
    setState(() {
      _isPinging = false;
    });
    _pingTimer?.cancel();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (!didPop) {
          // Navigate to home instead of popping
          context.go('/');
        }
      },
      child: Scaffold(
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
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            TextField(
                              controller: _hostController,
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                labelText: 'Host or IP Address',
                                labelStyle: TextStyle(
                                  color: Colors.white.withOpacity(0.7),
                                ),
                                hintText: 'google.com or 8.8.8.8',
                                hintStyle: TextStyle(
                                  color: Colors.white.withOpacity(0.5),
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
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed:
                                        _isPinging ? _stopPing : _startPing,
                                    icon: Icon(_isPinging
                                        ? Icons.stop
                                        : Icons.play_arrow),
                                    label: Text(
                                        _isPinging ? 'Stop' : 'Start Ping'),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      if (_packetsSent > 0) ...[
                        const SizedBox(height: 16),
                        GlassCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const GradientText(
                                'Statistics',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16),
                              _buildStatRow(
                                  'Packets Sent', _packetsSent.toString()),
                              _buildStatRow('Packets Received',
                                  _packetsReceived.toString()),
                              _buildStatRow('Lost',
                                  '${_packetsSent - _packetsReceived} (${((_packetsSent - _packetsReceived) / _packetsSent * 100).toStringAsFixed(1)}%)'),
                              if (_packetsReceived > 0) ...[
                                _buildStatRow('Min Time',
                                    '${_minTime.toStringAsFixed(2)}ms'),
                                _buildStatRow('Max Time',
                                    '${_maxTime.toStringAsFixed(2)}ms'),
                                _buildStatRow('Avg Time',
                                    '${_avgTime.toStringAsFixed(2)}ms'),
                              ],
                            ],
                          ),
                        ),
                      ],
                      if (_pingResults.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        GlassCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const GradientText(
                                'Ping Results',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Container(
                                height: 200,
                                child: ListView.builder(
                                  itemCount: _pingResults.length,
                                  itemBuilder: (context, index) {
                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: 8),
                                      child: Text(
                                        _pingResults[index],
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 14,
                                          fontFamily: 'monospace',
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
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

  Widget _buildStatRow(String label, String value) {
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

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () {
              _stopPing();
              context.go('/');
            },
          ),
          const Expanded(
            child: GradientText(
              'Ping Test',
              style: TextStyle(
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
