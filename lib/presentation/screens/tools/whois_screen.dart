import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:clipboard/clipboard.dart';
import 'package:share_plus/share_plus.dart';

import '../../widgets/glass_card.dart';
import '../../widgets/gradient_text.dart';
import '../../widgets/tool_screen_wrapper.dart';
import '../../widgets/common_input_decoration.dart';
import '../../widgets/loading_indicator.dart';

class WhoisScreen extends StatefulWidget {
  const WhoisScreen({super.key});

  @override
  State<WhoisScreen> createState() => _WhoisScreenState();
}

class _WhoisScreenState extends State<WhoisScreen> {
  final TextEditingController _domainController = TextEditingController();
  String? _whoisData;
  Map<String, dynamic>? _parsedWhoisData;
  bool _isLoading = false;
  String? _error;
  String? _currentDomain;

  Map<String, dynamic>? _asStringMap(dynamic value) {
    if (value is Map) {
      try {
        return Map<String, dynamic>.from(value);
      } catch (_) {
        final raw = value as Map;
        return raw.map((k, v) => MapEntry(k.toString(), v));
      }
    }
    return null;
  }

  // Normalize user input to a clean domain (strip protocol, www, path)
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

  // Basic domain validator: labels 1-63 chars, no leading/trailing hyphen, valid TLD or punycode
  bool _isValidDomain(String domain) {
    final re = RegExp(r'^(?!-)(?:[a-z0-9-]{1,63}(?<!-)\.)+(?:[a-z]{2,63}|xn--[a-z0-9]{1,59})$');
    return re.hasMatch(domain);
  }

  @override
  void dispose() {
    _domainController.dispose();
    super.dispose();
  }

  Future<void> _performWhoisLookup() async {
    final normalized = _normalizeDomain(_domainController.text);
    if (normalized.isEmpty) {
      setState(() => _error = 'Please enter a domain name');
      return;
    }
    if (!_isValidDomain(normalized)) {
      setState(() => _error = 'Please enter a valid domain (e.g., example.com)');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
      _whoisData = null;
      _parsedWhoisData = null;
      _currentDomain = normalized;
      // Reflect normalized value back to input
      _domainController.text = normalized;
      _domainController.selection = TextSelection.fromPosition(
        TextPosition(offset: normalized.length),
      );
    });

