import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';

import '../../widgets/glass_card.dart';
import '../../widgets/gradient_text.dart';
import '../../widgets/tool_screen_wrapper.dart';
import '../../widgets/common_input_decoration.dart';
import '../../widgets/common_info_row.dart';
import '../../../core/constants/colors.dart';

class PortScannerScreen extends StatefulWidget {
  const PortScannerScreen({super.key});

  @override
  State<PortScannerScreen> createState() => _PortScannerScreenState();
}

class _PortScannerScreenState extends State<PortScannerScreen> {
  final TextEditingController _hostController = TextEditingController();
  final TextEditingController _portController = TextEditingController();
  final List<PortResult> _portResults = [];
  bool _isScanning = false;
  int _scannedPorts = 0;
  int _totalPortsToCheck = 0;
  int _openPorts = 0;
  int _closedPorts = 0;
  Timer? _progressTimer;

  // Common ports to check
  final List<int> _commonPorts = [
    21, 22, 23, 25, 53, 80, 110, 143, 443, 465, 587, 993, 995, 3306, 3389, 5432, 8080
  ];

  @override
  void dispose() {
    _hostController.dispose();
    _portController.dispose();
    _progressTimer?.cancel();
    super.dispose();
  }

  Future<void> _scanPort(String host, int port, Duration timeout) async {
    try {
      final socket = await Socket.connect(host, port, timeout: timeout).timeout(timeout);
      await socket.close();
      return;
    } catch (e) {
      throw Exception('Port closed or filtered');
    }
  }

  List<int> _parsePorts(String portInput) {
    final ports = <int>[];
    final parts = portInput.split(',');
    
    for (final part in parts) {
      final trimmed = part.trim();
      if (trimmed.isEmpty) continue;
      
      final port = int.tryParse(trimmed);
      if (port == null) {
        throw FormatException('Invalid port: $trimmed');
      }
      
      if (port < 1 || port > 65535) {
        throw FormatException('Port must be between 1 and 65535: $port');
      }
      
      if (!ports.contains(port)) {
        ports.add(port);
      }
    }
    
    return ports;
  }

  Future<void> _checkPorts() async {
    final host = _hostController.text.trim();
    if (host.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a host or IP address')),
      );
      return;
    }

