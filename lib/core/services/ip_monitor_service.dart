// ignore_for_file: uri_does_not_exist, undefined_identifier, undefined_function, undefined_method
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class IpMonitorService {
  static const String ipCheckTask = 'ipCheckTask';
  static const String lastKnownIpKey = 'last_known_ip';

  static final FlutterLocalNotificationsPlugin notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
    );

    await notificationsPlugin.initialize(settings);

    await Workmanager().initialize(
      ipMonitorCallbackDispatcher,
      isInDebugMode: kDebugMode,
    );
  }

  static Future<void> startMonitoring() async {
    await Workmanager().registerPeriodicTask(
      ipCheckTask, // unique name
      ipCheckTask, // task name
      frequency: const Duration(minutes: 15),
      initialDelay: const Duration(seconds: 10),
      existingWorkPolicy: ExistingWorkPolicy.keep,
      constraints: Constraints(
        networkType: NetworkType.connected,
      ),
    );
  }

  static Future<void> stopMonitoring() async {
    await Workmanager().cancelByUniqueName(ipCheckTask);
  }

  static Future<String> _getCurrentIp() async {
    try {
      final response = await http.get(Uri.parse('https://api.ipify.org'));
      if (response.statusCode == 200) {
        return response.body.trim();
      }
      return 'unknown';
    } catch (_) {
      return 'unknown';
    }
  }

  static Future<void> _showIpChangeNotification(
    String oldIp,
    String newIp,
  ) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'ip_change_channel',
      'IP Change Notifications',
      channelDescription: 'Notifications when your IP address changes',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
    );
    const NotificationDetails details =
        NotificationDetails(android: androidDetails);
    await notificationsPlugin.show(
      0,
      '🌐 IP Address Changed',
      'Your IP changed from $oldIp to $newIp',
      details,
    );
  }

  static Future<void> _checkIpChange() async {
    final prefs = await SharedPreferences.getInstance();
    final String? lastIp = prefs.getString(lastKnownIpKey);
    final String currentIp = await _getCurrentIp();

    if (lastIp == null) {
      await prefs.setString(lastKnownIpKey, currentIp);
      return;
    }

    if (lastIp != currentIp) {
      await _showIpChangeNotification(lastIp, currentIp);
      await prefs.setString(lastKnownIpKey, currentIp);
    }
  }
}

@pragma('vm:entry-point')
void ipMonitorCallbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    WidgetsFlutterBinding.ensureInitialized();
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings settings =
        InitializationSettings(android: androidSettings);
    await IpMonitorService.notificationsPlugin.initialize(settings);

    try {
      await IpMonitorService._checkIpChange();
      return Future.value(true);
    } catch (_) {
      return Future.value(true);
    }
  });
}