    try {
      final dio = Dio();
      
      // Try multiple WHOIS APIs as fallback
      // Primary: domainsduck.com (reliable API with API key)
      // Fallbacks: Free public APIs
      final apis = [
        {
          'url': 'https://us.domainsduck.com/api/get/?domain=$normalized&apikey=N7XSP6DFBKM9&whois=1',
          'type': 'domainsduck',
        },
        {
          'url': 'https://api.hackertarget.com/whois/?q=$normalized',
          'type': 'hackertarget',
        },
        {
          'url': 'https://dns-api.org/whois/$normalized',
          'type': 'dnsapi',
        },
      ];

      bool success = false;
      String? lastError;
      
      for (final api in apis) {
        try {
          final response = await dio.get(
            api['url']!,
        options: Options(
              headers: {
                'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
                'Accept': 'application/json, text/plain, */*',
              },
              receiveTimeout: const Duration(seconds: 20),
              followRedirects: true,
              validateStatus: (status) => status! < 500, // Accept 4xx as valid responses
            ),
          );

          if (response.statusCode == 200 && response.data != null) {
            String whoisText = '';
            
            if (response.data is String) {
              whoisText = response.data as String;
              // Remove HTML tags if present
              whoisText = whoisText.replaceAll(RegExp(r'<[^>]*>'), '');
            } else if (response.data is Map) {
              // Try to extract whois data from JSON response
              Map<String, dynamic> data;
              try {
                data = Map<String, dynamic>.from(response.data as Map);
              } catch (_) {
                final raw = response.data as Map;
                data = raw.map((key, value) => MapEntry(key.toString(), value));
              }
              
              if (api['type'] == 'domainsduck') {
                // Check for domainsduck API errors first
                if (data['availability'] != null) {
                  // This is an availability response, not WHOIS
                  // Check if it's an error message
                  final availability = data['availability'].toString().toLowerCase();
                  if (availability == 'rate limit exceeded' ||
                      availability == 'key invalid' ||
                      availability == 'no permissions' ||
                      availability == 'out of credits' ||
                      availability == 'bad tld' ||
                      availability == 'unknown error') {
                    lastError = 'API Error: ${data['availability']}';
                    continue;
                  }
                }
                
                // Store parsed data for formatted display
                _parsedWhoisData = data;
                
                // Parse domainsduck.com format
                if (data['RawWhois'] != null) {
                  // Use raw WHOIS text if available (most complete)
                  whoisText = data['RawWhois'].toString();
                } else if (data['RawRdap'] != null) {
                  // Use RDAP data if WHOIS is not available
                  whoisText = data['RawRdap'].toString();
                } else if (data['DomainName'] != null) {
                  // Format structured data if we have domain info
                  whoisText = _formatDomainsDuckWhois(data);
                } else {
                  // No valid data
                  lastError = 'No WHOIS data available';
                  continue;
                }
              } else if (api['type'] == 'dnsapi') {
                // Parse dns-api.org format
                if (data['whois'] != null) {
                  whoisText = data['whois'].toString();
                } else if (data['raw'] != null) {
                  whoisText = data['raw'].toString();
                } else {
                  whoisText = _formatWhoisFromJson(data);
                }
              } else if (data['WhoisRecord'] != null) {
                // Parse whoisxmlapi.com format
                final record = _asStringMap(data['WhoisRecord']);
                if (record != null) {
                  whoisText = _formatWhoisXmlApi(record, normalized);
                } else {
                  lastError = 'Unexpected WHOIS format';
                  continue;
                }
              } else if (data['ErrorMessage'] != null) {
                lastError = data['ErrorMessage']['msg']?.toString() ?? 'API error';
                continue;
              } else if (data['whois'] != null) {
                whoisText = data['whois'].toString();
              } else if (data['raw'] != null) {
                whoisText = data['raw'].toString();
              } else if (data['data'] != null && data['data'] is Map) {
                final m = _asStringMap(data['data']);
                whoisText = _formatWhoisFromJson(m ?? {});
              } else {
                // Try to format JSON data
                whoisText = _formatWhoisFromJson(data);
              }
            } else {
              whoisText = response.data.toString();
            }

            // Clean and validate whois data
            whoisText = whoisText.trim();
            
            // Check if we got valid whois data
            // Look for common WHOIS indicators or just check if it's not an error
            final lowerText = whoisText.toLowerCase();
            final isErrorResponse = lowerText.contains('api rate limit') ||
                lowerText.contains('quota exceeded') ||
                lowerText.contains('too many requests') ||
                lowerText.contains('access denied') ||
                lowerText.contains('invalid api') ||
                (lowerText.contains('error') && whoisText.length < 50);
            
            final isNotFound = lowerText.contains('not found') ||
                lowerText.contains('invalid domain') ||
                lowerText.contains('domain not registered') ||
                lowerText.contains('no match');
            
            // Accept any response that's not an error and has reasonable length
            if (whoisText.isNotEmpty && 
                !isErrorResponse &&
                !isNotFound &&
                whoisText.length > 10) {
              
              if (!mounted) return;
              setState(() {
                _whoisData = whoisText;
                // If we have parsed data from domainsduck, keep it
                // Otherwise try to parse the text
                if (_parsedWhoisData == null && api['type'] != 'domainsduck') {
                  _parsedWhoisData = _parseWhoisText(whoisText);
                }
                _isLoading = false;
              });
              success = true;
              break;
            } else if (isErrorResponse) {
              lastError = 'API rate limit or access denied';
              continue;
            } else if (isNotFound) {
              lastError = 'Domain not found or invalid';
              continue;
            }
          } else if (response.statusCode != null && response.statusCode! >= 400) {
            // Handle API errors
            if (response.data is Map) {
              final errorData = response.data as Map;
              lastError = errorData['error']?.toString() ?? 
                         errorData['message']?.toString() ?? 
                         'API returned error';
            }
          }
        } catch (e) {
          // Store error but try next API
          if (lastError == null) {
            lastError = 'Network error: ${e.toString()}';
          }
          // Try next API
          continue;
        }
      }

      if (!success) {
        if (!mounted) return;
        setState(() {
          _error = lastError != null 
              ? 'Unable to fetch WHOIS data: $lastError\n\nPlease check the domain name and try again.'
              : 'Unable to fetch WHOIS data. Please check the domain name and try again.';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Error: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  String _formatWhoisFromJson(Map<String, dynamic> data) {
    final buffer = StringBuffer();
    
    if (data['domain'] != null) {
      buffer.writeln('Domain: ${data['domain']}');
    }
    if (data['registrar'] != null) {
      buffer.writeln('Registrar: ${data['registrar']}');
    }
    if (data['created'] != null || data['createdDate'] != null) {
      buffer.writeln('Created: ${data['created'] ?? data['createdDate']}');
    }
    if (data['updated'] != null || data['updatedDate'] != null) {
      buffer.writeln('Updated: ${data['updated'] ?? data['updatedDate']}');
    }
    if (data['expires'] != null || data['expiresDate'] != null) {
      buffer.writeln('Expires: ${data['expires'] ?? data['expiresDate']}');
    }
    if (data['nameServers'] != null) {
      buffer.writeln('Name Servers:');
      final ns = data['nameServers'];
      if (ns is List) {
        for (var server in ns) {
          if (server is Map) {
            buffer.writeln('  - ${server['name'] ?? server.toString()}');
          } else {
            buffer.writeln('  - $server');
          }
        }
      } else if (ns is String) {
        buffer.writeln('  - $ns');
      }
    }
    if (data['registrant'] != null) {
      buffer.writeln('Registrant: ${data['registrant']}');
    }
    if (data['status'] != null) {
      buffer.writeln('Status: ${data['status']}');
    }
    
    return buffer.toString();
  }

  String _formatDomainsDuckWhois(Map<String, dynamic> data) {
    final buffer = StringBuffer();
    
    if (data['DomainName'] != null) {
      buffer.writeln('Domain: ${data['DomainName']}');
    }
    
    if (data['Registrar'] != null) {
      buffer.writeln('Registrar: ${data['Registrar']}');
    }
    
    if (data['CreationDate'] != null) {
      buffer.writeln('Created: ${data['CreationDate']}');
    }
    
    if (data['UpdatedDate'] != null) {
      buffer.writeln('Updated: ${data['UpdatedDate']}');
    }
    
    if (data['ExpiryDate'] != null) {
      buffer.writeln('Expires: ${data['ExpiryDate']}');
    }
    
    if (data['NameServer'] != null) {
      buffer.writeln('Name Servers:');
      final ns = data['NameServer'];
      if (ns is List) {
        for (var server in ns) {
          buffer.writeln('  - $server');
        }
      } else if (ns is String) {
        buffer.writeln('  - $ns');
      }
    }
    
    if (data['Status'] != null) {
      buffer.writeln('Status:');
      final status = data['Status'];
      if (status is List) {
        for (var s in status) {
          buffer.writeln('  - $s');
        }
      } else {
        buffer.writeln('  - $status');
      }
    }
    
    if (data['Contacts'] != null) {
      final contacts = data['Contacts'] as Map<String, dynamic>?;
      if (contacts != null) {
        if (contacts['Registrant'] != null) {
          final registrant = _asStringMap(contacts['Registrant']);
          if (registrant != null) {
            buffer.writeln('\nRegistrant:');
            if (registrant['Name'] != null) {
              buffer.writeln('  Name: ${registrant['Name']}');
            }
            if (registrant['Organization'] != null) {
              buffer.writeln('  Organization: ${registrant['Organization']}');
            }
            if (registrant['Country'] != null) {
              buffer.writeln('  Country: ${registrant['Country']}');
            }
            if (registrant['Email'] != null) {
              buffer.writeln('  Email: ${registrant['Email']}');
            }
          }
        }
      }
    }
    
    if (data['RegistrarAbuseEmail'] != null) {
      buffer.writeln('\nRegistrar Abuse Email: ${data['RegistrarAbuseEmail']}');
    }
    
    if (data['RegistrarAbusePhone'] != null) {
      buffer.writeln('Registrar Abuse Phone: ${data['RegistrarAbusePhone']}');
    }
    
    return buffer.toString();
  }

  String _formatWhoisXmlApi(Map<String, dynamic> record, String domain) {
    final buffer = StringBuffer();
    
    buffer.writeln('Domain: ${record['domainName'] ?? domain}');
    
    if (record['registrarName'] != null) {
      buffer.writeln('Registrar: ${record['registrarName']}');
    }
    
    if (record['createdDate'] != null) {
      buffer.writeln('Created: ${record['createdDate']}');
    }
    
    if (record['updatedDate'] != null) {
      buffer.writeln('Updated: ${record['updatedDate']}');
    }
    
    if (record['expiresDate'] != null) {
      buffer.writeln('Expires: ${record['expiresDate']}');
    }
    
    if (record['nameServers'] != null) {
      buffer.writeln('Name Servers:');
      final ns = record['nameServers'];
      if (ns is Map && ns['rawText'] != null) {
        final rawText = ns['rawText'];
        if (rawText is List) {
          for (var server in rawText) {
            buffer.writeln('  - $server');
          }
        } else {
          buffer.writeln('  - $rawText');
        }
      } else if (ns is List) {
        for (var server in ns) {
          buffer.writeln('  - $server');
        }
      }
    }
    
    if (record['registrant'] != null) {
      final registrant = _asStringMap(record['registrant']);
      if (registrant != null) {
        buffer.writeln('\nRegistrant:');
        if (registrant['name'] != null) {
          buffer.writeln('  Name: ${registrant['name']}');
        }
        if (registrant['organization'] != null) {
          buffer.writeln('  Organization: ${registrant['organization']}');
        }
        if (registrant['country'] != null) {
          buffer.writeln('  Country: ${registrant['country']}');
        }
      }
    }
    
    return buffer.toString();
  }

  Map<String, dynamic> _parseWhoisText(String whoisText) {
    final parsed = <String, dynamic>{};
    final lines = whoisText.split('\n');
    
    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;
      
      // Parse common WHOIS patterns
      if (trimmed.toLowerCase().startsWith('domain name:')) {
        parsed['DomainName'] = trimmed.substring('Domain Name:'.length).trim();
      } else if (trimmed.toLowerCase().startsWith('registrar:')) {
        parsed['Registrar'] = trimmed.substring('Registrar:'.length).trim();
      } else if (trimmed.toLowerCase().contains('creation date:') || 
                 trimmed.toLowerCase().contains('created date:')) {
        final match = RegExp(r'[Cc]reation [Dd]ate:\s*(.+)', caseSensitive: false).firstMatch(trimmed);
        if (match != null) parsed['CreationDate'] = match.group(1)?.trim();
      } else if (trimmed.toLowerCase().contains('updated date:') ||
                 trimmed.toLowerCase().contains('last updated:')) {
        final match = RegExp(r'[Uu]pdated [Dd]ate:\s*(.+)', caseSensitive: false).firstMatch(trimmed);
        if (match != null) parsed['UpdatedDate'] = match.group(1)?.trim();
      } else if (trimmed.toLowerCase().contains('expiry date:') ||
                 trimmed.toLowerCase().contains('expiration date:') ||
                 trimmed.toLowerCase().contains('registry expiry date:')) {
        final match = RegExp(r'[Ee]xpir[^:]+:\s*(.+)', caseSensitive: false).firstMatch(trimmed);
        if (match != null) parsed['ExpiryDate'] = match.group(1)?.trim();
      } else if (trimmed.toLowerCase().contains('name server:') ||
                 trimmed.toLowerCase().startsWith('nameserver')) {
        final match = RegExp(r'[Nn]ame [Ss]erver[^:]*:\s*(.+)', caseSensitive: false).firstMatch(trimmed);
        if (match != null) {
          final ns = match.group(1)?.trim();
          if (ns != null) {
            if (parsed['NameServer'] == null) {
              parsed['NameServer'] = <String>[];
            }
            (parsed['NameServer'] as List).add(ns);
          }
        }
      }
    }
    
    return parsed;
  }

  Widget _buildFormattedWhoisView() {
    if (_parsedWhoisData == null) return const SizedBox();
    
    final data = _parsedWhoisData!;
    final nameServers = data['NameServer'];
    final statusData = data['Status'];
    
    // Helper to safely check if value is a non-empty list
    bool isNonEmptyList(dynamic value) {
      return value != null && value is Iterable && value.isNotEmpty;
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Domain Information Section
        if (data['DomainName'] != null || data['Registrar'] != null) ...[
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.domain,
                        color: Colors.blue,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Domain Information',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (data['DomainName'] != null)
                  _buildFormattedRow('Domain', data['DomainName'].toString(), Icons.language),
                if (data['Registrar'] != null) ...[
                  if (data['DomainName'] != null) const SizedBox(height: 12),
                  _buildFormattedRow('Registrar', data['Registrar'].toString(), Icons.business),
                ],
              ],
            ),
          ),
        ],
        
        // Dates Section
        if (data['CreationDate'] != null || 
            data['UpdatedDate'] != null || 
            data['ExpiryDate'] != null) ...[
          const SizedBox(height: 16),
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.calendar_today,
                        color: Colors.green,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Important Dates',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (data['CreationDate'] != null)
                  _buildFormattedRow('Created', _formatDate(data['CreationDate'].toString()), Icons.add_circle),
                if (data['UpdatedDate'] != null) ...[
                  if (data['CreationDate'] != null) const SizedBox(height: 12),
                  _buildFormattedRow('Updated', _formatDate(data['UpdatedDate'].toString()), Icons.update),
                ],
                if (data['ExpiryDate'] != null) ...[
                  if (data['UpdatedDate'] != null || data['CreationDate'] != null) const SizedBox(height: 12),
                  _buildFormattedRow('Expires', _formatDate(data['ExpiryDate'].toString()), Icons.event),
                ],
              ],
            ),
          ),
        ],
        
        // Name Servers Section
        if (isNonEmptyList(nameServers)) ...[
          const SizedBox(height: 16),
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.purple.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.dns,
                        color: Colors.purple,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Name Servers',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ...(nameServers as Iterable).map((ns) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Icon(
                          Icons.circle,
                          size: 8,
                          color: Colors.purple.withOpacity(0.8),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: SelectableText(
                            ns.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontFamily: 'monospace',
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
        
        // Status Section
        if (statusData != null) ...[
          const SizedBox(height: 16),
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.info,
                        color: Colors.orange,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Domain Status',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (isNonEmptyList(statusData)) ...[
                  ...(statusData as Iterable).map((statusItem) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Icon(
                            Icons.check_circle,
                            size: 16,
                            color: Colors.green.withOpacity(0.8),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              statusItem.toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ] else ...[
                  Text(
                    statusData.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
        
        // Contacts Section
        if (data['Contacts'] != null) ...[
          const SizedBox(height: 16),
          _buildContactsSection(_asStringMap(data['Contacts'])),
        ],
        
        // Registrar Abuse Section
        if (data['RegistrarAbuseEmail'] != null || data['RegistrarAbusePhone'] != null) ...[
          const SizedBox(height: 16),
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.report,
                        color: Colors.red,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Registrar Abuse Contact',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (data['RegistrarAbuseEmail'] != null)
                  _buildFormattedRow('Email', data['RegistrarAbuseEmail'].toString(), Icons.email),
                if (data['RegistrarAbusePhone'] != null) ...[
                  if (data['RegistrarAbuseEmail'] != null) const SizedBox(height: 12),
                  _buildFormattedRow('Phone', data['RegistrarAbusePhone'].toString(), Icons.phone),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildFormattedRow(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: Colors.white.withOpacity(0.8),
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                SelectableText(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactsSection(Map<String, dynamic>? contacts) {
    if (contacts == null) return const SizedBox();
    
    return GlassCard(
          child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.teal.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.contacts,
                  color: Colors.teal,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Contact Information',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (contacts['Registrant'] != null) ...[
            _buildContactCard('Registrant', _asStringMap(contacts['Registrant'])),
          ],
          if (contacts['Admin'] != null) ...[
            if (contacts['Registrant'] != null) const SizedBox(height: 12),
            _buildContactCard('Admin', _asStringMap(contacts['Admin'])),
          ],
          if (contacts['Tech'] != null) ...[
            if (contacts['Admin'] != null || contacts['Registrant'] != null) const SizedBox(height: 12),
            _buildContactCard('Tech', _asStringMap(contacts['Tech'])),
          ],
        ],
      ),
    );
  }

  Widget _buildContactCard(String title, Map<String, dynamic>? contact) {
    if (contact == null) return const SizedBox();
    
    final hasData = contact['Name'] != null ||
        contact['Organization'] != null ||
        contact['Email'] != null ||
        contact['Country'] != null ||
        contact['State'] != null;
    
    if (!hasData) return const SizedBox();
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: Colors.teal.withOpacity(0.9),
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          if (contact['Name'] != null)
            _buildContactRow('Name', contact['Name'].toString()),
          if (contact['Organization'] != null) ...[
            if (contact['Name'] != null) const SizedBox(height: 4),
            _buildContactRow('Organization', contact['Organization'].toString()),
          ],
          if (contact['Email'] != null) ...[
            if (contact['Organization'] != null || contact['Name'] != null) const SizedBox(height: 4),
            _buildContactRow('Email', contact['Email'].toString()),
          ],
          if (contact['Country'] != null) ...[
            if (contact['Email'] != null || contact['Organization'] != null || contact['Name'] != null) const SizedBox(height: 4),
            _buildContactRow('Country', contact['Country'].toString()),
          ],
          if (contact['State'] != null) ...[
            if (contact['Country'] != null || contact['Email'] != null || contact['Organization'] != null || contact['Name'] != null) const SizedBox(height: 4),
            _buildContactRow('State', contact['State'].toString()),
          ],
        ],
      ),
    );
  }

  Widget _buildContactRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 90,
          child: Text(
            '$label:',
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: 12,
            ),
          ),
        ),
              Expanded(
          child: SelectableText(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRawWhoisView() {
    void _shareWhois() {
      if (_whoisData == null || _whoisData!.isEmpty) return;
      final subject = _currentDomain != null ? 'WHOIS: $_currentDomain' : 'WHOIS Result';
      Share.share(_whoisData!, subject: subject);
    }
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const GradientText(
                'Raw WHOIS Data',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.share, color: Colors.white, size: 20),
                    onPressed: _shareWhois,
                    tooltip: 'Share',
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy, color: Colors.white, size: 20),
                    onPressed: () {
                      if (_whoisData != null) {
                        final scaffoldContext = context;
                        FlutterClipboard.copy(_whoisData!).then((_) {
                          if (mounted) {
                            ScaffoldMessenger.of(scaffoldContext).showSnackBar(
                              const SnackBar(
                                content: Text('WHOIS data copied to clipboard!'),
                                duration: Duration(seconds: 2),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                        }).catchError((e) {
                          // Handle copy error silently
                        });
                      }
                    },
                    tooltip: 'Copy',
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            constraints: const BoxConstraints(maxHeight: 300),
                child: SingleChildScrollView(
              child: SelectableText(
                _whoisData ?? '',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontFamily: 'monospace',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String dateStr) {
    try {
      // Try to parse ISO format dates
      if (dateStr.contains('T')) {
        final date = DateTime.parse(dateStr);
        return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
      }
      return dateStr;
    } catch (e) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ToolScreenWrapper(
      title: 'WHOIS Lookup',
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
                    _performWhoisLookup();
                  },
                  decoration: CommonInputDecoration.textField(
                                labelText: 'Domain Name',
                                hintText: 'example.com',
                              ),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                  onPressed: _isLoading
                      ? null
                      : () {
                          FocusScope.of(context).unfocus();
                          _performWhoisLookup();
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
                      if (_whoisData != null) ...[
                        const SizedBox(height: 16),
            // Show formatted view if we have parsed data
            if (_parsedWhoisData != null) ...[
              _buildFormattedWhoisView(),
              const SizedBox(height: 16),
              // Also show raw data in expandable section
              _buildRawWhoisView(),
            ] else ...[
              // Show raw text if no parsed data
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
        ],
      ),
    );
  }
}

