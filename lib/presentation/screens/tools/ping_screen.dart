import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';

import '../../widgets/glass_card.dart';
import '../../widgets/gradient_text.dart';
import '../../widgets/tool_screen_wrapper.dart';
import '../../widgets/common_input_decoration.dart';
import '../../widgets/common_info_row.dart';

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

  String _normalizeHost(String input) {
    var s = input.trim().toLowerCase();
    s = s.replaceAll(RegExp(r'^https?://'), '');
    s = s.replaceAll(RegExp(r'^www\.'), '');
    final q = s.indexOf('?');
    if (q != -1) s = s.substring(0, q);
    final slash = s.indexOf('/');
    if (slash != -1) s = s.substring(0, slash);
    return s;
  }

  bool _isValidIp(String host) {
    try {
      return InternetAddress.tryParse(host) != null;
    } catch (_) {
      return false;
    }
  }

  bool _isValidDomain(String host) {
    final re = RegExp(r'^(?!-)(?:[a-z0-9-]{1,63}(?<!-)\.)+(?:[a-z]{2,63}|xn--[a-z0-9]{1,59})$');
    return re.hasMatch(host);
  }

  @override
  void dispose() {
    _hostController.dispose();
    _pingTimer?.cancel();
    super.dispose();
  }

  Future<void> _startPing() async {
    // Hide keyboard
    FocusScope.of(context).unfocus();

    final normalized = _normalizeHost(_hostController.text);
    if (normalized.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a host or IP address')),
      );
      return;
    }

    if (!(_isValidIp(normalized) || _isValidDomain(normalized))) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid IP (v4/v6) or domain, e.g., 8.8.8.8 or example.com')),
      );
      return;
    }

    // Reflect normalized text
    _hostController.text = normalized;
    _hostController.selection = TextSelection.fromPosition(
      TextPosition(offset: normalized.length),
    );

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
        final result = await InternetAddress.lookup(normalized);
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
    return ToolScreenWrapper(
      title: 'Ping Test',
      onBackPressed: () {
        _stopPing();
      },
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
                  keyboardType: TextInputType.url,
                  textInputAction: TextInputAction.search,
                  onSubmitted: (_) {
                    if (_isPinging) return;
                    FocusScope.of(context).unfocus();
                    _startPing();
                  },
                  decoration: CommonInputDecoration.textField(
                    labelText: 'Host or IP Address',
                    hintText: 'google.com or 8.8.8.8',
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _isPinging
                            ? _stopPing
                            : () {
                                FocusScope.of(context).unfocus();
                                _startPing();
                              },
                        icon: Icon(_isPinging ? Icons.stop : Icons.play_arrow),
                        label: Text(_isPinging ? 'Stop' : 'Start Ping'),
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
                  CommonStatRow(
                    label: 'Packets Sent',
                    value: _packetsSent.toString(),
                  ),
                  CommonStatRow(
                    label: 'Packets Received',
                    value: _packetsReceived.toString(),
                  ),
                  CommonStatRow(
                    label: 'Lost',
                    value: '${_packetsSent - _packetsReceived} (${((_packetsSent - _packetsReceived) / _packetsSent * 100).toStringAsFixed(1)}%)',
                  ),
                  if (_packetsReceived > 0) ...[
                    CommonStatRow(
                      label: 'Min Time',
                      value: '${_minTime.toStringAsFixed(2)}ms',
                    ),
                    CommonStatRow(
                      label: 'Max Time',
                      value: '${_maxTime.toStringAsFixed(2)}ms',
                    ),
                    CommonStatRow(
                      label: 'Avg Time',
                      value: '${_avgTime.toStringAsFixed(2)}ms',
                    ),
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
    );
  }
}

