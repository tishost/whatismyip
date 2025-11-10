import 'package:flutter/material.dart';
import 'dart:io';

import '../../widgets/glass_card.dart';
import '../../widgets/gradient_text.dart';
import '../../../core/utils/app_theme.dart';
import '../../../core/constants/strings.dart';
import '../../../core/constants/colors.dart';

class DnsScreen extends StatefulWidget {
  const DnsScreen({super.key});

  @override
  State<DnsScreen> createState() => _DnsScreenState();
}

class _DnsScreenState extends State<DnsScreen> {
  final TextEditingController _domainController = TextEditingController();
  final TextEditingController _recordTypeController = TextEditingController(
    text: 'A',
  );
  Map<String, dynamic>? _dnsResults;
  bool _isLoading = false;
  String? _error;

  final List<String> _recordTypes = ['A', 'AAAA', 'MX', 'NS', 'TXT', 'CNAME'];

  @override
  void dispose() {
    _domainController.dispose();
    _recordTypeController.dispose();
    super.dispose();
  }

  Future<void> _performDnsLookup() async {
    final domain = _domainController.text.trim();
    final recordType = _recordTypeController.text.trim().toUpperCase();

    if (domain.isEmpty) {
      setState(() => _error = 'Please enter a domain name');
      return;
    }

    if (!_recordTypes.contains(recordType)) {
      setState(() => _error = 'Invalid record type');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
      _dnsResults = null;
    });

    try {
      final results = <String, List<String>>{};

      // Perform DNS lookup using dart:io
      // Note: This is a simplified version. For production, use a proper DNS library
      if (recordType == 'A' || recordType == 'ALL') {
        try {
          final addresses = await InternetAddress.lookup(domain);
          results['A'] = addresses.map((a) => a.address).toList();
        } catch (e) {
          results['A'] = ['Not found'];
        }
      }

      // For other record types, you would need a DNS library or API
      // This is a placeholder - implement with actual DNS lookup service
      setState(() {
        _dnsResults = results;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Error: ${e.toString()}';
        _isLoading = false;
      });
    }
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
                            DropdownButtonFormField<String>(
                              value: _recordTypes.first,
                              decoration: InputDecoration(
                                labelText: 'Record Type',
                                labelStyle: TextStyle(
                                  color: Colors.white.withOpacity(0.7),
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: Colors.white.withOpacity(0.3),
                                  ),
                                ),
                              ),
                              dropdownColor: Colors.black87,
                              style: const TextStyle(color: Colors.white),
                              items: _recordTypes.map((type) {
                                return DropdownMenuItem(
                                  value: type,
                                  child: Text(type),
                                );
                              }).toList(),
                              onChanged: (value) {
                                if (value != null) {
                                  _recordTypeController.text = value;
                                }
                              },
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: _isLoading ? null : _performDnsLookup,
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
                      if (_dnsResults != null) ...[
                        const SizedBox(height: 16),
                        GlassCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const GradientText(
                                'DNS Results',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16),
                              ..._dnsResults!.entries.map((entry) {
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${entry.key} Records:',
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.7),
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      ...entry.value.map((value) {
                                        return Padding(
                                          padding:
                                              const EdgeInsets.only(left: 16),
                                          child: Text(
                                            value,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 14,
                                              fontFamily: 'monospace',
                                            ),
                                          ),
                                        );
                                      }),
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
                ),
              ),
            ],
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
            onPressed: () => Navigator.pop(context),
          ),
          const Expanded(
            child: GradientText(
              'DNS Lookup',
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
