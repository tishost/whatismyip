import 'package:flutter/foundation.dart';
import '../../data/models/ip_info.dart';
import '../../core/services/ip_service.dart';
import '../../core/utils/network_utils.dart';

class IpProvider with ChangeNotifier {
  final IpService _ipService;
  
  IpInfo? _ipInfo;
  String? _privateIp;
  String? _privateIpv6;
  bool _isLoading = false;
  String? _error;
  bool _isVpnProxy = false;
  String? _connectionType;
  String? _dnsServer;

  IpProvider(this._ipService);

  IpInfo? get ipInfo => _ipInfo;
  String? get privateIp => _privateIp;
  String? get privateIpv6 => _privateIpv6;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isVpnProxy => _isVpnProxy;
  String? get connectionType => _connectionType;
  String? get dnsServer => _dnsServer;

  Future<void> fetchIpInfo({bool forceRefresh = false}) async {
    if (_isLoading && !forceRefresh) return;
    
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Check connectivity first
      final connectivity = await NetworkUtils.checkConnectivity();
      if (!NetworkUtils.isConnected(connectivity)) {
        _error = 'No internet connection. Please check your network.';
        _isLoading = false;
        notifyListeners();
        return;
      }

      // Get local info first (doesn't require network)
      _privateIp = await NetworkUtils.getPrivateIp();
      _privateIpv6 = await NetworkUtils.getPrivateIpv6();
      _connectionType = await NetworkUtils.getConnectionType();
      _dnsServer = await NetworkUtils.getPrimaryDns();
      
      // Fetch IP info with better error handling
      try {
        _ipInfo = await _ipService.fetchIpInfo();
        
        if (_ipInfo != null && _ipInfo!.ipv4 != null && _ipInfo!.ipv4!.isNotEmpty) {
          // Check VPN/Proxy in background (non-blocking)
          _ipService.checkVpnProxy().then((isVpn) {
            _isVpnProxy = isVpn;
            notifyListeners();
          }).catchError((_) {
            // Ignore VPN check errors
          });
          _error = null; // Clear any previous errors
        } else {
          // Try fallback method to get at least the IP
          final publicIp = await _ipService.getPublicIp();
          if (publicIp != null && publicIp.isNotEmpty) {
            // Create minimal IP info with just the IP
            _ipInfo = IpInfo(ipv4: publicIp);
            _error = null;
          } else {
            _error = 'Unable to fetch IP information. Please check your internet connection and try again.';
          }
        }
      } catch (e) {
        // Try to get at least the public IP as fallback
        try {
          final publicIp = await _ipService.getPublicIp();
          if (publicIp != null && publicIp.isNotEmpty) {
            _ipInfo = IpInfo(ipv4: publicIp);
            _error = null;
          } else {
            throw Exception('No IP available');
          }
        } catch (_) {
          // Determine error type and show appropriate message
          final errorStr = e.toString().toLowerCase();
          if (errorStr.contains('timeout') || errorStr.contains('timed out')) {
            _error = 'Connection timeout. Please check your internet speed and try again.';
          } else if (errorStr.contains('socket') || errorStr.contains('network') || errorStr.contains('connection')) {
            _error = 'Network connection failed. Please check your internet connection.';
          } else if (errorStr.contains('dns') || errorStr.contains('host')) {
            _error = 'DNS resolution failed. Please check your network settings.';
          } else {
            _error = 'Unable to fetch IP information. Please try again later.';
          }
        }
      }
    } catch (e) {
      _error = 'Error: ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() async {
    await fetchIpInfo(forceRefresh: true);
  }
}

