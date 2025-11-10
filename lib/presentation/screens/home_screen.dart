// NOTE: This is a template. Update imports and adapt from old home_screen.dart
// Key changes:
// - Import from '../../data/models/' for models
// - Import from '../../core/services/' for services
// - Import from '../widgets/' for widgets
// - Import from '../../core/constants/' for constants
// - Import from '../providers/' for providers

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:clipboard/clipboard.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:async';

import '../providers/ip_provider.dart';
import '../widgets/glass_card.dart';
import '../widgets/gradient_text.dart';
import '../widgets/particle_background.dart';
import '../widgets/animated_ip_text.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/strings.dart';
import '../../core/utils/app_theme.dart';
import '../../core/services/ad_service.dart';
import 'detail_screen.dart';
import 'tools_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  BannerAd? _bannerAd;
  bool _isBannerAdReady = false;
  StreamSubscription<dynamic>? _connectivitySubscription;
  ConnectivityResult? _lastConnectivityResult;

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          ParticleBackground(
            child: Container(
              decoration: AppTheme.gradientBackground(),
            ),
          ),
          SafeArea(
            child: IndexedStack(
              index: _currentIndex,
              children: [
                _buildHomeTab(),
                const ToolsScreen(),
                const SettingsScreen(),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
      bottomSheet: _isBannerAdReady && _bannerAd != null
          ? Container(
              height: _bannerAd!.size.height.toDouble(),
              alignment: Alignment.center,
              child: AdWidget(ad: _bannerAd!),
            )
          : null,
    );
  }

  Widget _buildHomeTab() {
    return RefreshIndicator(
      onRefresh: () async {
        await context.read<IpProvider>().refresh();
      },
      color: AppColors.neonBlue,
      backgroundColor: Colors.black.withOpacity(0.3),
      strokeWidth: 3.0,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Expanded(
                  child: GradientText(
                    AppStrings.appTitle,
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Consumer<IpProvider>(
                  builder: (context, ipProvider, child) {
                    return InkWell(
                      onTap: ipProvider.isLoading
                          ? null
                          : () => ipProvider.refresh(),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.neonBlue.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: AppColors.neonBlue.withOpacity(0.5),
                            width: 1.5,
                          ),
                        ),
                        child: ipProvider.isLoading
                            ? SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    AppColors.neonBlue,
                                  ),
                                ),
                              )
                            : Icon(
                                Icons.refresh,
                                color: AppColors.neonBlue,
                                size: 24,
                              ),
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              AppStrings.appSubtitle,
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 32),
            _buildIpCard(),
            const SizedBox(height: 24),
            _buildMetadataCard(),
            const SizedBox(height: 100), // Extra space for better swipe experience
        ],
      ),
    );
  }

  Widget _buildIpCard() {
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
        final ip = ipInfo?.ipv4 ?? (ipProvider.error != null ? 'Not Available' : 'Loading...');

        return GlassCard(
          onTap: null,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    AppStrings.publicIp,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 14,
                    ),
                  ),
                  if (ip != 'Loading...')
                    InkWell(
                      onTap: () {
                        FlutterClipboard.copy(ip).then((_) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(AppStrings.ipCopied),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        });
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        child: Icon(
                          Icons.copy,
                          size: 20,
                          color: Colors.white.withOpacity(0.7),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              AnimatedIpText(
                text: ip,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              if (ipProvider.privateIp != null) ...[
                const SizedBox(height: 16),
                Divider(color: Colors.white.withOpacity(0.2)),
                const SizedBox(height: 12),
                Text(
                  AppStrings.privateIp,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  ipProvider.privateIp!,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              if (ipInfo?.ipv6 != null && ipInfo!.ipv6!.isNotEmpty) ...[
                const SizedBox(height: 16),
                Divider(color: Colors.white.withOpacity(0.2)),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'IPv6 Address',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 14,
                      ),
                    ),
                    InkWell(
                      onTap: () {
                        final ipv6 = ipInfo!.ipv6!;
                        FlutterClipboard.copy(ipv6).then((_) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('IPv6 copied to clipboard!'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        });
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        child: Icon(
                          Icons.copy,
                          size: 20,
                          color: Colors.white.withOpacity(0.7),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  ipInfo!.ipv6!,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              if (ipProvider.privateIpv6 != null && ipProvider.privateIpv6!.isNotEmpty) ...[
                const SizedBox(height: 16),
                Divider(color: Colors.white.withOpacity(0.2)),
                const SizedBox(height: 12),
                Text(
                  'Private IPv6',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  ipProvider.privateIpv6!,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildMetadataCard() {
    return Consumer<IpProvider>(
      builder: (context, ipProvider, child) {
        final ipInfo = ipProvider.ipInfo;
        if (ipInfo == null) return const SizedBox();

        return GlassCard(
          onTap: null,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.location_on, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      ipInfo.displayLocation,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: () {
                      FlutterClipboard.copy(ipInfo.displayLocation).then((_) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Address copied to clipboard!'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      });
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      child: Icon(
                        Icons.copy,
                        size: 20,
                        color: Colors.white.withOpacity(0.7),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (ipProvider.connectionType != null)
                _buildMetadataRow(
                  AppStrings.connectionType,
                  ipProvider.connectionType!,
                  icon: ipProvider.connectionType == 'WiFi'
                      ? Icons.wifi
                      : Icons.signal_cellular_alt,
                ),
              if (ipProvider.dnsServer != null)
                _buildMetadataRow(
                  AppStrings.dnsServer,
                  ipProvider.dnsServer!,
                  icon: Icons.dns,
                ),
              if (ipInfo.isp != null)
                _buildMetadataRow(AppStrings.isp, ipInfo.isp!),
              if (ipInfo.organization != null)
                _buildMetadataRow(AppStrings.organization, ipInfo.organization!),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => DetailScreen(ipInfo: ipInfo),
                      ),
                    );
                  },
                  icon: const Icon(Icons.info_outline),
                  label: const Text(AppStrings.viewDetails),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.neonBlue.withOpacity(0.2),
                    foregroundColor: AppColors.neonBlue,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMetadataRow(String label, String value, {IconData? icon}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Icon(icon, color: Colors.white.withOpacity(0.7), size: 16),
            const SizedBox(width: 8),
          ],
          SizedBox(
            width: icon != null ? 90 : 100,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.white.withOpacity(0.6),
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
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
        onTap: (index) => setState(() => _currentIndex = index),
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
            icon: Icon(Icons.settings),
            label: AppStrings.settings,
          ),
        ],
      ),
    );
  }
}

