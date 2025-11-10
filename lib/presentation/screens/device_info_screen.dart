import 'package:flutter/material.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:io';

import '../widgets/glass_card.dart';
import '../widgets/gradient_text.dart';
import '../widgets/particle_background.dart';
import '../../core/utils/app_theme.dart';
import '../../core/services/system_info_service.dart';

class DeviceInfoScreen extends StatefulWidget {
  const DeviceInfoScreen({super.key});

  @override
  State<DeviceInfoScreen> createState() => _DeviceInfoScreenState();
}

class _DeviceInfoScreenState extends State<DeviceInfoScreen> {
  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();
  final SystemInfoService _systemInfoService = SystemInfoService();
  Map<String, dynamic>? _deviceData;
  Map<String, String>? _systemInfo;
  bool _isLoading = true;
  bool _isSystemFeaturesExpanded = false;

  @override
  void initState() {
    super.initState();
    _loadDeviceInfo();
  }

  Future<void> _loadDeviceInfo() async {
    try {
      Map<String, dynamic> deviceData = {};
      
      // Load system info (RAM, CPU, Disk)
      final systemInfo = await _systemInfoService.getSystemInfo();
      
      if (Platform.isAndroid) {
        final androidInfo = await _deviceInfo.androidInfo;
        deviceData = {
          'Device': androidInfo.model,
          'Manufacturer': androidInfo.manufacturer,
          'Brand': androidInfo.brand,
          'Device Name': androidInfo.device,
          'Product': androidInfo.product,
          'Hardware': androidInfo.hardware,
          'Android Version': androidInfo.version.release,
          'SDK Version': androidInfo.version.sdkInt.toString(),
          'Android ID': androidInfo.id,
          'Board': androidInfo.board,
          'Bootloader': androidInfo.bootloader,
          'Display': androidInfo.display,
          'Fingerprint': androidInfo.fingerprint,
          'Host': androidInfo.host,
          'Tags': androidInfo.tags,
          'Type': androidInfo.type,
          'Is Physical Device': androidInfo.isPhysicalDevice ? 'Yes' : 'No',
          'System Features': androidInfo.systemFeatures.join(', '),
          'Supported ABIs': androidInfo.supportedAbis.join(', '),
        };
      } else if (Platform.isIOS) {
        final iosInfo = await _deviceInfo.iosInfo;
        deviceData = {
          'Device': iosInfo.name,
          'Model': iosInfo.model,
          'System Name': iosInfo.systemName,
          'System Version': iosInfo.systemVersion,
          'Device ID': iosInfo.identifierForVendor ?? 'N/A',
          'Is Physical Device': iosInfo.isPhysicalDevice ? 'Yes' : 'No',
          'Localized Model': iosInfo.localizedModel,
          'UTS Name': iosInfo.utsname.machine,
        };
      } else if (Platform.isWindows) {
        final windowsInfo = await _deviceInfo.windowsInfo;
        deviceData = {
          'Computer Name': windowsInfo.computerName,
          'User Name': windowsInfo.userName,
          'OS Version': '${windowsInfo.majorVersion}.${windowsInfo.minorVersion}.${windowsInfo.buildNumber}',
          'OS Build': windowsInfo.buildNumber,
          'OS Build Lab': windowsInfo.buildLab,
          'OS Display Version': windowsInfo.displayVersion,
          'OS Edition': windowsInfo.editionId,
          'OS Install Date': windowsInfo.installDate,
          'OS Product ID': windowsInfo.productId,
          'OS Registered Owner': windowsInfo.registeredOwner,
        };
      } else if (Platform.isMacOS) {
        final macInfo = await _deviceInfo.macOsInfo;
        deviceData = {
          'Computer Name': macInfo.computerName,
          'Host Name': macInfo.hostName,
          'Model': macInfo.model,
          'Kernel Version': macInfo.kernelVersion,
          'OS Release': macInfo.osRelease,
          'Active CPUs': macInfo.activeCPUs.toString(),
          'Memory Size': '${(macInfo.memorySize / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB',
          'CPU Frequency': '${(macInfo.cpuFrequency / 1000000).toStringAsFixed(2)} MHz',
        };
      } else if (Platform.isLinux) {
        final linuxInfo = await _deviceInfo.linuxInfo;
        deviceData = {
          'Machine ID': linuxInfo.machineId,
          'Name': linuxInfo.name,
          'Pretty Name': linuxInfo.prettyName,
          'Version': linuxInfo.version,
          'Version ID': linuxInfo.versionId,
          'Variant': linuxInfo.variant,
          'Variant ID': linuxInfo.variantId,
        };
      }

      setState(() {
        _deviceData = deviceData;
        _systemInfo = systemInfo;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ParticleBackground(
      child: Container(
        decoration: AppTheme.gradientBackground(),
        child: SafeArea(
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                )
              : SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),
                      const GradientText(
                        'Device Information',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Complete device specifications',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 32),
                      if (_systemInfo != null && _systemInfo!.isNotEmpty)
                        GlassCard(
                          onTap: null,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'System Resources',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16),
                              ..._systemInfo!.entries.map((entry) {
                                return _buildInfoRow(entry.key, entry.value);
                              }).toList(),
                            ],
                          ),
                        ),
                      if (_systemInfo != null && _systemInfo!.isNotEmpty)
                        const SizedBox(height: 24),
                      if (_deviceData != null)
                        GlassCard(
                          onTap: null,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Device Details',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16),
                              ..._deviceData!.entries.map((entry) {
                                if (entry.key == 'System Features') {
                                  return _buildSystemFeaturesRow(entry.value.toString());
                                }
                                return _buildInfoRow(entry.key, entry.value.toString());
                              }).toList(),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.white.withOpacity(0.6),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSystemFeaturesRow(String value) {
    const int maxLength = 100; // Show first 100 characters initially
    final bool isLong = value.length > maxLength;
    final String displayText = _isSystemFeaturesExpanded || !isLong
        ? value
        : '${value.substring(0, maxLength)}...';

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: Text(
                  'System Features',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      displayText,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.end,
                    ),
                    if (isLong) ...[
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: () {
                          setState(() {
                            _isSystemFeaturesExpanded = !_isSystemFeaturesExpanded;
                          });
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.2),
                            ),
                          ),
                          child: Text(
                            _isSystemFeaturesExpanded ? 'Read Less' : 'Read More',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

