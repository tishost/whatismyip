import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/timezone.dart' as tz;
import 'dart:io';

class NotificationService {
  static final NotificationService instance = NotificationService._init();
  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  bool _permissionGranted = false;

  NotificationService._init();

  Future<void> initialize() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(initSettings);
    await requestNotificationPermission();
  }

  Future<bool> requestNotificationPermission() async {
    if (Platform.isAndroid) {
      // Android 13+ (API 33+) requires POST_NOTIFICATIONS permission
      if (await Permission.notification.isDenied) {
        final status = await Permission.notification.request();
        _permissionGranted = status.isGranted;
        return _permissionGranted;
      } else {
        _permissionGranted = await Permission.notification.isGranted;
        return _permissionGranted;
      }
    } else if (Platform.isIOS) {
      // iOS permission is requested automatically on first notification
      final result = await _notifications
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
      _permissionGranted = result ?? false;
      return _permissionGranted;
    }
    return true;
  }

  Future<bool> isPermissionGranted() async {
    if (Platform.isAndroid) {
      final status = await Permission.notification.status;
      return status.isGranted;
    } else if (Platform.isIOS) {
      // For iOS, check if permissions were granted
      // Note: iOS doesn't have a direct way to check, so we assume granted if initialized
      return true; // iOS will show permission dialog on first notification
    }
    return true;
  }

  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    // Check permission before showing notification
    final hasPermission = await isPermissionGranted();
    if (!hasPermission) {
      return;
    }

    const androidDetails = AndroidNotificationDetails(
      'ip_channel',
      'IP Notifications',
      channelDescription: 'Notifications for IP changes',
      importance: Importance.high,
      priority: Priority.high,
      enableVibration: true,
      playSound: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(id, title, body, details);
  }

  Future<void> scheduleDailyNotification({
    required int id,
    required String title,
    required String body,
    required tz.TZDateTime scheduledDate,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'ip_channel',
      'IP Notifications',
      channelDescription: 'Daily IP change notifications',
      importance: Importance.high,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails();

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.zonedSchedule(
      id,
      title,
      body,
      scheduledDate,
      details,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }
}

