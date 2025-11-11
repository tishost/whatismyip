import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/ip_info.dart';
import '../../core/services/ip_service.dart';
import '../../core/utils/network_utils.dart';
import '../../data/repositories/ip_repository.dart';
import '../../core/services/notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'notification_provider.dart';

class IpState {
  final IpInfo? ipInfo;
  final String? privateIp;
  final String? privateIpv6;
  final bool isLoading;
  final String? error;
  final bool isVpnProxy;
  final String? connectionType;
  final String? dnsServer;

  IpState({
    this.ipInfo,
    this.privateIp,
    this.privateIpv6,
    this.isLoading = false,
    this.error,
    this.isVpnProxy = false,
    this.connectionType,
    this.dnsServer,
  });

  IpState copyWith({
    IpInfo? ipInfo,
    String? privateIp,
    String? privateIpv6,
    bool? isLoading,
    String? error,
    bool? isVpnProxy,
    String? connectionType,
    String? dnsServer,
  }) {
    return IpState(
      ipInfo: ipInfo ?? this.ipInfo,
      privateIp: privateIp ?? this.privateIp,
      privateIpv6: privateIpv6 ?? this.privateIpv6,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      isVpnProxy: isVpnProxy ?? this.isVpnProxy,
      connectionType: connectionType ?? this.connectionType,
      dnsServer: dnsServer ?? this.dnsServer,
    );
  }
}

class IpNotifier extends StateNotifier<IpState> {
  final IpService _ipService;
  final IpRepository _ipRepository = IpRepository.instance;
  final Ref _ref;
  String? _lastKnownIp;
  String? _lastKnownIpv6;
  Timer? _backgroundCheckTimer;

  IpNotifier(this._ipService, this._ref) : super(IpState()) {
    _loadLastKnownIps();
    _startBackgroundChecking();
  }

