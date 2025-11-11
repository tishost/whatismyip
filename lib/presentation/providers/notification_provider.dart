import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'theme_provider.dart';

class NotificationNotifier extends StateNotifier<bool> {
  final SharedPreferences _prefs;

  NotificationNotifier(this._prefs) : super(true) {
    _loadNotificationPreference();
  }

  Future<void> _loadNotificationPreference() async {
    state = _prefs.getBool('notifications_enabled') ?? true;
  }

  Future<void> setNotificationsEnabled(bool enabled) async {
    state = enabled;
    await _prefs.setBool('notifications_enabled', enabled);
  }
}

// Notification provider
final notificationProvider = StateNotifierProvider<NotificationNotifier, bool>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return NotificationNotifier(prefs);
});
