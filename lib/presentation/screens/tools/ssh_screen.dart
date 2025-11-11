import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../widgets/glass_card.dart';
import '../../widgets/gradient_text.dart';
import '../../widgets/tool_screen_wrapper.dart';
import '../../widgets/common_input_decoration.dart';
import '../../widgets/loading_indicator.dart';
import '../../widgets/interactive_terminal.dart';
import '../../../core/constants/colors.dart';
import '../../../core/services/ssh_service.dart';

class SshScreen extends StatefulWidget {
  const SshScreen({super.key});

  @override
  State<SshScreen> createState() => _SshScreenState();
}

class _SshScreenState extends State<SshScreen> {
  final TextEditingController _hostController = TextEditingController();
  final TextEditingController _portController = TextEditingController(text: '22');
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  SshConnection? _connection;
  final List<String> _terminalOutput = [];
  bool _isConnected = false;
  bool _isConnecting = false;
  bool _isExecuting = false;
  String _connectionStatus = 'Disconnected';

  @override
  void dispose() {
    _hostController.dispose();
    _portController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _scrollController.dispose();
    _disconnect();
    super.dispose();
  }

  void _addOutput(String text, {bool isError = false}) {
    setState(() {
      _terminalOutput.add(text);
      if (_terminalOutput.length > 1000) {
        _terminalOutput.removeAt(0); // Keep last 1000 lines
      }
    });
    // Auto scroll to bottom
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _connect() async {
    FocusScope.of(context).unfocus();

    final host = _hostController.text.trim();
    final portStr = _portController.text.trim();
    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();

    if (host.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a host or IP address')),
      );
      return;
    }

    if (username.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a username')),
      );
      return;
    }

    int port = 22;
    if (portStr.isNotEmpty) {
      port = int.tryParse(portStr) ?? 22;
      if (port < 1 || port > 65535) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Port must be between 1 and 65535')),
        );
        return;
      }
    }

    setState(() {
      _isConnecting = true;
      _connectionStatus = 'Connecting...';
    });

    _addOutput('Connecting to $username@$host:$port...');

    try {
      _connection = SshConnection(
        host: host,
        port: port,
        username: username,
        password: password.isEmpty ? null : password,
      );

      final result = await _connection!.connect();

      if (result['success'] == true) {
        setState(() {
          _isConnected = true;
          _isConnecting = false;
          _connectionStatus = 'Connected (Direct)';
        });
        _addOutput('✓ Connected successfully (Direct SSH)');
        _addOutput('---');
      } else {
        setState(() {
          _isConnecting = false;
          _connectionStatus = 'Connection failed';
        });
        final error = result['error']?.toString() ?? 'Unknown error';
        _addOutput('✗ Connection failed: $error', isError: true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Connection failed: $error')),
        );
      }
    } catch (e) {
      setState(() {
        _isConnecting = false;
        _connectionStatus = 'Connection error';
      });
      _addOutput('✗ Connection error: ${e.toString()}', isError: true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Connection error: ${e.toString()}')),
      );
    }
  }

  Future<void> _disconnect() async {
    if (_connection != null) {
      _addOutput('Disconnecting...');
      await _connection!.disconnect();
      _connection = null;
    }
    setState(() {
      _isConnected = false;
      _connectionStatus = 'Disconnected';
    });
    _addOutput('Disconnected');
  }

  Future<void> _executeCommand(String command) async {
    if (!_isConnected || _connection == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Not connected to SSH server')),
      );
      return;
    }

    if (command.isEmpty) {
      return;
    }

    // Show command in terminal (already shown by interactive terminal)
    // _addOutput('\$ ${command}');

    setState(() {
      _isExecuting = true;
    });

    try {
      final result = await _connection!.executeCommand(command);

      if (result['success'] == true) {
        final output = result['output']?.toString() ?? '';
        
        // Always show output
        if (output.isNotEmpty) {
          // Split output by newlines
          final lines = output.split('\n');
          
          // If output has newlines, add each line separately
          if (lines.length > 1) {
            for (final line in lines) {
              // Add line (even if empty to preserve formatting)
              _addOutput(line);
            }
          } else {
            // Single line output - add as is
            _addOutput(output);
          }
        } else {
          // If output is empty, show a message
          _addOutput('(command executed successfully, no output)');
        }
        
        if (result['error'] != null && result['error'].toString().isNotEmpty) {
          _addOutput('Error: ${result['error']}', isError: true);
        }
      } else {
        final error = result['error']?.toString() ?? 'Command execution failed';
        _addOutput('Error: $error', isError: true);
      }
    } catch (e) {
      _addOutput('Error: ${e.toString()}', isError: true);
    } finally {
      setState(() {
        _isExecuting = false;
      });
    }
  }


  void _clearTerminal() {
    setState(() {
      _terminalOutput.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return ToolScreenWrapper(
      title: 'SSH Terminal',
      onBackPressed: () {
        _disconnect();
        context.go('/');
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Connection Status
          GlassCard(
            child: Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _isConnected
                        ? Colors.green
                        : (_isConnecting ? Colors.orange : Colors.red),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _connectionStatus,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Connection Form
          if (!_isConnected) ...[
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GradientText(
                    'Connection Settings',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _hostController,
                    decoration: CommonInputDecoration.textField(
                      labelText: 'Host / IP Address',
                      hintText: 'example.com or 192.168.1.1',
                    ),
                    style: const TextStyle(color: Colors.white),
                    keyboardType: TextInputType.text,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _portController,
                    decoration: CommonInputDecoration.textField(
                      labelText: 'Port',
                      hintText: '22',
                    ),
                    style: const TextStyle(color: Colors.white),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _usernameController,
                    decoration: CommonInputDecoration.textField(
                      labelText: 'Username',
                      hintText: 'root',
                    ),
                    style: const TextStyle(color: Colors.white),
                    keyboardType: TextInputType.text,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _passwordController,
                    decoration: CommonInputDecoration.textField(
                      labelText: 'Password',
                      hintText: 'Enter password',
                    ),
                    style: const TextStyle(color: Colors.white),
                    obscureText: true,
                    keyboardType: TextInputType.text,
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isConnecting ? null : _connect,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.neonBlue,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isConnecting
                          ? const CommonLoadingIndicator()
                          : const Text(
                              'Connect',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Interactive Terminal Section
          if (_isConnected) ...[
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GradientText(
                    'Terminal',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Interactive Terminal
                  SizedBox(
                    height: 400,
                    child: InteractiveTerminal(
                      key: ValueKey(_terminalOutput.length),
                      onCommand: _executeCommand,
                      outputLines: List.from(_terminalOutput), // Create new list to trigger rebuild
                      prompt: _usernameController.text.isNotEmpty
                          ? '${_usernameController.text}@${_hostController.text}:~\$ '
                          : '\$ ',
                      isExecuting: _isExecuting,
                      onClear: _clearTerminal,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _disconnect,
                      icon: const Icon(Icons.close),
                      label: const Text('Disconnect'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red[300],
                        side: BorderSide(color: Colors.red[300]!),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
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

