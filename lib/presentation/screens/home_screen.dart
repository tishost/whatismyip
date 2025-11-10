// NOTE: This is a template. Update imports and adapt from old home_screen.dart
// Key changes:
// - Import from '../../data/models/' for models
// - Import from '../../core/services/' for services
// - Import from '../widgets/' for widgets
// - Import from '../../core/constants/' for constants
// - Import from '../providers/' for providers

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:clipboard/clipboard.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:go_router/go_router.dart';
import 'dart:async';

import '../providers/ip_provider.dart';
import '../widgets/glass_card.dart';
import '../widgets/particle_background.dart';
import '../widgets/animated_ip_text.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/strings.dart';
import '../../core/utils/app_theme.dart';
import '../../core/services/ad_service.dart';

class HomeScreen extends StatefulWidget {
  final StatefulNavigationShell? navigationShell;
  
  const HomeScreen({
    super.key,
    this.navigationShell,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

// Separate widget for home tab content
class HomeScreenContent extends StatelessWidget {
  const HomeScreenContent({super.key});

  @override
  Widget build(BuildContext context) {
    return const _HomeTabContent();
  }
}

class _HomeTabContent extends StatelessWidget {
  const _HomeTabContent();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      children: [
        // Material Design 3 Top App Bar - Square (Full Width)
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [
                      const Color(0xFF5A1D99), // Darker purple
                      const Color(0xFF4A0D7A), // Darker violet
                    ]
                  : [
                      Color.lerp(AppColors.purple, Colors.white, 0.2)!,
                      Color.lerp(AppColors.violet, Colors.white, 0.15)!,
                    ],
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Title in center
                  Expanded(
                    child: Center(
                      child: Text(
                        AppStrings.appTitle,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.15,
                        ),
                      ),
                    ),
                  ),
                  // Refresh icon on right
                  Consumer<IpProvider>(
                    builder: (context, ipProvider, child) {
                      return Material(
                        color: Colors.transparent,
                        child: IconButton(
                          onPressed: ipProvider.isLoading
                              ? null
                              : () => ipProvider.refresh(),
                          icon: ipProvider.isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                              : const Icon(
                                  Icons.refresh_rounded,
                                  color: Colors.white,
                                  size: 24,
                                ),
                          tooltip: 'Refresh',
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
        // Scrollable content with RefreshIndicator
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              await context.read<IpProvider>().refresh();
            },
            color: AppColors.neonBlue,
            backgroundColor: Colors.black.withOpacity(0.3),
            strokeWidth: 3.0,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              children: [
                const SizedBox(height: 16),
                const _IpDetailsSectionWidget(),
                const SizedBox(height: 24),
                const _ConnectionDetailsSectionWidget(),
                const SizedBox(height: 24),
                const _SecuritySectionWidget(),
                const SizedBox(height: 24),
                const _AddressDetailsSectionWidget(),
                const SizedBox(height: 100), // Extra space for better swipe experience
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// Section widgets for home tab
class _IpDetailsSectionWidget extends StatelessWidget {
  const _IpDetailsSectionWidget();

  @override
  Widget build(BuildContext context) {
    return _HomeScreenState()._buildIpDetailsSection();
  }
}

class _ConnectionDetailsSectionWidget extends StatelessWidget {
  const _ConnectionDetailsSectionWidget();

  @override
  Widget build(BuildContext context) {
    return _HomeScreenState()._buildConnectionDetailsSection();
  }
}

class _SecuritySectionWidget extends StatelessWidget {
  const _SecuritySectionWidget();

  @override
  Widget build(BuildContext context) {
    return _HomeScreenState()._buildSecuritySection();
  }
}

class _AddressDetailsSectionWidget extends StatelessWidget {
  const _AddressDetailsSectionWidget();

  @override
  Widget build(BuildContext context) {
    return _HomeScreenState()._buildAddressDetailsSection();
  }
}

class _HomeScreenState extends State<HomeScreen> {
  BannerAd? _bannerAd;
  bool _isBannerAdReady = false;
  StreamSubscription<dynamic>? _connectivitySubscription;
  ConnectivityResult? _lastConnectivityResult;
  
  int get _currentIndex => widget.navigationShell?.currentIndex ?? 0;

  @override
  void initState() {
    super.initState();
    _loadBannerAd();
    _setupConnectivityListener();
  }

  void _setupConnectivityListener() {
    final connectivity = Connectivity();
    
    // Get initial connectivity
    connectivity.checkConnectivity().then((result) {
      ConnectivityResult initialResult;
      if (result is List<ConnectivityResult>) {
        final results = result as List<ConnectivityResult>;
        initialResult = results.isNotEmpty ? results.first : ConnectivityResult.none;
      } else {
        initialResult = result;
      }
      _lastConnectivityResult = initialResult;
    });

    // Listen to connectivity changes
    _connectivitySubscription = connectivity.onConnectivityChanged.listen((result) {
      ConnectivityResult currentResult;
      if (result is List<ConnectivityResult>) {
        final results = result as List<ConnectivityResult>;
        currentResult = results.isNotEmpty ? results.first : ConnectivityResult.none;
      } else {
        currentResult = result;
      }
      
      // Check if connectivity actually changed
      if (_lastConnectivityResult != currentResult) {
        _lastConnectivityResult = currentResult;
        
        // If connected, refresh IP info
        if (currentResult != ConnectivityResult.none) {
          // Small delay to ensure network is ready
          Future.delayed(const Duration(seconds: 1), () {
            if (mounted) {
              context.read<IpProvider>().refresh();
            }
          });
        }
      }
    });
  }

  void _loadBannerAd() async {
    if (await AdService.isProUser()) return;
    
    _bannerAd = await AdService.createBannerAd(
      adSize: AdSize.banner,
      onAdLoaded: (_) {
        setState(() => _isBannerAdReady = true);
      },
      onAdFailedToLoad: (ad, error) {
        ad.dispose();
      },
    );
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    _bannerAd?.dispose();
    super.dispose();
  }

  Future<void> _handleBackPress() async {
    if (!mounted) return;
    
    // Check if we're on home tab (index 0)
    final isOnHomeTab = _currentIndex == 0;
    
    if (isOnHomeTab) {
      // If on home tab, show exit confirmation
      if (!mounted) return;
      
      final shouldExit = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => AlertDialog(
          backgroundColor: Colors.grey[900],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Exit App?',
            style: TextStyle(color: Colors.white, fontSize: 20),
          ),
          content: const Text(
            'Do you want to exit the app?',
            style: TextStyle(color: Colors.white70, fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.white70),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text(
                'Exit',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        ),
      );
      
      if (shouldExit == true && mounted) {
        // Exit app
        SystemNavigator.pop();
      }
    } else {
      // Navigate to home tab if on other tabs
      if (mounted) {
        widget.navigationShell?.goBranch(0);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (didPop) return;
        if (!mounted) return;
        
        // Use Future.microtask to ensure dialog shows properly
        Future.microtask(() => _handleBackPress());
      },
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            ParticleBackground(
              child: Container(
                decoration: AppTheme.gradientBackground(
                  brightness: Theme.of(context).brightness,
                ),
              ),
            ),
            SafeArea(
              child: widget.navigationShell != null
                  ? widget.navigationShell!
                  : _buildHomeTab(),
            ),
          ],
        ),
        bottomNavigationBar: widget.navigationShell != null
            ? _buildBottomNav()
            : null,
        bottomSheet: _isBannerAdReady && _bannerAd != null
            ? Container(
                height: _bannerAd!.size.height.toDouble(),
                alignment: Alignment.center,
                child: AdWidget(ad: _bannerAd!),
              )
            : null,
      ),
    );
  }

  Widget _buildHomeTab() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return RefreshIndicator(
      onRefresh: () async {
        await context.read<IpProvider>().refresh();
      },
      color: AppColors.neonBlue,
      backgroundColor: Colors.black.withOpacity(0.3),
      strokeWidth: 3.0,
      child: Column(
        children: [
          // Material Design 3 Top App Bar - Square (Full Width)
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [
                        const Color(0xFF5A1D99), // Darker purple
                        const Color(0xFF4A0D7A), // Darker violet
                      ]
                    : [
                        Color.lerp(AppColors.purple, Colors.white, 0.2)!,
                        Color.lerp(AppColors.violet, Colors.white, 0.15)!,
                      ],
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Title in center
                    Expanded(
                      child: Center(
                        child: Text(
                          AppStrings.appTitle,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.15,
                          ),
                        ),
                      ),
                    ),
                    // Refresh icon on right
                    Consumer<IpProvider>(
                      builder: (context, ipProvider, child) {
                        return Material(
                          color: Colors.transparent,
                          child: IconButton(
                            onPressed: ipProvider.isLoading
                                ? null
                                : () => ipProvider.refresh(),
                            icon: ipProvider.isLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  )
                                : const Icon(
                                    Icons.refresh_rounded,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                            tooltip: 'Refresh',
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Scrollable content
          Expanded(
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              children: [
                const SizedBox(height: 16),
                _buildIpDetailsSection(),
                const SizedBox(height: 24),
                _buildConnectionDetailsSection(),
                const SizedBox(height: 24),
                _buildSecuritySection(),
                const SizedBox(height: 24),
                _buildAddressDetailsSection(),
                const SizedBox(height: 100), // Extra space for better swipe experience
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIpDetailsSection() {
    return Consumer<IpProvider>(
      builder: (context, ipProvider, child) {
        if (ipProvider.isLoading) {
          return GlassCard(
            onTap: null,
            child: const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
          );
        }

        if (ipProvider.error != null && ipProvider.ipInfo == null) {
          return GlassCard(
            onTap: null,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.wifi_off,
                    color: Colors.orange.withOpacity(0.8),
                    size: 56,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Connection Issue',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    ipProvider.error!,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => ipProvider.refresh(),
                    icon: const Icon(Icons.refresh),
                    label: const Text(AppStrings.retry),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.neonBlue.withOpacity(0.2),
                      foregroundColor: AppColors.neonBlue,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        final ipInfo = ipProvider.ipInfo;
        final publicIpv4 = ipInfo?.ipv4;
        final publicIpv6 = ipInfo?.ipv6;
        final ip = publicIpv4 ?? (ipProvider.error != null ? 'Not Available' : 'Loading...');
        
        // Check if IPv6 exists and is valid
        final hasValidIpv6 = publicIpv6 != null && 
                            publicIpv6.isNotEmpty && 
                            publicIpv6.trim().isNotEmpty;

        return Card(
          elevation: 0,
          color: Colors.white.withOpacity(0.08),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(
              color: Colors.white.withOpacity(0.1),
              width: 1,
            ),
          ),
          margin: const EdgeInsets.only(bottom: 16),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withOpacity(0.1),
                  Colors.white.withOpacity(0.05),
                ],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Section Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.neonBlue.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.network_check,
                        color: AppColors.neonBlue,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Network Information',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // IPv6 at the top if available (with copy button)
                if (hasValidIpv6) ...[
                  _buildModernIpRow(
                    'IPv6 Address',
                    publicIpv6.trim(),
                    Icons.dns,
                    onCopy: () {
                      FlutterClipboard.copy(publicIpv6.trim()).then((_) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Row(
                              children: [
                                Icon(Icons.check_circle, color: Colors.white),
                                SizedBox(width: 8),
                                Text(AppStrings.ipCopied),
                              ],
                            ),
                            backgroundColor: Colors.green,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  Divider(
                    color: Colors.white.withOpacity(0.1),
                    height: 1,
                  ),
                  const SizedBox(height: 16),
                ],
                // Public IPv4 with copy button (always show if available)
                if (publicIpv4 != null && publicIpv4.isNotEmpty) ...[
                  _buildModernIpRow(
                    AppStrings.publicIp,
                    publicIpv4,
                    Icons.public,
                    isPrimary: true,
                    onCopy: () {
                      FlutterClipboard.copy(publicIpv4).then((_) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Row(
                              children: [
                                Icon(Icons.check_circle, color: Colors.white),
                                SizedBox(width: 8),
                                Text(AppStrings.ipCopied),
                              ],
                            ),
                            backgroundColor: Colors.green,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      });
                    },
                  ),
                ] else ...[
                  _buildModernIpRow(
                    AppStrings.publicIp,
                    ip,
                    Icons.public,
                    isPrimary: true,
                    onCopy: ip != 'Loading...' && ip != 'Not Available'
                        ? () {
                            FlutterClipboard.copy(ip).then((_) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: const Row(
                                    children: [
                                      Icon(Icons.check_circle, color: Colors.white),
                                      SizedBox(width: 8),
                                      Text(AppStrings.ipCopied),
                                    ],
                                  ),
                                  backgroundColor: Colors.green,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                            });
                          }
                        : null,
                  ),
                ],
                if (ipProvider.privateIp != null) ...[
                  const SizedBox(height: 16),
                  Divider(
                    color: Colors.white.withOpacity(0.1),
                    height: 1,
                  ),
                  const SizedBox(height: 16),
                  _buildModernInfoRow(
                    AppStrings.privateIp,
                    ipProvider.privateIp!,
                    Icons.router,
                  ),
                ],
                if (ipProvider.connectionType != null) ...[
                  const SizedBox(height: 16),
                  Divider(
                    color: Colors.white.withOpacity(0.1),
                    height: 1,
                  ),
                  const SizedBox(height: 16),
                  _buildModernInfoRow(
                    AppStrings.connectionType,
                    ipProvider.connectionType!,
                    Icons.signal_wifi_4_bar,
                  ),
                ],
                if (ipProvider.dnsServer != null) ...[
                  const SizedBox(height: 16),
                  Divider(
                    color: Colors.white.withOpacity(0.1),
                    height: 1,
                  ),
                  const SizedBox(height: 16),
                  _buildModernInfoRow(
                    AppStrings.dnsServer,
                    ipProvider.dnsServer!,
                    Icons.dns,
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildModernIpRow(
    String label,
    String value,
    IconData icon, {
    bool isPrimary = false,
    VoidCallback? onCopy,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isPrimary
            ? AppColors.neonBlue.withOpacity(0.15)
            : Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isPrimary
              ? AppColors.neonBlue.withOpacity(0.3)
              : Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isPrimary
                  ? AppColors.neonBlue.withOpacity(0.2)
                  : Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: isPrimary ? AppColors.neonBlue : Colors.white.withOpacity(0.8),
              size: 22,
            ),
          ),
          const SizedBox(width: 16),
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
                const SizedBox(height: 6),
                AnimatedIpText(
                  text: value,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isPrimary ? 22 : 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          if (onCopy != null)
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onCopy,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.copy_rounded,
                    size: 20,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildModernInfoRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
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
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRowWithoutCopy(String label, String value) {
    return _buildModernInfoRow(label, value, Icons.info_outline);
  }

  Widget _buildConnectionDetailsSection() {
    return Consumer<IpProvider>(
      builder: (context, ipProvider, child) {
        final ipInfo = ipProvider.ipInfo;
        if (ipInfo == null) return const SizedBox();

        final hasData = ipInfo.isp != null ||
            ipInfo.organization != null;

        if (!hasData) return const SizedBox();

        return Card(
          elevation: 0,
          color: Colors.white.withOpacity(0.08),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(
              color: Colors.white.withOpacity(0.1),
              width: 1,
            ),
          ),
          margin: const EdgeInsets.only(bottom: 16),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withOpacity(0.1),
                  Colors.white.withOpacity(0.05),
                ],
              ),
            ),
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
                        Icons.business_center,
                        color: Colors.blue,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Connection Details',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                if (ipInfo.isp != null)
                  _buildMetadataRow(AppStrings.isp, _cleanIspString(ipInfo.isp!), icon: Icons.business),
                if (ipInfo.organization != null) ...[
                  if (ipInfo.isp != null) const SizedBox(height: 16),
                  _buildMetadataRow(
                    AppStrings.organization,
                    ipInfo.organization!,
                    icon: Icons.corporate_fare,
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSecuritySection() {
    return Consumer<IpProvider>(
      builder: (context, ipProvider, child) {
        final ipInfo = ipProvider.ipInfo;
        if (ipInfo == null) return const SizedBox();

        final hasSecurityData = ipInfo.isVpn != null ||
            ipInfo.isProxy != null ||
            ipInfo.isTor != null ||
            ipInfo.abuseConfidenceScore != null ||
            ipInfo.isBlacklisted != null ||
            ipInfo.threatType != null;

        if (!hasSecurityData) return const SizedBox();

        return Card(
          elevation: 0,
          color: Colors.white.withOpacity(0.08),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(
              color: Colors.white.withOpacity(0.1),
              width: 1,
            ),
          ),
          margin: const EdgeInsets.only(bottom: 16),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withOpacity(0.1),
                  Colors.white.withOpacity(0.05),
                ],
              ),
            ),
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
                        Icons.security,
                        color: Colors.orange,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Security Status',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                if (ipInfo.isVpn != null)
                  _buildSecurityRow(
                    'VPN Detection',
                    ipInfo.isVpn == true ? 'Detected' : 'Not Detected',
                    ipInfo.isVpn == true,
                    icon: Icons.vpn_key,
                  ),
                if (ipInfo.isProxy != null) ...[
                  if (ipInfo.isVpn != null) const SizedBox(height: 12),
                  _buildSecurityRow(
                    'Proxy Detection',
                    ipInfo.isProxy == true ? 'Detected' : 'Not Detected',
                    ipInfo.isProxy == true,
                    icon: Icons.swap_horiz,
                  ),
                ],
                if (ipInfo.isTor != null) ...[
                  if (ipInfo.isProxy != null || ipInfo.isVpn != null) const SizedBox(height: 12),
                  _buildSecurityRow(
                    'TOR Detection',
                    ipInfo.isTor == true ? 'Detected' : 'Not Detected',
                    ipInfo.isTor == true,
                    icon: Icons.lock,
                  ),
                ],
              if (ipInfo.abuseConfidenceScore != null) ...[
                if (ipInfo.isTor != null || ipInfo.isProxy != null || ipInfo.isVpn != null)
                  const SizedBox(height: 12),
                _buildSecurityRow(
                  'Threat Score',
                  '${ipInfo.abuseConfidenceScore}%',
                  ipInfo.abuseConfidenceScore! > 50,
                  icon: Icons.warning,
                ),
              ],
              if (ipInfo.isBlacklisted == true) ...[
                if (ipInfo.abuseConfidenceScore != null) const SizedBox(height: 12),
                _buildSecurityRow(
                  'Blacklist Status',
                  'Blacklisted',
                  true,
                  icon: Icons.block,
                ),
              ],
              if (ipInfo.threatType != null && ipInfo.threatType!.isNotEmpty) ...[
                if (ipInfo.isBlacklisted == true || ipInfo.abuseConfidenceScore != null)
                  const SizedBox(height: 12),
                _buildSecurityRow(
                  'Threat Type',
                  ipInfo.threatType!,
                  true,
                  icon: Icons.security,
                ),
              ],
            ],
          ),
        ),
      );
      },
    );
  }

  Widget _buildSecurityRow(String label, String value, bool isThreat, {IconData? icon}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isThreat
            ? Colors.red.withOpacity(0.15)
            : Colors.green.withOpacity(0.15),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isThreat
              ? Colors.red.withOpacity(0.3)
              : Colors.green.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          if (icon != null) ...[
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isThreat
                    ? Colors.red.withOpacity(0.2)
                    : Colors.green.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: isThreat ? Colors.red.shade300 : Colors.green.shade300,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
          ],
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
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    color: isThreat ? Colors.red.shade300 : Colors.green.shade300,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: isThreat
                  ? Colors.red.withOpacity(0.2)
                  : Colors.green.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              isThreat ? Icons.warning_rounded : Icons.check_circle_rounded,
              color: isThreat ? Colors.red.shade300 : Colors.green.shade300,
              size: 18,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddressDetailsSection() {
    return Consumer<IpProvider>(
      builder: (context, ipProvider, child) {
        final ipInfo = ipProvider.ipInfo;
        if (ipInfo == null) return const SizedBox();

        final hasData = ipInfo.displayLocation != 'Unknown' ||
            ipInfo.city != null ||
            ipInfo.region != null ||
            ipInfo.country != null ||
            ipInfo.zip != null ||
            ipInfo.timezone != null ||
            (ipInfo.latitude != null && ipInfo.longitude != null);

        if (!hasData) return const SizedBox();

        return Card(
          elevation: 0,
          color: Colors.white.withOpacity(0.08),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(
              color: Colors.white.withOpacity(0.1),
              width: 1,
            ),
          ),
          margin: const EdgeInsets.only(bottom: 16),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withOpacity(0.1),
                  Colors.white.withOpacity(0.05),
                ],
              ),
            ),
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
                        Icons.location_on,
                        color: Colors.purple,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Location Details',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                if (ipInfo.displayLocation != 'Unknown')
                  _buildMetadataRow(
                    AppStrings.location,
                    ipInfo.displayLocation,
                    icon: Icons.location_on,
                  ),
                if (ipInfo.city != null) ...[
                  if (ipInfo.displayLocation != 'Unknown') const SizedBox(height: 12),
                  _buildMetadataRow('City', ipInfo.city!, icon: Icons.location_city),
                ],
                if (ipInfo.region != null) ...[
                  if (ipInfo.city != null) const SizedBox(height: 12),
                  _buildMetadataRow('Region', ipInfo.region!, icon: Icons.map),
                ],
                if (ipInfo.country != null) ...[
                  if (ipInfo.region != null) const SizedBox(height: 12),
                  _buildMetadataRow('Country', ipInfo.country!, icon: Icons.public),
                ],
                if (ipInfo.zip != null) ...[
                  if (ipInfo.country != null) const SizedBox(height: 12),
                  _buildMetadataRow('ZIP Code', ipInfo.zip!, icon: Icons.markunread_mailbox),
                ],
                if (ipInfo.timezone != null) ...[
                  if (ipInfo.zip != null) const SizedBox(height: 12),
                  _buildMetadataRow('Timezone', ipInfo.timezone!, icon: Icons.access_time),
                ],
                if (ipInfo.latitude != null && ipInfo.longitude != null) ...[
                  if (ipInfo.timezone != null) const SizedBox(height: 12),
                  _buildMetadataRow(
                    'Coordinates',
                    '${ipInfo.latitude}, ${ipInfo.longitude}',
                    icon: Icons.my_location,
                  ),
                ],
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      context.push('/detail', extra: ipInfo);
                    },
                    icon: const Icon(Icons.arrow_forward_rounded),
                    label: const Text(
                      AppStrings.viewDetails,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.neonBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _cleanIspString(String isp) {
    // Remove AS numbers (AS12345, AS 12345, ASN12345, etc.)
    return isp
        .replaceAll(RegExp(r'\s*AS\s*\d+\s*', caseSensitive: false), ' ')
        .replaceAll(RegExp(r'\s*ASN\s*\d+\s*', caseSensitive: false), ' ')
        .trim()
        .replaceAll(RegExp(r'\s+'), ' ');
  }

  Widget _buildMetadataRow(String label, String value, {IconData? icon}) {
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
          if (icon != null) ...[
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: Colors.white.withOpacity(0.8),
                size: 16,
              ),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
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


  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          widget.navigationShell?.goBranch(index);
        },
        backgroundColor: Colors.transparent,
        elevation: 0,
        selectedItemColor: AppColors.neonBlue,
        unselectedItemColor: Colors.white.withOpacity(0.6),
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: AppStrings.home,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.build),
            label: AppStrings.tools,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.phone_android),
            label: AppStrings.deviceInfo,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: AppStrings.settings,
          ),
        ],
      ),
    );
  }
}