    final portInput = _portController.text.trim();
    if (portInput.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter port number(s)')),
      );
      return;
    }

    List<int> ports;
    try {
      ports = _parsePorts(portInput);
      if (ports.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter at least one valid port')),
        );
        return;
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('FormatException: ', ''))),
      );
      return;
    }

    setState(() {
      _isScanning = true;
      _portResults.clear();
      _scannedPorts = 0;
      _totalPortsToCheck = ports.length;
      _openPorts = 0;
      _closedPorts = 0;
    });

    final timeout = const Duration(seconds: 3);

    // Update progress periodically
    _progressTimer = Timer.periodic(const Duration(milliseconds: 300), (timer) {
      if (!_isScanning) {
        timer.cancel();
        return;
      }
      setState(() {});
    });

    // Check each port
    for (final port in ports) {
      if (!_isScanning) break;
      
      try {
        await _scanPort(host, port, timeout);
        setState(() {
          _openPorts++;
          _portResults.add(PortResult(port: port, isOpen: true));
        });
      } catch (e) {
        setState(() {
          _closedPorts++;
          _portResults.add(PortResult(port: port, isOpen: false));
        });
      }
      setState(() {
        _scannedPorts++;
      });
    }

    _progressTimer?.cancel();
    setState(() {
      _isScanning = false;
    });

    // Sort results by port number
    _portResults.sort((a, b) => a.port.compareTo(b.port));
  }

  Future<void> _checkCommonPorts() async {
    final host = _hostController.text.trim();
    if (host.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a host or IP address')),
      );
      return;
    }

    // Set common ports in the input field
    _portController.text = _commonPorts.join(', ');

    setState(() {
      _isScanning = true;
      _portResults.clear();
      _scannedPorts = 0;
      _totalPortsToCheck = _commonPorts.length;
      _openPorts = 0;
      _closedPorts = 0;
    });

    final timeout = const Duration(seconds: 3);
    _progressTimer = Timer.periodic(const Duration(milliseconds: 300), (timer) {
      if (!_isScanning) {
        timer.cancel();
        return;
      }
      setState(() {});
    });

    for (final port in _commonPorts) {
      if (!_isScanning) break;
      
      try {
        await _scanPort(host, port, timeout);
        setState(() {
          _openPorts++;
          _portResults.add(PortResult(port: port, isOpen: true));
        });
      } catch (e) {
        setState(() {
          _closedPorts++;
          _portResults.add(PortResult(port: port, isOpen: false));
        });
      }
      setState(() {
        _scannedPorts++;
      });
    }

    _progressTimer?.cancel();
    setState(() {
      _isScanning = false;
    });

    _portResults.sort((a, b) => a.port.compareTo(b.port));
  }

  void _stopScan() {
    setState(() {
      _isScanning = false;
    });
    _progressTimer?.cancel();
  }

  String _getPortService(int port) {
    const portServices = {
      21: 'FTP',
      22: 'SSH',
      23: 'Telnet',
      25: 'SMTP',
      53: 'DNS',
      80: 'HTTP',
      110: 'POP3',
      143: 'IMAP',
      443: 'HTTPS',
      465: 'SMTPS',
      587: 'SMTP',
      993: 'IMAPS',
      995: 'POP3S',
      3306: 'MySQL',
      3389: 'RDP',
      5432: 'PostgreSQL',
      8080: 'HTTP-Proxy',
    };
    return portServices[port] ?? 'Unknown';
  }

  @override
  Widget build(BuildContext context) {
    final progress = _totalPortsToCheck > 0 ? (_scannedPorts / _totalPortsToCheck) : 0.0;

    return ToolScreenWrapper(
      title: 'Port Checker',
      onBackPressed: () {
        _stopScan();
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
                                decoration: CommonInputDecoration.textField(
                                  labelText: 'Host or IP Address',
                                  hintText: 'example.com or 192.168.1.1',
                                ),
                              ),
                              const SizedBox(height: 16),
                              TextField(
                                controller: _portController,
                                keyboardType: TextInputType.text,
                                style: const TextStyle(color: Colors.white),
                                decoration: CommonInputDecoration.textField(
                                  labelText: 'Port(s)',
                                  hintText: '80 or 80,443,8080',
                                  helperText: 'Enter single port or comma-separated ports',
                                ),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed: _isScanning ? _stopScan : _checkPorts,
                                      icon: Icon(_isScanning ? Icons.stop : Icons.check_circle),
                                      label: Text(_isScanning ? 'Stop Check' : 'Check Ports'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.neonBlue,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(vertical: 16),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed: _isScanning ? null : _checkCommonPorts,
                                      icon: const Icon(Icons.star),
                                      label: const Text('Common Ports'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.purple.withOpacity(0.3),
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
                        if (_isScanning || _scannedPorts > 0) ...[
                          const SizedBox(height: 16),
                          GlassCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const GradientText(
                                  'Check Progress',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                if (_isScanning && _portResults.isNotEmpty) ...[
                                  LinearProgressIndicator(
                                    value: progress,
                                    backgroundColor: Colors.white.withOpacity(0.2),
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      AppColors.neonBlue,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    '${_scannedPorts} / $_totalPortsToCheck ports checked',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.8),
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 16),
                                CommonStatRow(
                                  label: 'Scanned',
                                  value: _scannedPorts.toString(),
                                ),
                                CommonStatRow(
                                  label: 'Open',
                                  value: _openPorts.toString(),
                                ),
                                CommonStatRow(
                                  label: 'Closed',
                                  value: _closedPorts.toString(),
                                ),
                              ],
                            ),
                          ),
                        ],
                        if (_portResults.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          GlassCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const GradientText(
                                      'Open Ports',
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    if (_portResults.isNotEmpty)
                                      Text(
                                        '${_portResults.where((r) => r.isOpen).length} found',
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.7),
                                          fontSize: 14,
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                ..._portResults.where((r) => r.isOpen).map((result) {
                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.green.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: Colors.green.withOpacity(0.3),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.check_circle,
                                          color: Colors.green.shade300,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Port ${result.port}',
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              Text(
                                                _getPortService(result.port),
                                                style: TextStyle(
                                                  color: Colors.white.withOpacity(0.7),
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }),
                              ],
                            ),
                          ),
                        ],
                        if (_portResults.any((r) => !r.isOpen)) ...[
                          const SizedBox(height: 16),
                          GlassCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const GradientText(
                                      'Closed Ports',
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      '${_portResults.where((r) => !r.isOpen).length} found',
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.7),
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                ..._portResults.where((r) => !r.isOpen).map((result) {
                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.red.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: Colors.red.withOpacity(0.3),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.close,
                                          color: Colors.red.shade300,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            'Port ${result.port}',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }),
                              ],
                            ),
                          ),
                        ],
        ],
      ),
    );
  }
}

class PortResult {
  final int port;
  final bool isOpen;

  PortResult({
    required this.port,
    required this.isOpen,
  });
}

