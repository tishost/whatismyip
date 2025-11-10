import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';

class SystemInfoService {
  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();

  Future<Map<String, String>> getSystemInfo() async {
    Map<String, String> systemInfo = {};

    try {
      if (Platform.isAndroid) {
        systemInfo = await _getAndroidSystemInfo();
      } else if (Platform.isIOS) {
        systemInfo = await _getIOSSystemInfo();
      } else if (Platform.isMacOS) {
        systemInfo = await _getMacOSSystemInfo();
      } else if (Platform.isWindows) {
        systemInfo = await _getWindowsSystemInfo();
      } else if (Platform.isLinux) {
        systemInfo = await _getLinuxSystemInfo();
      }
    } catch (e) {
      // Handle errors
    }

    return systemInfo;
  }

  Future<Map<String, String>> _getAndroidSystemInfo() async {
    Map<String, String> info = {};
    
    try {
      // Read RAM info from /proc/meminfo
      final memInfoFile = File('/proc/meminfo');
      if (await memInfoFile.exists()) {
        final memInfo = await memInfoFile.readAsString();
        final lines = memInfo.split('\n');
        
        int? totalRam;
        int? availableRam;
        
        for (var line in lines) {
          if (line.startsWith('MemTotal:')) {
            final value = line.split(RegExp(r'\s+'))[1];
            totalRam = int.tryParse(value);
          } else if (line.startsWith('MemAvailable:')) {
            final value = line.split(RegExp(r'\s+'))[1];
            availableRam = int.tryParse(value);
          }
        }
        
        if (totalRam != null) {
          info['Total RAM'] = '${(totalRam / 1024 / 1024).toStringAsFixed(2)} GB';
        }
        if (availableRam != null && totalRam != null) {
          final usedRam = totalRam - availableRam;
          info['Used RAM'] = '${(usedRam / 1024 / 1024).toStringAsFixed(2)} GB';
          info['Available RAM'] = '${(availableRam / 1024 / 1024).toStringAsFixed(2)} GB';
        }
      }

      // Read CPU info from /proc/cpuinfo
      final cpuInfoFile = File('/proc/cpuinfo');
      if (await cpuInfoFile.exists()) {
        final cpuInfo = await cpuInfoFile.readAsString();
        final lines = cpuInfo.split('\n');
        
        String? processor;
        int cpuCount = 0;
        String? hardware;
        
        for (var line in lines) {
          if (line.startsWith('processor')) {
            cpuCount++;
          } else if (line.startsWith('Hardware:')) {
            hardware = line.split(':')[1].trim();
          } else if (line.startsWith('Processor:') && processor == null) {
            processor = line.split(':')[1].trim();
          }
        }
        
        if (cpuCount > 0) {
          info['CPU Cores'] = cpuCount.toString();
        }
        if (processor != null) {
          info['CPU Model'] = processor;
        } else if (hardware != null) {
          info['CPU Model'] = hardware;
        }
      }

      // Get CPU frequency
      try {
        final cpuFreqFile = File('/sys/devices/system/cpu/cpu0/cpufreq/cpuinfo_max_freq');
        if (await cpuFreqFile.exists()) {
          final freq = await cpuFreqFile.readAsString();
          final freqValue = int.tryParse(freq.trim());
          if (freqValue != null) {
            info['CPU Frequency'] = '${(freqValue / 1000).toStringAsFixed(2)} MHz';
          }
        }
      } catch (e) {
        // CPU frequency not available
      }

      // Disk space (approximate)
      // For Android, disk info requires additional permissions
      info['Storage Info'] = 'Check Settings for details';
    } catch (e) {
      // Handle errors
    }

    return info;
  }

  Future<Map<String, String>> _getIOSSystemInfo() async {
    Map<String, String> info = {};
    
    try {
      final iosInfo = await _deviceInfo.iosInfo;
      
      // iOS doesn't expose RAM/CPU/Disk directly
      // We can only show what's available
      info['Device Model'] = iosInfo.model;
      info['System Version'] = iosInfo.systemVersion;
      info['Note'] = 'RAM/CPU/Disk info requires system access';
    } catch (e) {
      // Handle errors
    }

    return info;
  }

  Future<Map<String, String>> _getMacOSSystemInfo() async {
    Map<String, String> info = {};
    
    try {
      final macInfo = await _deviceInfo.macOsInfo;
      
      info['Total RAM'] = '${(macInfo.memorySize / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
      info['CPU Cores'] = macInfo.activeCPUs.toString();
      info['CPU Frequency'] = '${(macInfo.cpuFrequency / 1000000).toStringAsFixed(2)} MHz';
      
      // Disk info would need additional system calls
      info['Model'] = macInfo.model;
    } catch (e) {
      // Handle errors
    }

    return info;
  }

  Future<Map<String, String>> _getWindowsSystemInfo() async {
    Map<String, String> info = {};
    
    try {
      // Windows system info requires WMI or system calls
      // For now, show basic info
      final windowsInfo = await _deviceInfo.windowsInfo;
      info['OS Version'] = '${windowsInfo.majorVersion}.${windowsInfo.minorVersion}';
      info['Note'] = 'RAM/CPU/Disk info requires system access';
    } catch (e) {
      // Handle errors
    }

    return info;
  }

  Future<Map<String, String>> _getLinuxSystemInfo() async {
    Map<String, String> info = {};
    
    try {
      // Read RAM info from /proc/meminfo
      final memInfoFile = File('/proc/meminfo');
      if (await memInfoFile.exists()) {
        final memInfo = await memInfoFile.readAsString();
        final lines = memInfo.split('\n');
        
        int? totalRam;
        int? availableRam;
        
        for (var line in lines) {
          if (line.startsWith('MemTotal:')) {
            final value = line.split(RegExp(r'\s+'))[1];
            totalRam = int.tryParse(value);
          } else if (line.startsWith('MemAvailable:')) {
            final value = line.split(RegExp(r'\s+'))[1];
            availableRam = int.tryParse(value);
          }
        }
        
        if (totalRam != null) {
          info['Total RAM'] = '${(totalRam / 1024 / 1024).toStringAsFixed(2)} GB';
        }
        if (availableRam != null && totalRam != null) {
          final usedRam = totalRam - availableRam;
          info['Used RAM'] = '${(usedRam / 1024 / 1024).toStringAsFixed(2)} GB';
          info['Available RAM'] = '${(availableRam / 1024 / 1024).toStringAsFixed(2)} GB';
        }
      }

      // Read CPU info
      final cpuInfoFile = File('/proc/cpuinfo');
      if (await cpuInfoFile.exists()) {
        final cpuInfo = await cpuInfoFile.readAsString();
        final lines = cpuInfo.split('\n');
        
        int cpuCount = 0;
        String? modelName;
        
        for (var line in lines) {
          if (line.startsWith('processor')) {
            cpuCount++;
          } else if (line.startsWith('model name') && modelName == null) {
            modelName = line.split(':')[1].trim();
          }
        }
        
        if (cpuCount > 0) {
          info['CPU Cores'] = cpuCount.toString();
        }
        if (modelName != null) {
          info['CPU Model'] = modelName;
        }
      }
    } catch (e) {
      // Handle errors
    }

    return info;
  }
}

