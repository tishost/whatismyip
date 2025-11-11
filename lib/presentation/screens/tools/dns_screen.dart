import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'dart:io';

import '../../widgets/glass_card.dart';
import '../../widgets/gradient_text.dart';
import '../../widgets/tool_screen_wrapper.dart';
import '../../widgets/common_input_decoration.dart';
import '../../widgets/loading_indicator.dart';

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
  final Dio _dio = Dio();

  final List<String> _recordTypes = ['A', 'AAAA', 'MX', 'NS', 'TXT', 'CNAME'];

  String _normalizeDomain(String input) {
    var s = input.trim().toLowerCase();
    s = s.replaceAll(RegExp(r'^https?://'), '');
    s = s.replaceAll(RegExp(r'^www\.'), '');
    final q = s.indexOf('?');
    if (q != -1) s = s.substring(0, q);
    final slash = s.indexOf('/');
    if (slash != -1) s = s.substring(0, slash);
    return s;
  }

  bool _isValidDomain(String domain) {
    final re = RegExp(r'^(?!-)(?:[a-z0-9-]{1,63}(?<!-)\.)+(?:[a-z]{2,63}|xn--[a-z0-9]{1,59})$');
    return re.hasMatch(domain);
  }

  @override
  void dispose() {
    _domainController.dispose();
    _recordTypeController.dispose();
    _dio.close();
    super.dispose();
  }

  Future<void> _performDnsLookup() async {
    FocusScope.of(context).unfocus();
    final domain = _normalizeDomain(_domainController.text);
    final recordType = _recordTypeController.text.trim().toUpperCase();

    if (domain.isEmpty) {
      setState(() => _error = 'Please enter a domain name');
      return;
    }

    if (!_isValidDomain(domain)) {
      setState(() => _error = 'Please enter a valid domain (e.g., example.com)');
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
      _domainController.text = domain;
      _domainController.selection = TextSelection.fromPosition(
        TextPosition(offset: domain.length),
      );
    });

    try {
      final results = <String, List<String>>{};

      // Use Google DNS over HTTPS API for all record types
      final dnsType = _getDnsType(recordType);
      final url = 'https://dns.google/resolve?name=$domain&type=$dnsType';

      try {
        final response = await _dio.get(
          url,
          options: Options(
            headers: {
              'Accept': 'application/dns-json',
            },
            receiveTimeout: const Duration(seconds: 10),
          ),
        );

        if (response.statusCode == 200 && response.data != null) {
          final data = response.data;
          
          if (data['Status'] == 0 && data['Answer'] != null) {
            final answers = data['Answer'] as List;
            final recordList = <String>[];

            for (var answer in answers) {
              final dataValue = answer['data'] as String?;

              if (dataValue != null && dataValue.isNotEmpty) {
                String formattedValue = dataValue;

                // Format based on record type
                if (recordType == 'MX') {
                  // MX records: priority exchange
                  final parts = dataValue.split(' ');
                  if (parts.length >= 2) {
                    formattedValue = 'Priority: ${parts[0]}, Exchange: ${parts.sublist(1).join(' ')}';
                  }
                } else if (recordType == 'TXT') {
                  // TXT records might have quotes
                  formattedValue = dataValue.replaceAll('"', '');
                } else if (recordType == 'CNAME') {
                  // CNAME records
                  formattedValue = dataValue;
                } else if (recordType == 'NS') {
                  // NS records
                  formattedValue = dataValue;
                } else if (recordType == 'AAAA') {
                  // AAAA records (IPv6)
                  formattedValue = dataValue;
                } else if (recordType == 'A') {
                  // A records (IPv4)
                  formattedValue = dataValue;
                }

                recordList.add(formattedValue);
              }
            }

            if (recordList.isNotEmpty) {
              results[recordType] = recordList;
            } else {
              results[recordType] = ['No records found'];
            }
          } else if (data['Status'] == 3) {
            // NXDOMAIN - domain does not exist
            results[recordType] = ['Domain not found'];
          } else {
            results[recordType] = ['No records found'];
          }
        } else {
          results[recordType] = ['Failed to fetch DNS records'];
        }
      } catch (e) {
        // Fallback to basic A record lookup for A type only
        if (recordType == 'A') {
          try {
            final addresses = await InternetAddress.lookup(domain);
            results['A'] = addresses.map((a) => a.address).toList();
          } catch (_) {
            results[recordType] = ['Not found'];
          }
        } else {
          results[recordType] = ['Error: ${e.toString()}'];
        }
      }

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

  int _getDnsType(String recordType) {
    switch (recordType) {
      case 'A':
        return 1;
      case 'AAAA':
        return 28;
      case 'MX':
        return 15;
      case 'NS':
        return 2;
      case 'TXT':
        return 16;
      case 'CNAME':
        return 5;
      default:
        return 1;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ToolScreenWrapper(
      title: 'DNS Lookup',
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
                              keyboardType: TextInputType.url,
                              textInputAction: TextInputAction.search,
                              onSubmitted: (_) {
                                if (_isLoading) return;
                                FocusScope.of(context).unfocus();
                                _performDnsLookup();
                              },
                              decoration: CommonInputDecoration.textField(
                                labelText: 'Domain Name',
                                hintText: 'example.com',
                              ),
                            ),
                            const SizedBox(height: 16),
                            DropdownButtonFormField<String>(
                              value: _recordTypeController.text.isEmpty 
                                  ? _recordTypes.first 
                                  : _recordTypeController.text,
                              decoration: CommonInputDecoration.textField(
                                labelText: 'Record Type',
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
                                  setState(() {
                                    _recordTypeController.text = value;
                                  });
                                }
                              },
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: _isLoading
                                  ? null
                                  : () {
                                      FocusScope.of(context).unfocus();
                                      _performDnsLookup();
                                    },
                              icon: _isLoading
                                  ? const CommonLoadingIndicator(
                                      size: 20,
                                      color: Colors.white,
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
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.red.withOpacity(0.3)),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(Icons.error_outline, color: Colors.red.shade300, size: 20),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    _error!,
                                    style: const TextStyle(color: Colors.white, fontSize: 14),
                                  ),
                                ),
                              ],
                            ),
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
    );
  }
}