  @override
  void dispose() {
    _backgroundCheckTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadLastKnownIps() async {
    final prefs = await SharedPreferences.getInstance();
    _lastKnownIp = prefs.getString('last_known_ip');
    _lastKnownIpv6 = prefs.getString('last_known_ipv6');
  }

  Future<void> _saveLastKnownIps(String? ipv4, String? ipv6) async {
    final prefs = await SharedPreferences.getInstance();
    if (ipv4 != null) {
      await prefs.setString('last_known_ip', ipv4);
      _lastKnownIp = ipv4;
    }
    if (ipv6 != null) {
      await prefs.setString('last_known_ipv6', ipv6);
      _lastKnownIpv6 = ipv6;
    }
  }

  void _startBackgroundChecking() {
    // Check IP every 5 minutes when app is active
    _backgroundCheckTimer = Timer.periodic(const Duration(minutes: 5), (timer) async {
      await _checkIpInBackground();
    });
  }

  Future<void> _checkIpInBackground() async {
    try {
      // Only check if we have internet
      final connectivity = await NetworkUtils.checkConnectivity();
      if (!NetworkUtils.isConnected(connectivity)) {
        return;
      }

      // Fetch IP info silently (without showing loading)
      final ipInfo = await _ipService.fetchIpInfo();
      
      if (ipInfo != null) {
        await _checkAndSaveIpChange(ipInfo, isBackgroundCheck: true);
      }
    } catch (e) {
      // Background IP check failed silently
    }
  }

  Future<void> _checkAndSaveIpChange(IpInfo? newIpInfo, {bool isBackgroundCheck = false}) async {
    if (newIpInfo == null || (newIpInfo.ipv4 == null || newIpInfo.ipv4!.isEmpty)) {
      return;
    }

    final currentIpv4 = newIpInfo.ipv4!;
    final currentIpv6 = newIpInfo.ipv6;
    
    bool ipv4Changed = false;
    bool ipv6Changed = false;
    String notificationBody = '';
    
    // Check if IPv4 has changed
    if (_lastKnownIp != null && _lastKnownIp != currentIpv4) {
      ipv4Changed = true;
      notificationBody = 'IPv4: $_lastKnownIp → $currentIpv4';
    }
    
    // Check if IPv6 has changed
    if (currentIpv6 != null && currentIpv6.isNotEmpty) {
      if (_lastKnownIpv6 != null && _lastKnownIpv6 != currentIpv6) {
        ipv6Changed = true;
        if (notificationBody.isNotEmpty) {
          notificationBody += '\nIPv6: $_lastKnownIpv6 → $currentIpv6';
        } else {
          notificationBody = 'IPv6: $_lastKnownIpv6 → $currentIpv6';
        }
      }
    }
    
    // Show notification if IP changed and notifications are enabled
    if (ipv4Changed || ipv6Changed) {
      final notificationsEnabled = _ref.read(notificationProvider);
      
      if (notificationsEnabled) {
        await NotificationService.instance.showNotification(
          id: 1,
          title: 'IP Address Changed',
          body: notificationBody.isNotEmpty 
              ? notificationBody 
              : 'Your IP address has changed',
        );
      }
    }

    // Save to history (only if it's different from last saved IP or first time)
    try {
      final allHistory = await _ipRepository.getAllIpHistory();
      bool shouldSave = false;
      
      if (allHistory.isEmpty) {
        // First time - always save
        shouldSave = true;
      } else {
        // Check if IP has changed
        final lastEntry = allHistory.first;
        final lastIpv4 = lastEntry['ipv4'] as String?;
        final lastIpv6 = lastEntry['ipv6'] as String?;
        
        if (lastIpv4 != currentIpv4) {
          shouldSave = true;
        } else if (currentIpv6 != null && currentIpv6.isNotEmpty && lastIpv6 != currentIpv6) {
          // IPv6 changed even if IPv4 is same
          shouldSave = true;
        }
      }
      
      if (shouldSave) {
        await _ipRepository.insertIpHistory(newIpInfo);
      }
    } catch (e) {
      // Error saving IP history silently
    }

    // Save current IPs as last known (always update, even if not changed)
    await _saveLastKnownIps(currentIpv4, currentIpv6);
  }

  Future<void> fetchIpInfo({bool forceRefresh = false}) async {
    if (state.isLoading && !forceRefresh) return;
    
    state = state.copyWith(isLoading: true, error: null);

    try {
      // Check connectivity first
      final connectivity = await NetworkUtils.checkConnectivity();
      if (!NetworkUtils.isConnected(connectivity)) {
        state = state.copyWith(
          error: 'No internet connection. Please check your network.',
          isLoading: false,
        );
        return;
      }

      // Get local info first (doesn't require network)
      final privateIp = await NetworkUtils.getPrivateIp();
      final privateIpv6 = await NetworkUtils.getPrivateIpv6();
      final connectionType = await NetworkUtils.getConnectionType();
      final dnsServer = await NetworkUtils.getPrimaryDns();
      
      state = state.copyWith(
        privateIp: privateIp,
        privateIpv6: privateIpv6,
        connectionType: connectionType,
        dnsServer: dnsServer,
      );
      
      // Fetch IP info with better error handling
      try {
        final ipInfo = await _ipService.fetchIpInfo();
        
        if (ipInfo != null && ipInfo.ipv4 != null && ipInfo.ipv4!.isNotEmpty) {
          // Check for IP change and save to history
          await _checkAndSaveIpChange(ipInfo);
          
          // Check VPN/Proxy in background (non-blocking)
          _ipService.checkVpnProxy().then((isVpn) {
            state = state.copyWith(isVpnProxy: isVpn);
          }).catchError((_) {
            // Ignore VPN check errors
          });
          
          state = state.copyWith(ipInfo: ipInfo, error: null);
        } else {
          // Try fallback method to get at least the IP
          final publicIp = await _ipService.getPublicIp();
          if (publicIp != null && publicIp.isNotEmpty) {
            // Create minimal IP info with just the IP
            final ipInfo = IpInfo(ipv4: publicIp);
            await _checkAndSaveIpChange(ipInfo);
            state = state.copyWith(ipInfo: ipInfo, error: null);
          } else {
            state = state.copyWith(
              error: 'Unable to fetch IP information. Please check your internet connection and try again.',
            );
          }
        }
      } catch (e) {
        // Try to get at least the public IP as fallback
        try {
          final publicIp = await _ipService.getPublicIp();
          if (publicIp != null && publicIp.isNotEmpty) {
            final ipInfo = IpInfo(ipv4: publicIp);
            await _checkAndSaveIpChange(ipInfo);
            state = state.copyWith(ipInfo: ipInfo, error: null);
          } else {
            throw Exception('No IP available');
          }
        } catch (_) {
          // Determine error type and show appropriate message
          final errorStr = e.toString().toLowerCase();
          String errorMessage;
          if (errorStr.contains('timeout') || errorStr.contains('timed out')) {
            errorMessage = 'Connection timeout. Please check your internet speed and try again.';
          } else if (errorStr.contains('socket') || errorStr.contains('network') || errorStr.contains('connection')) {
            errorMessage = 'Network connection failed. Please check your internet connection.';
          } else if (errorStr.contains('dns') || errorStr.contains('host')) {
            errorMessage = 'DNS resolution failed. Please check your network settings.';
          } else {
            errorMessage = 'Unable to fetch IP information. Please try again later.';
          }
          state = state.copyWith(error: errorMessage);
        }
      }
    } catch (e) {
      state = state.copyWith(error: 'Error: ${e.toString()}');
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> refresh() async {
    await fetchIpInfo(forceRefresh: true);
  }

  Future<void> checkIpOnResume() async {
    // Check IP when app resumes from background
    try {
      final connectivity = await NetworkUtils.checkConnectivity();
      if (!NetworkUtils.isConnected(connectivity)) {
        return;
      }

      // Fetch IP info silently
      final ipInfo = await _ipService.fetchIpInfo();
      
      if (ipInfo != null) {
        await _checkAndSaveIpChange(ipInfo, isBackgroundCheck: true);
      }
    } catch (e) {
      // Resume IP check failed silently
    }
  }
}

// IP Service provider
final ipServiceProvider = Provider<IpService>((ref) {
  return IpService();
});

// IP provider
final ipProvider = StateNotifierProvider<IpNotifier, IpState>((ref) {
  final ipService = ref.watch(ipServiceProvider);
  final notifier = IpNotifier(ipService, ref);
  // Fetch IP info on initialization
  notifier.fetchIpInfo();
  return notifier;
});
