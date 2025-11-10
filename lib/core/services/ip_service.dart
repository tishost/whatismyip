import 'package:dio/dio.dart';
import '../../data/models/ip_info.dart';
import '../constants/app_constants.dart';

class IpService {
  final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: AppConstants.networkTimeout,
      receiveTimeout: AppConstants.networkTimeout,
      sendTimeout: AppConstants.networkTimeout,
    ),
  );
  String? _primaryApiEndpoint;

  IpService({String? apiEndpoint}) : _primaryApiEndpoint = apiEndpoint;

  Future<String?> getPublicIp() async {
    for (final endpoint in AppConstants.fallbackIpEndpoints) {
      try {
        final response = await _dio.get(endpoint, options: Options(
          receiveTimeout: AppConstants.networkReceiveTimeout,
        ));
        
        if (response.data is Map) {
          return response.data['ip'] ?? response.data['query'];
        } else if (response.data is String) {
          return response.data.trim();
        }
      } catch (e) {
        continue;
      }
    }
    return null;
  }

  /// Verify IP from multiple sources to ensure accuracy
  /// Returns the most common IP found, or null if verification fails
  /// If ipFromOwnApi is empty, just returns the most common IP from sources
  Future<String?> _verifyPublicIp(String ipFromOwnApi) async {
    final ipSources = <String>[];
    
    // Collect IPs from multiple reliable sources
    final verifyEndpoints = [
      'https://api.ipify.org?format=json',
      'https://api.ip.sb/ip',
      'https://ipinfo.io/json',
      'https://api.ipify.org',
    ];
    
    for (final endpoint in verifyEndpoints) {
      try {
        final response = await _dio.get(
          endpoint,
          options: Options(
            receiveTimeout: const Duration(seconds: 3),
          ),
        );
        
        String? ip;
        if (response.data is Map) {
          ip = response.data['ip'] ?? response.data['query'];
        } else if (response.data is String) {
          ip = response.data.trim();
        }
        
        if (ip != null && ip.isNotEmpty) {
          ipSources.add(ip);
        }
      } catch (e) {
        continue;
      }
    }
    
    if (ipSources.isEmpty) {
      return null; // Verification failed
    }
    
    // Count occurrences of each IP
    final ipCounts = <String, int>{};
    for (final ip in ipSources) {
      ipCounts[ip] = (ipCounts[ip] ?? 0) + 1;
    }
    
    // Find the most common IP
    String? mostCommonIp;
    int maxCount = 0;
    for (final entry in ipCounts.entries) {
      if (entry.value > maxCount) {
        maxCount = entry.value;
        mostCommonIp = entry.key;
      }
    }
    
    // If ipFromOwnApi is empty, just return the most common IP
    if (ipFromOwnApi.isEmpty) {
      return mostCommonIp;
    }
    
    // If own API IP matches the most common IP, return it
    // Otherwise return the most common IP (which is likely correct)
    if (mostCommonIp == ipFromOwnApi) {
      return ipFromOwnApi; // Verified
    } else {
      return mostCommonIp; // Return verified IP from other sources
    }
  }

  Future<IpInfo?> fetchIpInfo({String? ip}) async {
    // For visitor's own IP, verify first before calling own API
    String? verifiedIp;
    if (ip == null || ip.isEmpty) {
      // Get verified IP from multiple sources first
      verifiedIp = await _verifyPublicIp('');
    }
    
    // Try own API (digdns.io) first
    try {
      // Use verified IP if available, otherwise use provided IP
      final lookupIp = verifiedIp ?? ip;
      final ownApiInfo = await _fetchFromOwnApi(lookupIp);
      
      if (ownApiInfo != null && ownApiInfo.ipv4 != null) {
        // For visitor's own IP, ensure we use verified IP
        if (ip == null || ip.isEmpty) {
          // Use verified IP instead of own API IP if different
          final finalIpv4 = verifiedIp ?? ownApiInfo.ipv4;
          
          // Only fetch IPv6 if we're looking up visitor's own IP (ip == null)
          String? ipv6 = ownApiInfo.ipv6;
          if ((ip == null || ip.isEmpty) && (ipv6 == null || ipv6.isEmpty)) {
            // Only fetch visitor's own IPv6, not for specific IP lookups
            ipv6 = await _fetchPublicIpv6();
          }
          
          // Validate IPv6 (must be public, not private)
          if (ipv6 != null && ipv6.isNotEmpty) {
            if (!_isValidPublicIpv6(ipv6)) {
              ipv6 = null; // Don't show private IPv6
            }
          }
          
          // Return with verified IP and own API data
          return IpInfo(
            ipv4: finalIpv4, // Use verified IP
            ipv6: ipv6,
            isp: ownApiInfo.isp,
            asn: ownApiInfo.asn,
            country: ownApiInfo.country,
            countryCode: ownApiInfo.countryCode,
            city: ownApiInfo.city,
            region: ownApiInfo.region,
            zip: ownApiInfo.zip,
            latitude: ownApiInfo.latitude,
            longitude: ownApiInfo.longitude,
            timezone: ownApiInfo.timezone,
            isVpn: ownApiInfo.isVpn,
            isProxy: ownApiInfo.isProxy,
            isTor: ownApiInfo.isTor,
            hostname: ownApiInfo.hostname,
            organization: ownApiInfo.organization,
            timestamp: ownApiInfo.timestamp,
            abuseConfidenceScore: ownApiInfo.abuseConfidenceScore,
            isBlacklisted: ownApiInfo.isBlacklisted,
            threatType: ownApiInfo.threatType,
          );
        } else {
          // For specific IP lookups, use own API directly
          return IpInfo(
            ipv4: ownApiInfo.ipv4,
            ipv6: ownApiInfo.ipv6,
            isp: ownApiInfo.isp,
            asn: ownApiInfo.asn,
            country: ownApiInfo.country,
            countryCode: ownApiInfo.countryCode,
            city: ownApiInfo.city,
            region: ownApiInfo.region,
            zip: ownApiInfo.zip,
            latitude: ownApiInfo.latitude,
            longitude: ownApiInfo.longitude,
            timezone: ownApiInfo.timezone,
            isVpn: ownApiInfo.isVpn,
            isProxy: ownApiInfo.isProxy,
            isTor: ownApiInfo.isTor,
            hostname: ownApiInfo.hostname,
            organization: ownApiInfo.organization,
            timestamp: ownApiInfo.timestamp,
            abuseConfidenceScore: ownApiInfo.abuseConfidenceScore,
            isBlacklisted: ownApiInfo.isBlacklisted,
            threatType: ownApiInfo.threatType,
          );
        }
      }
    } catch (e) {
      // Own API failed, continue to fallback
    }
    
    // Fallback to existing system (primary API)
    // Use verified IP if already fetched, otherwise fetch now
    if (verifiedIp == null && (ip == null || ip.isEmpty)) {
      // Get verified IP from multiple sources
      verifiedIp = await _verifyPublicIp(''); // Empty string to get IP from sources
    }
    
    try {
      // Use verified IP if available, otherwise use provided IP
      final lookupIp = verifiedIp ?? ip;
      final endpoint = _primaryApiEndpoint ?? 
          '${AppConstants.defaultIpApiEndpoint}/${lookupIp ?? ""}/json/';
      
      final response = await _dio.get(
        endpoint,
        options: Options(
          receiveTimeout: AppConstants.networkTimeout,
        ),
      );

      if (response.statusCode == 200) {
        final data = response.data;
        
        if (data['error'] != null) {
          return await _fetchFromIpInfo(lookupIp);
        }
        
        final ipInfo = IpInfo.fromJson(data);
        
        // Use verified IP if available, otherwise use API response IP
        final originalIpv4 = verifiedIp ?? ipInfo.ipv4;
        
        // Only fetch IPv6 if we're looking up visitor's own IP (ip == null)
        // Don't fetch IPv6 for specific IP lookups as it would be visitor's IPv6, not the lookup IP's
        String? ipv6 = ipInfo.ipv6;
        if ((ip == null || ip.isEmpty) && (ipv6 == null || ipv6.isEmpty)) {
          // Only fetch visitor's own IPv6, not for specific IP lookups
          ipv6 = await _fetchPublicIpv6();
        }
        
        // Validate IPv6 (must be public, not private)
        if (ipv6 != null && ipv6.isNotEmpty) {
          if (!_isValidPublicIpv6(ipv6)) {
            ipv6 = null; // Don't show private IPv6
          }
        }
        
        // Enhance with security data
        // Always use original IPv4 from API, never let IPv6 fetch overwrite it
        final enhancedInfo = await _enhanceWithSecurityData(
          IpInfo(
            ipv4: originalIpv4, // Preserve original IPv4
            ipv6: ipv6,
            isp: ipInfo.isp,
            asn: ipInfo.asn,
            country: ipInfo.country,
            countryCode: ipInfo.countryCode,
            city: ipInfo.city,
            region: ipInfo.region,
            zip: ipInfo.zip,
            latitude: ipInfo.latitude,
            longitude: ipInfo.longitude,
            timezone: ipInfo.timezone,
            isVpn: ipInfo.isVpn,
            isProxy: ipInfo.isProxy,
            isTor: ipInfo.isTor,
            hostname: ipInfo.hostname,
            organization: ipInfo.organization,
            timestamp: ipInfo.timestamp,
            abuseConfidenceScore: ipInfo.abuseConfidenceScore,
            isBlacklisted: ipInfo.isBlacklisted,
            threatType: ipInfo.threatType,
          ),
        );
        
        return enhancedInfo;
      }
    } catch (e) {
      // Try fallback API
      final ipInfo = await _fetchFromIpInfo(ip);
      if (ipInfo != null) {
        // Preserve original IPv4 from API response
        final originalIpv4 = ipInfo.ipv4;
        
        // Only fetch IPv6 if we're looking up visitor's own IP (ip == null)
        // Don't fetch IPv6 for specific IP lookups as it would be visitor's IPv6, not the lookup IP's
        String? ipv6 = ipInfo.ipv6;
        if ((ip == null || ip.isEmpty) && (ipv6 == null || ipv6.isEmpty)) {
          // Only fetch visitor's own IPv6, not for specific IP lookups
          ipv6 = await _fetchPublicIpv6();
        }
        
        // Validate IPv6 (must be public, not private)
        if (ipv6 != null && ipv6.isNotEmpty) {
          if (!_isValidPublicIpv6(ipv6)) {
            ipv6 = null; // Don't show private IPv6
          }
        }
        
        final enhancedInfo = await _enhanceWithSecurityData(
          IpInfo(
            ipv4: originalIpv4, // Preserve original IPv4
            ipv6: ipv6,
            isp: ipInfo.isp,
            asn: ipInfo.asn,
            country: ipInfo.country,
            countryCode: ipInfo.countryCode,
            city: ipInfo.city,
            region: ipInfo.region,
            zip: ipInfo.zip,
            latitude: ipInfo.latitude,
            longitude: ipInfo.longitude,
            timezone: ipInfo.timezone,
            isVpn: ipInfo.isVpn,
            isProxy: ipInfo.isProxy,
            isTor: ipInfo.isTor,
            hostname: ipInfo.hostname,
            organization: ipInfo.organization,
            timestamp: ipInfo.timestamp,
            abuseConfidenceScore: ipInfo.abuseConfidenceScore,
            isBlacklisted: ipInfo.isBlacklisted,
            threatType: ipInfo.threatType,
          ),
        );
        
        return enhancedInfo;
      }
    }
    return null;
  }

  Future<IpInfo?> _fetchFromOwnApi(String? ip) async {
    try {
      final endpoint = ip != null
          ? 'https://digdns.io/api/node/v1/ip/location?ip=$ip'
          : 'https://digdns.io/api/node/v1/ip/location';
      
      final response = await _dio.get(
        endpoint,
        options: Options(
          receiveTimeout: AppConstants.networkTimeout,
          headers: {
            'Accept': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200) {
        final data = response.data;
        
        // Check if response is successful
        if (data['success'] == true && data['data'] != null) {
          final responseData = data['data'];
          final proxy = responseData['proxy'] ?? {};
          
          // Parse timestamp
          DateTime? timestamp;
          if (responseData['timestamp'] != null) {
            timestamp = DateTime.tryParse(responseData['timestamp'].toString());
          }
          
          return IpInfo(
            ipv4: responseData['ip'],
            ipv6: null, // Will be fetched separately if needed
            isp: responseData['isp'],
            asn: null, // Not provided by own API
            country: responseData['country'],
            countryCode: responseData['countryCode'],
            city: responseData['city'],
            region: responseData['region'],
            zip: null, // Not provided by own API
            latitude: responseData['latitude'] != null 
                ? double.tryParse(responseData['latitude'].toString()) 
                : null,
            longitude: responseData['longitude'] != null 
                ? double.tryParse(responseData['longitude'].toString()) 
                : null,
            timezone: responseData['timezone'],
            isVpn: proxy['isVpn'] == true,
            isProxy: proxy['isProxy'] == true,
            isTor: proxy['isTor'] == true,
            hostname: responseData['domain']?.toString().isNotEmpty == true 
                ? responseData['domain'] 
                : null,
            organization: null, // Not provided by own API
            timestamp: timestamp,
            abuseConfidenceScore: null, // Not provided by own API
            isBlacklisted: null, // Not provided by own API
            threatType: null, // Not provided by own API
          );
        }
      }
    } catch (e) {
      // API failed or unavailable
      return null;
    }
    return null;
  }

  Future<String?> _fetchPublicIpv6() async {
    // Try multiple APIs to fetch public IPv6
    // Note: This only fetches visitor's own IPv6, not for specific IP lookups
    final ipv6Endpoints = [
      'https://api64.ipify.org?format=json',
      'https://ipv6.icanhazip.com',
      'https://v6.ident.me',
      'https://api6.ipify.org?format=json',
      'https://ipv6.whatismyip.akamai.com',
      'https://icanhazip.com/v6',
      'https://ifconfig.co/ip',
    ];
    
    for (final endpoint in ipv6Endpoints) {
      try {
        final response = await _dio.get(
          endpoint,
          options: Options(
            receiveTimeout: const Duration(seconds: 5),
            headers: {
              'Accept': 'application/json, text/plain, */*',
            },
          ),
        );
        
        String? ipv6;
        if (response.data is Map) {
          // Only extract IPv6, ignore IPv4 if present
          ipv6 = response.data['ipv6'] ?? response.data['address'];
          // If 'ip' field contains IPv6 format (has colons), use it
          if (ipv6 == null && response.data['ip'] != null) {
            final ip = response.data['ip'].toString();
            if (ip.contains(':')) {
              ipv6 = ip; // It's IPv6
            }
            // If it doesn't contain ':', it's IPv4, so ignore it
          }
        } else if (response.data is String) {
          final dataStr = response.data.toString().trim();
          // Only use if it contains ':' (IPv6 format)
          if (dataStr.contains(':')) {
            ipv6 = dataStr;
            // Remove any HTML tags or extra text
            ipv6 = ipv6.replaceAll(RegExp(r'<[^>]*>'), '').trim();
          }
        }
        
        if (ipv6 != null && ipv6.isNotEmpty) {
          // Clean up the IPv6 address
          ipv6 = ipv6.trim();
          // Remove any trailing newlines
          ipv6 = ipv6.replaceAll(RegExp(r'\s+'), '').trim();
          
          // Ensure it's actually IPv6 (contains colons)
          if (!ipv6.contains(':')) {
            continue; // Skip if it's not IPv6 format
          }
          
          // Validate it's a public IPv6
          if (_isValidPublicIpv6(ipv6)) {
            return ipv6;
          }
        }
      } catch (e) {
        continue;
      }
    }
    
    return null;
  }

  bool _isValidPublicIpv6(String ip) {
    if (ip.isEmpty) return false;
    
    // Remove whitespace
    ip = ip.trim();
    
    // Check if it contains colons (IPv6 characteristic)
    if (!ip.contains(':')) {
      return false; // Not IPv6 format
    }
    
    // Remove any trailing newlines or whitespace
    ip = ip.replaceAll(RegExp(r'\s+'), '').trim();
    
    // Check for private/local IPv6 addresses
    final lowerIp = ip.toLowerCase();
    
    // Split by :: to check first segment
    final parts = lowerIp.split('::');
    final firstPart = parts.isNotEmpty ? parts[0] : '';
    
    // fc00::/7 - Unique Local Addresses (ULA) - fc00:: to fdff::
    // Check first 2 hex digits
    if (firstPart.isNotEmpty) {
      final firstHex = firstPart.split(':').first;
      if (firstHex.length >= 2) {
        final prefix = firstHex.substring(0, 2);
        if (prefix == 'fc' || prefix == 'fd') {
          return false;
        }
      }
    }
    
    // fe80::/10 - Link-Local Addresses - fe80:: to febf::
    // Check first 3 hex digits
    if (firstPart.isNotEmpty) {
      final firstHex = firstPart.split(':').first;
      if (firstHex.length >= 3) {
        final prefix = firstHex.substring(0, 3);
        if (prefix == 'fe8' || prefix == 'fe9' || prefix == 'fea' || prefix == 'feb') {
          return false;
        }
      }
    }
    
    // ::1 - Loopback
    if (ip == '::1' || ip == '0:0:0:0:0:0:0:1' || lowerIp == '::1') {
      return false;
    }
    
    // 2001:db8::/32 - Documentation addresses
    if (lowerIp.startsWith('2001:db8:')) {
      return false;
    }
    
    // If it passes all checks, it's likely a public IPv6
    return true;
  }

  Future<IpInfo?> _fetchFromIpInfo(String? ip) async {
    try {
      final endpoint = ip != null 
          ? 'https://ipinfo.io/$ip/json'
          : 'https://ipinfo.io/json';
      
      final response = await _dio.get(
        endpoint,
        options: Options(
          receiveTimeout: AppConstants.networkTimeout,
        ),
      );

      if (response.statusCode == 200) {
        final data = response.data;
        
        double? lat, lon;
        if (data['loc'] != null) {
          final parts = data['loc'].toString().split(',');
          if (parts.length == 2) {
            lat = double.tryParse(parts[0]);
            lon = double.tryParse(parts[1]);
          }
        }
        
        return IpInfo(
          ipv4: data['ip'],
          ipv6: data['ipv6'], // ipinfo.io sometimes provides IPv6
          city: data['city'],
          region: data['region'],
          country: data['country'],
          zip: data['postal'],
          latitude: lat,
          longitude: lon,
          isp: data['org'],
          timezone: data['timezone'],
          hostname: data['hostname'],
        );
      }
    } catch (e) {
      return null;
    }
    return null;
  }

  Future<IpInfo> _enhanceWithSecurityData(IpInfo ipInfo) async {
    if (ipInfo.ipv4 == null) return ipInfo;
    
    try {
      // Check VPN/Proxy/TOR using ip-api.com
      final securityData = await _checkSecurityStatus(ipInfo.ipv4!);
      
      // Check abuse/threat data
      final abuseData = await _checkAbuseData(ipInfo.ipv4!);
      
      return IpInfo(
        ipv4: ipInfo.ipv4,
        ipv6: ipInfo.ipv6,
        isp: ipInfo.isp,
        asn: ipInfo.asn,
        country: ipInfo.country,
        countryCode: ipInfo.countryCode,
        city: ipInfo.city,
        region: ipInfo.region,
        zip: ipInfo.zip,
        latitude: ipInfo.latitude,
        longitude: ipInfo.longitude,
        timezone: ipInfo.timezone,
        isVpn: securityData['vpn'] == true ? true : (ipInfo.isVpn ?? false),
        isProxy: securityData['proxy'] == true ? true : (ipInfo.isProxy ?? false),
        isTor: securityData['tor'] == true ? true : (ipInfo.isTor ?? false),
        hostname: ipInfo.hostname,
        organization: ipInfo.organization,
        timestamp: ipInfo.timestamp,
        abuseConfidenceScore: abuseData['confidenceScore'],
        isBlacklisted: abuseData['isBlacklisted'],
        threatType: abuseData['threatType'],
      );
    } catch (e) {
      return ipInfo;
    }
  }

  Future<Map<String, dynamic>> _checkSecurityStatus(String ip) async {
    // Use multiple APIs and require confirmation from at least 2 sources
    Map<String, bool> vpnResults = {};
    Map<String, bool> proxyResults = {};
    Map<String, bool> torResults = {};
    
    // Method 1: vpnapi.io (most reliable)
    try {
      final response = await _dio.get(
        'https://vpnapi.io/api/$ip',
        options: Options(
          receiveTimeout: const Duration(seconds: 5),
          headers: {
            'Accept': 'application/json',
          },
        ),
      );
      
      if (response.statusCode == 200) {
        final data = response.data;
        final security = data['security'] ?? {};
        vpnResults['vpnapi'] = security['vpn'] == true;
        proxyResults['vpnapi'] = security['proxy'] == true;
        torResults['vpnapi'] = security['tor'] == true;
      }
    } catch (e) {
      // Continue to next method
    }
    
    // Method 2: ip-api.com (but don't use hosting as VPN indicator)
    try {
      final response = await _dio.get(
        'http://ip-api.com/json/$ip',
        queryParameters: {
          'fields': 'status,message,proxy,hosting',
        },
        options: Options(
          receiveTimeout: const Duration(seconds: 5),
        ),
      );
      
      if (response.statusCode == 200) {
        final data = response.data;
        if (data['status'] == 'success') {
          // Only use proxy, NOT hosting (hosting can be datacenter, not VPN)
          proxyResults['ipapi'] = data['proxy'] == true;
          // Don't set VPN from hosting alone - it's not accurate
        }
      }
    } catch (e) {
      // Continue
    }
    
    // Method 3: ipqualityscore.com (if available)
    try {
      final response = await _dio.get(
        'https://www.ipqualityscore.com/api/json/ip/',
        queryParameters: {
          'ip': ip,
          'strictness': '1',
          'allow_public_access_points': 'true',
          'fast': 'true',
        },
        options: Options(
          receiveTimeout: const Duration(seconds: 5),
        ),
      );
      
      if (response.statusCode == 200) {
        final data = response.data;
        if (data['success'] == true) {
          vpnResults['ipquality'] = data['is_vpn'] == true;
          proxyResults['ipquality'] = data['is_proxy'] == true;
          torResults['ipquality'] = data['is_tor'] == true;
        }
      }
    } catch (e) {
      // Continue
    }
    
    // Check TOR using tor-exit API
    try {
      final torResponse = await _dio.get(
        'https://check.torproject.org/api/ip',
        options: Options(
          receiveTimeout: const Duration(seconds: 3),
        ),
      );
      
      if (torResponse.statusCode == 200) {
        final torData = torResponse.data;
        if (torData['IsTor'] == true) {
          torResults['torproject'] = true;
        }
      }
    } catch (e) {
      // Ignore TOR check errors
    }
    
    // Decision logic: Require at least one positive result, but be conservative
    // For VPN: Require explicit VPN detection (not just hosting/datacenter)
    final vpnDetected = vpnResults.values.any((v) => v == true);
    final proxyDetected = proxyResults.values.any((v) => v == true);
    final torDetected = torResults.values.any((v) => v == true);
    
    return {
      'vpn': vpnDetected, // Only true if explicitly detected as VPN
      'proxy': proxyDetected,
      'tor': torDetected,
    };
  }

  Future<Map<String, dynamic>> _checkAbuseData(String ip) async {
    try {
      // Using AbuseIPDB API (requires API key, but we'll try without)
      // Alternative: Use ipqualityscore.com or similar
      final response = await _dio.get(
        'https://www.ipqualityscore.com/api/json/ip/',
        queryParameters: {
          'ip': ip,
          'strictness': '1',
          'allow_public_access_points': 'true',
          'fast': 'true',
        },
        options: Options(
          receiveTimeout: const Duration(seconds: 5),
        ),
      );
      
      if (response.statusCode == 200) {
        final data = response.data;
        if (data['success'] == true) {
          final threatTypes = <String>[];
          if (data['fraud_score'] != null && data['fraud_score'] > 75) {
            threatTypes.add('High Fraud Risk');
          }
          if (data['is_crawler'] == true) {
            threatTypes.add('Crawler/Bot');
          }
          if (data['is_tor'] == true) {
            threatTypes.add('TOR');
          }
          if (data['is_proxy'] == true) {
            threatTypes.add('Proxy');
          }
          if (data['is_vpn'] == true) {
            threatTypes.add('VPN');
          }
          
          return {
            'confidenceScore': data['fraud_score'],
            'isBlacklisted': data['abuse_velocity'] != null && data['abuse_velocity']! > 0,
            'threatType': threatTypes.isNotEmpty ? threatTypes.join(', ') : null,
          };
        }
      }
    } catch (e) {
      // API might require key or have rate limits
    }
    
    return {};
  }

  Future<bool> checkVpnProxy() async {
    try {
      final ipInfo = await fetchIpInfo();
      if (ipInfo == null) return false;
      
      final isVpn = ipInfo.isVpn ?? false;
      final isProxy = ipInfo.isProxy ?? false;
      final isTor = ipInfo.isTor ?? false;
      
      return isVpn || isProxy || isTor;
    } catch (e) {
      return false;
    }
  }

  Future<bool> checkBlacklist(String ip) async {
    try {
      final response = await _dio.get(
        'https://api.abuseipdb.com/api/v2/check',
        queryParameters: {'ipAddress': ip, 'maxAgeInDays': 90},
        options: Options(
          headers: {
            'Key': '',
            'Accept': 'application/json',
          },
        ),
      );
      
      if (response.statusCode == 200) {
        final data = response.data;
        return data['data']['abuseConfidenceScore'] > 0;
      }
    } catch (e) {
      // API key not configured
    }
    return false;
  }
}

