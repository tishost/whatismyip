import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';

import '../../widgets/glass_card.dart';
import '../../widgets/gradient_text.dart';
import '../../../core/utils/app_theme.dart';
import '../../../core/constants/colors.dart';

class TracerouteScreen extends StatefulWidget {
  const TracerouteScreen({super.key});

  @override
  State<TracerouteScreen> createState() => _TracerouteScreenState();
}

class _TracerouteScreenState extends State<TracerouteScreen> {
  final TextEditingController _hostController = TextEditingController();
  final List<Map<String, String>> _traceResults = [];
  bool _isTracing = false;
  Process? _traceProcess;

  @override
  void dispose() {
    _hostController.dispose();
    _traceProcess?.kill();
    super.dispose();
  }

  Future<void> _startTraceroute() async {
    final host = _hostController.text.trim();
    if (host.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a host or IP address')),
      );
      return;
    }

    setState(() {
      _isTracing = true;
      _traceResults.clear();
    });

    try {
      // Use API-based traceroute for all platforms
      // Native traceroute requires root permissions on mobile devices
      await _runTracerouteAPI(host);
    } catch (e) {
      if (mounted) {
        setState(() {
          _traceResults.add({
            'hop': 'Error',
            'ip': '',
            'time': '',
            'hostname': 'Failed to trace: ${e.toString()}',
          });
          _isTracing = false;
        });
      }
    }
  }


  Future<void> _runTracerouteAPI(String host) async {
    // Use online traceroute API services
    // Try multiple APIs for better reliability
    final apis = [
      'https://api.hackertarget.com/mtr/?q=$host',
      'https://ip-api.com/trace/$host',
    ];

    for (final apiUrl in apis) {
      try {
        final client = HttpClient();
        client.connectionTimeout = const Duration(seconds: 10);
        
        final uri = Uri.parse(apiUrl);
        final request = await client.getUrl(uri);
        final response = await request.close();
        
        if (response.statusCode == 200) {
          final data = await response.transform(const SystemEncoding().decoder).join();
          
          if (apiUrl.contains('hackertarget')) {
            // Parse HackerTarget MTR format
            final lines = data.split('\n');
            int hopNumber = 1;
            
            for (final line in lines) {
              if (line.trim().isEmpty || line.contains('HOST:')) continue;
              
              // Format: "HOST: example.com    Loss%   Snt   Last   Avg  Best  Wrst StDev"
              // or: "1.|-- 192.168.1.1  0.0%     5    1.2   1.3   1.1   1.5   0.1"
              final parts = line.split(RegExp(r'\s+'));
              if (parts.length >= 3 && parts[0].contains('|')) {
                final ipMatch = RegExp(r'(\d+\.\d+\.\d+\.\d+)').firstMatch(line);
                final timeMatch = RegExp(r'(\d+\.\d+)').allMatches(line);
                
                if (ipMatch != null) {
                  final ip = ipMatch.group(1) ?? '';
                  final times = timeMatch.map((m) => m.group(1)).toList();
                  final avgTime = times.isNotEmpty ? times[times.length ~/ 2] ?? '0' : '0';
                  
                  if (mounted) {
                    setState(() {
                      _traceResults.add({
                        'hop': hopNumber.toString(),
                        'ip': ip,
                        'time': '$avgTime ms',
                        'hostname': ip,
                      });
                    });
                  }
                  hopNumber++;
                }
              }
            }
          } else if (apiUrl.contains('ip-api')) {
            // Parse ip-api.com trace format
            final lines = data.split('\n');
            int hopNumber = 1;
            
            for (final line in lines) {
              if (line.trim().isEmpty) continue;
              
              // Try to extract IP and time
              final ipMatch = RegExp(r'(\d+\.\d+\.\d+\.\d+)').firstMatch(line);
              final timeMatch = RegExp(r'(\d+\.?\d*)\s*ms').firstMatch(line);
              
              if (ipMatch != null) {
                final ip = ipMatch.group(1) ?? '';
                final time = timeMatch?.group(1) ?? '0';
                
                if (mounted) {
                  setState(() {
                    _traceResults.add({
                      'hop': hopNumber.toString(),
                      'ip': ip,
                      'time': '$time ms',
                      'hostname': ip,
                    });
                  });
                }
                hopNumber++;
              }
            }
          }
          
          client.close();
          
          if (mounted && _traceResults.isNotEmpty) {
            setState(() {
              _isTracing = false;
            });
            return; // Success, exit
          }
        }
        
        client.close();
      } catch (e) {
        // Try next API
        continue;
      }
    }
    
    // If all APIs failed, show error message
    if (mounted) {
      if (_traceResults.isEmpty) {
        setState(() {
          _traceResults.add({
            'hop': 'Info',
            'ip': '',
            'time': '',
            'hostname': 'No traceroute data available. Please try again or check your internet connection.',
          });
        });
      }
      setState(() {
        _isTracing = false;
      });
    }
  }


  void _stopTraceroute() {
    _traceProcess?.kill();
    setState(() {
      _isTracing = false;
    });
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
          const Expanded(
            child: GradientText(
              'Traceroute',
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
                        onTap: null,
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
                                hintText: 'example.com or 8.8.8.8',
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
                                    onPressed: _isTracing 
                                        ? () {
                                            _stopTraceroute();
                                          }
                                        : () {
                                            _startTraceroute();
                                          },
                                    icon: Icon(_isTracing ? Icons.stop : Icons.play_arrow),
                                    label: Text(_isTracing ? 'Stop' : 'Start Traceroute'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.neonBlue,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(vertical: 16),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      if (_traceResults.isNotEmpty) ...[
                        const SizedBox(height: 24),
                        GlassCard(
                          onTap: null,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const GradientText(
                                'Trace Results',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16),
                              ..._traceResults.map((result) => Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    SizedBox(
                                      width: 40,
                                      child: Text(
                                        result['hop'] ?? '',
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.7),
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            result['hostname'] ?? '',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          if (result['ip'] != null && result['ip']!.isNotEmpty)
                                            Text(
                                              result['ip']!,
                                              style: TextStyle(
                                                color: Colors.white.withOpacity(0.6),
                                                fontSize: 12,
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                    if (result['time'] != null && result['time']!.isNotEmpty)
                                      Text(
                                        result['time']!,
                                        style: TextStyle(
                                          color: AppColors.neonBlue,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                  ],
                                ),
                              )).toList(),
                            ],
                          ),
                        ),
                      ],
                      if (_isTracing) ...[
                        const SizedBox(height: 24),
                        const Center(
                          child: CircularProgressIndicator(color: AppColors.neonBlue),
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
    );
  }
}

