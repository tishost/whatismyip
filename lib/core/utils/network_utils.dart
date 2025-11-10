import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';

class NetworkUtils {
  static Future<String?> getPrivateIp() async {
    try {
      for (final interface in await NetworkInterface.list()) {
        for (final addr in interface.addresses) {
          if (addr.type == InternetAddressType.IPv4 && 
              !addr.address.startsWith('127.')) {
            return addr.address;
          }
        }
      }
    } catch (e) {
      return null;
    }
    return null;
  }

  static Future<String?> getPrivateIpv6() async {
    try {
      for (final interface in await NetworkInterface.list()) {
        for (final addr in interface.addresses) {
          if (addr.type == InternetAddressType.IPv6 && 
              !addr.address.startsWith('::1') &&
              !addr.address.startsWith('fe80:')) {
            return addr.address;
          }
        }
      }
    } catch (e) {
      return null;
    }
    return null;
  }

  static Future<dynamic> checkConnectivity() async {
    final connectivity = Connectivity();
    return await connectivity.checkConnectivity();
  }

  static bool isConnected(dynamic result) {
    if (result is List<ConnectivityResult>) {
      return result.isNotEmpty && !result.contains(ConnectivityResult.none);
    }
    return result != ConnectivityResult.none;
  }

  /// Get connection type (WiFi or Mobile Data)
  static Future<String> getConnectionType() async {
    try {
      final connectivity = Connectivity();
      final result = await connectivity.checkConnectivity();
      
      // Handle both single result and list of results
      ConnectivityResult connectionResult;
      if (result is List<ConnectivityResult>) {
        final results = result as List<ConnectivityResult>;
        connectionResult = results.isNotEmpty ? results.first : ConnectivityResult.none;
      } else {
        connectionResult = result as ConnectivityResult;
      }
      
      if (connectionResult == ConnectivityResult.wifi) {
        return 'WiFi';
      } else if (connectionResult == ConnectivityResult.mobile) {
        return 'Mobile Data';
      } else if (connectionResult == ConnectivityResult.ethernet) {
        return 'Ethernet';
      } else if (connectionResult == ConnectivityResult.vpn) {
        return 'VPN';
      } else {
        return 'Unknown';
      }
    } catch (e) {
      return 'Unknown';
    }
  }

  /// Get DNS servers
  static Future<List<String>> getDnsServers() async {
    try {
      final dnsServers = <String>[];
      
      // Try to get DNS from network interfaces
      for (final interface in await NetworkInterface.list()) {
        for (final addr in interface.addresses) {
          // Check if this is a DNS server (usually gateway)
          if (addr.type == InternetAddressType.IPv4) {
            // Common DNS servers
            final ip = addr.address;
            // Check if it's a valid IP that could be a DNS server
            if (!ip.startsWith('127.') && !ip.startsWith('169.254.')) {
              // Get gateway/DNS from interface
              // Note: This is a simplified approach
              // For Android, we might need platform channels
            }
          }
        }
      }
      
      // Default DNS servers if none found
      if (dnsServers.isEmpty) {
        // Common public DNS servers
        dnsServers.addAll([
          '8.8.8.8',      // Google DNS
          '8.8.4.4',      // Google DNS
          '1.1.1.1',      // Cloudflare DNS
        ]);
      }
      
      return dnsServers;
    } catch (e) {
      // Return default DNS servers on error
      return ['8.8.8.8', '8.8.4.4'];
    }
  }

  /// Get primary DNS server (first one)
  static Future<String> getPrimaryDns() async {
    final dnsServers = await getDnsServers();
    return dnsServers.isNotEmpty ? dnsServers.first : '8.8.8.8';
  }

  static String formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(2)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  static String formatSpeed(double mbps) {
    return '${mbps.toStringAsFixed(2)} Mbps';
  }
}

