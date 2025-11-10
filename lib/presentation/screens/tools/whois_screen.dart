import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';

import '../../widgets/glass_card.dart';
import '../../widgets/gradient_text.dart';
import '../../../core/utils/app_theme.dart';
import '../../../core/constants/colors.dart';

class WhoisScreen extends StatefulWidget {
  const WhoisScreen({super.key});

  @override
  State<WhoisScreen> createState() => _WhoisScreenState();
}

class _WhoisScreenState extends State<WhoisScreen> {
  final TextEditingController _domainController = TextEditingController();
  String? _whoisData;
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _domainController.dispose();
    super.dispose();
  }

  Future<void> _performWhoisLookup() async {
    final domain = _domainController.text.trim();
    if (domain.isEmpty) {
      setState(() => _error = 'Please enter a domain name');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
      _whoisData = null;
    });

    try {
      // Using a public WHOIS API (you can replace with your own backend)
      final dio = Dio();
      final response = await dio.get(
        'https://www.whoisxmlapi.com/whoisserver/WhoisService',
        queryParameters: {
          'apiKey': '', // Add your API key
          'domainName': domain,
          'outputFormat': 'JSON',
        },
        options: Options(
          receiveTimeout: const Duration(seconds: 10),
        ),
      );

      if (response.statusCode == 200) {
        final data = response.data;
        final buffer = StringBuffer();

        if (data['WhoisRecord'] != null) {
          final record = data['WhoisRecord'];
          buffer.writeln('Domain: ${record['domainName'] ?? domain}');
          buffer.writeln('Registrar: ${record['registrarName'] ?? 'N/A'}');
          buffer.writeln('Created: ${record['createdDate'] ?? 'N/A'}');
          buffer.writeln('Updated: ${record['updatedDate'] ?? 'N/A'}');
          buffer.writeln('Expires: ${record['expiresDate'] ?? 'N/A'}');
          if (record['nameServers'] != null) {
            buffer.writeln('Name Servers:');
            for (var ns in record['nameServers']['rawText']) {
              buffer.writeln('  - $ns');
            }
          }
        } else {
          buffer.writeln('WHOIS data not available');
        }

        setState(() {
          _whoisData = buffer.toString();
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error: ${e.toString()}';
        _isLoading = false;
      });
    }
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
                              controller: _domainController,
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                labelText: 'Domain Name',
                                labelStyle: TextStyle(
                                  color: Colors.white.withOpacity(0.7),
                                ),
                                hintText: 'example.com',
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
                            ElevatedButton.icon(
                              onPressed:
                                  _isLoading ? null : _performWhoisLookup,
                              icon: _isLoading
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
                                  : const Icon(Icons.search),
                              label: const Text('Lookup'),
                            ),
                          ],
                        ),
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: 16),
                        GlassCard(
                          child: Text(
                            _error!,
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                      if (_whoisData != null) ...[
                        const SizedBox(height: 16),
                        GlassCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const GradientText(
                                'WHOIS Results',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16),
                              SelectableText(
                                _whoisData!,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontFamily: 'monospace',
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

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => context.go('/'),
          ),
          const Expanded(
            child: GradientText(
              'WHOIS Lookup',
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
