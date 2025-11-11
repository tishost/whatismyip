import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';

import '../../widgets/glass_card.dart';
import '../../widgets/gradient_text.dart';
import '../../widgets/tool_screen_wrapper.dart';
import '../../widgets/common_input_decoration.dart';
import '../../widgets/loading_indicator.dart';
import '../../../core/constants/colors.dart';

class TracerouteScreen extends StatefulWidget {
  const TracerouteScreen({super.key});

  @override
  State<TracerouteScreen> createState() => _TracerouteScreenState();
}

class _TracerouteScreenState extends State<TracerouteScreen> {
  final TextEditingController _hostController = TextEditingController();
  final List<Map<String, String>> _traceResults = [];
  final Dio _dio = Dio();
  bool _isTracing = false;
  Process? _traceProcess;

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
    try { return InternetAddress.tryParse(host) != null; } catch (_) { return false; }
  }

  bool _isValidDomain(String host) {
    final re = RegExp(r'^(?!-)(?:[a-z0-9-]{1,63}(?<!-)\.)+(?:[a-z]{2,63}|xn--[a-z0-9]{1,59})$');
    return re.hasMatch(host);
  }

  @override
  void dispose() {
    _hostController.dispose();
    _traceProcess?.kill();
    super.dispose();
  }

  Future<void> _startTraceroute() async {
    FocusScope.of(context).unfocus();
    final host = _normalizeHost(_hostController.text);
    if (host.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a host or IP address')),
      );
      return;
    }
    if (!(_isValidIp(host) || _isValidDomain(host))) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid IP (v4/v6) or domain, e.g., 8.8.8.8 or example.com')),
      );
      return;
    }

    _hostController.text = host;
    _hostController.selection = TextSelection.fromPosition(TextPosition(offset: host.length));

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

  Future<bool> _runOwnApiTraceroute(String host) async {
    try {
      // Use own API traceroute endpoint
      final response = await _dio.get(
        'https://digdns.io/api/node/v1/traceroute/$host',
        queryParameters: {
          'maxHops': '30',
          'timeout': '5',
        },
        options: Options(
          headers: {
            'Accept': 'application/json',
          },
          receiveTimeout: const Duration(seconds: 30),
        ),
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        
        if (data['success'] == true && data['data'] != null) {
          final traceData = data['data'];
          final hops = traceData['hops'] as List<dynamic>?;
          
          if (hops != null && hops.isNotEmpty) {
            // Clear info message if we have data
            if (mounted && _traceResults.isNotEmpty && _traceResults.first['hop'] == 'Info') {
              setState(() {
                _traceResults.clear();
              });
            }
            
            for (final hop in hops) {
              final hopNumber = hop['hop']?.toString() ?? '';
              final ip = hop['ip']?.toString() ?? '';
              final hostname = hop['hostname']?.toString();
              final avgTime = hop['avgTime'];
              final times = hop['times'] as List<dynamic>?;
              
              String timeStr = 'N/A';
              if (avgTime != null) {
                timeStr = '${avgTime.toStringAsFixed(2)} ms';
              } else if (times != null && times.isNotEmpty) {
                final avg = times.map((t) => (t as num).toDouble()).reduce((a, b) => a + b) / times.length;
                timeStr = '${avg.toStringAsFixed(2)} ms';
              }
              
              String displayHostname = ip;
              if (hostname != null && hostname.isNotEmpty && hostname != ip) {
                displayHostname = '$hostname ($ip)';
              } else if (ip.isEmpty) {
                displayHostname = 'Timeout';
              }
              
              if (mounted) {
                setState(() {
                  _traceResults.add({
                    'hop': hopNumber,
                    'ip': ip,
                    'time': timeStr,
                    'hostname': displayHostname,
                  });
                });
              }
            }
            
            if (mounted) {
              setState(() {
                _isTracing = false;
              });
            }
            return true; // Success
          }
        } else if (data['success'] == false) {
          // API returned error
          final errorMsg = data['error']?.toString() ?? 'Traceroute failed';
          if (mounted) {
            setState(() {
              _traceResults.add({
                'hop': 'Error',
                'ip': '',
                'time': '',
                'hostname': errorMsg,
              });
              _isTracing = false;
            });
          }
          return false;
        }
      }
    } catch (e) {
      // Own API failed, will try fallback
      return false;
    }
    
    return false;
  }


  Future<void> _runTracerouteAPI(String host) async {
    // Note: API-based traceroute traces from the server's IP, not your local device IP
    // This is the only option on mobile devices without root permissions
    
    // Show info message first
    if (mounted) {
      setState(() {
        _traceResults.add({
          'hop': 'Info',
          'ip': '',
          'time': '',
          'hostname': 'Note: Traceroute is performed from API server, not your local device.',
        });
      });
    }
    
    // Try own API first
    try {
      final ownApiResult = await _runOwnApiTraceroute(host);
      if (ownApiResult) {
        return; // Success
      }
    } catch (e) {
      // Own API failed, continue to fallback
    }
    
    // Fallback to external APIs
    final apis = [
      {
        'url': 'https://api.hackertarget.com/traceroute/?q=$host',
        'type': 'hackertarget',
      },
      {
        'url': 'https://api.hackertarget.com/mtr/?q=$host',
        'type': 'hackertarget-mtr',
      },
      {
        'url': 'https://ip-api.com/trace/$host',
        'type': 'ip-api',
      },
    ];

    for (final api in apis) {
      try {
        final response = await _dio.get(
          api['url']!,
          options: Options(
            headers: {
              'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
            },
            receiveTimeout: const Duration(seconds: 15),
            followRedirects: true,
          ),
        );
        
        if (response.statusCode == 200 && response.data != null) {
          final dataString = response.data is String 
              ? response.data as String
              : response.data.toString();
          
          if (dataString.trim().isEmpty) {
            continue;
          }
          
          if (api['type'] == 'hackertarget' || api['type'] == 'hackertarget-mtr') {
            // Parse HackerTarget Traceroute/MTR format
            final lines = dataString.split('\n');
            int hopNumber = 1;
            bool foundData = false;
            
            // Check for rate limit or error messages
            if (dataString.toLowerCase().contains('rate limit') || 
                dataString.toLowerCase().contains('too many requests') ||
                dataString.toLowerCase().contains('quota exceeded')) {
              if (mounted) {
                setState(() {
                  _traceResults.add({
                    'hop': 'Error',
                    'ip': '',
                    'time': '',
                    'hostname': 'API rate limit exceeded. Please try again later.',
                  });
                });
              }
              continue; // Try next API
            }
            
            for (final line in lines) {
              final trimmedLine = line.trim();
              if (trimmedLine.isEmpty || 
                  trimmedLine.contains('HOST:') || 
                  trimmedLine.contains('MTR') ||
                  trimmedLine.startsWith('Start:') ||
                  trimmedLine.toLowerCase().contains('error') ||
                  trimmedLine.toLowerCase().contains('rate limit')) {
                continue;
              }
              
              // Traceroute format: "1  192.168.1.1 (192.168.1.1)  1.234 ms"
              // MTR format: "1.|-- 192.168.1.1  0.0%     5    1.2   1.3   1.1   1.5   0.1"
              if (trimmedLine.contains('|--') || trimmedLine.contains('|') || 
                  RegExp(r'^\d+\s+').hasMatch(trimmedLine)) {
                final ipMatch = RegExp(r'(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})').firstMatch(trimmedLine);
                
                if (ipMatch != null) {
                  final ip = ipMatch.group(1) ?? '';
                  
                  // Extract time values
                  String avgTime = '0';
                  final timeMatch = RegExp(r'(\d+\.?\d*)\s*ms').firstMatch(trimmedLine);
                  if (timeMatch != null) {
                    avgTime = timeMatch.group(1) ?? '0';
                  } else {
                    // Try MTR format - extract numbers
                    final timeMatches = RegExp(r'(\d+\.?\d*)').allMatches(trimmedLine);
                    final times = timeMatches.map((m) => m.group(1)).whereType<String>().toList();
                    if (times.length >= 4) {
                      avgTime = times[3]; // Average is usually 4th number
                    } else if (times.length >= 2) {
                      avgTime = times[1];
                    }
                  }
                  
                  // Try to get hostname
                  String hostname = ip;
                  try {
                    final hostnameResult = await InternetAddress.lookup(ip);
                    if (hostnameResult.isNotEmpty && hostnameResult.first.host != ip) {
                      hostname = hostnameResult.first.host;
                    }
                  } catch (e) {
                    // Keep IP as hostname
                  }
                  
                  if (mounted) {
                    setState(() {
                      _traceResults.add({
                        'hop': hopNumber.toString(),
                        'ip': ip,
                        'time': '$avgTime ms',
                        'hostname': hostname != ip ? '$hostname ($ip)' : ip,
                      });
                    });
                  }
                  hopNumber++;
                  foundData = true;
                }
              }
            }
            
            if (foundData && mounted) {
              setState(() {
                _isTracing = false;
              });
              return; // Success
            }
          } else if (api['type'] == 'ip-api') {
            // Parse ip-api.com trace format (JSON or text)
            try {
              // Try JSON first
              final jsonData = dataString.trim();
              if (jsonData.startsWith('{') || jsonData.startsWith('[')) {
                // JSON format - skip for now, use text parsing
              }
              
              // Text format parsing
              final lines = dataString.split('\n');
              int hopNumber = 1;
              bool foundData = false;
              
              for (final line in lines) {
                final trimmedLine = line.trim();
                if (trimmedLine.isEmpty) continue;
                
                // Look for IP addresses
                final ipMatch = RegExp(r'(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})').firstMatch(trimmedLine);
                final timeMatch = RegExp(r'(\d+\.?\d*)\s*ms').firstMatch(trimmedLine);
                
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
                  foundData = true;
                }
              }
              
              if (foundData && mounted) {
                setState(() {
                  _isTracing = false;
                });
                return; // Success
              }
            } catch (e) {
              // Continue to next API
            }
          } else if (api['type'] == 'subnet') {
            // Parse subnet online format
            try {
              final lines = dataString.split('\n');
              int hopNumber = 1;
              bool foundData = false;
              
              for (final line in lines) {
                final trimmedLine = line.trim();
                if (trimmedLine.isEmpty || 
                    trimmedLine.contains('<') || 
                    trimmedLine.contains('html') ||
                    trimmedLine.contains('script')) {
                  continue;
                }
                
                // Look for IP addresses in various formats
                final ipMatch = RegExp(r'(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})').firstMatch(trimmedLine);
                final timeMatch = RegExp(r'(\d+\.?\d*)\s*ms').firstMatch(trimmedLine);
                
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
                  foundData = true;
                }
              }
              
              if (foundData && mounted) {
                setState(() {
                  _isTracing = false;
                });
                return; // Success
              }
            } catch (e) {
              // Continue to next API
            }
          }
        }
      } catch (e) {
        // Try next API
        continue;
      }
    }
    
    // If all APIs failed, try alternative method
    await _tryAlternativeTraceroute(host);
  }

  Future<void> _tryAlternativeTraceroute(String host) async {
    // Alternative: Use ping-based approach to simulate traceroute
    try {
      if (mounted) {
        setState(() {
          _traceResults.add({
            'hop': '1',
            'ip': 'Resolving...',
            'time': '',
            'hostname': 'Starting trace to $host',
          });
        });
      }

      // Try to resolve hostname
      try {
        final addresses = await InternetAddress.lookup(host);
        if (addresses.isNotEmpty) {
          final ip = addresses.first.address;
          
          if (mounted) {
            setState(() {
              _traceResults.clear();
              _traceResults.add({
                'hop': '1',
                'ip': ip,
                'time': 'N/A',
                'hostname': host,
              });
              _traceResults.add({
                'hop': 'Info',
                'ip': '',
                'time': '',
                'hostname': 'Direct connection detected. Full traceroute requires API access.',
              });
            });
          }
        }
      } catch (e) {
        // Host resolution failed
      }
    } catch (e) {
      // Error in alternative method
    }
    
    // If still no results, show error
    if (mounted) {
      if (_traceResults.isEmpty) {
        setState(() {
          _traceResults.add({
            'hop': 'Error',
            'ip': '',
            'time': '',
            'hostname': 'Unable to perform traceroute. API services may be unavailable. Please check your internet connection and try again.',
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

  @override
  Widget build(BuildContext context) {
    return ToolScreenWrapper(
      title: 'Traceroute',
      onBackPressed: () {
        _stopTraceroute();
      },
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
                              keyboardType: TextInputType.url,
                              textInputAction: TextInputAction.search,
                              onSubmitted: (_) {
                                if (_isTracing) return;
                                FocusScope.of(context).unfocus();
                                _startTraceroute();
                              },
                              decoration: CommonInputDecoration.textField(
                                labelText: 'Host or IP Address',
                                hintText: 'example.com or 8.8.8.8',
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: _isTracing 
                                        ? () { _stopTraceroute(); }
                                        : () { 
                                            FocusScope.of(context).unfocus();
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
                          child: CommonLoadingIndicator(),
                        ),
                      ],
        ],
      ),
    );
  }
}



