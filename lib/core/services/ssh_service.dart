import 'dart:async';
import 'dart:convert';
import 'package:dartssh2/dartssh2.dart';

/// SSH Connection Service - Direct local SSH only (no API)
class SshConnection {
  final String host;
  final int port;
  final String username;
  final String? password;
  final String? privateKey;
  
  SSHClient? _client;
  SSHSocket? _socket;
  bool _isConnected = false;
  
  SshConnection({
    required this.host,
    this.port = 22,
    required this.username,
    this.password,
    this.privateKey,
  });

  bool get isConnected => _isConnected;

  /// Connect to SSH server directly (local connection)
  Future<Map<String, dynamic>> connect() async {
    try {
      // Create SSH socket connection
      _socket = await SSHSocket.connect(host, port);
      
      // Create SSH client
      _client = SSHClient(
        _socket!,
        username: username,
        onPasswordRequest: () {
          // Return password if provided
          return password ?? '';
        },
      );

      // Wait for authentication
      await _client!.authenticated;
      _isConnected = true;
      
      return {
        'success': true,
        'mode': 'direct',
        'message': 'Connected directly',
      };
    } catch (e) {
      _isConnected = false;
      _client = null;
      _socket = null;
      return {
        'success': false,
        'error': 'Connection failed: ${e.toString()}',
      };
    }
  }

  /// Execute command directly
  Future<Map<String, dynamic>> executeCommand(String command) async {
    if (!_isConnected || _client == null) {
      return {
        'success': false,
        'error': 'Not connected to SSH server',
        'output': '',
      };
    }

    try {
      // Execute command using run method
      final result = await _client!.run(command);
      
      // Convert result to string
      String output = '';
      if (result.isNotEmpty) {
        try {
          output = utf8.decode(result);
        } catch (e) {
          // If UTF-8 decode fails, try as string
          try {
            output = String.fromCharCodes(result);
          } catch (e2) {
            // If that also fails, convert to hex or show error
            output = 'Output decode error: ${e.toString()}';
          }
        }
      }

      // Preserve all output including newlines and spaces
      // Don't trim - keep original formatting

      return {
        'success': true,
        'output': output,
        'exitCode': 0,
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'Command execution failed: ${e.toString()}',
        'output': '',
      };
    }
  }

  /// Disconnect from SSH server
  Future<void> disconnect() async {
    try {
      if (_client != null) {
        _client!.close();
        _client = null;
      }
      if (_socket != null) {
        _socket!.close();
        _socket = null;
      }
    } catch (e) {
      // Ignore disconnect errors
    }
    _isConnected = false;
  }
}
